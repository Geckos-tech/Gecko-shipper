param(
  [int]$Limit = 100,
  [int]$Offset = 0
)

$envFile = 'C:\Users\yetig\.openclaw\workspace\integrations\gohighlevel\.env'
Get-Content $envFile |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }

$locationId = [Environment]::GetEnvironmentVariable('GHL_LOCATION_ID', 'Process')
if (-not $locationId) { throw 'Missing GHL_LOCATION_ID' }

$path = "/payments/orders?altId=$locationId&altType=location&locationId=$locationId&limit=$Limit&offset=$Offset"
$json = powershell -ExecutionPolicy Bypass -File "C:\Users\yetig\.openclaw\workspace\skills\gohighlevel-api\scripts\ghl-request.ps1" -Method GET -Path $path
$obj = $json | ConvertFrom-Json

$openOrders = $obj.data | Where-Object {
  $_.fulfillmentStatus -eq 'unfulfilled' -or $_.status -eq 'pending'
}

$result = [PSCustomObject]@{
  totalCount = $obj.totalCount
  fetchedCount = @($obj.data).Count
  openCount = @($openOrders).Count
  openOrders = $openOrders
}

$result | ConvertTo-Json -Depth 20
