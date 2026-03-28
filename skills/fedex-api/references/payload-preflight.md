# Payload preflight

The shipment payload generator now includes a preflight readiness check.

## What it does

- validates required shipper fields
- validates required recipient fields
- checks package weight/dimensions presence
- checks state/province code normalization
- reports whether the payload is ready for live label creation

## Output contract

The review payload now contains:

- `payload`
- `readiness.readyForLiveLabelCreation`
- `readiness.blockingIssues`
- `readiness.warnings`

## Safety

This remains review-only and does not submit the payload to FedEx.

Technical payload readiness should be paired with the operator safety gate before any human treats the shipment as actually approved to ship.
