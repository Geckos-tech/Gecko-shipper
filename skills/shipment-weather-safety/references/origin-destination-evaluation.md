# Origin and destination evaluation

The shipping agent now evaluates more than just the customer destination.

## Origin source

Origin address is loaded from the local FedEx integration environment:

- `FEDEX_ORIGIN_STREET`
- `FEDEX_ORIGIN_CITY`
- `FEDEX_ORIGIN_STATE`
- `FEDEX_ORIGIN_POSTAL`
- `FEDEX_ORIGIN_COUNTRY`

## Current checked points

The weather-ready shipment builder now prepares:

1. origin point (YetiGex ship-from)
2. destination point (customer ship-to)

Both points are geocoded to latitude/longitude and then passed into the weather-enriched evaluator.

## Why this matters

A live-animal shipment can be unsafe either:

- at origin before departure
- at destination on arrival
- or later, once transit assumptions are added, during the route itself

Origin + destination is the minimum serious weather screen.

## Remaining next layer

After origin/destination checks, the next carrier-aware layer is:

- FedEx service availability
- transit timing / delivery commitment assumptions
- best-effort route or corridor decision support
