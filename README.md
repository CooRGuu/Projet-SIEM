# 🛡️ Projet de Déploiement d'un SOC avec Wazuh & Ansible

Ce dépôt contient l'infrastructure-as-code (IaC), les scripts de déploiement sécurisés, et l'ensemble de la documentation d'architecture pour le déploiement d'un **SOC (Security Operations Center)** basé sur le SIEM **Wazuh** dans un réseau d'établissement d'enseignement.

Il couvre le déploiement du **Manager Wazuh** (via Ansible), l'enrôlement de masse des **agents Windows** (via GPO/Active Directory avec durcissement de sécurité), ainsi que les audits réglementaires associés.

---

## 📂 Structure du Projet

```text
Projet-SIEM/
├── README.md                           # Ce fichier de présentation générale
├── config/                             # Configurations spécifiques hors Ansible-Galaxy
│   ├── ansible/
│   │   └── deploy_wazuh_manager.yml    # Playbook de déploiement de production autonome
│   └── wazuh-manager/
│       └── custom_wazuh_rules.xml      # Règles de détection personnalisées (MITRE ATT&CK)
├── docs/                               # Livrables, demandes et guides d'intégration
│   ├── demandes/
│   │   ├── fiche_demande_active_directory.html # Fiche de demande de droits AD
│   │   ├── fiche_demande_proxfibre.html        # Fiche réseau/infra ProxFibre
│   │   └── mail_tuteur_stage.txt       # Modèle d'email d'accompagnement
│   ├── audit/
│   │   ├── audit_conformite_referentiels.html  # Alignement ANSSI, NIST, ISO 27001
│   │   └── attack_playbooks_and_detection_matrix.html # Scénarios d'attaque et matrice de détection
│   └── guides/
│       ├── gpo_deployment_guide.html   # Guide technique complet pour l'admin AD
│       └── document_suivi_projet.html  # Journal d'avancement du projet
├── scripts/                            # Scripts opérationnels (Windows & Linux)
│   ├── windows/
│   │   ├── Deploy-WazuhAgent.ps1       # Script d'installation GPO (idempotent, DPAPI, SHA256)
│   │   ├── Initialize-WazuhDeployCredential.ps1 # Chiffrement local du jeton API (DPAPI)
│   │   └── Rotate-WazuhApiPassword.ps1 # Script de rotation du mot de passe de l'API Wazuh
│   └── linux/
│       └── wazuh-health-monitor.sh     # Script de monitoring du Manager Wazuh (Syslog/Email)
└── soc-infrastructure/                 # Rôles et playbooks Ansible structurés (Lab / Prod)
    ├── ansible.cfg                     # Paramétrages globaux Ansible
    ├── inventories/
    │   ├── lab/                        # Environnement de test local (Vagrant / Proxmox)
    │   │   ├── hosts.ini
    │   │   └── group_vars/
    │   │       ├── all.yml
    │   │       └── vault.yml           # Secrets chiffrés pour le Lab
    │   └── prod/                       # Environnement de production réelle (ProxFibre)
    │       ├── hosts.ini
    │       └── group_vars/
```

---

## 🚀 Composants Principaux & Sécurité

### 1. Déploiement Windows durci (GPO & PowerShell)
Le script `Deploy-WazuhAgent.ps1` (dans `scripts/windows/`) est conçu pour être exécuté en script de démarrage de machine (contexte `NT AUTHORITY\SYSTEM`). Il intègre des mesures de sécurité conformes aux recommandations de l'ANSSI :
* **Chiffrement DPAPI :** Le mot de passe ou jeton API pour l'enrôlement n'est pas stocké en clair. Il est pré-chiffré via le script `Initialize-WazuhDeployCredential.ps1` en contexte machine pour que seul le compte `SYSTEM` local de la machine cible puisse le déchiffrer.
* **Vérification d'intégrité :** Le script calcule l'empreinte SHA-256 du binaire d'installation MSI de l'agent et la compare à une empreinte de confiance avant de lancer l'installation.
* **Contrôle d'accès (ACL) :** Les clés cryptographiques stockées localement (`client.keys`) ont des permissions restreintes (seuls `SYSTEM` et `Administrators` y ont accès).
* **Idempotence :** Le script détecte si l'agent est déjà présent et opérationnel, et interrompt son exécution s'il n'y a rien à faire pour préserver les ressources.

### 2. Supervision du Manager (Linux)
Le script `wazuh-health-monitor.sh` (dans `scripts/linux/`) surveille l'état du manager Wazuh et envoie des alertes critiques (via Syslog ou alertes e-mail configurées) si le service manager ou l'API tombe, ou si les certificats TLS de communication approchent de leur date d'expiration (alertes à 90, 30 et 7 jours).

### 3. Matrice de conformité et détection
Les documents dans `docs/audit/` cartographient l'infrastructure SOC par rapport aux exigences réglementaires et décrivent les scénarios de test (tels que la détection de création d'utilisateurs suspects, d'exécution de scripts PowerShell encodés ou d'attaques par force brute sur Active Directory).

---

## 🛠️ Guide de Démarrage Rapide

### 1. Installation des dépendances Ansible
Depuis la machine d'administration Linux :
```bash
cd soc-infrastructure
ansible-galaxy install -r requirements.yml
```

### 2. Déploiement de l'infrastructure Manager
1. Créez un fichier `.vault_pass` contenant le mot de passe du coffre-fort Ansible **à la racine du projet `Projet-SIEM/`** (le fichier est ignoré par Git).
2. Configurez vos cibles et variables dans `soc-infrastructure/inventories/lab/` (ou `prod/`).
3. Exécutez le playbook de déploiement :
```bash
# Pour le laboratoire
ansible-playbook -i inventories/lab/hosts.ini playbooks/deploy_manager.yml --vault-password-file ../.vault_pass
```

### 3. Préparation du déploiement Windows (GPO)
Pour mettre en place le déploiement automatisé sur le réseau AD de l'école :
1. Consultez la fiche de demande AD dans `docs/demandes/fiche_demande_active_directory.html`.
2. Générez le secret d'enrôlement chiffré sur une machine de test en contexte local `SYSTEM` (ou via le guide dans `docs/guides/gpo_deployment_guide.html`) avec le script `Initialize-WazuhDeployCredential.ps1`.
3. Déposez `Deploy-WazuhAgent.ps1` et le binaire MSI sur votre partage de fichiers réseau (ex: `NETLOGON`).
4. Configurez la GPO pour lancer le script au démarrage des ordinateurs.

---

## 🛡️ Auditing & Qualité du Code
* **Linter Ansible :** Ce projet suit les standards de qualité définis par `ansible-lint` configuré dans `soc-infrastructure/.ansible-lint`.
* **Conformité réglementaire :** Mappage complet des contrôles du SOC sur le guide d'hygiène informatique de l'ANSSI et les contrôles CIS v8 disponible dans `docs/audit/audit_conformite_referentiels.html`.

