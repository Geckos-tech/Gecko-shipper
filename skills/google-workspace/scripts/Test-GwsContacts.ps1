$params = '{"resourceName":"people/me","pageSize":10,"personFields":"names,emailAddresses,phoneNumbers"}'
& "$PSScriptRoot\Invoke-GwsJson.ps1" -CommandParts @('people','people','connections','list') -ParamsJson $params
exit $LASTEXITCODE
