param([switch]$Reload)

$ErrorActionPreference = 'Stop'
$python = Join-Path $PSScriptRoot '.venv/Scripts/python.exe'
$envFile = Join-Path $PSScriptRoot '.env'

if (-not (Test-Path -LiteralPath $python)) {
    throw 'Create .venv and install requirements.txt first.'
}

$keyConfigured = -not [string]::IsNullOrWhiteSpace($env:TUNIFLOW_ML_API_KEY)
if (-not $keyConfigured -and (Test-Path -LiteralPath $envFile)) {
    $keyConfigured = [bool](Select-String -LiteralPath $envFile -Pattern '^TUNIFLOW_ML_API_KEY=(?!CHANGE_ME)' -Quiet)
}
if (-not $keyConfigured) {
    throw 'Set TUNIFLOW_ML_API_KEY in .env or in the current PowerShell session.'
}

$uvicornArgs = @('-m', 'uvicorn', 'app.main:app', '--host', '127.0.0.1', '--port', '8001')
if (Test-Path -LiteralPath $envFile) { $uvicornArgs += @('--env-file', $envFile) }
if ($Reload) { $uvicornArgs += @('--reload', '--reload-dir', 'app') }

Push-Location -LiteralPath $PSScriptRoot
try {
    & $python @uvicornArgs
    if ($LASTEXITCODE -ne 0) { throw "Uvicorn exited with code $LASTEXITCODE." }
} finally {
    Pop-Location
}
