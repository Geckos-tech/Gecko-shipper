---
name: shipment-weather-safety
description: Evaluate live-animal shipment safety by combining shipping details, transit assumptions, and weather forecasts against explicit temperature thresholds. Use when deciding whether an order is safe to fulfill for shipment, especially for same-day FedEx Priority Overnight shipments requiring hot/cold weather checks.
---

# Shipment Weather Safety

Use this skill to make repeatable shipping safety decisions for live-animal orders.

## Policy

Read `references/policy.md` for the current safety thresholds and decision rule.

## Workflow

1. Gather shipment origin and destination.
2. Determine the shipping service and expected travel window.
3. Identify route points or best-effort transit points.
4. Check weather for origin, destination, and transit points.
5. Compare highs/lows against the safety policy.
6. Return one of:
   - SAFE
   - HOLD
   - REVIEW

## Files

- `references/policy.md`
- `references/workflow.md`
- `references/shipping-agent-pdr-slice.md`
- `references/sample-input.json`
- `references/sample-weather-input.json`
- `references/ghl-order-normalization.md`
- `references/address-enrichment.md`
- `references/origin-destination-evaluation.md`
- `references/one-shot-runner.md`
- `references/transit-aware-logic.md`
- `references/operator-safety-gate.md`
- `scripts/Invoke-ShipmentSafetyEvaluation.ps1`
- `scripts/Get-WeatherForShipmentPoint.ps1`
- `scripts/Invoke-ShipmentSafetyWithWeather.ps1`
- `scripts/Convert-GhlOrderToShipmentInput.ps1`
- `scripts/Build-SampleShipmentInputFromLatestGhlOrder.ps1`
- `scripts/Get-LatLonForAddress.ps1`
- `scripts/Build-WeatherReadyShipmentInputFromLatestGhlOrder.ps1`

## Safety

- If any checked stop violates the policy, default to HOLD.
- If route certainty is poor, default to REVIEW or HOLD rather than assuming safe travel.
