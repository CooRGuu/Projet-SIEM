<#
.SYNOPSIS
    Rotation automatique du mot de passe du compte de service API Wazuh.

.DESCRIPTION
    Ce script effectue la rotation sécurisée du mot de passe du compte
    svc_enrollment utilisé pour l'enrôlement des agents Wazuh.
    
    Étapes :
      1. Déchiffre le credential actuel via DPAPI
      2. S'authentifie auprès de l'API Wazuh
      3. Génère un nouveau mot de passe cryptographiquement sûr
      4. Met à jour le mot de passe via l'API Wazuh
      5. Re-chiffre le nouveau credential via DPAPI
      6. Journalise l'opération dans l'EventLog

    Conformité :
      - NIST SP 800-63B : Rotation périodique des secrets de service
      - ANSSI Mesure 16 : Protection des mots de passe
      - ISO 27001 A.8.24 : Gestion cryptographique

.NOTES
    Version    : 1.0.0
    Exécution  : Tâche planifiée (tous les 90 jours) ou manuelle
    Prérequis  : Initialize-WazuhDeployCredential.ps1 exécuté au préalable
    Droits     : Administrateur local (pour DPAPI LocalMachine)
#>

# ============================================================================
# CONFIGURATION
# ============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$WazuhManagerFQDN    = "100.65.111.9"
$WazuhManagerAPIPort = 55000
$DpapiCredFile       = "C:\ProgramData\WazuhDeploy\api_credential.bin"
$EventSource         = "WazuhDeploy"
$EventLogName        = "Application"

# Longueur du nouveau mot de passe (caractères)
$PasswordLength = 32

# ============================================================================
# FONCTIONS
# ============================================================================

function Write-RotationLog {
    param(
        [int]$EventId,
        [string]$Message,
        [string]$EntryType = "Information"
    )
    if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
        [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $EventLogName)
    }
    Write-EventLog -LogName $EventLogName -Source $EventSource `
        -EventId $EventId -EntryType $EntryType -Message $Message
}

function New-SecurePassword {
    <#
    .SYNOPSIS
        Génère un mot de passe cryptographiquement sûr via RNGCryptoServiceProvider.
    #>
    param([int]$Length = 32)
    
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?'
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[] $Length
    $rng.GetBytes($bytes)
    
    $password = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
    $rng.Dispose()
    
    return $password
}

# ============================================================================
# ÉTAPE 1 : Déchiffrement du credential actuel
# ============================================================================

Write-RotationLog -EventId 2000 -Message "Rotation de mot de passe : Début de la procédure..."

if (-not (Test-Path $DpapiCredFile)) {
    Write-RotationLog -EventId 2009 `
        -Message "ÉCHEC : Fichier credential DPAPI introuvable ($DpapiCredFile)." `
        -EntryType "Error"
    exit 1
}

Add-Type -AssemblyName System.Security

$encryptedBytes = [System.IO.File]::ReadAllBytes($DpapiCredFile)
$decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
    $encryptedBytes, $null,
    [System.Security.Cryptography.DataProtectionScope]::LocalMachine
)
$credentialString = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
$colonIndex = $credentialString.IndexOf(':')
$apiUsername = $credentialString.Substring(0, $colonIndex)
$currentPassword = $credentialString.Substring($colonIndex + 1)

Write-RotationLog -EventId 2001 -Message "Credential actuel déchiffré pour le compte '$apiUsername'."

# ============================================================================
# ÉTAPE 2 : Authentification avec le mot de passe actuel
# ============================================================================

$apiBaseUrl = "https://${WazuhManagerFQDN}:${WazuhManagerAPIPort}"

# Bypass TLS pour la rotation (le cert pinning est dans le script principal)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

try {
    $basicAuth = [Convert]::ToBase64String(
        [System.Text.Encoding]::UTF8.GetBytes("${apiUsername}:${currentPassword}")
    )
    
    $authRequest = [System.Net.HttpWebRequest]::Create("$apiBaseUrl/security/user/authenticate")
    $authRequest.Method = "POST"
    $authRequest.Headers.Add("Authorization", "Basic $basicAuth")
    $authRequest.Timeout = 15000
    
    $authResponse = $authRequest.GetResponse()
    $authReader = New-Object System.IO.StreamReader($authResponse.GetResponseStream())
    $authResult = $authReader.ReadToEnd() | ConvertFrom-Json
    $authReader.Close()
    $authResponse.Close()
    
    $bearerToken = $authResult.data.token
    Write-RotationLog -EventId 2002 -Message "Authentification réussie avec le mot de passe actuel."
}
catch {
    Write-RotationLog -EventId 2009 `
        -Message "ÉCHEC : Authentification échouée avec le mot de passe actuel. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 2
}

# ============================================================================
# ÉTAPE 3 : Génération du nouveau mot de passe
# ============================================================================

$newPassword = New-SecurePassword -Length $PasswordLength
Write-RotationLog -EventId 2003 -Message "Nouveau mot de passe généré ($PasswordLength caractères, RNGCryptoServiceProvider)."

# ============================================================================
# ÉTAPE 4 : Mise à jour via l'API Wazuh
# ============================================================================

try {
    # Récupérer l'ID utilisateur
    $usersRequest = [System.Net.HttpWebRequest]::Create("$apiBaseUrl/security/users")
    $usersRequest.Method = "GET"
    $usersRequest.Headers.Add("Authorization", "Bearer $bearerToken")
    $usersRequest.Timeout = 15000
    
    $usersResponse = $usersRequest.GetResponse()
    $usersReader = New-Object System.IO.StreamReader($usersResponse.GetResponseStream())
    $usersResult = $usersReader.ReadToEnd() | ConvertFrom-Json
    $usersReader.Close()
    $usersResponse.Close()
    
    $userId = ($usersResult.data.affected_items | Where-Object { $_.username -eq $apiUsername }).id
    
    if (-not $userId) {
        throw "Utilisateur '$apiUsername' introuvable dans l'API."
    }
    
    # Mettre à jour le mot de passe
    $updateBody = @{ password = $newPassword } | ConvertTo-Json
    $updateRequest = [System.Net.HttpWebRequest]::Create("$apiBaseUrl/security/users/$userId")
    $updateRequest.Method = "PUT"
    $updateRequest.ContentType = "application/json"
    $updateRequest.Headers.Add("Authorization", "Bearer $bearerToken")
    $updateRequest.Timeout = 15000
    
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($updateBody)
    $updateRequest.ContentLength = $bodyBytes.Length
    $stream = $updateRequest.GetRequestStream()
    $stream.Write($bodyBytes, 0, $bodyBytes.Length)
    $stream.Close()
    
    $updateResponse = $updateRequest.GetResponse()
    $updateResponse.Close()
    
    Write-RotationLog -EventId 2004 -Message "Mot de passe mis à jour avec succès via l'API Wazuh (userId=$userId)."
}
catch {
    Write-RotationLog -EventId 2009 `
        -Message "ÉCHEC : Mise à jour du mot de passe échouée. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 3
}

# ============================================================================
# ÉTAPE 5 : Re-chiffrement DPAPI avec le nouveau mot de passe
# ============================================================================

try {
    $newCredentialString = "${apiUsername}:${newPassword}"
    $newPlainBytes = [System.Text.Encoding]::UTF8.GetBytes($newCredentialString)
    $newEncryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
        $newPlainBytes, $null,
        [System.Security.Cryptography.DataProtectionScope]::LocalMachine
    )
    
    # Écriture atomique : écrire dans un fichier temporaire puis renommer
    $tempFile = "$DpapiCredFile.tmp"
    [System.IO.File]::WriteAllBytes($tempFile, $newEncryptedBytes)
    
    # Backup de l'ancien fichier
    $backupFile = "$DpapiCredFile.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $DpapiCredFile -Destination $backupFile -Force
    
    # Remplacement atomique
    Move-Item -Path $tempFile -Destination $DpapiCredFile -Force
    
    # Verrouiller les ACL (SYSTEM + Administrators uniquement)
    $acl = Get-Acl $DpapiCredFile
    $acl.SetAccessRuleProtection($true, $false)
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
    $adminsSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        $systemSid, "FullControl", "Allow")))
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        $adminsSid, "FullControl", "Allow")))
    Set-Acl -Path $DpapiCredFile -AclObject $acl
    
    Write-RotationLog -EventId 2005 `
        -Message "Nouveau credential chiffré via DPAPI et sauvegardé ($DpapiCredFile). Backup: $backupFile"
}
catch {
    Write-RotationLog -EventId 2009 `
        -Message "ÉCHEC CRITIQUE : Re-chiffrement DPAPI échoué. L'ancien mot de passe est peut-être invalide. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 4
}
finally {
    # Nettoyage sécurisé de la mémoire
    if ($newPlainBytes) { for ($i = 0; $i -lt $newPlainBytes.Length; $i++) { $newPlainBytes[$i] = 0 } }
    $currentPassword = $null
    $newPassword = $null
    $newCredentialString = $null
    $bearerToken = $null
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    [System.GC]::Collect()
}

# ============================================================================
# SUCCÈS
# ============================================================================

Write-RotationLog -EventId 2010 `
    -Message ("ROTATION TERMINÉE AVEC SUCCÈS`n" +
              "Compte      : $apiUsername`n" +
              "Longueur    : $PasswordLength caractères`n" +
              "Générateur  : RNGCryptoServiceProvider`n" +
              "Stockage    : DPAPI LocalMachine`n" +
              "Backup      : $backupFile`n" +
              "Horodatage  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")

Write-Host "Rotation terminee avec succes." -ForegroundColor Green
exit 0
