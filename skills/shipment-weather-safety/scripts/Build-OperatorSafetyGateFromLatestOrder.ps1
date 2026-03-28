param(
  [string]$OutputFile = 'C:\Users\yetig\.openclaw\workspace\integrations\fulfillment-workflow\latest-operator-safety-gate.json'
)

$workspace = 'C:\Users\yetig\.openclaw\workspace'
$decisionScript = Join-Path $workspace 'skills\shipment-weather-safety\scripts\Invoke-LatestGhlOrderShipmentDecisionWithFedex.ps1'
$payloadScript = Join-Path $workspace 'skills\fedex-api\scripts\Build-FedexShipmentPayloadFromLatestOrder.ps1'

$decisionJson = powershell -ExecutionPolicy Bypass -File $decisionScript
$decision = $decisionJson | ConvertFrom-Json

$payloadJson = powershell -ExecutionPolicy Bypass -File $payloadScript
$payloadResult = $payloadJson | ConvertFrom-Json

$payloadReady = $false
if ($payloadResult.readiness) {
  $payloadReady = [bool]$payloadResult.readiness.readyForLiveLabelCreation
}

$policyApproved = ($decision.shipmentDecision.decision -eq 'SAFE')
$weatherBlocked = ($decision.shipmentDecision.decision -eq 'HOLD')

$operatorDisposition = if (-not $payloadReady) {
  'DO_NOT_CREATE_LABEL'
} elseif ($weatherBlocked) {
  'DO_NOT_CREATE_LABEL'
} elseif ($policyApproved) {
  'READY_FOR_OPERATOR_APPROVAL'
} else {
  'REVIEW_REQUIRED'
}

$reasons = [System.Collections.Generic.List[string]]::new()
if ($payloadReady) {
  [void]$reasons.Add('Shipment payload is technically ready for live label creation.')
}
else {
  [void]$reasons.Add('Shipment payload is not technically ready for live label creation.')
}

if ($policyApproved) {
  [void]$reasons.Add('Shipment decision is SAFE under current policy.')
}
elseif ($weatherBlocked) {
  [void]$reasons.Add('Shipment decision is HOLD under current weather policy.')
}
else {
  [void]$reasons.Add('Shipment decision requires manual review.')
}

if ($decision.recommendation -and $decision.recommendation.operatorSummary) {
  foreach ($line in @($decision.recommendation.operatorSummary)) {
    [void]$reasons.Add($line)
  }
}

$result = [PSCustomObject]@{
  orderId = $decision.shipmentDecision.orderId
  shipmentDate = $decision.shipmentDecision.shipmentDate
  shipmentDecision = $decision.shipmentDecision.decision
  payloadReadyForLiveLabelCreation = $payloadReady
  policyApprovedForShipment = $policyApproved
  operatorDisposition = $operatorDisposition
  blockingIssues = if ($payloadResult.readiness) { @($payloadResult.readiness.blockingIssues) } else { @('Missing payload readiness result.') }
  warnings = if ($payloadResult.readiness) { @($payloadResult.readiness.warnings) } else { @() }
  reasons = @($reasons)
  reviewOnly = $true
}

$resultJson = $result | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($OutputFile, $resultJson, [System.Text.UTF8Encoding]::new($false))
$resultJson
