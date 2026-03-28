param(
  [string]$Address1,
  [Parameter(Mandatory=$true)] [string]$City,
  [Parameter(Mandatory=$true)] [string]$State,
  [Parameter(Mandatory=$true)] [string]$PostalCode,
  [string]$Country = 'US'
)

$headers = @{
  'User-Agent' = 'OpenClaw-ShipmentSafety/1.0'
}

function Invoke-GeocodeQuery {
  param([string]$Query)

  $escaped = [System.Uri]::EscapeDataString($Query)
  $uri = "https://nominatim.openstreetmap.org/search?q=$escaped&format=jsonv2&limit=1"
  $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
  if ($response -and @($response).Count -gt 0) {
    return @($response)[0]
  }
  return $null
}

$queries = @()
if (-not [string]::IsNullOrWhiteSpace($Address1)) {
  $queries += (@($Address1, $City, $State, $PostalCode, $Country) -join ', ')
}
$queries += (@($City, $State, $PostalCode, $Country) -join ', ')
$queries += (@($City, $State, $Country) -join ', ')

$match = $null
foreach ($query in $queries) {
  $match = Invoke-GeocodeQuery -Query $query
  if ($null -ne $match) { break }
}

if ($null -eq $match) {
  throw 'No geocoding result found.'
}

$result = [PSCustomObject]@{
  latitude = [double]$match.lat
  longitude = [double]$match.lon
  displayName = $match.display_name
  source = 'Nominatim'
}

$result | ConvertTo-Json -Depth 10
