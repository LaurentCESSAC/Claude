# Gestion des utilisateurs Windows 11

Scripts PowerShell pour gérer les permissions utilisateurs sur Windows 11.

## Scripts

| Script | Description |
|--------|-------------|
| `00_Run-All.ps1` | Script principal qui enchaîne les deux opérations |
| `01_Create-AdminLocal.ps1` | Crée le compte `Admin_Local` avec droits administrateur complets |
| `02_Restrict-LaurentCessac.ps1` | Restreint `Laurent Cessac` : interdit l'installation de logiciels |

## Prérequis

- Windows 11
- PowerShell 5.1 ou supérieur
- Exécution en tant qu'**Administrateur**

## Utilisation

### Option A — Exécuter tout d'un coup

```powershell
# Ouvrir PowerShell en tant qu'Administrateur, puis :
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\00_Run-All.ps1
```

### Option B — Exécuter les scripts séparément

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 1. Créer Admin_Local
.\01_Create-AdminLocal.ps1

# 2. Restreindre Laurent Cessac
.\02_Restrict-LaurentCessac.ps1
```

## Ce que font les scripts

### `01_Create-AdminLocal.ps1`

- Crée le compte local `Admin_Local`
- Mot de passe saisi de manière sécurisée (masqué)
- Ajoute le compte au groupe **Administrateurs**
- Le mot de passe n'expire jamais, le compte non plus

### `02_Restrict-LaurentCessac.ps1`

Applique **5 couches de restriction** sur le compte "Laurent Cessac" :

1. **Retrait du groupe Administrateurs** → compte Utilisateur standard
2. **Registre utilisateur (HKU)** → `DisableMSI=1`, `DisableUserInstalls=1`
3. **Registre machine (HKLM)** → `AlwaysInstallElevated=0`, `DisableMSI=1`
4. **UAC strict** → `ConsentPromptBehaviorUser=0` (élévation refusée automatiquement)
5. **gpupdate /force** → applique immédiatement les stratégies

> Après l'exécution, un **redémarrage de session** de l'utilisateur "Laurent Cessac" est recommandé.

## Remarques

- Le script `02` recherche automatiquement le compte par nom complet ou partiel (`Laurent*Cessac*`).
- Si le nom de connexion Windows diffère (ex: `LCessac`), modifiez la variable `$TargetUser` dans le script.
