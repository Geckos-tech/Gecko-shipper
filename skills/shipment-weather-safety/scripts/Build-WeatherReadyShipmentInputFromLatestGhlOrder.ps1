param(
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-weather-ready-shipment-input.json',
  [string]$ShipmentDate
)

$workspace = 'C:\Users\yetig\.openclaw\workspace'
$openOrdersScript = Join-Path $workspace 'skills\gohighlevel-api\scripts\ghl-open-orders.ps1'
$getOrderScript = Join-Path $workspace 'skills\gohighlevel-api\scripts\ghl-request.ps1'
$normalizeScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Convert-GhlOrderToShipmentInput.ps1'
$geocodeScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Get-LatLonForAddress.ps1'
$fedexEnvFile = Join-Path $workspace 'integrations\fedex\.env'

if (-not (Test-Path $fedexEnvFile)) {
  throw "Missing env file: $fedexEnvFile"
}

Get-Content $fedexEnvFile |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }

$originStreet = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_STREET', 'Process')
$originCity = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_CITY', 'Process')
$originState = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_STATE', 'Process')
$originPostal = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_POSTAL', 'Process')
$originCountry = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_COUNTRY', 'Process')

$ordersJson = powershell -ExecutionPolicy Bypass -File $openOrdersScript
$ordersObject = $ordersJson | ConvertFrom-Json
$latestOrderSummary = @($ordersObject.openOrders | Where-Object { $_.paymentStatus -eq 'paid' -or $_.status -eq 'completed' } | Select-Object -First 1)[0]
if ($null -eq $latestOrderSummary) {
  throw 'No suitable open order found.'
}

$orderPath = "/payments/orders/$($latestOrderSummary._id)?altId=$($latestOrderSummary.altId)&altType=$($latestOrderSummary.altType)&locationId=$($latestOrderSummary.altId)"
$orderJson = powershell -ExecutionPolicy Bypass -File $getOrderScript -Method GET -Path $orderPath
$order = $orderJson | ConvertFrom-Json

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid().ToString()) + '.json')
$order | ConvertTo-Json -Depth 25 | Set-Content -Path $tempFile -Encoding UTF8

try {
  $args = @('-ExecutionPolicy','Bypass','-File',$normalizeScript,'-InputFile',$tempFile)
  if ($ShipmentDate) {
    $args += @('-ShipmentDate',$ShipmentDate)
  }
  $normalizedJson = & powershell @args
  $normalized = $normalizedJson | ConvertFrom-Json

  $checkedPoints = [System.Collections.ArrayList]::new()

  if (-not [string]::IsNullOrWhiteSpace($originStreet) -and -not [string]::IsNullOrWhiteSpace($originCity) -and -not [string]::IsNullOrWhiteSpace($originState) -and -not [string]::IsNullOrWhiteSpace($originPostal)) {
    $originGeoJson = powershell -ExecutionPolicy Bypass -File $geocodeScript -Address1 $originStreet -City $originCity -State $originState -PostalCode $originPostal -Country $originCountry
    $originGeo = $originGeoJson | ConvertFrom-Json

    [void]$checkedPoints.Add([PSCustomObject]@{
      type = 'origin'
      label = 'YetiGex origin'
      forecast = [PSCustomObject]@{
        lowF = $null
        highF = $null
      }
      address = [PSCustomObject]@{
        rawAvailable = $true
        address1 = $originStreet
        city = $originCity
        state = $originState
        postalCode = $originPostal
        country = $originCountry
        geocoder = $originGeo.source
        geocodedDisplayName = $originGeo.displayName
      }
      latitude = $originGeo.latitude
      longitude = $originGeo.longitude
    })
  }

  foreach ($point in @($normalized.checkedPoints)) {
    if ($point.type -eq 'destination' -and $point.address.rawAvailable) {
      $geoJson = powershell -ExecutionPolicy Bypass -File $geocodeScript -Address1 $point.address.address1 -City $point.address.city -State $point.address.state -PostalCode $point.address.postalCode -Country $point.address.country
      $geo = $geoJson | ConvertFrom-Json

      $point | Add-Member -NotePropertyName latitude -NotePropertyValue $geo.latitude -Force
      $point | Add-Member -NotePropertyName longitude -NotePropertyValue $geo.longitude -Force
      $point.address | Add-Member -NotePropertyName geocoder -NotePropertyValue $geo.source -Force
      $point.address | Add-Member -NotePropertyName geocodedDisplayName -NotePropertyValue $geo.displayName -Force
    }

    [void]$checkedPoints.Add($point)
  }

  $normalized.checkedPoints = @($checkedPoints)

  $assumptions = [System.Collections.Generic.List[string]]::new()
  foreach ($a in @($normalized.assumptions)) {
    if ($a -ne 'Origin point not injected yet.' -and $a -ne 'Geocoding is not wired yet.') {
      [void]$assumptions.Add($a)
    }
  }
  [void]$assumptions.Add('Origin address loaded from FedEx integration env.')
  [void]$assumptions.Add('Origin and destination geocoded with Nominatim for weather evaluation.')
  $normalized.assumptions = @($assumptions)

  $normalizedJsonOut = $normalized | ConvertTo-Json -Depth 15
  [System.IO.File]::WriteAllText($OutputFile, $normalizedJsonOut, [System.Text.UTF8Encoding]::new($false))
  $normalizedJsonOut
}
finally {
  if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
}
