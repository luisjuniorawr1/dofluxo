# =============================================================================
# DOFLUXO - Deploy Web com atualizacao obrigatoria
# =============================================================================
# Uso:  .\deploy.ps1
#
# O que faz:
#   1. Le a versao atual em pubspec.yaml (x.y.z+N)
#   2. Incrementa o build number (+N -> +N+1) e grava no pubspec.yaml
#   3. flutter pub get
#   4. flutter build web (release, sem service worker, versao injetada)
#   5. firebase deploy --only hosting
#   6. Imprime a versao publicada
#
# Por que incrementar: o aviso de atualizacao no app SO dispara quando a
# versao publicada (version.json) difere da versao em execucao.
# =============================================================================

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$pubspecPath = Join-Path $PSScriptRoot "pubspec.yaml"

# --- 1) Ler versao atual -----------------------------------------------------
$content = Get-Content $pubspecPath -Raw
$pattern = '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$match = [regex]::Match($content, $pattern)

if (-not $match.Success) {
    Write-Host "ERRO: nao encontrei uma linha 'version: x.y.z+N' em pubspec.yaml." -ForegroundColor Red
    exit 1
}

$major = $match.Groups[1].Value
$minor = $match.Groups[2].Value
$patch = $match.Groups[3].Value
$build = [int]$match.Groups[4].Value

$oldVersion = "$major.$minor.$patch+$build"
$newBuild = $build + 1
$newVersion = "$major.$minor.$patch+$newBuild"

Write-Host ""
Write-Host "Versao atual : $oldVersion" -ForegroundColor DarkGray
Write-Host "Nova versao  : $newVersion" -ForegroundColor Cyan
Write-Host ""

# --- 2) Gravar nova versao ---------------------------------------------------
$newContent = [regex]::Replace($content, $pattern, "version: $newVersion")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($pubspecPath, $newContent, $utf8NoBom)
Write-Host ">> pubspec.yaml atualizado para $newVersion" -ForegroundColor Green

# --- 3) flutter pub get ------------------------------------------------------
Write-Host ""
Write-Host ">> flutter pub get" -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO em 'flutter pub get'." -ForegroundColor Red; exit $LASTEXITCODE }

# --- 4) flutter build web ----------------------------------------------------
Write-Host ""
Write-Host ">> flutter build web (release, sem SW, versao=$newVersion)" -ForegroundColor Cyan
flutter build web `
    --release `
    --pwa-strategy=none `
    --no-web-resources-cdn `
    --no-wasm-dry-run `
    --dart-define=APP_VERSION=$newVersion
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO em 'flutter build web'." -ForegroundColor Red; exit $LASTEXITCODE }

# --- 5) firebase deploy ------------------------------------------------------
Write-Host ""
Write-Host ">> firebase deploy --only hosting" -ForegroundColor Cyan

if (Get-Command firebase -ErrorAction SilentlyContinue) {
    firebase deploy --only hosting
} else {
    Write-Host "   ('firebase' nao encontrado no PATH; usando 'npx firebase-tools')" -ForegroundColor DarkGray
    npx firebase-tools deploy --only hosting
}
if ($LASTEXITCODE -ne 0) { Write-Host "ERRO no deploy do Firebase Hosting." -ForegroundColor Red; exit $LASTEXITCODE }

# --- 6) Sucesso --------------------------------------------------------------
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host " DEPLOY CONCLUIDO - versao publicada: $newVersion" -ForegroundColor Green
Write-Host " https://dofluxo-organizer.web.app" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Clientes com o app aberto serao avisados em ate ~3 min" -ForegroundColor DarkGray
Write-Host "(ou ao focar a janela). Contador de 5 min ate auto-atualizar." -ForegroundColor DarkGray
Write-Host ""
Write-Host "Para testar:" -ForegroundColor Yellow
Write-Host "  1. Abra o site e DEIXE A ABA ABERTA" -ForegroundColor Yellow
Write-Host "  2. Rode .\deploy.ps1 de novo" -ForegroundColor Yellow
Write-Host "  3. Em ate ~3 min (ou ao focar) aparece a notificacao" -ForegroundColor Yellow
