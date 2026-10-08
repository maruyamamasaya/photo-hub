$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location $taskRoot
try {
    & ./scripts/verify-web.ps1
    foreach ($taskCommand in @('check', 'test', 'smoke')) {
        & npm.cmd run $taskCommand --prefix desktop
        if ($LASTEXITCODE -ne 0) { throw "Desktop $taskCommand failed" }
    }
} finally { Pop-Location }
