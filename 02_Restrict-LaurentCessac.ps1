#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Restreint les droits de "Laurent Cessac" pour interdire l'installation de logiciels.

.DESCRIPTION
    Ce script applique plusieurs restrictions sur le compte "Laurent Cessac" :

    1. Rétrogradation vers Utilisateur standard (retrait du groupe Administrateurs)
    2. Stratégie de groupe locale (GPO) bloquant Windows Installer
    3. Blocage de l'exécution des installateurs via les clés de registre
    4. Configuration de l'UAC en mode strict

.NOTES
    Doit être exécuté en tant qu'Administrateur.
    Les restrictions GPO nécessitent une actualisation (gpupdate) pour prendre effet.
#>

# ─── Paramètres ────────────────────────────────────────────────────────────────
$TargetUser = "Laurent Cessac"   # Adapter si le nom de compte diffère (ex: "LaurentC")

# ─── Résolution du nom de compte ───────────────────────────────────────────────
Write-Host "`n[0/5] Recherche du compte '$TargetUser'..." -ForegroundColor Cyan

# Cherche d'abord par nom complet, puis par nom de connexion partiel
$LocalUser = Get-LocalUser | Where-Object {
    $_.Name -eq $TargetUser -or
    $_.FullName -eq $TargetUser -or
    $_.Name -like "*Laurent*Cessac*" -or
    $_.Name -like "*LaurentCessac*"
} | Select-Object -First 1

if (-not $LocalUser) {
    Write-Error "Aucun compte local correspondant à '$TargetUser' n'a été trouvé."
    Write-Host "Comptes locaux disponibles :" -ForegroundColor Yellow
    Get-LocalUser | Select-Object Name, FullName, Enabled | Format-Table -AutoSize
    exit 1
}

$AccountName = $LocalUser.Name
Write-Host "   Compte trouvé : '$AccountName' (FullName: $($LocalUser.FullName))" -ForegroundColor Green

# ─── Étape 1 : Retrait du groupe Administrateurs ────────────────────────────────
Write-Host "`n[1/5] Vérification et retrait du groupe Administrateurs..." -ForegroundColor Cyan

$AdminGroup = (Get-LocalGroup | Where-Object { $_.SID -like "S-1-5-32-544" }).Name
$IsAdmin    = (Get-LocalGroupMember -Group $AdminGroup -ErrorAction SilentlyContinue).Name -like "*$AccountName*"

if ($IsAdmin) {
    Remove-LocalGroupMember -Group $AdminGroup -Member $AccountName -ErrorAction Stop
    Write-Host "   '$AccountName' retiré du groupe '$AdminGroup'." -ForegroundColor Green
} else {
    Write-Host "   '$AccountName' n'est pas dans le groupe '$AdminGroup'. Pas de changement." -ForegroundColor Yellow
}

# ─── Étape 2 : Blocage Windows Installer via le registre (utilisateur courant) ──
Write-Host "`n[2/5] Blocage de Windows Installer via le registre..." -ForegroundColor Cyan

# Récupère le SID de l'utilisateur cible
$UserSID = (New-Object System.Security.Principal.NTAccount($AccountName)).Translate(
              [System.Security.Principal.SecurityIdentifier]).Value

# Clé de registre spécifique à l'utilisateur dans HKU
$HKUPath       = "HKU:\$UserSID"
$InstallerKey  = "$HKUPath\Software\Policies\Microsoft\Windows\Installer"

# Monte HKU si absent
if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}

# Charge le profil si l'utilisateur n'est pas connecté
$ProfileLoaded = Test-Path $HKUPath
if (-not $ProfileLoaded) {
    Write-Host "   Chargement du profil de registre de '$AccountName'..." -ForegroundColor Yellow
    $ProfilePath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$UserSID").ProfileImagePath
    reg load "HKU\$UserSID" "$ProfilePath\NTUSER.DAT" | Out-Null
}

# Applique la restriction
if (-not (Test-Path $InstallerKey)) {
    New-Item -Path $InstallerKey -Force | Out-Null
}
Set-ItemProperty -Path $InstallerKey -Name "DisableMSI"          -Value 1 -Type DWord -Force
Set-ItemProperty -Path $InstallerKey -Name "DisableUserInstalls"  -Value 1 -Type DWord -Force

Write-Host "   Clés de registre Installer configurées pour '$AccountName'." -ForegroundColor Green

# Décharge le profil si on l'avait chargé
if (-not $ProfileLoaded) {
    [GC]::Collect()
    reg unload "HKU\$UserSID" | Out-Null
}

# ─── Étape 3 : Stratégie ordinateur (HKLM) – bloque pour tous les non-admins ───
Write-Host "`n[3/5] Application de la stratégie ordinateur (Windows Installer)..." -ForegroundColor Cyan

$MachineInstallerKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
if (-not (Test-Path $MachineInstallerKey)) {
    New-Item -Path $MachineInstallerKey -Force | Out-Null
}

# AlwaysInstallElevated = 0 empêche l'installation élevée par les utilisateurs standard
Set-ItemProperty -Path $MachineInstallerKey -Name "AlwaysInstallElevated" -Value 0 -Type DWord -Force
# DisableMSI = 1 : interdit MSI pour les non-administrateurs
Set-ItemProperty -Path $MachineInstallerKey -Name "DisableMSI"            -Value 1 -Type DWord -Force

Write-Host "   Stratégie ordinateur appliquée (AlwaysInstallElevated=0, DisableMSI=1)." -ForegroundColor Green

# ─── Étape 4 : Blocage des exécutables d'installation courants (AppLocker / SRP) ─
Write-Host "`n[4/5] Configuration UAC stricte pour les élévations de privilèges..." -ForegroundColor Cyan

$SystemPoliciesKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# ConsentPromptBehaviorUser = 0 : refuse automatiquement toute demande d'élévation
# des utilisateurs standard (pas d'invite UAC → installation bloquée)
Set-ItemProperty -Path $SystemPoliciesKey -Name "ConsentPromptBehaviorUser" -Value 0 -Type DWord -Force

# EnableInstallerDetection = 1 : Windows détecte les programmes d'installation et demande élévation
Set-ItemProperty -Path $SystemPoliciesKey -Name "EnableInstallerDetection"  -Value 1 -Type DWord -Force

Write-Host "   UAC configuré : élévation refusée automatiquement pour les utilisateurs standard." -ForegroundColor Green

# ─── Étape 5 : Mise à jour des stratégies de groupe ────────────────────────────
Write-Host "`n[5/5] Actualisation des stratégies de groupe (gpupdate)..." -ForegroundColor Cyan
gpupdate /force | Out-Null
Write-Host "   Stratégies actualisées." -ForegroundColor Green

# ─── Résumé ─────────────────────────────────────────────────────────────────────
Write-Host "`n=== Résumé des restrictions appliquées à '$AccountName' ===" -ForegroundColor Yellow
Write-Host "  [OK] Retiré du groupe Administrateurs              -> Utilisateur standard"
Write-Host "  [OK] DisableMSI (HKU)                             -> MSI bloqué pour ce profil"
Write-Host "  [OK] DisableUserInstalls (HKU)                    -> Installations utilisateur bloquées"
Write-Host "  [OK] AlwaysInstallElevated=0 (HKLM)              -> Élévation automatique désactivée"
Write-Host "  [OK] DisableMSI (HKLM)                            -> MSI bloqué machine"
Write-Host "  [OK] ConsentPromptBehaviorUser=0 (UAC)           -> Invite UAC refusée automatiquement"
Write-Host "  [OK] EnableInstallerDetection=1 (UAC)            -> Détection des installateurs activée"
Write-Host "`n'$AccountName' ne peut plus installer de logiciels." -ForegroundColor Green
Write-Host "Un redémarrage de session est recommandé pour que toutes les restrictions prennent effet." -ForegroundColor Yellow
