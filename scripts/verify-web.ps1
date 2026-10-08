$ErrorActionPreference = "Stop"
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    $taskPython = Join-Path $taskRoot '.venv/Scripts/python.exe'
    if (-not (Test-Path $taskPython)) { throw 'Run scripts/setup-web.ps1 first' }
    function Invoke-CheckedPython([string[]]$PythonArgs) {
        & $taskPython @PythonArgs
        if ($LASTEXITCODE -ne 0) { throw "Verification failed: $($PythonArgs -join ' ')" }
    }
    Invoke-CheckedPython -PythonArgs @('scripts/generate-contracts.py', '--check')
    Invoke-CheckedPython -PythonArgs @('scripts/verify.py')
    Invoke-CheckedPython -PythonArgs @('-m', 'unittest', 'discover', '-s', 'local-api/tests', '-v')
    Invoke-CheckedPython -PythonArgs @('-m', 'unittest', 'discover', '-s', 'backend/tests', '-v')
    Push-Location web
    try {
        & npm.cmd run build
        if ($LASTEXITCODE -ne 0) { throw 'Web build failed' }
    } finally { Pop-Location }
    & git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed' }
} finally { Pop-Location }
