# =============================================================================
# DOFLUXO - Atualizar e publicar (comando unico)
# =============================================================================
# Uso:  .\deploy-web.ps1
#
# Faz:
#   1. git pull
#   2. build + deploy Firebase (rules + hosting) via deploy.ps1
#
# Nao abre o Chrome. Abas ja abertas recebem o aviso de atualizacao; quem
# abrir depois carrega a versao nova automaticamente.
# =============================================================================

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "DOFLUXO - atualizar codigo e publicar" -ForegroundColor Cyan
Write-Host ""

Write-Host ">> git pull" -ForegroundColor Cyan
git pull
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO no git pull. Resolva conflitos ou autenticacao e tente de novo." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
& (Join-Path $PSScriptRoot "deploy.ps1")
exit $LASTEXITCODE
