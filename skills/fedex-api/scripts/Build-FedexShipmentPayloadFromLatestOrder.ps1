param(
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-fedex-shipment-payload.json',
  [string]$PackageProfileFile = 'C:\Users\yetig\.openclaw\workspace\skills\fedex-api\references\package-profile.json'
)

$workspace = 'C:\Users\yetig\.openclaw\workspace'
$draftScript = Join-Path $workspace 'skills\fedex-api\scripts\Build-FedexLabelDraftFromLatestOrder.ps1'
$decisionFile = Join-Path $workspace 'integrations\fulfillment-workflow\latest-shipment-decision-with-fedex.json'
$normalizeStateScript = Join-Path $workspace 'skills\fedex-api\scripts\Normalize-StateCode.ps1'
$preflightScript = Join-Path $workspace 'skills\fedex-api\scripts\Test-FedexShipmentPayloadReadiness.ps1'

$draftJson = powershell -ExecutionPolicy Bypass -File $draftScript -PackageProfileFile $PackageProfileFile
$draft = $draftJson | ConvertFrom-Json
$decision = Get-Content $decisionFile -Raw | ConvertFrom-Json

$shipperState = powershell -ExecutionPolicy Bypass -File $normalizeStateScript -Value $draft.shipper.address.stateOrProvinceCode
$recipientState = powershell -ExecutionPolicy Bypass -File $normalizeStateScript -Value $draft.recipient.address.stateOrProvinceCode

$payload = [PSCustomObject]@{
  labelResponseOptions = 'LABEL'
  requestedShipment = [PSCustomObject]@{
    shipDatestamp = $decision.shipmentDecision.shipmentDate
    serviceType = $draft.proposedService
    packagingType = $draft.package.packagingType
    pickupType = 'DROPOFF_AT_FEDEX_LOCATION'
    blockInsightVisibility = $false
    shippingChargesPayment = [PSCustomObject]@{
      paymentType = 'SENDER'
    }
    shipper = [PSCustomObject]@{
      contact = [PSCustomObject]@{
        personName = $draft.shipper.contactName
        phoneNumber = $draft.shipper.phoneNumber
        companyName = 'YetiGex'
      }
      address = [PSCustomObject]@{
        streetLines = $draft.shipper.address.streetLines
        city = $draft.shipper.address.city
        stateOrProvinceCode = $shipperState.Trim()
        postalCode = $draft.shipper.address.postalCode
        countryCode = $draft.shipper.address.countryCode
      }
    }
    recipients = @(
      [PSCustomObject]@{
        contact = [PSCustomObject]@{
          personName = $draft.recipient.contactName
          phoneNumber = $draft.recipient.phoneNumber
        }
        address = [PSCustomObject]@{
          streetLines = $draft.recipient.address.streetLines
          city = $draft.recipient.address.city
          stateOrProvinceCode = $recipientState.Trim()
          postalCode = $draft.recipient.address.postalCode
          countryCode = $draft.recipient.address.countryCode
        }
      }
    )
    labelSpecification = $draft.package.labelSpecification
    requestedPackageLineItems = @(
      [PSCustomObject]@{
        weight = $draft.package.weight
        dimensions = $draft.package.dimensions
      }
    )
  }
  reviewOnly = $true
  reviewNotes = @(
    'This payload is generated for review only and is not submitted to FedEx.',
    'Validate phone numbers, package details, and service choice before any live shipment creation call.',
    ('Current shipping decision: ' + $draft.shipmentDecision),
    ('Recommendation: ' + $draft.recommendationText)
  )
}

$tempPayload = Join-Path ([System.IO.Path]::GetTempPath()) (([System.Guid]::NewGuid().ToString()) + '.json')
try {
  $payloadJson = $payload | ConvertTo-Json -Depth 15
  [System.IO.File]::WriteAllText($tempPayload, $payloadJson, [System.Text.UTF8Encoding]::new($false))
  $preflight = powershell -ExecutionPolicy Bypass -File $preflightScript -PayloadFile $tempPayload | ConvertFrom-Json

  $final = [PSCustomObject]@{
    payload = $payload
    readiness = $preflight
  }

  $finalJson = $final | ConvertTo-Json -Depth 15
  [System.IO.File]::WriteAllText($OutputFile, $finalJson, [System.Text.UTF8Encoding]::new($false))
  $finalJson
}
finally {
  if (Test-Path $tempPayload) { Remove-Item $tempPayload -Force }
}
