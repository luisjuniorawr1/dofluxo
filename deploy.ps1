# Publica o DOFLUXO web no Firebase Hosting (dofluxo-organizer.web.app).
# Uso: powershell -ExecutionPolicy Bypass -File .\deploy.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ">> flutter pub get"
flutter pub get

Write-Host ">> flutter build web --release"
flutter build web --release

Write-Host ">> firebase deploy --only hosting"
firebase deploy --only hosting

Write-Host ""
Write-Host "Deploy concluido!"
Write-Host "Site: https://dofluxo-organizer.web.app"
Write-Host "Dica: feche a aba e abra de novo (ou Ctrl+Shift+R) para ver a versao nova."
