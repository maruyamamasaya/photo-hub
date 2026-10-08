param([string]$Python = "python")
$ErrorActionPreference = "Stop"
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    if (-not (Test-Path '.venv/Scripts/python.exe')) {
        & $Python -m venv .venv
        if ($LASTEXITCODE -ne 0 -and -not (Test-Path '.venv/Scripts/python.exe')) { throw 'Python venv creation failed' }
    }
    & $Python -m pip --python .venv/Scripts/python.exe install -r local-api/requirements.lock.txt
    if ($LASTEXITCODE -ne 0) { throw 'Python dependency installation failed' }
    Push-Location web
    try {
        & npm.cmd ci
        if ($LASTEXITCODE -ne 0) { throw 'Web dependency installation failed' }
    } finally { Pop-Location }
    & .venv/Scripts/python.exe scripts/generate-contracts.py
    if ($LASTEXITCODE -ne 0) { throw 'Contract generation failed' }
    & .venv/Scripts/python.exe scripts/create-fixtures.py
    if ($LASTEXITCODE -ne 0) { throw 'Fixture creation failed' }
} finally { Pop-Location }
