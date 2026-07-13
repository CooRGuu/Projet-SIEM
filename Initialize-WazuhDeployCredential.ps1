<#
.SYNOPSIS
    Provisionne les prérequis pour le déploiement Zero-Touch de l'agent Wazuh.
    À exécuter UNE SEULE FOIS par un administrateur, sur chaque machine cible ou via GPO Immediate Task.

.DESCRIPTION
    Ce script effectue 4 opérations :
    1. Création du répertoire local sécurisé C:\ProgramData\WazuhDeploy
    2. Chiffrement des credentials API Wazuh via DPAPI (scope LocalMachine)
    3. Verrouillage des ACLs (SYSTEM ReadOnly, héritage désactivé)
    4. Enregistrement de la source EventLog "WazuhDeploy"

.NOTES
    Auteur  : [Étudiant Master Cybersécurité]
    Version : 1.0.0
    Prérequis : Exécution en tant qu'Administrateur local
    Référence : ISO 27001:2022 A.5.17 — Informations d'authentification
#>

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION
# ============================================================================
$DeployDir    = "C:\ProgramData\WazuhDeploy"
$CredFile     = Join-Path $DeployDir "api_credential.bin"
$EventSource  = "WazuhDeploy"
$EventLogName = "Application"

# ============================================================================
# FONCTIONS
# ============================================================================

function Write-Status {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "OK"      { "Green" }
        "WARN"    { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# ============================================================================
# ÉTAPE 1 : Création du répertoire sécurisé
# ============================================================================
Write-Status "Création du répertoire $DeployDir..."

if (-not (Test-Path $DeployDir)) {
    New-Item -Path $DeployDir -ItemType Directory -Force | Out-Null
}

# Verrouiller les ACLs du répertoire : SYSTEM (FullControl) + Administrators (FullControl)
$dirAcl = New-Object System.Security.AccessControl.DirectorySecurity
$dirAcl.SetAccessRuleProtection($true, $false)  # Désactiver l'héritage, ne pas copier les règles héritées

# Utilisation des SIDs universels (indépendant de la langue de l'OS)
$sidSystem = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")           # NT AUTHORITY\SYSTEM
$sidAdmins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")       # BUILTIN\Administrateurs

$ruleSystem = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $sidSystem, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$ruleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $sidAdmins, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$dirAcl.AddAccessRule($ruleSystem)
$dirAcl.AddAccessRule($ruleAdmin)
Set-Acl -Path $DeployDir -AclObject $dirAcl

Write-Status "Répertoire créé et sécurisé (SYSTEM + Admins uniquement)." "OK"

# ============================================================================
# ÉTAPE 2 : Chiffrement des credentials via DPAPI
# ============================================================================
Write-Status "Saisie des credentials du compte de service API Wazuh..."
Write-Host ""
Write-Host "  Entrez les credentials du compte de service Wazuh API (ex: svc_enrollment)." -ForegroundColor White
Write-Host "  Ces credentials seront chiffrés via DPAPI et ne seront JAMAIS stockés en clair." -ForegroundColor DarkGray
Write-Host ""

$cred = Get-Credential -Message "Compte de service API Wazuh (ex: svc_enrollment)"

if (-not $cred) {
    Write-Status "Opération annulée par l'utilisateur." "ERROR"
    exit 1
}

# Construire la chaîne "username:password" et chiffrer via DPAPI
$username = $cred.UserName
$password = $cred.GetNetworkCredential().Password
$plaintext = "${username}:${password}"
$plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

Add-Type -AssemblyName System.Security
$encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
    $plaintextBytes,
    $null,
    [System.Security.Cryptography.DataProtectionScope]::LocalMachine
)

# Écrire le fichier chiffré
[System.IO.File]::WriteAllBytes($CredFile, $encryptedBytes)

# Nettoyage des variables sensibles en mémoire
$plaintext = $null
$plaintextBytes = $null
$password = $null
[System.GC]::Collect()

Write-Status "Credentials chiffrés via DPAPI (LocalMachine scope) → $CredFile" "OK"

# ============================================================================
# ÉTAPE 3 : Verrouillage des ACLs du fichier credential
# ============================================================================
Write-Status "Verrouillage des ACLs du fichier credential..."

$fileAcl = New-Object System.Security.AccessControl.FileSecurity
$fileAcl.SetAccessRuleProtection($true, $false)  # Héritage désactivé

# SIDs universels (indépendant de la langue de l'OS)
$sidSystem = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")           # NT AUTHORITY\SYSTEM
$sidAdmins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")       # BUILTIN\Administrateurs

# Seul SYSTEM peut lire (le script GPO tourne en SYSTEM)
$ruleRead = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $sidSystem, "Read", "Allow"
)
# Administrators conservent FullControl pour la maintenance
$ruleAdminFile = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $sidAdmins, "FullControl", "Allow"
)
$fileAcl.AddAccessRule($ruleRead)
$fileAcl.AddAccessRule($ruleAdminFile)
Set-Acl -Path $CredFile -AclObject $fileAcl

Write-Status "ACLs verrouillées : SYSTEM=Read, Administrators=FullControl." "OK"

# ============================================================================
# ÉTAPE 4 : Enregistrement de la source EventLog
# ============================================================================
Write-Status "Enregistrement de la source EventLog '$EventSource'..."

if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
    [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $EventLogName)
    Write-Status "Source EventLog '$EventSource' enregistrée dans '$EventLogName'." "OK"
} else {
    Write-Status "Source EventLog '$EventSource' déjà enregistrée." "WARN"
}

# ============================================================================
# VALIDATION FINALE
# ============================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  PROVISIONNEMENT TERMINÉ AVEC SUCCÈS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Répertoire sécurisé : $DeployDir" -ForegroundColor White
Write-Host "  Credential chiffré  : $CredFile ($([Math]::Round((Get-Item $CredFile).Length / 1KB, 2)) KB)" -ForegroundColor White
Write-Host "  Source EventLog     : $EventSource" -ForegroundColor White
Write-Host ""
Write-Host "  Le script Deploy-WazuhAgent.ps1 peut maintenant être déployé via GPO." -ForegroundColor Cyan
Write-Host ""
