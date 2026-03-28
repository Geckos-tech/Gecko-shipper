---
name: fedex-api
description: Access FedEx sandbox or production APIs from the local OpenClaw workspace using stored credentials and OAuth bearer tokens. Use when authenticating to FedEx, validating shipping addresses, checking service availability, requesting rates/transit times, or preparing repeatable shipping workflows.
---

# FedEx API

Use this skill for repeatable local FedEx API access.

## Credentials

- Read credentials from `integrations/fedex/.env`.
- Never paste raw secrets into chat replies, memory files, or commits.
- FedEx APIs require OAuth bearer tokens.

## Workflow

1. Read `references/api-notes.md` for the auth and request pattern.
2. Use `scripts/fedex-token.ps1` to request a bearer token.
3. Use `scripts/fedex-request.ps1` for API calls.
4. Start with safe read-only endpoints before creating shipments.
5. Prefer Rates and Transit Times plus Service Availability for pre-shipment planning.

## Files

- `references/api-notes.md`
- `scripts/fedex-token.ps1`
- `scripts/fedex-request.ps1`

## Safety

- Default to read-only API calls unless explicitly asked to create shipments or pickups.
- Confirm before creating labels, shipments, or pickup requests.
