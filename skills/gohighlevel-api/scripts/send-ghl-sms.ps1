param(
  [Parameter(Mandatory=$true)] [string]$ContactId,
  [Parameter(Mandatory=$true)] [string]$Phone,
  [Parameter(Mandatory=$true)] [string]$Body,
  [string]$MessageType = 'SMS'
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

$privateIntegration = [Environment]::GetEnvironmentVariable('GHL_PRIVATE_INTEGRATION', 'Process')
$apiKey = [Environment]::GetEnvironmentVariable('GHL_API_KEY', 'Process')
$locationId = [Environment]::GetEnvironmentVariable('GHL_LOCATION_ID', 'Process')
$token = if ($privateIntegration) { $privateIntegration } elseif ($apiKey) { $apiKey } else { $null }

if (-not $token) { throw 'Missing GHL_PRIVATE_INTEGRATION or GHL_API_KEY' }
if (-not $locationId) { throw 'Missing GHL_LOCATION_ID' }

$headers = @{
  Authorization = "Bearer $token"
  Version = '2021-07-28'
  Accept = 'application/json'
  'Content-Type' = 'application/json; charset=utf-8'
  'Location-Id' = $locationId
}

$bodyObj = @{
  type = $MessageType
  contactId = $ContactId
  phone = $Phone
  message = $Body
  body = $Body
}

$json = $bodyObj | ConvertTo-Json -Depth 10
$utf8 = [System.Text.Encoding]::UTF8.GetBytes($json)
$uri = 'https://services.leadconnectorhq.com/conversations/messages'
$response = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $utf8
$response | ConvertTo-Json -Depth 20
