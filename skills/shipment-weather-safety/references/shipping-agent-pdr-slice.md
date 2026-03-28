# Shipping agent PDR slice

This document captures the shipping-agent-only portion of the fulfillment workflow currently being built.

## Scope

The shipping agent is responsible for deciding whether a live-animal order is safe to ship today using the intended service level.

It does **not** yet:

- create FedEx labels
- buy postage
- schedule pickups
- update remote fulfillment records automatically

## Goal

Given an order and shipment date, return a repeatable shipment recommendation:

- `SAFE`
- `HOLD`
- `REVIEW`

with enough supporting detail for a human to act confidently.

## Inputs

Required inputs:

- order id
- recipient name
- destination address
- shipment date
- requested or default shipping service

Optional but useful inputs:

- phone/email
- package type
- box count
- animal type / sensitivity notes
- special handling notes

## Current source systems

### Order intake

Source: GoHighLevel orders API.

Current known usable path:

- `/payments/orders?altId=<locationId>&altType=location&locationId=<locationId>`

### Carrier planning

Source: FedEx APIs.

Current planned pre-shipment usage:

- OAuth token
- service availability
- rates/transit times
- address validation if needed

### Weather decisioning

Source: weather checks for:

- origin
- destination
- likely transit corridor / hub approximation when possible

## Business policy

Use the current explicit live-animal policy:

- minimum safe temperature: `30 F`
- maximum safe temperature: `85 F`
- if any checked stop is forecast outside range, `HOLD`
- include overnight lows and daytime highs
- check same-day conditions
- primary service: `FedEx Priority Overnight`

## Decision model

### SAFE

Return `SAFE` when:

- address is shippable
- service is available
- expected transit fits the shipment window
- all checked locations are forecast within policy range
- assumptions are acceptable

### HOLD

Return `HOLD` when:

- any checked point is below 30 F or above 85 F
- destination or origin conditions clearly violate policy
- required overnight protection window appears unsafe

### REVIEW

Return `REVIEW` when:

- route certainty is weak
- weather confidence is weak
- address or serviceability is ambiguous
- carrier results conflict with internal assumptions

## Proposed evaluator phases

### Phase 1: Order normalization

Normalize an incoming order into a shipping-evaluation object containing:

- order metadata
- recipient identity
- normalized destination address
- requested shipping service
- shipment date

### Phase 2: Carrier planning

Query FedEx for best-effort planning data:

- validate destination if needed
- confirm service availability
- obtain expected transit timing for Priority Overnight

Output:

- chosen service
- estimated delivery day/window
- planning assumptions

### Phase 3: Weather coverage model

Build checked points list:

1. origin
2. destination
3. best-effort transit point(s), if available

For each checked point collect:

- daily high
- overnight low
- forecast date/time context

### Phase 4: Safety decision

Apply explicit threshold policy and return:

- decision
- reasons
- checked points
- forecast ranges
- assumptions
- confidence notes

## Output contract

The shipping agent should emit a structured result like:

```json
{
  "decision": "SAFE",
  "orderId": "example-order-id",
  "shipmentDate": "2026-03-27",
  "service": "FEDEX_PRIORITY_OVERNIGHT",
  "checkedPoints": [
    {
      "type": "origin",
      "label": "Origin facility",
      "forecast": {
        "lowF": 48,
        "highF": 71
      },
      "status": "within-range"
    }
  ],
  "reasons": [
    "All checked points are within the configured 30F-85F range."
  ],
  "assumptions": [
    "FedEx exact hub routing unavailable; best-effort point model used."
  ],
  "confidence": "medium"
}
```

## Immediate next implementation target

Build a local script that accepts a normalized shipment input JSON and returns the structured decision object.

That script should:

1. be safe and read-only
2. avoid secrets in inputs/outputs
3. support plugging in weather retrieval next
4. support plugging in FedEx planning results next

## Current progress

Completed so far:

- local decision evaluator for normalized shipment input
- Open-Meteo weather enrichment for shipment points using latitude/longitude
- GHL order normalization bridge that converts a real order into shipping-agent input shape

Immediate next layer after this:

- destination address enrichment from GHL or related source
- geocoding for destination/origin points
- FedEx service/transit planning enrichment

## Non-goals for this step

This step does not automate:

- customer notification
- warehouse pick/pack
- label purchase
- fulfillment status writes back to GHL
