$ErrorActionPreference = "Stop"
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    if (-not (Test-Path '.venv/Scripts/python.exe')) { throw 'Run scripts/setup-web.ps1 first' }
    Push-Location web
    try {
        & npm.cmd run build
        if ($LASTEXITCODE -ne 0) { throw 'Web build failed' }
    } finally { Pop-Location }
    Write-Host 'Asset Library: http://127.0.0.1:8765  (Ctrl+C to stop)'
    & .venv/Scripts/python.exe local-api/run.py
} finally { Pop-Location }
