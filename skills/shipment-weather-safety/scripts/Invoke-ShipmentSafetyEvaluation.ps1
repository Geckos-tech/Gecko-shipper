param(
  [Parameter(Mandatory=$true)] [string]$InputFile
)

if (-not (Test-Path $InputFile)) {
  throw "Input file not found: $InputFile"
}

$inputObject = Get-Content $InputFile -Raw | ConvertFrom-Json

function Add-Reason {
  param(
    [System.Collections.Generic.List[string]]$List,
    [string]$Text
  )

  if ($Text) { [void]$List.Add($Text) }
}

$minSafeF = 30
$maxSafeF = 85

$reasons = [System.Collections.Generic.List[string]]::new()
$assumptions = [System.Collections.Generic.List[string]]::new()
$checkedPointsOut = @()
$decision = 'SAFE'
$confidence = 'medium'

if (-not $inputObject.orderId) { throw 'Missing orderId' }
if (-not $inputObject.shipmentDate) { throw 'Missing shipmentDate' }

if (-not $inputObject.service) {
  $inputObject | Add-Member -NotePropertyName service -NotePropertyValue 'FEDEX_PRIORITY_OVERNIGHT'
  [void]$assumptions.Add('No service supplied; defaulted to FEDEX_PRIORITY_OVERNIGHT.')
}

$checkedPoints = @($inputObject.checkedPoints)
if (-not $checkedPoints -or $checkedPoints.Count -eq 0) {
  $decision = 'REVIEW'
  $confidence = 'low'
  Add-Reason -List $reasons -Text 'No checkedPoints were supplied for weather evaluation.'
  [void]$assumptions.Add('Weather retrieval is not wired yet; this output only validates the decision contract.')
}
else {
  foreach ($point in $checkedPoints) {
    $status = 'within-range'
    $violations = @()

    $lowF = $null
    $highF = $null

    if ($null -ne $point.forecast) {
      $lowF = $point.forecast.lowF
      $highF = $point.forecast.highF
    }

    if ($null -eq $lowF -or $null -eq $highF) {
      $status = 'forecast-missing'
      if ($decision -ne 'HOLD') { $decision = 'REVIEW' }
      $confidence = 'low'
      $violations += 'missing forecast bounds'
      Add-Reason -List $reasons -Text ("Forecast bounds missing for {0}." -f $point.label)
    }
    else {
      if ([double]$lowF -lt $minSafeF) {
        $status = 'below-min'
        $decision = 'HOLD'
        $violations += ("low {0}F below {1}F minimum" -f $lowF, $minSafeF)
      }

      if ([double]$highF -gt $maxSafeF) {
        $status = if ($status -eq 'within-range') { 'above-max' } else { $status }
        $decision = 'HOLD'
        $violations += ("high {0}F above {1}F maximum" -f $highF, $maxSafeF)
      }

      if ($violations.Count -gt 0) {
        Add-Reason -List $reasons -Text ("{0}: {1}." -f $point.label, ($violations -join '; '))
      }
    }

    $checkedPointsOut += [PSCustomObject]@{
      type = $point.type
      label = $point.label
      forecast = [PSCustomObject]@{
        lowF = $lowF
        highF = $highF
      }
      status = $status
    }
  }
}

if ($decision -eq 'SAFE' -and $reasons.Count -eq 0) {
  Add-Reason -List $reasons -Text ("All checked points are within the configured {0}F-{1}F range." -f $minSafeF, $maxSafeF)
}

$result = [PSCustomObject]@{
  decision = $decision
  orderId = $inputObject.orderId
  shipmentDate = $inputObject.shipmentDate
  service = $inputObject.service
  checkedPoints = $checkedPointsOut
  reasons = @($reasons)
  assumptions = @($assumptions)
  confidence = $confidence
}

$result | ConvertTo-Json -Depth 10
