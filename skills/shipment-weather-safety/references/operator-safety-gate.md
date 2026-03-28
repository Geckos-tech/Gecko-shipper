# Operator safety gate

The shipping-agent workflow now includes a final operator safety gate.

## Purpose

Separate two different questions:

1. Is the shipment payload technically ready for a live label creation call?
2. Is the shipment actually approved to ship under current policy/weather?

These are not the same thing.

## Output fields

- `payloadReadyForLiveLabelCreation`
- `policyApprovedForShipment`
- `operatorDisposition`
- `blockingIssues`
- `warnings`
- `reasons`
- `reviewOnly`

## Operator dispositions

- `DO_NOT_CREATE_LABEL`
- `REVIEW_REQUIRED`
- `READY_FOR_OPERATOR_APPROVAL`

## Current rule set

- If payload is not technically ready → `DO_NOT_CREATE_LABEL`
- If shipment decision is `HOLD` → `DO_NOT_CREATE_LABEL`
- If payload is ready and shipment decision is `SAFE` → `READY_FOR_OPERATOR_APPROVAL`
- Otherwise → `REVIEW_REQUIRED`

## Safety boundary

This gate does not create or buy labels. It is an explicit review-layer control.
