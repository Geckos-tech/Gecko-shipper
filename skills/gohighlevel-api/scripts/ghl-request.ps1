param(
  [Parameter(Mandatory=$true)] [string]$Method,
  [Parameter(Mandatory=$true)] [string]$Path,
  [string]$BodyFile,
  [string]$BaseUrl = 'https://services.leadconnectorhq.com'
)

$envFile = 'C:\Users\yetig\.openclaw\workspace\integrations\gohighlevel\.env'
if (-not (Test-Path $envFile)) {
  throw "Missing env file: $envFile"
}

Get-Content $envFile |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }

$apiKey = [Environment]::GetEnvironmentVariable('GHL_API_KEY', 'Process')
$locationId = [Environment]::GetEnvironmentVariable('GHL_LOCATION_ID', 'Process')

if (-not $apiKey) { throw 'Missing GHL_API_KEY' }
if (-not $locationId) { throw 'Missing GHL_LOCATION_ID' }

$headers = @{
  Authorization = "Bearer $apiKey"
  Version = '2021-07-28'
  Accept = 'application/json'
  'Content-Type' = 'application/json'
  'Location-Id' = $locationId
}

$uri = "$BaseUrl$Path"
$invokeParams = @{
  Method = $Method
  Uri = $uri
  Headers = $headers
}

if ($BodyFile) {
  if (-not (Test-Path $BodyFile)) {
    throw "Body file not found: $BodyFile"
  }
  $invokeParams.Body = Get-Content $BodyFile -Raw
}

$response = Invoke-RestMethod @invokeParams
$response | ConvertTo-Json -Depth 20
