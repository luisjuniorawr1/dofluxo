# Build + deploy da aplicacao web no Firebase Hosting (site dofluxo-organizer).
# Uso: .\deploy-web.ps1
$ErrorActionPreference = "Stop"

Write-Host "==> Gerando build web (release)..." -ForegroundColor Cyan
flutter build web --release

Write-Host "==> Publicando no Firebase Hosting..." -ForegroundColor Cyan
firebase deploy --only hosting

Write-Host "==> Concluido! App atualizado em https://dofluxo-organizer.web.app" -ForegroundColor Green
