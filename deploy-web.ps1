# Atalho legado — encaminha para .\deploy.ps1 (bump de versao + build + hosting).
# Uso: .\deploy-web.ps1
$ErrorActionPreference = "Stop"
& "$PSScriptRoot\deploy.ps1"
