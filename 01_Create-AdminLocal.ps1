#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Crée un utilisateur local "Admin_Local" avec tous les droits administrateur.

.DESCRIPTION
    Ce script crée un compte utilisateur local "Admin_Local" sur Windows 11
    et l'ajoute au groupe Administrateurs pour lui accorder tous les privilèges.

.NOTES
    Doit être exécuté en tant qu'Administrateur.
#>

# ─── Paramètres ────────────────────────────────────────────────────────────────
$Username    = "Admin_Local"
$Description = "Compte administrateur local avec tous les droits"

# ─── Demande sécurisée du mot de passe ─────────────────────────────────────────
$SecurePassword = Read-Host -Prompt "Mot de passe pour '$Username'" -AsSecureString

# ─── Création du compte ─────────────────────────────────────────────────────────
Write-Host "`n[1/3] Création du compte utilisateur '$Username'..." -ForegroundColor Cyan

if (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue) {
    Write-Warning "L'utilisateur '$Username' existe déjà. Le script continue sans le recréer."
} else {
    New-LocalUser `
        -Name        $Username `
        -Password    $SecurePassword `
        -Description $Description `
        -PasswordNeverExpires $true `
        -AccountNeverExpires  `
        -ErrorAction Stop

    Write-Host "   Compte '$Username' créé avec succès." -ForegroundColor Green
}

# ─── Ajout au groupe Administrateurs ────────────────────────────────────────────
Write-Host "[2/3] Ajout au groupe 'Administrateurs'..." -ForegroundColor Cyan

$AdminGroup = (Get-LocalGroup | Where-Object { $_.SID -like "S-1-5-32-544" }).Name

if ((Get-LocalGroupMember -Group $AdminGroup -ErrorAction SilentlyContinue).Name -like "*$Username*") {
    Write-Warning "   '$Username' est déjà membre du groupe '$AdminGroup'."
} else {
    Add-LocalGroupMember -Group $AdminGroup -Member $Username -ErrorAction Stop
    Write-Host "   '$Username' ajouté au groupe '$AdminGroup'." -ForegroundColor Green
}

# ─── Vérification ───────────────────────────────────────────────────────────────
Write-Host "[3/3] Vérification du compte..." -ForegroundColor Cyan

$User    = Get-LocalUser -Name $Username
$Members = Get-LocalGroupMember -Group $AdminGroup | Where-Object { $_.Name -like "*$Username*" }

Write-Host "`n=== Résumé ===" -ForegroundColor Yellow
Write-Host "Nom         : $($User.Name)"
Write-Host "Description : $($User.Description)"
Write-Host "Activé      : $($User.Enabled)"
Write-Host "Groupe      : $AdminGroup"
Write-Host "Membre admin: $(if ($Members) { 'OUI' } else { 'NON' })"

Write-Host "`nTerminé. '$Username' dispose de tous les droits administrateur." -ForegroundColor Green
