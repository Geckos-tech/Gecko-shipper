param(
  [string]$PayloadFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-fedex-shipment-payload.json',
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-fedex-shipment-validation.json'
)

if (-not (Test-Path $PayloadFile)) {
  throw "Payload file not found: $PayloadFile"
}

$payloadRoot = Get-Content $PayloadFile -Raw | ConvertFrom-Json
$payload = if ($payloadRoot.payload) { $payloadRoot.payload } else { $payloadRoot }

if (-not $payload.reviewOnly) {
  throw 'Refusing validation because payload is not marked reviewOnly.'
}

$candidatePaths = @(
  '/ship/v1/shipments/validate',
  '/ship/v1/validateShipment',
  '/ship/v1/shipments/validateShipment'
)

$tempBody = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid().ToString()) + '.json')
try {
  $body = [PSCustomObject]@{
    accountNumber = [PSCustomObject]@{
      value = '210907910'
    }
    requestedShipment = $payload.requestedShipment
  }

  $bodyJson = $body | ConvertTo-Json -Depth 25
  [System.IO.File]::WriteAllText($tempBody, $bodyJson, [System.Text.UTF8Encoding]::new($false))

  $attempts = foreach ($path in $candidatePaths) {
    $responseJson = powershell -ExecutionPolicy Bypass -File 'C:\Users\yetig\.openclaw\workspace\skills\fedex-api\scripts\fedex-request.ps1' -Method POST -Path $path -BodyFile $tempBody
    $response = $responseJson | ConvertFrom-Json

    [PSCustomObject]@{
      path = $path
      response = $response
    }
  }

  $successful = @($attempts | Where-Object { $_.response.ok })
  $result = [PSCustomObject]@{
    reviewOnly = $true
    validationAttempted = $true
    payloadFile = $PayloadFile
    attempts = @($attempts)
    success = (@($successful).Count -gt 0)
    winningPath = if (@($successful).Count -gt 0) { @($successful)[0].path } else { $null }
  }

  $resultJson = $result | ConvertTo-Json -Depth 25
  [System.IO.File]::WriteAllText($OutputFile, $resultJson, [System.Text.UTF8Encoding]::new($false))
  $resultJson
}
finally {
  if (Test-Path $tempBody) { Remove-Item $tempBody -Force }
}
