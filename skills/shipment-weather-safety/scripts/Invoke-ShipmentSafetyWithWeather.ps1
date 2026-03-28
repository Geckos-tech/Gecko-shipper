param(
  [Parameter(Mandatory=$true)] [string]$InputFile
)

if (-not (Test-Path $InputFile)) {
  throw "Input file not found: $InputFile"
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$getWeatherScript = Join-Path $scriptRoot 'Get-WeatherForShipmentPoint.ps1'
$evaluateScript = Join-Path $scriptRoot 'Invoke-ShipmentSafetyEvaluation.ps1'

$inputObject = Get-Content $InputFile -Raw | ConvertFrom-Json
if (-not $inputObject.orderId) { throw 'Missing orderId' }
if (-not $inputObject.shipmentDate) { throw 'Missing shipmentDate' }

$checkedPoints = @()

foreach ($point in @($inputObject.checkedPoints)) {
  $hasForecast = $false
  if ($null -ne $point.forecast -and $null -ne $point.forecast.lowF -and $null -ne $point.forecast.highF) {
    $hasForecast = $true
  }

  if (-not $hasForecast) {
    if ($null -eq $point.latitude -or $null -eq $point.longitude) {
      $checkedPoints += [PSCustomObject]@{
        type = $point.type
        label = $point.label
        forecast = [PSCustomObject]@{
          lowF = $null
          highF = $null
        }
      }
      continue
    }

    $weatherJson = powershell -ExecutionPolicy Bypass -File $getWeatherScript -Latitude ([string]$point.latitude) -Longitude ([string]$point.longitude) -Label $point.label -Date $inputObject.shipmentDate
    $weather = $weatherJson | ConvertFrom-Json

    $checkedPoints += [PSCustomObject]@{
      type = $point.type
      label = $point.label
      forecast = [PSCustomObject]@{
        lowF = $weather.forecast.lowF
        highF = $weather.forecast.highF
      }
      source = $weather.source
      latitude = $weather.latitude
      longitude = $weather.longitude
    }
  }
  else {
    $checkedPoints += [PSCustomObject]@{
      type = $point.type
      label = $point.label
      forecast = [PSCustomObject]@{
        lowF = $point.forecast.lowF
        highF = $point.forecast.highF
      }
      latitude = $point.latitude
      longitude = $point.longitude
    }
  }
}

$evaluationInput = [PSCustomObject]@{
  orderId = $inputObject.orderId
  shipmentDate = $inputObject.shipmentDate
  service = $inputObject.service
  checkedPoints = $checkedPoints
}

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid().ToString()) + '.json')
$evaluationInput | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Encoding UTF8

try {
  $resultJson = powershell -ExecutionPolicy Bypass -File $evaluateScript -InputFile $tempFile
  $result = $resultJson | ConvertFrom-Json

  $result | Add-Member -NotePropertyName weatherEnriched -NotePropertyValue $true -Force
  $result | ConvertTo-Json -Depth 10
}
finally {
  if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
}
