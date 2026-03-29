$params = '{"userId":"me","maxResults":5}'
& "$PSScriptRoot\Invoke-GwsJson.ps1" -CommandParts @('gmail','users','messages','list') -ParamsJson $params
exit $LASTEXITCODE
