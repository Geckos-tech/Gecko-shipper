param(
  [string]$ShipmentDate,
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-shipment-decision.json'
)

$workspace = 'C:\Users\yetig\.openclaw\workspace'
$buildInputScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Build-WeatherReadyShipmentInputFromLatestGhlOrder.ps1'
$evaluateScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Invoke-ShipmentSafetyWithWeather.ps1'
$tempInputFile = Join-Path $workspace 'integrations\fulfillment-workflow\latest-weather-ready-shipment-input.json'

$args = @('-ExecutionPolicy','Bypass','-File',$buildInputScript,'-OutputFile',$tempInputFile)
if ($ShipmentDate) {
  $args += @('-ShipmentDate',$ShipmentDate)
}

$builtJson = & powershell @args
if (-not (Test-Path $tempInputFile)) {
  throw 'Weather-ready shipment input was not created.'
}

$resultJson = powershell -ExecutionPolicy Bypass -File $evaluateScript -InputFile $tempInputFile
$result = $resultJson | ConvertFrom-Json
$built = $builtJson | ConvertFrom-Json

$result | Add-Member -NotePropertyName inputSummary -NotePropertyValue ([PSCustomObject]@{
  checkedPointCount = @($built.checkedPoints).Count
  checkedPointTypes = @($built.checkedPoints | ForEach-Object { $_.type })
}) -Force

$resultJsonOut = $result | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($OutputFile, $resultJsonOut, [System.Text.UTF8Encoding]::new($false))
$resultJsonOut
