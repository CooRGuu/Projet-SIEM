<#
.SYNOPSIS
    Script de simulation d'attaques pour environnement de test SOC/Wazuh.

.DESCRIPTION
    ATTENTION : CE SCRIPT DOIT ÊTRE UTILISÉ UNIQUEMENT DANS UN ENVIRONNEMENT DE TEST OU DE LABORATOIRE.
    NE PAS EXÉCUTER EN PRODUCTION.
    Ce script génère des comportements suspects afin de déclencher et de valider les règles de détection (Wazuh, SIEM).
    Chaque fonction est associée à une tactique/technique MITRE ATT&CK.

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient entreprises sans réellement les exécuter.

.EXAMPLE
    .\Simulate-Attacks.ps1 -DryRun
    .\Simulate-Attacks.ps1
#>

param(
    [switch]$DryRun
)

$LogFile = "C:\Temp\AttackSimulation.log"

Function Write-SimLog {
    param([string]$Message)
    $TimeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $LogLine = "[$TimeStamp] $Message"
    Write-Host $LogLine -ForegroundColor Yellow
    if (-not $DryRun) {
        $LogLine | Out-File -FilePath $LogFile -Append
    }
}

Function Simulate-BruteForce {
    <#
    .SYNOPSIS
        MITRE ATT&CK: T1110 (Brute Force)
    #>
    Write-SimLog "--- Démarrage Simulation Brute Force (T1110) ---"
    $Attempts = 10
    $FakeUser = "TestBruteForceUser"
    
    for ($i = 1; $i -le $Attempts; $i++) {
        Write-SimLog "Tentative de connexion échouée $i pour l'utilisateur $FakeUser"
        if (-not $DryRun) {
            # Note: PowerShell direct login attempt to trigger 4625 is complex without invoking API or specific commands.
            # Here we simulate by trying to run a command as a non-existent user, which will fail and may log an event.
            try {
                $pwd = ConvertTo-SecureString "WrongPass123!" -AsPlainText -Force
                $cred = New-Object System.Management.Automation.PSCredential ($FakeUser, $pwd)
                Start-Process "cmd.exe" -Credential $cred -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

Function Simulate-PrivilegeEscalation {
    <#
    .SYNOPSIS
        MITRE ATT&CK: T1078 (Valid Accounts), T1098 (Account Manipulation)
    #>
    Write-SimLog "--- Démarrage Simulation Escalade de Privilèges (T1078/T1098) ---"
    $FakeUser = "SimAdminTest"
    
    Write-SimLog "Création de l'utilisateur local $FakeUser et ajout au groupe Administrateurs"
    if (-not $DryRun) {
        try {
            net user $FakeUser "TempPass123!" /add
            net localgroup Administrators $FakeUser /add
            Start-Sleep -Seconds 2
            # Cleanup
            net user $FakeUser /delete
            Write-SimLog "Nettoyage: utilisateur $FakeUser supprimé."
        } catch {
            Write-SimLog "Erreur lors de la simulation d'escalade de privilèges."
        }
    }
}

Function Simulate-SuspiciousProcess {
    <#
    .SYNOPSIS
        MITRE ATT&CK: T1059 (Command and Scripting Interpreter), T1105 (Ingress Tool Transfer)
    #>
    Write-SimLog "--- Démarrage Simulation Processus Suspect (T1059/T1105) ---"
    
    Write-SimLog "Lancement d'une commande PowerShell encodée (Base64)"
    if (-not $DryRun) {
        # Commande: Write-Host 'Test'
        $EncodedCommand = "VwByAGkAdABlAC0ASABvAHMAdAAgACcAVABlAHMAdAAnAA==" 
        Start-Process powershell.exe -ArgumentList "-EncodedCommand $EncodedCommand" -WindowStyle Hidden
    }

    Write-SimLog "Utilisation de certutil.exe pour télécharger un fichier factice"
    if (-not $DryRun) {
        Start-Process certutil.exe -ArgumentList "-urlcache -split -f https://example.com/ C:\Temp\fake_download.txt" -WindowStyle Hidden
    }
}

Function Simulate-RegistryPersistence {
    <#
    .SYNOPSIS
        MITRE ATT&CK: T1547.001 (Registry Run Keys / Startup Folder)
    #>
    Write-SimLog "--- Démarrage Simulation Persistance Registre (T1547.001) ---"
    $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $RegName = "MaliciousUpdate"
    $RegValue = "C:\Windows\System32\cmd.exe /c echo 'Persistence'"

    Write-SimLog "Ajout de la clé de registre: $RegPath\$RegName"
    if (-not $DryRun) {
        New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType String -Force | Out-Null
        Start-Sleep -Seconds 2
        # Cleanup
        Remove-ItemProperty -Path $RegPath -Name $RegName -Force
        Write-SimLog "Nettoyage: clé de registre supprimée."
    }
}

Function Simulate-FileIntegrityChange {
    <#
    .SYNOPSIS
        MITRE ATT&CK: T1490 (Inhibit System Recovery) - Indirectement, testera le FIM Wazuh.
    #>
    Write-SimLog "--- Démarrage Simulation Modification Fichier (FIM Test) ---"
    
    # Assurez-vous que C:\Temp\FIM_Test est surveillé par Wazuh syscheck
    $FIMDir = "C:\Temp\FIM_Test"
    $FIMFile = "$FIMDir\critical_config.txt"

    if (-not (Test-Path $FIMDir)) {
        New-Item -ItemType Directory -Path $FIMDir | Out-Null
    }

    Write-SimLog "Création/Modification du fichier $FIMFile"
    if (-not $DryRun) {
        "Configuration sécurisée $(Get-Date)" | Out-File -FilePath $FIMFile
        Start-Sleep -Seconds 1
        "Configuration MODIFIÉE $(Get-Date)" | Out-File -FilePath $FIMFile -Append
    }
}

Function Simulate-NetworkScan {
    <#
    .SYNOPSIS
        MITRE ATT&CK: T1046 (Network Service Discovery)
    #>
    Write-SimLog "--- Démarrage Simulation Scan Réseau (T1046) ---"
    $TargetIP = "192.168.1.1" # Mettre une IP locale générique
    $Ports = @(22, 445, 3389, 8080)

    Write-SimLog "Tentatives de connexion vers $TargetIP sur les ports courants"
    if (-not $DryRun) {
        foreach ($Port in $Ports) {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $connect = $tcpClient.BeginConnect($TargetIP, $Port, $null, $null)
                $wait = $connect.AsyncWaitHandle.WaitOne(200, $false)
                $tcpClient.Close()
            } catch {}
        }
    }
}

Function Show-Menu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "       SIMULATEUR D'ATTAQUES SOC         " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "1. T1110 - Brute Force Login (Failed)"
    Write-Host "2. T1078/T1098 - Privilege Escalation"
    Write-Host "3. T1059/T1105 - Suspicious Processes (Encoded PS, Certutil)"
    Write-Host "4. T1547.001 - Registry Persistence (Run Key)"
    Write-Host "5. FIM Test - Modify Monitored File"
    Write-Host "6. T1046 - Network Scan"
    Write-Host "7. Run ALL Simulations"
    Write-Host "Q. Quitter"
    Write-Host "-----------------------------------------"
}

# Main Logic
if (-not (Test-Path "C:\Temp")) { New-Item -ItemType Directory -Path "C:\Temp" | Out-Null }
Write-SimLog "Lancement de Simulate-Attacks.ps1 (DryRun=$DryRun)"

$RunLoop = $true
while ($RunLoop) {
    Show-Menu
    $Choice = Read-Host "Sélectionnez une option"

    switch ($Choice) {
        '1' { Simulate-BruteForce; Pause }
        '2' { Simulate-PrivilegeEscalation; Pause }
        '3' { Simulate-SuspiciousProcess; Pause }
        '4' { Simulate-RegistryPersistence; Pause }
        '5' { Simulate-FileIntegrityChange; Pause }
        '6' { Simulate-NetworkScan; Pause }
        '7' { 
            Simulate-BruteForce
            Simulate-PrivilegeEscalation
            Simulate-SuspiciousProcess
            Simulate-RegistryPersistence
            Simulate-FileIntegrityChange
            Simulate-NetworkScan
            Pause
        }
        'Q' { $RunLoop = $false }
        'q' { $RunLoop = $false }
        default { Write-Host "Choix invalide." -ForegroundColor Red; Pause }
    }
}

Write-SimLog "Fin du script de simulation."
