# GHL order normalization for shipping agent

This document defines the current bridge from GoHighLevel order data into the shipping-agent input contract.

## Purpose

The shipping agent needs a normalized shipment input object, but current GHL order results do not yet provide a complete destination address payload in the fields already verified.

This bridge therefore does two things:

1. preserves the verified order metadata needed for fulfillment decisions
2. emits a shipment-input-shaped object that can be enriched later with destination address, geocoding, origin, and weather

## Current mapped fields

From the current GHL orders payload we map:

- order id
- contact id
- contact name
- contact email
- source name / source type
- payment status
- fulfillment status
- amount
- currency
- total products
- created timestamp

## Current gaps

Not yet reliably present in the validated sample payload:

- destination street
- city
- state
- postal code
- country
- latitude/longitude

## Resulting behavior

The normalization bridge emits:

- shipping service default (`FEDEX_PRIORITY_OVERNIGHT`)
- shipment date
- customer metadata
- order metadata
- placeholder destination checked point
- explicit assumptions describing missing address/geocode enrichment

## Why this is still useful

It lets the shipping agent pipeline advance in layers:

1. GHL intake
2. normalization
3. address enrichment
4. weather enrichment
5. FedEx planning
6. final decision

That is enough to keep the shipping-agent build moving without guessing hidden address fields.
