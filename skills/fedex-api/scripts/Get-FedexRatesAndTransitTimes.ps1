param(
  [Parameter(Mandatory=$true)] [string]$DestinationPostalCode,
  [Parameter(Mandatory=$true)] [string]$DestinationCountryCode,
  [string]$DestinationStateOrProvinceCode
)

$envFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fedex\.env'
if (-not (Test-Path $envFile)) { throw "Missing env file: $envFile" }

Get-Content $envFile |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }

$originPostal = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_POSTAL', 'Process')
$originCountry = [Environment]::GetEnvironmentVariable('FEDEX_ORIGIN_COUNTRY', 'Process')
$accountNumber = [Environment]::GetEnvironmentVariable('FEDEX_ACCOUNT_NUMBER', 'Process')

if (-not $originPostal) { throw 'Missing FEDEX_ORIGIN_POSTAL' }
if (-not $originCountry) { throw 'Missing FEDEX_ORIGIN_COUNTRY' }
if (-not $accountNumber) { throw 'Missing FEDEX_ACCOUNT_NUMBER' }

$body = [ordered]@{
  accountNumber = @{ value = $accountNumber }
  requestedShipment = @{
    shipper = @{
      address = @{
        postalCode = $originPostal
        countryCode = $originCountry
      }
    }
    recipient = @{
      address = @{
        postalCode = $DestinationPostalCode
        countryCode = $DestinationCountryCode
      }
    }
    pickupType = 'DROPOFF_AT_FEDEX_LOCATION'
    rateRequestType = @('ACCOUNT')
    requestedPackageLineItems = @(
      @{
        weight = @{
          units = 'LB'
          value = 1
        }
      }
    )
  }
}

$tempBody = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid().ToString()) + '.json')
[System.IO.File]::WriteAllText($tempBody, ($body | ConvertTo-Json -Depth 20), [System.Text.UTF8Encoding]::new($false))

try {
  $requestScript = 'C:\Users\yetig\.openclaw\workspace\skills\fedex-api\scripts\fedex-request.ps1'
  $requestBodyText = [System.IO.File]::ReadAllText($tempBody, [System.Text.UTF8Encoding]::new($false))
  $responseEnvelope = (& powershell -ExecutionPolicy Bypass -File $requestScript -Method POST -Path '/rate/v1/rates/quotes' -BodyFile $tempBody) | Out-String | ConvertFrom-Json

  if (-not $responseEnvelope.ok -and $responseEnvelope.errorBody -and $responseEnvelope.errorBody.Trim().StartsWith('{')) {
    try {
      $fedexError = $responseEnvelope.errorBody | ConvertFrom-Json
      if ($fedexError.errors -and @($fedexError.errors).Count -gt 0) {
        $firstError = @($fedexError.errors)[0]
        $responseEnvelope.error = $firstError.message
      }
    }
    catch {}
  }

  if (-not $responseEnvelope.ok) {
    [PSCustomObject]@{
      ok = $false
      requestedLane = [PSCustomObject]@{
        originPostalCode = $originPostal
        destinationPostalCode = $DestinationPostalCode
        destinationCountryCode = $DestinationCountryCode
        destinationStateOrProvinceCode = $DestinationStateOrProvinceCode
      }
      error = $responseEnvelope.error
      errorBody = $responseEnvelope.errorBody
      requestBody = $requestBodyText
    } | ConvertTo-Json -Depth 12
    return
  }

  $response = $responseEnvelope.response
  $rateReplyDetails = @($response.output.rateReplyDetails)
  if ($rateReplyDetails.Count -eq 0) {
    [PSCustomObject]@{
      ok = $false
      requestedLane = [PSCustomObject]@{
        originPostalCode = $originPostal
        destinationPostalCode = $DestinationPostalCode
        destinationCountryCode = $DestinationCountryCode
        destinationStateOrProvinceCode = $DestinationStateOrProvinceCode
      }
      error = 'FedEx response contained no rateReplyDetails.'
      requestBody = $requestBodyText
    } | ConvertTo-Json -Depth 12
    return
  }

  $services = foreach ($detail in $rateReplyDetails) {
    $ratedDetail = @($detail.ratedShipmentDetails)[0]
    $shipmentRateDetail = if ($ratedDetail) { $ratedDetail.shipmentRateDetail } else { $null }

    [PSCustomObject]@{
      serviceType = $detail.serviceType
      serviceName = $detail.serviceName
      packagingType = $detail.packagingType
      deliveryDay = if ($detail.commit) { $detail.commit.deliveryDay } else { $null }
      commitDate = if ($detail.commit -and $detail.commit.dateDetail) { $detail.commit.dateDetail.dayFormat } else { $null }
      transitTime = if ($detail.operationalDetail) { $detail.operationalDetail.transitTime } else { $null }
      amount = if ($ratedDetail) { $ratedDetail.totalNetCharge } else { $null }
      currency = if ($ratedDetail) { $ratedDetail.currency } else { $null }
      rateType = if ($ratedDetail) { $ratedDetail.rateType } else { $null }
      rateZone = if ($shipmentRateDetail) { $shipmentRateDetail.rateZone } else { $null }
    }
  }

  $preferred = @($services | Where-Object { $_.serviceType -eq 'PRIORITY_OVERNIGHT' } | Select-Object -First 1)[0]

  [PSCustomObject]@{
    ok = $true
    requestedLane = [PSCustomObject]@{
      originPostalCode = $originPostal
      destinationPostalCode = $DestinationPostalCode
      destinationCountryCode = $DestinationCountryCode
      destinationStateOrProvinceCode = $DestinationStateOrProvinceCode
    }
    services = @($services)
    preferredService = $preferred
    rawAlerts = @($response.output.alerts)
    requestBody = $requestBodyText
  } | ConvertTo-Json -Depth 12
}
finally {
  if (Test-Path $tempBody) { Remove-Item $tempBody -Force }
}
