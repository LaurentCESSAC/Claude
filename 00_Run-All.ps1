#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Script principal : exécute les deux opérations de gestion des utilisateurs Windows 11.

.DESCRIPTION
    1. Crée le compte "Admin_Local" avec tous les droits administrateur.
    2. Restreint le compte "Laurent Cessac" pour interdire l'installation de logiciels.

.NOTES
    Doit être exécuté en tant qu'Administrateur depuis PowerShell.

.EXAMPLE
    # Depuis PowerShell en tant qu'Administrateur :
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\00_Run-All.ps1
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  Gestion des utilisateurs Windows 11"        -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta

# ─── Opération 1 ────────────────────────────────────────────────────────────────
Write-Host "`n>>> ÉTAPE 1 : Création de Admin_Local" -ForegroundColor Magenta
& "$ScriptDir\01_Create-AdminLocal.ps1"

# ─── Opération 2 ────────────────────────────────────────────────────────────────
Write-Host "`n>>> ÉTAPE 2 : Restriction de Laurent Cessac" -ForegroundColor Magenta
& "$ScriptDir\02_Restrict-LaurentCessac.ps1"

Write-Host "`n=============================================" -ForegroundColor Magenta
Write-Host "  Toutes les opérations sont terminées."        -ForegroundColor Magenta
Write-Host "  Redémarrez la session de Laurent Cessac."     -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
