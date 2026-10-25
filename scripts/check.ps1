$ErrorActionPreference = 'Stop'
node "$PSScriptRoot/project.mjs" check
exit $LASTEXITCODE
