# FedEx shipment validation

This phase validates a review-only shipment payload against the FedEx shipment validation capability when the correct endpoint is available in the current environment.

## Goal

Check whether the prepared shipment payload is acceptable to FedEx without creating a label or purchasing a shipment.

## Script

- `scripts/Validate-FedexShipmentPayload.ps1`

## Current behavior

The script tries a small set of likely Ship API validation paths and records the result of each attempt.

## Safety

- requires `reviewOnly: true`
- targets validation instead of create shipment
- does not purchase labels
- writes validation output to disk for inspection

## Expected outcome

One of:

- a matching validation endpoint is found and accepts the request
- all candidate paths fail, which indicates the current sandbox/base-url path needs further FedEx-specific confirmation
