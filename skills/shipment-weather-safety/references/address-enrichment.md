# Address enrichment for shipping agent

The shipping agent now has a verified path to destination address data.

## Verified source

For a real paid/unfulfilled order, the destination address is available from:

- order detail endpoint: `/payments/orders/{orderId}`
- embedded `contactSnapshot`
- direct contact endpoint: `/contacts/{contactId}`

## Verified fields observed

- `address1`
- `city`
- `state`
- `postalCode`
- `country`
- `phone`
- `email`

## Practical decision

Use the order detail endpoint as the preferred source for shipping evaluation because it keeps the shipping agent tied to the exact order being evaluated.

Use the contact endpoint as fallback or comparison if needed.

## Current enrichment flow

1. fetch latest suitable GHL order summary
2. fetch full order detail
3. normalize into shipping-agent input shape
4. extract destination address from `contactSnapshot`
5. geocode destination into latitude/longitude
6. emit weather-ready shipment input for the evaluator

## Remaining gaps

- inject origin point automatically
- add geocoding for origin
- run live weather evaluation automatically on the enriched file
- add FedEx service/transit planning assumptions
