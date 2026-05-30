# Regenerates lib/l10n/app_localizations*.dart from ARB files (uses l10n.yaml).
$ErrorActionPreference = "Stop"
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    flutter gen-l10n
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host ""
    Write-Host "l10n OK: generated from lib/l10n/app_*.arb (config: l10n.yaml)" -ForegroundColor Green
    Write-Host "The 'Because l10n.yaml exists...' line above is informational only, not an error."
}
finally {
    Pop-Location
}
