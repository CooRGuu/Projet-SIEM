# Guide d'Implémentation GPO : Déploiement Zero-Touch Wazuh

Ce document détaille la procédure standard de déploiement du script `Deploy-WazuhAgent.ps1` via les stratégies de groupe (GPO) Active Directory sur un parc de postes de travail Windows.

## 1. Préparation de l'infrastructure de distribution (Staging)

Afin d'éviter la saturation de la bande passante vers l'extérieur et centraliser la gestion, les fichiers doivent être hébergés sur un partage réseau sécurisé (ex: `\\AD.DOMAIN.LOCAL\NETLOGON` ou un DFS dédié).

1. Créer un répertoire de distribution, ex: `\\SRV-FICHIERS\Deploy\Wazuh\`
2. Y déposer :
   - Le script `Deploy-WazuhAgent.ps1`
   - Le binaire `wazuh-agent-4.10.4-1.msi`
3. Restreindre les droits NTFS et de partage :
   - **Admins du domaine** : Contrôle Total
   - **Ordinateurs du domaine** : Lecture et Exécution (indispensable pour l'installation par `SYSTEM`)
   - **Utilisateurs du domaine** : Lecture (ou accès refusé selon la politique)
4. Modifier la ligne 17 du script `Deploy-WazuhAgent.ps1` pour cibler ce partage :
   ```powershell
   $MsiNetworkSource = "\\SRV-FICHIERS\Deploy\Wazuh\wazuh-agent-4.10.4-1.msi"
   ```

## 2. Configuration de la GPO "Wazuh_Agent_Deployment"

Le script nécessite les droits `NT AUTHORITY\SYSTEM` pour installer un MSI et interagir avec DPAPI (LocalMachine scope). Il doit donc être déployé en tant que **Script de démarrage ordinateur (Computer Startup Script)**.

1. Ouvrir la console **Gestion de stratégie de groupe** (`gpmc.msc`).
2. Créer une nouvelle GPO nommée `SEC_DEP_WazuhAgent` et la lier à l'Unité d'Organisation (OU) contenant les postes cibles.
3. Éditer la GPO : `Configuration ordinateur > Stratégies > Paramètres Windows > Scripts (démarrage/arrêt)`.
4. Double-cliquer sur **Démarrage**, aller dans l'onglet **Scripts PowerShell**.
5. Cliquer sur **Ajouter** :
   - **Nom du script** : `\\SRV-FICHIERS\Deploy\Wazuh\Deploy-WazuhAgent.ps1`
   - **Paramètres** : (laisser vide)
6. Dans le menu déroulant en bas, sélectionner **Exécuter les scripts Windows PowerShell en premier**.

> [!IMPORTANT]
> Pour que le script puisse démarrer avant l'ouverture de session de l'utilisateur et avoir le temps d'attendre Tailscale, assurez-vous que la GPO de délai maximal d'exécution des scripts n'est pas réglée trop bas (par défaut 600 secondes, ce qui est suffisant).

## 3. Gestion du secret DPAPI (Limites du Lab et Scalabilité)

### Le défi actuel
La sécurité implémentée repose sur DPAPI avec le scope `LocalMachine`. La clé générée est unique au matériel physique du poste. Il est donc **impossible** de provisionner le fichier `api_credential.bin` sur le serveur AD et de le copier via GPO (le poste cible ne pourrait pas le déchiffrer).

### Déploiement dans le contexte "Lab"
Actuellement, pour qu'un poste exécute la GPO avec succès, il faut au préalable qu'un administrateur ait provisionné le secret localement :
1. Connexion en admin sur le poste (ou exécution via WinRM/PowerShell Remoting).
2. Exécution de `Initialize-WazuhDeployCredential.ps1`.
3. Au redémarrage suivant, la GPO s'applique et déploie l'agent.

### L'Option 3 (Cible de Production Industrielle)
Pour industrialiser ce processus sur 10 000 postes de travail de manière réellement "Zero-Touch" et éviter la contrainte DPAPI :

1. **Retirer les credentials du script GPO**. Le script GPO s'authentifie auprès du Manager Wazuh (ou d'un proxy) en utilisant l'identité Kerberos de la machine (`POSTE01$@DOMAIN.LOCAL`).
2. **Déployer une API Proxy intermédiaire** (ex: API Python / Go hébergée sur l'AD ou dans une DMZ) qui :
   - Reçoit la requête d'enrôlement du poste.
   - Vérifie dans l'AD si `POSTE01$` est légitime et actif.
   - Si oui, l'API Proxy utilise ses propres credentials administrateurs (cachés côté serveur) pour interagir avec l'API Wazuh.
   - Renvoie la clé unique chiffrée à l'agent.

## 4. Stratégie de mise à jour (Life Cycle Management)

L'architecture actuelle gère nativement l'idempotence et les mises à jour :
- L'agent vérifie sa version via la base de registre (`HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall`).
- Pour pousser la version `4.11.0` du parc, il suffira de :
  1. Déposer le nouveau MSI sur le partage réseau.
  2. Mettre à jour `$MsiExpectedHash` dans le script de déploiement avec le hash de la nouvelle version.
  3. Au prochain redémarrage des postes, le script détectera la différence de version et lancera l'upgrade (msiexec gère nativement les mises à niveau).
