$envFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fedex\.env'
if (-not (Test-Path $envFile)) { throw "Missing env file: $envFile" }

Get-Content $envFile |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }

$baseUrl = [Environment]::GetEnvironmentVariable('FEDEX_TEST_BASE_URL', 'Process')
$key = [Environment]::GetEnvironmentVariable('FEDEX_TEST_KEY', 'Process')
$secret = [Environment]::GetEnvironmentVariable('FEDEX_TEST_SECRET', 'Process')

if (-not $baseUrl) { throw 'Missing FEDEX_TEST_BASE_URL' }
if (-not $key) { throw 'Missing FEDEX_TEST_KEY' }
if (-not $secret) { throw 'Missing FEDEX_TEST_SECRET' }

$body = @{
  grant_type = 'client_credentials'
  client_id = $key
  client_secret = $secret
}

$response = Invoke-RestMethod -Method POST -Uri "$baseUrl/oauth/token" -ContentType 'application/x-www-form-urlencoded' -Body $body
$response | ConvertTo-Json -Depth 10
