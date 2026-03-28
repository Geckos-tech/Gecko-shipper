param(
  [string]$ShipmentDate,
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-shipment-decision-with-fedex.json'
)

$workspace = 'C:\Users\yetig\.openclaw\workspace'
$decisionScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Invoke-LatestGhlOrderShipmentDecision.ps1'
$fedexRatesScript = Join-Path $workspace 'skills\fedex-api\scripts\Get-FedexRatesAndTransitTimes.ps1'
$inputFile = Join-Path $workspace 'integrations\fulfillment-workflow\latest-weather-ready-shipment-input.json'

$args = @('-ExecutionPolicy','Bypass','-File',$decisionScript)
if ($ShipmentDate) {
  $args += @('-ShipmentDate',$ShipmentDate)
}
$decisionJson = & powershell @args
$decision = $decisionJson | ConvertFrom-Json

if (-not (Test-Path $inputFile)) {
  throw 'Expected weather-ready shipment input not found.'
}

$input = Get-Content $inputFile -Raw | ConvertFrom-Json
$destination = @($input.checkedPoints | Where-Object { $_.type -eq 'destination' } | Select-Object -First 1)[0]
if ($null -eq $destination) {
  throw 'Destination checked point missing.'
}
if (-not $destination.address -or -not $destination.address.postalCode -or -not $destination.address.country) {
  throw 'Destination address missing postalCode/country.'
}

$rateArgs = @(
  '-ExecutionPolicy','Bypass',
  '-File',$fedexRatesScript,
  '-DestinationPostalCode',$destination.address.postalCode,
  '-DestinationCountryCode',$destination.address.country
)

$fedexJson = & powershell @rateArgs
$fedex = $fedexJson | ConvertFrom-Json

$operatorSummary = [System.Collections.Generic.List[string]]::new()
$transitAssessment = [PSCustomObject]@{
  status = 'unknown'
  notes = @()
}

if ($fedex.ok -and $fedex.preferredService) {
  [void]$operatorSummary.Add(("Preferred FedEx service: {0} at {1} {2}." -f $fedex.preferredService.serviceType, $fedex.preferredService.amount, $fedex.preferredService.currency))
  if ($fedex.preferredService.rateZone) {
    [void]$operatorSummary.Add(("FedEx lane rate zone: {0}." -f $fedex.preferredService.rateZone))
  }

  $transitNotes = [System.Collections.Generic.List[string]]::new()
  $transitStatus = 'review'

  if ($fedex.preferredService.serviceType -eq 'PRIORITY_OVERNIGHT') {
    $transitStatus = 'acceptable'
    [void]$transitNotes.Add('Preferred service is Priority Overnight, which matches the current live-animal shipping preference.')
  }
  else {
    [void]$transitNotes.Add('Preferred service does not match the current Priority Overnight preference.')
  }

  if ($decision.decision -eq 'HOLD') {
    [void]$transitNotes.Add('Transit planning is available, but weather policy already blocks shipment.')
  }

  $transitAssessment = [PSCustomObject]@{
    status = $transitStatus
    notes = @($transitNotes)
  }
}
elseif (-not $fedex.ok) {
  [void]$operatorSummary.Add('FedEx planning unavailable for this run.')
  $transitAssessment = [PSCustomObject]@{
    status = 'unavailable'
    notes = @($fedex.error)
  }
}

$recommendationText = switch ($decision.decision) {
  'SAFE' { 'Ship order using the preferred FedEx service, subject to final operator review.' }
  'HOLD' { 'Hold shipment. Weather policy is not satisfied for the current shipment date.' }
  default { 'Review shipment manually before proceeding.' }
}

$result = [PSCustomObject]@{
  shipmentDecision = $decision
  fedexPlanning = $fedex
  recommendation = [PSCustomObject]@{
    text = $recommendationText
    operatorSummary = @($operatorSummary)
    preferredService = $fedex.preferredService
    transitAssessment = $transitAssessment
  }
}

$resultJsonOut = $result | ConvertTo-Json -Depth 15
[System.IO.File]::WriteAllText($OutputFile, $resultJsonOut, [System.Text.UTF8Encoding]::new($false))
$resultJsonOut
