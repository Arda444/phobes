# Phobes web release build (Firebase Hosting).
# Regenerates Material icon manifest (icon tree shaker) then builds release web.
# --no-wasm-dry-run: hides Wasm compatibility info (app still builds with dart2js, not Wasm).

param(
    [string]$RecaptchaSiteKey = $env:RECAPTCHA_SITE_KEY
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not $RecaptchaSiteKey) {
    Write-Host "Warning: RECAPTCHA_SITE_KEY not set. Pass -RecaptchaSiteKey or set env var." -ForegroundColor Yellow
}

$define = @()
if ($RecaptchaSiteKey) {
    $define += "--dart-define=RECAPTCHA_SITE_KEY=$RecaptchaSiteKey"
}

dart run tool/generate_icon_manifest.dart

flutter build web --release `
    --no-wasm-dry-run `
    @define

Write-Host "Output: build\web" -ForegroundColor Green
