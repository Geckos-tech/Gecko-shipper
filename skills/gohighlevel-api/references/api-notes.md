# GoHighLevel local integration notes

## Credential source

Use `C:/Users/yetig/.openclaw/workspace/integrations/gohighlevel/.env`.

## PowerShell env loading pattern

```powershell
Get-Content 'C:\Users\yetig\.openclaw\workspace\integrations\gohighlevel\.env' |
  Where-Object { $_ -and -not $_.StartsWith('#') } |
  ForEach-Object {
    $name, $value = $_ -split '=', 2
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
  }
```

## Request pattern

Use the wrapper script:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\yetig\.openclaw\workspace\skills\gohighlevel-api\scripts\ghl-request.ps1" -Method GET -Path "/<endpoint>"
```

## Headers

The wrapper sends:

- `Authorization: Bearer <GHL_API_KEY>`
- `Version: 2021-07-28`
- `Accept: application/json`
- `Content-Type: application/json`
- `Location-Id: <GHL_LOCATION_ID>`

Adjust later if the specific endpoint expects different auth/header conventions.

## First checks

Start with safe read-only endpoints and inspect response codes before building automations.

## Automation

For repeatable jobs, prefer a small wrapper command or a cron job that invokes the PowerShell script with:

- a fixed method
- a fixed endpoint
- optional JSON body file

Avoid embedding secrets directly in cron payloads; let the script load `.env`.
