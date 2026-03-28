# Workflow notes

## Inputs needed

- order id
- recipient name
- destination address
- shipping service
- shipment date

## Best-effort route model

If FedEx does not expose exact pre-shipment routing, use a best-effort model:

1. origin weather
2. destination weather
3. likely transit corridor / hub approximation if available
4. service-level transit window

## Output format

Return:

- decision: SAFE / HOLD / REVIEW
- reasons
- checked points
- forecast ranges at each checked point
- assumptions made
