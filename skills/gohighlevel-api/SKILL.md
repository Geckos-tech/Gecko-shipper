---
name: gohighlevel-api
description: Access GoHighLevel (GHL) APIs from the local OpenClaw workspace using stored credentials and repeatable scripts. Use when setting up, testing, or making recurring API calls to GoHighLevel endpoints, especially for location-scoped operations, endpoint exploration, or building autonomous API workflows.
---

# GoHighLevel API

Use this skill for repeatable local GoHighLevel API access.

## Credentials

- Read credentials from `integrations/gohighlevel/.env`.
- Never paste raw secrets into chat replies, memory files, or commits.
- Prefer environment loading over hardcoding credentials in commands.

Expected variables:

- `GHL_LOCATION_ID`
- `GHL_API_KEY`
- `GHL_PRIVATE_INTEGRATION`

## Workflow

1. Read `references/api-notes.md` for the local usage pattern.
2. Load env vars from `integrations/gohighlevel/.env` in the shell session.
3. Use `scripts/ghl-request.ps1` for PowerShell-based API calls.
4. Start by testing a safe read endpoint before doing writes.
5. For recurring tasks, create wrapper scripts or cron jobs that call the script with explicit endpoints and methods.

## Files

- `references/api-notes.md` — local usage notes and safety rules
- `scripts/ghl-request.ps1` — reusable request wrapper for GHL API

## Safety

- Default to GET/read-only unless the user clearly requests writes.
- Confirm before creating, updating, or deleting records remotely.
- Log only sanitized results when storing notes.
