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
#   5. firebase deploy --only firestore:rules,hosting
#   6. Imprime a versao publicada
#
# Por que incrementar: o aviso de atualizacao no app SO dispara quando a
# versao publicada (version.json) difere da versao em execucao. Sem bump,
# nenhum cliente sera forcado a atualizar.
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
# Set-Content com -NoNewline preserva o final original do arquivo.
Set-Content -Path $pubspecPath -Value $newContent -NoNewline -Encoding UTF8
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

# --- 5) firebase deploy (rules + hosting) ------------------------------------
Write-Host ""
Write-Host ">> firebase deploy --only firestore:rules,hosting" -ForegroundColor Cyan

$deployArgs = @("deploy", "--only", "firestore:rules,hosting", "--project", "dofluxo-organizer")
if (-not (Get-Command "firebase" -ErrorAction SilentlyContinue)) {
    Write-Host "   ('firebase' nao encontrado no PATH; usando 'npx firebase-tools')" -ForegroundColor DarkGray
    npx firebase-tools @deployArgs
} else {
    firebase @deployArgs
}
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO no deploy do Firebase." -ForegroundColor Red
    Write-Host "Se for autenticacao, no Firebase CLI Win: firebase login --reauth" -ForegroundColor Yellow
    exit $LASTEXITCODE
}

# --- 6) Sucesso --------------------------------------------------------------
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host " DEPLOY CONCLUIDO - versao publicada: $newVersion" -ForegroundColor Green
Write-Host " Rules Firestore + Hosting publicados" -ForegroundColor Green
Write-Host " https://dofluxo-organizer.web.app" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Clientes com o app aberto serao avisados para atualizar em ate ~5 s" -ForegroundColor DarkGray
Write-Host "(ou imediatamente ao focar / voltar para a aba)." -ForegroundColor DarkGray
Write-Host ""
Write-Host "IMPORTANTE: para testar o overlay:" -ForegroundColor Yellow
Write-Host "  1. Abra o site e DEIXE A ABA ABERTA" -ForegroundColor Yellow
Write-Host "  2. Rode .\deploy.ps1 de novo (gera a proxima versao)" -ForegroundColor Yellow
Write-Host "  3. Em ate 5 segundos o overlay 'Atualizar agora' aparece" -ForegroundColor Yellow
