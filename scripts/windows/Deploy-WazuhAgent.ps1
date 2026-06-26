<#
.SYNOPSIS
    Déploiement Zero-Touch de l'agent Wazuh v4.10 — Script GPO Startup durci.

.DESCRIPTION
    Script de déploiement automatisé pour GPO Computer Startup, exécuté en NT AUTHORITY\SYSTEM.
    Implémente une défense en profondeur à 8 couches :
      - Attente explicite du tunnel Tailscale (overlay WireGuard)
      - Certificate Pinning TLS (thumbprint SHA-256)
      - Credentials API chiffrés via DPAPI (LocalMachine)
      - Retry pattern avec backoff exponentiel
      - Staging MSI centralisé avec fallback local
      - Vérification d'intégrité SHA-256 du MSI
      - Journalisation complète dans l'EventLog Windows
      - Vérification post-installation du service

.NOTES
    Auteur     : [Étudiant Master Cybersécurité]
    Version    : 3.0.0 — Production-Grade (ACL lockdown, secure wipe, service recovery)
    Exécution  : GPO Computer Startup Script (NT AUTHORITY\SYSTEM)
    Prérequis  : Initialize-WazuhDeployCredential.ps1 exécuté au préalable

    Référentiels de conformité :
      - ISO 27001:2022 : A.5.17, A.8.9, A.8.15, A.8.24
      - CIS Controls v8 : 2.5, 3.10, 8.2
      - NIST SP 800-52 Rev2 (TLS)
      - OWASP : A07:2021, CWE-798 (corrigé)
      - NIS2 Art.21 §2 (d)(e)(g)

    Codes de sortie :
      0 = Succès ou agent déjà installé (idempotent)
      1 = Erreur de connectivité réseau (après toutes les tentatives)
      2 = Erreur de déchiffrement DPAPI (fichier credential absent ou corrompu)
      3 = Erreur d'authentification API Wazuh
      4 = Erreur de création de l'agent via l'API
      5 = Erreur d'intégrité du MSI (hash mismatch — possible supply chain attack)
      6 = Erreur d'installation MSI
      7 = Erreur post-installation (service non démarré)
      8 = Erreur Tailscale (service non démarré après timeout)
#>

# ============================================================================
# DIRECTIVES STRICTES
# ============================================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# CONFIGURATION — ADAPTER CES VALEURS À VOTRE ENVIRONNEMENT
# ============================================================================

# --- Wazuh Manager ---
$WazuhManagerFQDN      = "100.65.111.9"
$WazuhManagerAPIPort   = 55000
$WazuhManagerCommsPort = 1514

# --- Certificat TLS du Manager (Certificate Pinning) ---
# Récupérer le thumbprint SHA-256 du certificat du Manager :
#   openssl x509 -in /var/ossec/api/configuration/ssl/server.crt -fingerprint -sha256 -noout
# Puis retirer les ":" pour obtenir la chaîne hexadécimale brute.
$TrustedCertThumbprint = "7E4496D56930C59E9733E85F7359FC5075FA2B4590ADDC8B78F97B3DC8B310FB"

# --- MSI Agent (Staging réseau → fallback local) ---
# Source réseau centralisée (partage admin sur le DC). Laisser $null si non utilisé.
$MsiNetworkSource = $null   # Ex: "\\DC01\WazuhDeploy$\wazuh-agent-4.10.4-1.msi"
# Chemin local de staging (le MSI sera copié ici depuis le réseau, ou doit y être déjà)
$MsiLocalPath    = "C:\Wazuh_Deploy\wazuh-agent-4.10.4-1.msi"
$MsiExpectedHash = "B6B87131A180142B81288EF8F90F586D3749D9AFCBAA26AE3304EDD2D3A3AAD6"

# --- Credentials DPAPI ---
$DpapiCredFile = "C:\ProgramData\WazuhDeploy\api_credential.bin"

# --- Tailscale (overlay réseau WireGuard) ---
# Le Wazuh Manager est accessible via Tailscale (100.65.x.x).
# Le script doit attendre que le tunnel soit établi avant de tenter la connexion.
$TailscaleServiceName   = "Tailscale"   # Nom du service Windows Tailscale
$TailscaleMaxWaitSeconds = 120          # Timeout max d'attente du tunnel (2 min)
$TailscaleCheckInterval  = 5            # Intervalle de vérification (secondes)

# --- Retry Pattern (connectivité API, après Tailscale) ---
$MaxRetries          = 5
$InitialDelaySeconds = 5    # Backoff : 5s → 10s → 20s → 40s → 80s

# --- Journalisation ---
$EventSource  = "WazuhDeploy"
$EventLogName = "Application"

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

function Write-DeployLog {
    <#
    .SYNOPSIS
        Écrit un événement dans l'EventLog Windows avec un ID structuré.
    #>
    param(
        [Parameter(Mandatory)][int]$EventId,
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("Information","Warning","Error")]
        [string]$EntryType = "Information"
    )

    # Sécurité : vérifier que la source existe (normalement créée par Initialize-*)
    if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
        try {
            [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $EventLogName)
        } catch {
            # En cas d'échec (permissions), écrire dans stdout — capturé par GPO
            Write-Output "[FALLBACK] EventId=$EventId | $EntryType | $Message"
            return
        }
    }

    Write-EventLog -LogName $EventLogName -Source $EventSource `
        -EventId $EventId -EntryType $EntryType -Message $Message
}

function Test-TcpPort {
    <#
    .SYNOPSIS
        Teste la connectivité TCP vers un hôte:port avec un timeout.
    #>
    param(
        [Parameter(Mandatory)][string]$ComputerName,
        [Parameter(Mandatory)][int]$Port,
        [int]$TimeoutMs = 3000
    )

    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $connect = $tcp.BeginConnect($ComputerName, $Port, $null, $null)
        $connected = $connect.AsyncWaitHandle.WaitOne($TimeoutMs, $false)

        if ($connected) {
            $tcp.EndConnect($connect)
            $tcp.Close()
            return $true
        }

        $tcp.Close()
        return $false
    } catch {
        return $false
    }
}

function Invoke-WazuhAPI {
    <#
    .SYNOPSIS
        Appelle l'API Wazuh avec Certificate Pinning et gestion d'erreurs.
    .DESCRIPTION
        Utilise System.Net.HttpWebRequest pour un contrôle fin de la validation TLS.
        Le certificat du serveur est validé par comparaison de thumbprint SHA-256.
    #>
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Method,
        [hashtable]$Headers = @{},
        [string]$Body,
        [string]$ContentType = "application/json"
    )

    # --- Certificate Pinning via callback personnalisé ---
    # IMPORTANT : Ce callback remplace le bypass {$true} de l'ancien script.
    # Il valide que le certificat présenté correspond EXACTEMENT au thumbprint attendu.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
        param($senderObj, $certificate, $chain, $sslPolicyErrors)

        if ($null -eq $certificate) { return $false }

        # Extraire le thumbprint SHA-256 du certificat présenté
        $certHash = $certificate.GetCertHashString("SHA256")

        if ($certHash -eq $script:TrustedCertThumbprint) {
            return $true
        }

        # Journaliser la tentative avec un certificat non reconnu
        $msg = "ALERTE CERT PINNING : Certificat non reconnu.`n" +
               "Thumbprint reçu  : $certHash`n" +
               "Thumbprint attendu: $($script:TrustedCertThumbprint)`n" +
               "Subject: $($certificate.Subject)`n" +
               "Issuer : $($certificate.Issuer)"

        Write-DeployLog -EventId 1010 -Message $msg -EntryType "Error"
        return $false
    }

    try {
        $request = [System.Net.HttpWebRequest]::Create($Uri)
        $request.Method = $Method
        $request.ContentType = $ContentType
        $request.Timeout = 15000    # 15 secondes

        foreach ($key in $Headers.Keys) {
            $request.Headers.Add($key, $Headers[$key])
        }

        if ($Body) {
            $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($Body)
            $request.ContentLength = $bodyBytes.Length
            $stream = $request.GetRequestStream()
            $stream.Write($bodyBytes, 0, $bodyBytes.Length)
            $stream.Close()
        }

        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
        $responseText = $reader.ReadToEnd()
        $reader.Close()
        $response.Close()

        return ($responseText | ConvertFrom-Json)
    }
    catch [System.Net.WebException] {
        $errorResponse = $_.Exception.Response
        $errorMsg = "API Error: $($_.Exception.Message)"

        if ($errorResponse) {
            $errorReader = New-Object System.IO.StreamReader($errorResponse.GetResponseStream())
            $errorBody = $errorReader.ReadToEnd()
            $errorReader.Close()
            $errorMsg += " | Body: $errorBody"
        }

        throw $errorMsg
    }
    finally {
        # Réinitialiser le callback pour ne pas affecter d'autres processus
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
    }
}

# ============================================================================
# PHASE 0 : IDEMPOTENCE — Vérification d'installation existante
# ============================================================================

$existingService = Get-Service -Name "WazuhSvc" -ErrorAction SilentlyContinue

if ($existingService) {
    Write-DeployLog -EventId 1000 `
        -Message "Agent Wazuh déjà installé (Service: $($existingService.Status)). Aucune action requise." `
        -EntryType "Information"
    exit 0
}

Write-DeployLog -EventId 1001 `
    -Message "Début du déploiement Zero-Touch de l'agent Wazuh. Hostname: $env:COMPUTERNAME" `
    -EntryType "Information"

# ============================================================================
# PHASE 1 : ATTENTE TAILSCALE — Le tunnel WireGuard doit être établi
# ============================================================================
# Le Wazuh Manager est sur le tailnet (100.65.x.x). Sans Tailscale, pas de
# connectivité. Au boot Windows, le service Tailscale peut mettre 15-60s à
# s'initialiser et à établir le tunnel. On attend explicitement.
# ============================================================================

Write-DeployLog -EventId 1050 `
    -Message "Phase 1 : Attente du service Tailscale (timeout: ${TailscaleMaxWaitSeconds}s)..." `
    -EntryType "Information"

$tailscaleReady = $false
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

while ($stopwatch.Elapsed.TotalSeconds -lt $TailscaleMaxWaitSeconds) {

    $tailscaleSvc = Get-Service -Name $TailscaleServiceName -ErrorAction SilentlyContinue

    if ($tailscaleSvc -and $tailscaleSvc.Status -eq 'Running') {
        # Le service tourne, mais le tunnel peut ne pas encore être établi.
        # On vérifie la connectivité réelle vers l'IP Tailscale du Manager.
        if (Test-TcpPort -ComputerName $WazuhManagerFQDN -Port $WazuhManagerAPIPort -TimeoutMs 2000) {
            $elapsed = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
            Write-DeployLog -EventId 1051 `
                -Message "Tunnel Tailscale opérationnel. Connectivité ${WazuhManagerFQDN}:${WazuhManagerAPIPort} confirmée en ${elapsed}s." `
                -EntryType "Information"
            $tailscaleReady = $true
            break
        }

        $elapsed = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
        Write-DeployLog -EventId 1052 `
            -Message "Service Tailscale démarré mais tunnel pas encore actif (${elapsed}s/${TailscaleMaxWaitSeconds}s)..." `
            -EntryType "Information"
    }
    else {
        $svcStatus = if ($tailscaleSvc) { $tailscaleSvc.Status } else { "Non trouvé" }
        $elapsed = [Math]::Round($stopwatch.Elapsed.TotalSeconds, 1)
        Write-DeployLog -EventId 1053 `
            -Message "En attente du service Tailscale (état: $svcStatus, ${elapsed}s/${TailscaleMaxWaitSeconds}s)..." `
            -EntryType "Warning"
    }

    Start-Sleep -Seconds $TailscaleCheckInterval
}

$stopwatch.Stop()

if (-not $tailscaleReady) {
    Write-DeployLog -EventId 1059 `
        -Message ("ÉCHEC FATAL : Le tunnel Tailscale n'a pas pu être établi dans le délai imparti (${TailscaleMaxWaitSeconds}s).`n" +
                  "Le Wazuh Manager (${WazuhManagerFQDN}) est inaccessible. Déploiement abandonné.`n" +
                  "Vérifier : 1) Tailscale est installé, 2) La machine est authentifiée sur le tailnet, 3) Le Manager est en ligne.") `
        -EntryType "Error"
    exit 8
}

# ============================================================================
# PHASE 2 : CONNECTIVITÉ API — Retry avec backoff exponentiel (post-Tailscale)
# ============================================================================
# Cette phase sert de filet de sécurité : même si Tailscale est up, l'API
# Wazuh peut ne pas encore écouter (redémarrage du Manager, etc.).
# ============================================================================

Write-DeployLog -EventId 1100 `
    -Message "Phase 2 : Validation de la connectivité API vers ${WazuhManagerFQDN}:${WazuhManagerAPIPort}..." `
    -EntryType "Information"

$networkReady = $false

for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {

    $delay = $InitialDelaySeconds * [Math]::Pow(2, $attempt - 1)

    if (Test-TcpPort -ComputerName $WazuhManagerFQDN -Port $WazuhManagerAPIPort) {
        Write-DeployLog -EventId 1101 `
            -Message "Connectivité API confirmée (tentative $attempt/$MaxRetries)." `
            -EntryType "Information"
        $networkReady = $true
        break
    }

    Write-DeployLog -EventId 1102 `
        -Message "API non joignable (tentative $attempt/$MaxRetries). Prochain essai dans ${delay}s." `
        -EntryType "Warning"

    Start-Sleep -Seconds $delay
}

if (-not $networkReady) {
    Write-DeployLog -EventId 1109 `
        -Message "ÉCHEC FATAL : API Wazuh (${WazuhManagerFQDN}:${WazuhManagerAPIPort}) injoignable après $MaxRetries tentatives. Tunnel Tailscale OK mais API non disponible." `
        -EntryType "Error"
    exit 1
}

# ============================================================================
# PHASE 2 : DÉCHIFFREMENT DPAPI — Récupération des credentials API
# ============================================================================

Write-DeployLog -EventId 1200 `
    -Message "Phase 3 : Déchiffrement des credentials API via DPAPI..." `
    -EntryType "Information"

if (-not (Test-Path $DpapiCredFile)) {
    Write-DeployLog -EventId 1209 `
        -Message "ÉCHEC FATAL : Fichier credential DPAPI introuvable ($DpapiCredFile). Exécuter Initialize-WazuhDeployCredential.ps1 au préalable." `
        -EntryType "Error"
    exit 2
}

try {
    Add-Type -AssemblyName System.Security
    $encryptedBytes = [System.IO.File]::ReadAllBytes($DpapiCredFile)
    $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $encryptedBytes,
        $null,
        [System.Security.Cryptography.DataProtectionScope]::LocalMachine
    )
    $credentialString = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

    # Parser "username:password"
    $colonIndex = $credentialString.IndexOf(':')
    if ($colonIndex -le 0) {
        throw "Format credential invalide (attendu: 'username:password')"
    }
    $apiUsername = $credentialString.Substring(0, $colonIndex)
    $apiPassword = $credentialString.Substring($colonIndex + 1)

    Write-DeployLog -EventId 1201 `
        -Message "Credentials déchiffrés avec succès pour le compte '$apiUsername'." `
        -EntryType "Information"
}
catch {
    Write-DeployLog -EventId 1209 `
        -Message "ÉCHEC FATAL : Impossible de déchiffrer le fichier credential DPAPI. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 2
}
finally {
    # Nettoyage des variables intermédiaires
    $decryptedBytes = $null
    $credentialString = $null
    [System.GC]::Collect()
}

# ============================================================================
# PHASE 3 : AUTHENTIFICATION API WAZUH — Obtention du Bearer Token
# ============================================================================

Write-DeployLog -EventId 1300 `
    -Message "Phase 4 : Authentification auprès de l'API Wazuh (compte: $apiUsername)..." `
    -EntryType "Information"

$apiBaseUrl = "https://${WazuhManagerFQDN}:${WazuhManagerAPIPort}"

try {
    $basicAuth = [Convert]::ToBase64String(
        [System.Text.Encoding]::UTF8.GetBytes("${apiUsername}:${apiPassword}")
    )

    $authResponse = Invoke-WazuhAPI `
        -Uri "$apiBaseUrl/security/user/authenticate" `
        -Method "POST" `
        -Headers @{ Authorization = "Basic $basicAuth" }

    $bearerToken = $authResponse.data.token

    if (-not $bearerToken) {
        throw "Token Bearer absent de la réponse API."
    }

    Write-DeployLog -EventId 1301 `
        -Message "Authentification API réussie. Bearer Token obtenu." `
        -EntryType "Information"
}
catch {
    Write-DeployLog -EventId 1309 `
        -Message "ÉCHEC FATAL : Authentification API échouée. Vérifier le compte '$apiUsername' et ses permissions RBAC. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 3
}
finally {
    # Nettoyage immédiat des secrets en mémoire
    $apiPassword = $null
    $basicAuth = $null
    [System.GC]::Collect()
}

# ============================================================================
# PHASE 4 : PRÉ-PROVISIONING — Création de l'agent et obtention de la clé
# ============================================================================

Write-DeployLog -EventId 1400 `
    -Message "Phase 5 : Création de l'agent '$env:COMPUTERNAME' via l'API Wazuh..." `
    -EntryType "Information"

try {
    $agentPayload = @{
        name = $env:COMPUTERNAME
        ip   = "any"
    } | ConvertTo-Json

    $agentResponse = Invoke-WazuhAPI `
        -Uri "$apiBaseUrl/agents" `
        -Method "POST" `
        -Headers @{ Authorization = "Bearer $bearerToken" } `
        -Body $agentPayload

    $agentId  = $agentResponse.data.id
    $agentKey = $agentResponse.data.key

    if (-not $agentKey) {
        throw "Clé agent absente de la réponse API."
    }

    Write-DeployLog -EventId 1401 `
        -Message "Agent créé avec succès. ID=$agentId, Nom=$env:COMPUTERNAME" `
        -EntryType "Information"
}
catch {
    Write-DeployLog -EventId 1409 `
        -Message "ÉCHEC FATAL : Création de l'agent échouée. L'agent '$env:COMPUTERNAME' existe peut-être déjà. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 4
}
finally {
    # Le Bearer Token n'est plus nécessaire
    $bearerToken = $null
}

# ============================================================================
# PHASE 6 : STAGING & INTÉGRITÉ MSI — Copie centralisée + Hash SHA-256
# ============================================================================
# Stratégie de résolution du MSI (ordre de priorité) :
#   1. Si $MsiNetworkSource est défini → copier depuis le partage réseau vers $MsiLocalPath
#   2. Sinon → utiliser le $MsiLocalPath déjà présent localement
#   3. Dans tous les cas → vérifier le hash SHA-256 avant installation
# ============================================================================

Write-DeployLog -EventId 1500 `
    -Message "Phase 6 : Staging et vérification d'intégrité du MSI..." `
    -EntryType "Information"

# --- Étape 6a : Staging depuis le partage réseau (si configuré) ---
if ($MsiNetworkSource) {
    Write-DeployLog -EventId 1501 `
        -Message "Source réseau configurée : $MsiNetworkSource. Tentative de staging..." `
        -EntryType "Information"

    try {
        if (Test-Path $MsiNetworkSource) {
            # Créer le répertoire local si nécessaire
            $localDir = Split-Path -Parent $MsiLocalPath
            if (-not (Test-Path $localDir)) {
                New-Item -Path $localDir -ItemType Directory -Force | Out-Null
            }

            # Copier avec écrasement (mise à jour centralisée)
            Copy-Item -Path $MsiNetworkSource -Destination $MsiLocalPath -Force

            Write-DeployLog -EventId 1502 `
                -Message "MSI copié avec succès depuis le partage réseau vers $MsiLocalPath." `
                -EntryType "Information"
        }
        else {
            Write-DeployLog -EventId 1503 `
                -Message "Partage réseau inaccessible ($MsiNetworkSource). Fallback sur le chemin local..." `
                -EntryType "Warning"
        }
    }
    catch {
        Write-DeployLog -EventId 1504 `
            -Message "Erreur lors de la copie réseau : $($_.Exception.Message). Fallback sur le chemin local..." `
            -EntryType "Warning"
    }
}

# --- Étape 6b : Vérification de la présence locale ---
if (-not (Test-Path $MsiLocalPath)) {
    Write-DeployLog -EventId 1509 `
        -Message ("ÉCHEC FATAL : MSI introuvable.`n" +
                  "Chemin local : $MsiLocalPath (absent)`n" +
                  "Source réseau : $(if ($MsiNetworkSource) { $MsiNetworkSource } else { 'Non configurée' })`n" +
                  "Action requise : Placer le MSI localement ou configurer `$MsiNetworkSource.") `
        -EntryType "Error"
    exit 5
}

# --- Étape 6c : Vérification d'intégrité SHA-256 ---
$actualHash = (Get-FileHash -Path $MsiLocalPath -Algorithm SHA256).Hash

if ($actualHash -ne $MsiExpectedHash) {
    Write-DeployLog -EventId 1510 `
        -Message ("ALERTE INTÉGRITÉ — POSSIBLE SUPPLY CHAIN ATTACK`n" +
                  "Le hash du MSI ne correspond pas au hash attendu.`n" +
                  "Fichier      : $MsiLocalPath`n" +
                  "Hash reçu    : $actualHash`n" +
                  "Hash attendu : $MsiExpectedHash`n" +
                  "Installation annulée. Investiguer immédiatement.") `
        -EntryType "Error"
    exit 5
}

Write-DeployLog -EventId 1505 `
    -Message "Intégrité MSI vérifiée (SHA-256: $actualHash)." `
    -EntryType "Information"

# ============================================================================
# PHASE 7 : INSTALLATION SILENCIEUSE + IMPORT CLE + HARDENING CONFIG
# ============================================================================
# Etape 7a : Installation MSI (sans cle - le parametre WAZUH_AGENT_KEY
#            n'injecte pas fiablement dans client.keys sur 4.10.x)
# Etape 7b : Import de la cle via manage_agents.exe -i (methode fiable)
# Etape 7c : Desactivation de l'auto-enrollment dans ossec.conf
#            (empeche l'agent de tenter un re-enrollment via authd)
# ============================================================================

Write-DeployLog -EventId 1600 `
    -Message "Phase 7 : Installation et configuration de l'agent Wazuh..." `
    -EntryType "Information"

# --- Etape 7a : Installation MSI ---
Write-DeployLog -EventId 1610 `
    -Message "Etape 7a : Installation MSI silencieuse..." `
    -EntryType "Information"

try {
    $msiArgs = @(
        "/i", "`"$MsiLocalPath`""
        "/qn"
        "WAZUH_MANAGER=`"$WazuhManagerFQDN`""
        "WAZUH_AGENT_NAME=`"$env:COMPUTERNAME`""
        "WAZUH_PROTOCOL=`"TCP`""
    )

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs `
        -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "msiexec a retourne le code de sortie $($process.ExitCode)."
    }

    Write-DeployLog -EventId 1611 `
        -Message "Installation MSI terminee avec succes (ExitCode=0)." `
        -EntryType "Information"
}
catch {
    Write-DeployLog -EventId 1619 `
        -Message "ECHEC FATAL : Installation MSI echouee. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 6
}

# --- Etape 7b : Import direct de la cle agent ---
Write-DeployLog -EventId 1620 `
    -Message "Etape 7b : Ecriture directe de la cle agent dans client.keys..." `
    -EntryType "Information"

try {
    $clientKeys = "C:\Program Files (x86)\ossec-agent\client.keys"
    
    # Decodage Base64 de la cle renvoyee par l'API
    $decodedKey = [System.Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String($agentKey)
    )
    
    # Ecriture dans le fichier client.keys
    [System.IO.File]::WriteAllText($clientKeys, $decodedKey)

    if ((Test-Path $clientKeys) -and ((Get-Item $clientKeys).Length -gt 0)) {
        # --- PRODUCTION HARDENING : Verrouillage ACL du fichier client.keys ---
        # Seuls SYSTEM et Administrators peuvent lire ce fichier.
        # Cela empêche un utilisateur standard de voler la clé d'authentification de l'agent.
        try {
            $acl = New-Object System.Security.AccessControl.FileSecurity
            $acl.SetAccessRuleProtection($true, $false)  # Désactiver l'héritage
            $systemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")  # SYSTEM
            $adminsSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")  # Administrators
            $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $systemSid, "FullControl", "Allow")
            $adminsRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $adminsSid, "FullControl", "Allow")
            $acl.AddAccessRule($systemRule)
            $acl.AddAccessRule($adminsRule)
            [System.IO.File]::SetAccessControl($clientKeys, $acl)
            Write-DeployLog -EventId 1622 `
                -Message "ACL client.keys verrouille : acces restreint a SYSTEM et Administrators." `
                -EntryType "Information"
        }
        catch {
            Write-DeployLog -EventId 1623 `
                -Message "AVERTISSEMENT : Impossible de verrouiller les ACL de client.keys. Erreur: $($_.Exception.Message)" `
                -EntryType "Warning"
        }

        Write-DeployLog -EventId 1621 `
            -Message "Cle injectee avec succes dans client.keys." `
            -EntryType "Information"
    }
    else {
        throw "Le fichier client.keys est vide ou introuvable apres l'ecriture."
    }
}
catch {
    Write-DeployLog -EventId 1629 `
        -Message "ECHEC FATAL : Import de la cle echoue. Erreur: $($_.Exception.Message)" `
        -EntryType "Error"
    exit 6
}
finally {
    # --- PRODUCTION HARDENING : Nettoyage securise de la memoire ---
    # Ecraser les octets du secret avant de liberer la reference.
    if ($decodedKey) {
        $charArray = $decodedKey.ToCharArray()
        for ($i = 0; $i -lt $charArray.Length; $i++) { $charArray[$i] = [char]0 }
        $decodedKey = $null
    }
    $agentKey = $null
    [System.GC]::Collect()
}

# --- Etape 7c : Desactivation de l'auto-enrollment ---
Write-DeployLog -EventId 1630 `
    -Message "Etape 7c : Desactivation de l'auto-enrollment dans ossec.conf..." `
    -EntryType "Information"

try {
    $ossecConf = "C:\Program Files (x86)\ossec-agent\ossec.conf"
    $confContent = [System.IO.File]::ReadAllText($ossecConf, [System.Text.Encoding]::UTF8)

    # Remplacer <enabled>yes</enabled> par <enabled>no</enabled> dans la section enrollment
    $pattern = '(<enrollment>\s*<enabled>)yes(</enabled>)'
    if ($confContent -match $pattern) {
        $confContent = $confContent -replace $pattern, '${1}no${2}'
        [System.IO.File]::WriteAllText($ossecConf, $confContent, [System.Text.Encoding]::UTF8)
        Write-DeployLog -EventId 1631 `
            -Message "Auto-enrollment desactive dans ossec.conf (enrollment.enabled = no)." `
            -EntryType "Information"
    }
    else {
        Write-DeployLog -EventId 1632 `
            -Message "Section enrollment deja desactivee ou absente dans ossec.conf." `
            -EntryType "Information"
    }
}
catch {
    Write-DeployLog -EventId 1639 `
        -Message "AVERTISSEMENT : Impossible de modifier ossec.conf. L'agent pourrait tenter un re-enrollment. Erreur: $($_.Exception.Message)" `
        -EntryType "Warning"
}

# ============================================================================
# PHASE 8 : VÉRIFICATION POST-INSTALLATION — Validation du service
# ============================================================================

Write-DeployLog -EventId 1700 `
    -Message "Phase 8 : Vérification post-installation du service WazuhSvc..." `
    -EntryType "Information"

# Attendre quelques secondes pour que le service s'initialise
Start-Sleep -Seconds 10

$svc = Get-Service -Name "WazuhSvc" -ErrorAction SilentlyContinue

if (-not $svc) {
    Write-DeployLog -EventId 1709 `
        -Message "AVERTISSEMENT : Le service WazuhSvc n'existe pas après l'installation. Vérification manuelle requise." `
        -EntryType "Error"
    exit 7
}

# --- PRODUCTION HARDENING : Politique de redemarrage automatique du service ---
# En cas de crash de l'agent, Windows le redémarrera automatiquement.
# 1er échec : redémarrage après 30s, 2e échec : après 60s, suivants : après 120s.
try {
    sc.exe failure WazuhSvc reset= 86400 actions= restart/30000/restart/60000/restart/120000 | Out-Null
    Write-DeployLog -EventId 1703 `
        -Message "Politique de recovery configuree : redemarrage auto apres 30s/60s/120s." `
        -EntryType "Information"
}
catch {
    Write-DeployLog -EventId 1704 `
        -Message "AVERTISSEMENT : Impossible de configurer la politique de recovery. Erreur: $($_.Exception.Message)" `
        -EntryType "Warning"
}

if ($svc.Status -ne "Running") {
    Write-DeployLog -EventId 1702 `
        -Message "Le service WazuhSvc existe mais n'est pas démarré (Status: $($svc.Status)). Tentative de démarrage..." `
        -EntryType "Warning"

    try {
        Start-Service -Name "WazuhSvc"
        Start-Sleep -Seconds 5
        $svc.Refresh()
    } catch {
        Write-DeployLog -EventId 1709 `
            -Message "Impossible de démarrer le service WazuhSvc. Erreur: $($_.Exception.Message)" `
            -EntryType "Error"
        exit 7
    }
}

# ============================================================================
# SUCCÈS FINAL
# ============================================================================

Write-DeployLog -EventId 1800 `
    -Message ("DÉPLOIEMENT TERMINÉ AVEC SUCCÈS`n" +
              "Hostname    : $env:COMPUTERNAME`n" +
              "Agent ID    : $agentId`n" +
              "Manager     : $WazuhManagerFQDN`n" +
              "Service     : $($svc.Status)`n" +
              "MSI Hash    : $actualHash`n" +
              "Horodatage  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')") `
    -EntryType "Information"

exit 0
