$ErrorActionPreference = 'Stop'
node "$PSScriptRoot/project.mjs" setup
exit $LASTEXITCODE
