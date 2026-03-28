param(
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-fedex-label-draft.json',
  [string]$PackageProfileFile = 'C:\Users\yetig\.openclaw\workspace\skills\fedex-api\references\package-profile.json'
)

$workspace = 'C:\Users\yetig\.openclaw\workspace'
$decisionWithFedexScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Invoke-LatestGhlOrderShipmentDecisionWithFedex.ps1'
$inputFile = Join-Path $workspace 'integrations\fulfillment-workflow\latest-weather-ready-shipment-input.json'
$envFile = Join-Path $workspace 'integrations\fedex\.env'

$resultJson = powershell -ExecutionPolicy Bypass -File $decisionWithFedexScript
$result = $resultJson | ConvertFrom-Json
$input = Get-Content $inputFile -Raw | ConvertFrom-Json

if (-not (Test-Path $envFile)) { throw "Missing env file: $envFile" }
Get-Content $envFile |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }

if (-not (Test-Path $PackageProfileFile)) { throw "Missing package profile file: $PackageProfileFile" }
$packageProfile = Get-Content $PackageProfileFile -Raw | ConvertFrom-Json

$destinationPoint = @($input.checkedPoints | Where-Object { $_.type -eq 'destination' } | Select-Object -First 1)[0]
$preferredService = $result.fedexPlanning.preferredService
$serviceType = if ($packageProfile.serviceTypeOverride) { $packageProfile.serviceTypeOverride } elseif ($preferredService) { $preferredService.serviceType } else { 'PRIORITY_OVERNIGHT' }

$draft = [PSCustomObject]@{
  orderId = $result.shipmentDecision.orderId
  shipmentDecision = $result.shipmentDecision.decision
  recommendationText = $result.recommendation.text
  proposedCarrier = 'FEDEX'
  proposedService = $serviceType
  shipper = [PSCustomObject]@{
    contactName = 'YetiGex Shipping'
    phoneNumber = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_PHONE', 'Process')
    address = [PSCustomObject]@{
      streetLines = @([Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_STREET', 'Process'))
      city = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_CITY', 'Process')
      stateOrProvinceCode = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_STATE', 'Process')
      postalCode = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_POSTAL', 'Process')
      countryCode = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_COUNTRY', 'Process')
    }
  }
  recipient = [PSCustomObject]@{
    contactName = $input.customer.name
    phoneNumber = $input.customer.phone
    email = $input.customer.email
    address = [PSCustomObject]@{
      streetLines = @($destinationPoint.address.address1)
      city = $destinationPoint.address.city
      stateOrProvinceCode = $destinationPoint.address.state
      postalCode = $destinationPoint.address.postalCode
      countryCode = $destinationPoint.address.country
    }
  }
  package = [PSCustomObject]@{
    packagingType = $packageProfile.packagingType
    weight = $packageProfile.weight
    dimensions = $packageProfile.dimensions
    signatureOptionType = $packageProfile.signatureOptionType
    labelSpecification = $packageProfile.labelSpecification
  }
  validation = [PSCustomObject]@{
    shipperPhonePresent = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_PHONE', 'Process'))
    recipientPhonePresent = -not [string]::IsNullOrWhiteSpace($input.customer.phone)
    recipientAddressPresent = $destinationPoint.address.rawAvailable
    packageDimensionsPresent = ($null -ne $packageProfile.dimensions.length -and $null -ne $packageProfile.dimensions.width -and $null -ne $packageProfile.dimensions.height)
    packageWeightPresent = ($null -ne $packageProfile.weight.value)
  }
  status = 'draft-only'
}

$draftJson = $draft | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($OutputFile, $draftJson, [System.Text.UTF8Encoding]::new($false))
$draftJson
