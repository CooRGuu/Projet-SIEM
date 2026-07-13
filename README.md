# ðŸ›¡ï¸ Projet de DÃ©ploiement d'un SOC avec Wazuh & Ansible

Ce dÃ©pÃ´t contient l'infrastructure-as-code (IaC), les scripts de dÃ©ploiement sÃ©curisÃ©s, et l'ensemble de la documentation d'architecture pour le dÃ©ploiement d'un **SOC (Security Operations Center)** basÃ© sur le SIEM **Wazuh** dans un rÃ©seau d'Ã©tablissement d'enseignement.

Il couvre le dÃ©ploiement du **Manager Wazuh** (via Ansible), l'enrÃ´lement de masse des **agents Windows** (via GPO/Active Directory avec durcissement de sÃ©curitÃ©), ainsi que les audits rÃ©glementaires associÃ©s.

---

## ðŸ“‚ Structure du Projet

```text
Projet-SIEM/
â”œâ”€â”€ README.md                           # Ce fichier de prÃ©sentation gÃ©nÃ©rale
â”œâ”€â”€ config/                             # Configurations spÃ©cifiques hors Ansible-Galaxy
â”‚   â”œâ”€â”€ ansible/
â”‚   â”‚   â””â”€â”€ deploy_wazuh_manager.yml    # Playbook de dÃ©ploiement de production autonome
â”‚   â””â”€â”€ wazuh-manager/
â”‚       â””â”€â”€ custom_wazuh_rules.xml      # RÃ¨gles de dÃ©tection personnalisÃ©es (MITRE ATT&CK)
â”œâ”€â”€ docs/                               # Livrables, demandes et guides d'intÃ©gration
â”‚   â”œâ”€â”€ demandes/
â”‚   â”‚   â”œâ”€â”€ fiche_demande_active_directory.md # Fiche de demande de droits AD
â”‚   â”‚   â”œâ”€â”€ fiche_demande_proxfibre.md        # Fiche rÃ©seau/infra ProxFibre
â”‚   â”‚   â””â”€â”€ mail_tuteur_stage.txt       # ModÃ¨le d'email d'accompagnement
â”‚   â”œâ”€â”€ audit/
â”‚   â”‚   â”œâ”€â”€ audit_conformite_referentiels.md  # Alignement ANSSI, NIST, ISO 27001
â”‚   â”‚   â””â”€â”€ attack_playbooks_and_detection_matrix.md # ScÃ©narios d'attaque et matrice de dÃ©tection
â”‚   â””â”€â”€ guides/
â”‚       â”œâ”€â”€ gpo_deployment_guide.md   # Guide technique complet pour l'admin AD
â”‚       â””â”€â”€ document_suivi_projet_v2.md  # Journal d'avancement du projet
â”œâ”€â”€ scripts/                            # Scripts opÃ©rationnels (Windows & Linux)
â”‚   â”œâ”€â”€ windows/
â”‚   â”‚   â”œâ”€â”€ Deploy-WazuhAgent.ps1       # Script d'installation GPO (idempotent, DPAPI, SHA256)
â”‚   â”‚   â”œâ”€â”€ Initialize-WazuhDeployCredential.ps1 # Chiffrement local du jeton API (DPAPI)
â”‚   â”‚   â””â”€â”€ Rotate-WazuhApiPassword.ps1 # Script de rotation du mot de passe de l'API Wazuh
â”‚   â””â”€â”€ linux/
â”‚       â””â”€â”€ wazuh-health-monitor.sh     # Script de monitoring du Manager Wazuh (Syslog/Email)
â””â”€â”€ soc-infrastructure/                 # RÃ´les et playbooks Ansible structurÃ©s (Lab / Prod)
    â”œâ”€â”€ ansible.cfg                     # ParamÃ©trages globaux Ansible
    â”œâ”€â”€ inventories/
    â”‚   â”œâ”€â”€ lab/                        # Environnement de test local (Vagrant / Proxmox)
    â”‚   â”‚   â”œâ”€â”€ hosts.ini
    â”‚   â”‚   â””â”€â”€ group_vars/
    â”‚   â”‚       â”œâ”€â”€ all.yml
    â”‚   â”‚       â””â”€â”€ vault.yml           # Secrets chiffrÃ©s pour le Lab
    â”‚   â””â”€â”€ prod/                       # Environnement de production rÃ©elle (ProxFibre)
    â”‚       â”œâ”€â”€ hosts.ini
    â”‚       â””â”€â”€ group_vars/
```

---

## ðŸš€ Composants Principaux & SÃ©curitÃ©

### 1. DÃ©ploiement Windows durci (GPO & PowerShell)
Le script `Deploy-WazuhAgent.ps1` (dans `scripts/windows/`) est conÃ§u pour Ãªtre exÃ©cutÃ© en script de dÃ©marrage de machine (contexte `NT AUTHORITY\SYSTEM`). Il intÃ¨gre des mesures de sÃ©curitÃ© conformes aux recommandations de l'ANSSI :
* **Chiffrement DPAPI :** Le mot de passe ou jeton API pour l'enrÃ´lement n'est pas stockÃ© en clair. Il est prÃ©-chiffrÃ© via le script `Initialize-WazuhDeployCredential.ps1` en contexte machine pour que seul le compte `SYSTEM` local de la machine cible puisse le dÃ©chiffrer.
* **VÃ©rification d'intÃ©gritÃ© :** Le script calcule l'empreinte SHA-256 du binaire d'installation MSI de l'agent et la compare Ã  une empreinte de confiance avant de lancer l'installation.
* **ContrÃ´le d'accÃ¨s (ACL) :** Les clÃ©s cryptographiques stockÃ©es localement (`client.keys`) ont des permissions restreintes (seuls `SYSTEM` et `Administrators` y ont accÃ¨s).
* **Idempotence :** Le script dÃ©tecte si l'agent est dÃ©jÃ  prÃ©sent et opÃ©rationnel, et interrompt son exÃ©cution s'il n'y a rien Ã  faire pour prÃ©server les ressources.

### 2. Supervision du Manager (Linux)
Le script `wazuh-health-monitor.sh` (dans `scripts/linux/`) surveille l'Ã©tat du manager Wazuh et envoie des alertes critiques (via Syslog ou alertes e-mail configurÃ©es) si le service manager ou l'API tombe, ou si les certificats TLS de communication approchent de leur date d'expiration (alertes Ã  90, 30 et 7 jours).

### 3. Matrice de conformitÃ© et dÃ©tection
Les documents dans `docs/audit/` cartographient l'infrastructure SOC par rapport aux exigences rÃ©glementaires et dÃ©crivent les scÃ©narios de test (tels que la dÃ©tection de crÃ©ation d'utilisateurs suspects, d'exÃ©cution de scripts PowerShell encodÃ©s ou d'attaques par force brute sur Active Directory).

---

## ðŸ› ï¸ Guide de DÃ©marrage Rapide

### 1. Installation des dÃ©pendances Ansible
Depuis la machine d'administration Linux :
```bash
cd soc-infrastructure
ansible-galaxy install -r requirements.yml
```

### 2. DÃ©ploiement de l'infrastructure Manager
1. CrÃ©ez un fichier `.vault_pass` contenant le mot de passe du coffre-fort Ansible **Ã  la racine du projet `Projet-SIEM/`** (le fichier est ignorÃ© par Git).
2. Configurez vos cibles et variables dans `soc-infrastructure/inventories/lab/` (ou `prod/`).
3. ExÃ©cutez le playbook de dÃ©ploiement :
```bash
# Pour le laboratoire
ansible-playbook -i inventories/lab/hosts.ini playbooks/deploy_manager.yml --vault-password-file ../.vault_pass
```

### 3. PrÃ©paration du dÃ©ploiement Windows (GPO)
Pour mettre en place le dÃ©ploiement automatisÃ© sur le rÃ©seau AD de l'Ã©cole :
1. Consultez la fiche de demande AD dans `docs/demandes/fiche_demande_active_directory.md`.
2. GÃ©nÃ©rez le secret d'enrÃ´lement chiffrÃ© sur une machine de test en contexte local `SYSTEM` (ou via le guide dans `docs/guides/gpo_deployment_guide.md`) avec le script `Initialize-WazuhDeployCredential.ps1`.
3. DÃ©posez `Deploy-WazuhAgent.ps1` et le binaire MSI sur votre partage de fichiers rÃ©seau (ex: `NETLOGON`).
4. Configurez la GPO pour lancer le script au dÃ©marrage des ordinateurs.

---

## ðŸ›¡ï¸ Auditing & QualitÃ© du Code
* **Linter Ansible :** Ce projet suit les standards de qualitÃ© dÃ©finis par `ansible-lint` configurÃ© dans `soc-infrastructure/.ansible-lint`.
* **ConformitÃ© rÃ©glementaire :** Mappage complet des contrÃ´les du SOC sur le guide d'hygiÃ¨ne informatique de l'ANSSI et les contrÃ´les CIS v8 disponible dans `docs/audit/audit_conformite_referentiels.md`.


