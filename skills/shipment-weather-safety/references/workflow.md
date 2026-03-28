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

## Local evaluator

Current local evaluator script:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\yetig\.openclaw\workspace\skills\shipment-weather-safety\scripts\Invoke-ShipmentSafetyEvaluation.ps1" -InputFile "C:\Users\yetig\.openclaw\workspace\skills\shipment-weather-safety\references\sample-input.json"
```

This is the current shipping-agent step:

1. accept normalized shipment input
2. evaluate checked point temperature ranges against policy
3. emit a structured SAFE / HOLD / REVIEW decision

Live weather enrichment is now available through a wrapper script that fills in forecast lows/highs from Open-Meteo when latitude/longitude are provided.

### Weather-enriched evaluator

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\yetig\.openclaw\workspace\skills\shipment-weather-safety\scripts\Invoke-ShipmentSafetyWithWeather.ps1" -InputFile "C:\Users\yetig\.openclaw\workspace\skills\shipment-weather-safety\references\sample-weather-input.json"
```

This remains intentionally read-only and still does not create shipments.
