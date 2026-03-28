param(
  [Parameter(Mandatory=$true)] [string]$PayloadFile
)

if (-not (Test-Path $PayloadFile)) {
  throw "Payload file not found: $PayloadFile"
}

$payload = Get-Content $PayloadFile -Raw | ConvertFrom-Json
$issues = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

$shipment = $payload.requestedShipment
if ($null -eq $shipment) {
  throw 'Payload missing requestedShipment'
}

if ([string]::IsNullOrWhiteSpace($shipment.serviceType)) { [void]$issues.Add('Missing serviceType.') }
if ([string]::IsNullOrWhiteSpace($shipment.packagingType)) { [void]$issues.Add('Missing packagingType.') }
if ($null -eq $shipment.shipper -or $null -eq $shipment.shipper.contact) { [void]$issues.Add('Missing shipper contact.') }
if ($null -eq $shipment.shipper -or $null -eq $shipment.shipper.address) { [void]$issues.Add('Missing shipper address.') }
if ($null -eq $shipment.recipients -or @($shipment.recipients).Count -eq 0) { [void]$issues.Add('Missing recipient.') }

if ($shipment.shipper.contact) {
  if ([string]::IsNullOrWhiteSpace($shipment.shipper.contact.personName)) { [void]$issues.Add('Missing shipper personName.') }
  if ([string]::IsNullOrWhiteSpace($shipment.shipper.contact.phoneNumber)) { [void]$issues.Add('Missing shipper phoneNumber.') }
}

if ($shipment.shipper.address) {
  if ($null -eq $shipment.shipper.address.streetLines -or @($shipment.shipper.address.streetLines).Count -eq 0) { [void]$issues.Add('Missing shipper streetLines.') }
  if ([string]::IsNullOrWhiteSpace($shipment.shipper.address.city)) { [void]$issues.Add('Missing shipper city.') }
  if ([string]::IsNullOrWhiteSpace($shipment.shipper.address.stateOrProvinceCode)) { [void]$issues.Add('Missing shipper stateOrProvinceCode.') }
  if ([string]::IsNullOrWhiteSpace($shipment.shipper.address.postalCode)) { [void]$issues.Add('Missing shipper postalCode.') }
  if ([string]::IsNullOrWhiteSpace($shipment.shipper.address.countryCode)) { [void]$issues.Add('Missing shipper countryCode.') }
}

$recipient = @($shipment.recipients)[0]
if ($recipient.contact) {
  if ([string]::IsNullOrWhiteSpace($recipient.contact.personName)) { [void]$issues.Add('Missing recipient personName.') }
  if ([string]::IsNullOrWhiteSpace($recipient.contact.phoneNumber)) { [void]$warnings.Add('Missing recipient phoneNumber.') }
}
else {
  [void]$issues.Add('Missing recipient contact.')
}

if ($recipient.address) {
  if ($null -eq $recipient.address.streetLines -or @($recipient.address.streetLines).Count -eq 0) { [void]$issues.Add('Missing recipient streetLines.') }
  if ([string]::IsNullOrWhiteSpace($recipient.address.city)) { [void]$issues.Add('Missing recipient city.') }
  if ([string]::IsNullOrWhiteSpace($recipient.address.stateOrProvinceCode)) { [void]$issues.Add('Missing recipient stateOrProvinceCode.') }
  if ([string]::IsNullOrWhiteSpace($recipient.address.postalCode)) { [void]$issues.Add('Missing recipient postalCode.') }
  if ([string]::IsNullOrWhiteSpace($recipient.address.countryCode)) { [void]$issues.Add('Missing recipient countryCode.') }
  if ($recipient.address.stateOrProvinceCode -cmatch '^[A-Z]{2}$' -eq $false) { [void]$warnings.Add('Recipient stateOrProvinceCode is not a 2-letter code.') }
}
else {
  [void]$issues.Add('Missing recipient address.')
}

$package = @($shipment.requestedPackageLineItems)[0]
if ($null -eq $package) {
  [void]$issues.Add('Missing requestedPackageLineItems.')
}
else {
  if ($null -eq $package.weight -or $null -eq $package.weight.value) { [void]$issues.Add('Missing package weight.') }
  if ($null -eq $package.dimensions) { [void]$warnings.Add('Missing package dimensions.') }
}

$result = [PSCustomObject]@{
  readyForLiveLabelCreation = ($issues.Count -eq 0)
  blockingIssues = @($issues)
  warnings = @($warnings)
}

$result | ConvertTo-Json -Depth 10
