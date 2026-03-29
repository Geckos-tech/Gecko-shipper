param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('gmail-readonly','contacts-readonly')]
    [string]$Profile
)

$root = Split-Path -Parent $PSScriptRoot
$authRoot = Join-Path $root 'auth'
$profileDir = Join-Path $authRoot $Profile
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

switch ($Profile) {
    'gmail-readonly' {
        $scopes = @(
            'https://www.googleapis.com/auth/gmail.readonly',
            'openid',
            'https://www.googleapis.com/auth/userinfo.email',
            'https://www.googleapis.com/auth/userinfo.profile'
        )
    }
    'contacts-readonly' {
        $scopes = @(
            'https://www.googleapis.com/auth/contacts.readonly',
            'openid',
            'https://www.googleapis.com/auth/userinfo.email',
            'https://www.googleapis.com/auth/userinfo.profile'
        )
    }
}

$scopesArg = ($scopes -join ',')
Write-Host "Starting auth for $Profile"
Write-Host "Scopes: $scopesArg"
Write-Host "Auth store: $profileDir"
Write-Host ""
Write-Host "NOTE: This currently launches gws auth for the requested scope set."
Write-Host "Because gws manages its own store, this script is presently a staging helper while the dedicated wrapper auth flow is completed."
Write-Host ""
& gws auth login --scopes $scopesArg
exit $LASTEXITCODE
