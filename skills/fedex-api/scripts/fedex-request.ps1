param(
  [Parameter(Mandatory=$true)] [string]$Method,
  [Parameter(Mandatory=$true)] [string]$Path,
  [string]$BodyFile,
  [switch]$DebugBody
)

$tokenScript = 'C:\Users\yetig\.openclaw\workspace\skills\fedex-api\scripts\fedex-token.ps1'
$envFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fedex\.env'

if (-not (Test-Path $envFile)) { throw "Missing env file: $envFile" }

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
  Accept = 'application/json'
}

$invokeParams = @{
  Method = $Method
  Uri = "$baseUrl$Path"
  Headers = $headers
  ErrorAction = 'Stop'
}

$bodyText = $null
if ($BodyFile) {
  if (-not (Test-Path $BodyFile)) { throw "Body file not found: $BodyFile" }
  $bodyText = [System.IO.File]::ReadAllText($BodyFile, [System.Text.UTF8Encoding]::new($false))
  $invokeParams.ContentType = 'application/json'
  $invokeParams.Body = $bodyText
}

try {
  $response = Invoke-RestMethod @invokeParams
  [PSCustomObject]@{
    ok = $true
    status = 'success'
    response = $response
  } | ConvertTo-Json -Depth 40
}
catch {
  $errorMessage = $_.Exception.Message
  $errorBody = $null

  if ($_.Exception.Response) {
    try {
      $stream = $_.Exception.Response.GetResponseStream()
      if ($stream) {
        $reader = New-Object System.IO.StreamReader($stream)
        $errorBody = $reader.ReadToEnd()
        $reader.Close()
      }
    }
    catch {
      $errorBody = $null
    }
  }

  if ($DebugBody -and $bodyText) {
    [PSCustomObject]@{
      ok = $false
      status = 'error'
      error = $errorMessage
      errorBody = $errorBody
      requestBody = $bodyText
    } | ConvertTo-Json -Depth 20
  }
  else {
    [PSCustomObject]@{
      ok = $false
      status = 'error'
      error = $errorMessage
      errorBody = $errorBody
    } | ConvertTo-Json -Depth 20
  }
}
