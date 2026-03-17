#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Liste tous les utilisateurs locaux Windows 11 avec leurs groupes.
#>

Write-Host "`n=== Utilisateurs locaux ===" -ForegroundColor Magenta

$AdminGroup = (Get-LocalGroup | Where-Object { $_.SID -like "S-1-5-32-544" }).Name
$AdminMembers = (Get-LocalGroupMember -Group $AdminGroup -ErrorAction SilentlyContinue).Name

Get-LocalUser | Sort-Object Name | ForEach-Object {
    $isAdmin = $AdminMembers -like "*$($_.Name)*"
    $role    = if ($isAdmin) { "Administrateur" } else { "Utilisateur standard" }
    $status  = if ($_.Enabled) { "Actif" } else { "Désactivé" }
    $color   = if ($isAdmin) { "Cyan" } else { "White" }

    Write-Host "`nNom         : $($_.Name)" -ForegroundColor $color
    if ($_.FullName) {
    Write-Host "Nom complet : $($_.FullName)" -ForegroundColor $color }
    Write-Host "Rôle        : $role"
    Write-Host "Statut      : $status"
    Write-Host "Dernière co.: $(if ($_.LastLogon) { $_.LastLogon } else { 'Jamais' })"
}

Write-Host "`n=== Membres du groupe '$AdminGroup' ===" -ForegroundColor Yellow
Get-LocalGroupMember -Group $AdminGroup | Select-Object Name, ObjectClass | Format-Table -AutoSize
