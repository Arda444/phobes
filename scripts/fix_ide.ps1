# Phobes — IDE / analyzer / l10n fix (run from repo root).
# Usage: .\scripts\fix_ide.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "=== 1/5 Clean tool caches ===" -ForegroundColor Cyan
Get-ChildItem -Path . -Recurse -Directory -Filter __pycache__ -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }

Write-Host "=== 2/5 flutter pub get ===" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== 3/5 flutter gen-l10n ===" -ForegroundColor Cyan
flutter gen-l10n
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "l10n OK (l10n.yaml message above is normal, not an error)" -ForegroundColor Green

Write-Host "=== 4/5 dart fix --apply ===" -ForegroundColor Cyan
dart fix --apply

Write-Host "=== 5/5 flutter analyze ===" -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "All checks passed. Restart Dart Analysis Server in IDE if Problems panel is stale." -ForegroundColor Green
