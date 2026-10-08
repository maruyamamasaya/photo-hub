param([switch]$WebLibrary)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    if (-not (Test-Path '.venv/Scripts/python.exe')) { throw 'Run scripts/setup-web.ps1 first' }
    if (-not (Test-Path 'desktop/node_modules/electron/package.json')) { throw 'Run npm.cmd ci --prefix desktop first' }
    & npm.cmd run build --prefix web
    if ($LASTEXITCODE -ne 0) { throw 'Web build failed' }
    if ($WebLibrary) { & npm.cmd start --prefix desktop -- --web-library }
    else { & npm.cmd start --prefix desktop }
    if ($LASTEXITCODE -ne 0) { throw 'Desktop app failed' }
} finally { Pop-Location }
