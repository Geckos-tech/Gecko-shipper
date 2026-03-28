param(
  [Parameter(Mandatory=$true)] [string]$Method,
  [Parameter(Mandatory=$true)] [string]$Path,
  [string]$BodyFile
)

$tokenScript = 'C:\Users\yetig\.openclaw\workspace\skills\fedex-api\scripts\fedex-token.ps1'
$envFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fedex\.env'

Get-Content $envFile |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }

$baseUrl = [Environment]::GetEnvironmentVariable('FEDEX_TEST_BASE_URL', 'Process')
if (-not $baseUrl) { throw 'Missing FEDEX_TEST_BASE_URL' }

$tokenJson = powershell -ExecutionPolicy Bypass -File $tokenScript
$tokenObj = $tokenJson | ConvertFrom-Json
$token = $tokenObj.access_token
if (-not $token) { throw 'Failed to obtain FedEx access token' }

$headers = @{
  Authorization = "Bearer $token"
  'X-locale' = 'en_US'
}

$invokeParams = @{
  Method = $Method
  Uri = "$baseUrl$Path"
  Headers = $headers
}

if ($BodyFile) {
  if (-not (Test-Path $BodyFile)) { throw "Body file not found: $BodyFile" }
  $invokeParams.ContentType = 'application/json'
  $invokeParams.Body = Get-Content $BodyFile -Raw
}

$response = Invoke-RestMethod @invokeParams
$response | ConvertTo-Json -Depth 20
