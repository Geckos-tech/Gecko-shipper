param(
  [Parameter(Mandatory=$true)] [string]$InputFile,
  [string]$ShipmentDate,
  [string]$DefaultService = 'FEDEX_PRIORITY_OVERNIGHT'
)

if (-not (Test-Path $InputFile)) {
  throw "Input file not found: $InputFile"
}

$order = Get-Content $InputFile -Raw | ConvertFrom-Json

if (-not $order._id) { throw 'Missing order _id' }

if (-not $ShipmentDate) {
  $ShipmentDate = (Get-Date).ToString('yyyy-MM-dd')
}

$contact = $order.contactSnapshot
if ($null -eq $contact -and $order.contact) {
  $contact = $order.contact
}

$address1 = $null
$city = $null
$state = $null
$postalCode = $null
$country = $null

if ($null -ne $contact) {
  $address1 = $contact.address1
  $city = $contact.city
  $state = $contact.state
  $postalCode = $contact.postalCode
  $country = $contact.country
}

$hasAddress = -not [string]::IsNullOrWhiteSpace($address1) -and -not [string]::IsNullOrWhiteSpace($city) -and -not [string]::IsNullOrWhiteSpace($state) -and -not [string]::IsNullOrWhiteSpace($postalCode)

$destinationLabel = if ($contact -and $contact.firstName -and $contact.lastName) {
  "$($contact.firstName) $($contact.lastName) destination"
} elseif ($order.contactName) {
  "$($order.contactName) destination"
} else {
  'Customer destination'
}

$assumptions = [System.Collections.Generic.List[string]]::new()
[void]$assumptions.Add('Origin point not injected yet.')
[void]$assumptions.Add('Geocoding is not wired yet.')

if (-not $hasAddress) {
  [void]$assumptions.Add('Destination address is incomplete in the current source payload.')
}

$result = [PSCustomObject]@{
  orderId = $order._id
  shipmentDate = $ShipmentDate
  service = $DefaultService
  customer = [PSCustomObject]@{
    contactId = $order.contactId
    name = if ($contact) { ((@($contact.firstName, $contact.lastName) -join ' ').Trim()) } else { $order.contactName }
    email = if ($contact) { $contact.email } else { $order.contactEmail }
    phone = if ($contact) { $contact.phone } else { $null }
  }
  order = [PSCustomObject]@{
    source = if ($order.source) { $order.source.name } else { $order.sourceName }
    sourceType = if ($order.source) { $order.source.type } else { $order.sourceType }
    status = $order.status
    paymentStatus = $order.paymentStatus
    fulfillmentStatus = $order.fulfillmentStatus
    amount = $order.amount
    currency = $order.currency
    totalProducts = if ($order.items) { @($order.items).Count } else { $order.totalProducts }
    createdAt = $order.createdAt
  }
  checkedPoints = @(
    [PSCustomObject]@{
      type = 'destination'
      label = $destinationLabel
      forecast = [PSCustomObject]@{
        lowF = $null
        highF = $null
      }
      address = [PSCustomObject]@{
        rawAvailable = $hasAddress
        address1 = $address1
        city = $city
        state = $state
        postalCode = $postalCode
        country = $country
      }
    }
  )
  assumptions = @($assumptions)
}

$result | ConvertTo-Json -Depth 10
