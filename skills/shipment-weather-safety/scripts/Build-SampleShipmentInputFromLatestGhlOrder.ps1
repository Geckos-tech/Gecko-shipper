param(
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-shipment-input.json',
  [string]$ShipmentDate
)

$workspace = 'C:\Users\yetig\.openclaw\workspace'
$openOrdersScript = Join-Path $workspace 'skills\gohighlevel-api\scripts\ghl-open-orders.ps1'
$normalizeScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Convert-GhlOrderToShipmentInput.ps1'

$ordersJson = powershell -ExecutionPolicy Bypass -File $openOrdersScript
$ordersObject = $ordersJson | ConvertFrom-Json
$latestOrder = @($ordersObject.openOrders | Where-Object { $_.paymentStatus -eq 'paid' -or $_.status -eq 'completed' } | Select-Object -First 1)[0]

if ($null -eq $latestOrder) {
  throw 'No suitable open order found to normalize.'
}

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid().ToString()) + '.json')
$latestOrder | ConvertTo-Json -Depth 20 | Set-Content -Path $tempFile -Encoding UTF8

try {
  $args = @('-ExecutionPolicy','Bypass','-File',$normalizeScript,'-InputFile',$tempFile)
  if ($ShipmentDate) {
    $args += @('-ShipmentDate',$ShipmentDate)
  }

  $normalizedJson = & powershell @args
  $normalizedJson | Set-Content -Path $OutputFile -Encoding UTF8
  $normalizedJson
}
finally {
  if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
}
