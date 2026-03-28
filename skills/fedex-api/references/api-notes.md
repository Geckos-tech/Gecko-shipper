# FedEx local integration notes

## Credential source

Use `C:/Users/yetig/.openclaw/workspace/integrations/fedex/.env`.

Expected variables:

- `FEDEX_TEST_BASE_URL`
- `FEDEX_TEST_KEY`
- `FEDEX_TEST_SECRET`
- `FEDEX_ACCOUNT_NUMBER`
- origin address values

## Auth

FedEx APIs use OAuth 2.0 bearer tokens.

Request a token with `client_credentials` using the API key and secret, then pass:

- `Authorization: Bearer <token>`
- `Content-Type: application/json`
- `X-locale: en_US` (optional but useful)

## Scripts

### Get token

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\yetig\.openclaw\workspace\skills\fedex-api\scripts\fedex-token.ps1"
```

### Make a request

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\yetig\.openclaw\workspace\skills\fedex-api\scripts\fedex-request.ps1" -Method POST -Path "/rate/v1/rates/quotes" -BodyFile "C:\path\to\body.json"
```

## Planning use

For live-animal shipment planning, the likely useful APIs are:

- Address Validation
- Service Availability
- Rates and Transit Times
- Ship API (only after approval / when actually shipping)

## Limits

FedEx may not expose exact planned hub-by-hub routing pre-shipment. If exact routing is unavailable, use:

- origin
- destination
- service level
- estimated transit window
- likely shipping corridor / major transit approximation
