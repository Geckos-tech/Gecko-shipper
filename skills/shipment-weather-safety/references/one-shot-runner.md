# One-shot runner

The shipping agent now has a one-shot local runner for the latest suitable GHL order.

## Runner

`Invoke-LatestGhlOrderShipmentDecision.ps1`

This script performs:

1. fetch/normalize latest suitable GHL order
2. inject origin from FedEx config
3. geocode checked points
4. fetch weather for those points
5. emit final SAFE / HOLD / REVIEW decision

## FedEx planning wrapper

`Invoke-LatestGhlOrderShipmentDecisionWithFedex.ps1`

This extends the one-shot runner by also requesting FedEx rate/transit planning data for the destination.

FedEx planning is now returning valid sandbox rate/transit quote responses. The working request shape uses a minimal account-based rate quote body, omits the extra `shippingChargesPayment` block that caused account mismatch errors, and avoids passing destination state/province text in the integrated rate quote request.

## Current scope

Still read-only:

- no label creation
- no fulfillment writes
- no pickups
