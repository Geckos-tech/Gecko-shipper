param(
  [string]$Value,
  [string]$MapFile = 'C:\Users\yetig\.openclaw\workspace\skills\fedex-api\references\state-code-map.json'
)

if ([string]::IsNullOrWhiteSpace($Value)) {
  ''
  return
}

$trimmed = $Value.Trim()
if ($trimmed.Length -eq 2) {
  $trimmed.ToUpperInvariant()
  return
}

if (-not (Test-Path $MapFile)) {
  $trimmed
  return
}

$map = Get-Content $MapFile -Raw | ConvertFrom-Json
$property = $map.PSObject.Properties[$trimmed]
if ($null -ne $property) {
  [string]$property.Value
}
else {
  $trimmed
}
