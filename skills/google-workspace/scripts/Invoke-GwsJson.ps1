param(
    [Parameter(Mandatory=$true)][string[]]$CommandParts,
    [Parameter(Mandatory=$false)][string]$ParamsJson,
    [Parameter(Mandatory=$false)][string]$BodyJson
)

$argv = @()
$argv += $CommandParts

if ($ParamsJson) {
    $argv += '--params'
    $argv += $ParamsJson
}

if ($BodyJson) {
    $argv += '--json'
    $argv += $BodyJson
}

& gws @argv
exit $LASTEXITCODE
