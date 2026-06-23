# Publica o DOFLUXO no Firebase Hosting (build + deploy + verificação).
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot\..

$firebase = Join-Path $PSScriptRoot '..\node_modules\.bin\firebase.cmd'

Write-Host ">> Verificando login Firebase..." -ForegroundColor Cyan
& $firebase login:list 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
  Write-Host "Rode: npx firebase login --reauth" -ForegroundColor Yellow
  exit 1
}

Write-Host ">> flutter build web" -ForegroundColor Cyan
flutter build web
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$html = Get-Content "build\web\index.html" -Raw
if ($html -match 'DOFLUXO_SW_MIGRATING') {
  Write-Error "build/web/index.html ainda contém script legado. Abortando."
}

Write-Host ">> firebase deploy --only hosting" -ForegroundColor Cyan
& $firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
  Write-Host "Se falhar com autenticação: npx firebase login --reauth" -ForegroundColor Yellow
  exit $LASTEXITCODE
}

Write-Host ">> Verificando produção..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
$prod = (Invoke-WebRequest -Uri "https://dofluxo-organizer.web.app/index.html" -UseBasicParsing).Content
if ($prod -match 'DOFLUXO_SW_MIGRATING') {
  Write-Warning "Produção ainda mostra index.html antigo. Aguarde 1 min e recarregue com Ctrl+Shift+R."
} elseif ($prod -match 'flutter-first-frame') {
  Write-Host "OK: produção atualizada." -ForegroundColor Green
} else {
  Write-Warning "Deploy concluído, mas não foi possível confirmar o index.html novo."
}
