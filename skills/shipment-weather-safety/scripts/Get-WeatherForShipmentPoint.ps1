param(
  [Parameter(Mandatory=$true)] [string]$Latitude,
  [Parameter(Mandatory=$true)] [string]$Longitude,
  [string]$Label = 'Point',
  [string]$Date
)

$lat = [double]$Latitude
$lon = [double]$Longitude

if (-not $Date) {
  $Date = (Get-Date).ToString('yyyy-MM-dd')
}

$uri = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit&timezone=America%2FNew_York&start_date=$Date&end_date=$Date"
$response = Invoke-RestMethod -Method GET -Uri $uri

if (-not $response.daily -or -not $response.daily.time -or $response.daily.time.Count -eq 0) {
  throw "No forecast returned for $Label on $Date"
}

$result = [PSCustomObject]@{
  label = $Label
  latitude = $lat
  longitude = $lon
  date = $Date
  forecast = [PSCustomObject]@{
    lowF = $response.daily.temperature_2m_min[0]
    highF = $response.daily.temperature_2m_max[0]
  }
  source = 'Open-Meteo'
}

$result | ConvertTo-Json -Depth 10
