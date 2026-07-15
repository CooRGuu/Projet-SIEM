# Projet de déploiement d'un SOC avec Wazuh & Ansible

Ce dépôt contient l'infrastructure-as-code (IaC), les scripts de déploiement et la documentation pour mettre en place un **SOC (Security Operations Center)** basé sur le SIEM **Wazuh** dans un réseau d'établissement d'enseignement.

On couvre ici le déploiement du Manager Wazuh via Ansible, l'enrôlement de masse des agents Windows via GPO/Active Directory (avec durcissement de sécurité), ainsi que les audits de conformité associés.

---

## Structure du projet

```text
Projet-SIEM/
├── README.md
├── config/
│   ├── ansible/
│   │   └── deploy_wazuh_manager.yml    # Playbook de déploiement autonome
│   └── wazuh-manager/
│       └── custom_wazuh_rules.xml      # Règles de détection personnalisées (MITRE ATT&CK)
├── docs/
│   ├── audit/
│   │   ├── attack_playbooks_and_detection_matrix.md
│   │   ├── audit_conformite_complet.md
│   │   ├── audit_conformite_referentiels.md
│   │   ├── audit_soc_wazuh_devsecops.md
│   │   └── benchmark_deploiement_agents_siem.md
│   ├── diagramme_gantt_projet.md
│   ├── glossaire_technique.md
│   ├── grc/
│   │   ├── analyse_risques_ebios_rm.md
│   │   ├── charte_admin_soc.md
│   │   ├── matrice_raci.md
│   │   ├── plan_continuite_reprise_activite.md
│   │   ├── plan_reponse_incidents.md
│   │   ├── politique_gestion_acces_iam.md
│   │   ├── politique_sauvegarde_restauration.md
│   │   ├── politique_securite_journalisation_audit.md
│   │   ├── procedure_gestion_changements.md
│   │   ├── registre_traitement_rgpd.md
│   │   └── tableau_kpis_soc.md
│   └── guides/
│       ├── document_suivi_projet_v2.md
│       ├── gpo_deployment_guide.md
│       ├── guide_dimensionnement.md
│       ├── manuel_deploiement_administrateur.md
│       ├── rapport_stage_soc_wazuh.md
│       └── support_soutenance_projet_soc.md
├── scripts/
│   ├── linux/
│   │   └── wazuh-health-monitor.sh     # Monitoring du Manager (Syslog/Email)
│   ├── tests/
│   │   └── Simulate-Attacks.ps1
│   └── windows/
│       ├── Deploy-WazuhAgent.ps1       # Script GPO (idempotent, DPAPI, SHA256)
│       ├── Initialize-WazuhDeployCredential.ps1  # Chiffrement du jeton API (DPAPI)
│       └── Rotate-WazuhApiPassword.ps1 # Rotation du mot de passe API
├── soc-infrastructure/                 # Rôles et playbooks Ansible (Lab / Prod)
│   ├── ansible.cfg
│   ├── inventories/
│   │   ├── lab/
│   │   └── prod/
│   ├── playbooks/
│   │   ├── bootstrap.yml
│   │   ├── deploy_agent.yml
│   │   ├── deploy_agents_mass.yml
│   │   └── deploy_manager.yml
│   ├── requirements.yml
│   └── roles/
│       ├── wazuh-agent/
│       └── wazuh-manager/
└── docs/wazuh_architecture.jpg
```

---

## Composants principaux

### 1. Déploiement Windows durci (GPO & PowerShell)

Le script `Deploy-WazuhAgent.ps1` est conçu pour tourner en script de démarrage machine (contexte `NT AUTHORITY\SYSTEM`). Il intègre plusieurs mesures de sécurité conformes aux recommandations de l'ANSSI :

- **Chiffrement DPAPI :** le mot de passe API n'est pas stocké en clair. Il est pré-chiffré via `Initialize-WazuhDeployCredential.ps1` en contexte machine, de sorte que seul le compte `SYSTEM` local puisse le déchiffrer.
- **Vérification d'intégrité :** le script calcule l'empreinte SHA-256 du MSI et la compare à une empreinte de confiance avant de lancer l'installation.
- **Contrôle d'accès (ACL) :** les clés cryptographiques (`client.keys`) ont des permissions restreintes (seuls `SYSTEM` et `Administrators` y accèdent).
- **Idempotence :** le script détecte si l'agent est déjà présent et opérationnel, et s'arrête s'il n'y a rien à faire.

### 2. Supervision du Manager (Linux)

Le script `wazuh-health-monitor.sh` surveille l'état du Manager Wazuh. Il envoie des alertes (Syslog ou e-mail) si le service ou l'API tombe, ou si les certificats TLS approchent de leur expiration (alertes à 90, 30 et 7 jours).

### 3. Matrice de conformité et détection

Les documents dans `docs/audit/` cartographient l'infrastructure SOC par rapport aux exigences réglementaires et décrivent les scénarios de test : détection de création d'utilisateurs suspects, exécution de scripts PowerShell encodés, attaques par force brute sur Active Directory, etc.

---

## Guide de démarrage rapide

### 1. Installation des dépendances Ansible

Depuis la machine d'administration Linux :
```bash
cd soc-infrastructure
ansible-galaxy install -r requirements.yml
```

### 2. Déploiement du Manager

1. Créez un fichier `.vault_pass` contenant le mot de passe du coffre-fort Ansible à la racine du projet (le fichier est ignoré par Git).
2. Configurez vos cibles et variables dans `soc-infrastructure/inventories/lab/` (ou `prod/`).
3. Lancez le playbook :
```bash
# Pour le laboratoire
ansible-playbook -i inventories/lab/hosts.ini playbooks/deploy_manager.yml --vault-password-file ../.vault_pass
```

### 3. Préparation du déploiement Windows (GPO)

Pour mettre en place le déploiement automatisé sur le réseau AD :
1. Générez le secret d'enrôlement chiffré sur une machine de test en contexte `SYSTEM` (voir `docs/guides/gpo_deployment_guide.md`) avec `Initialize-WazuhDeployCredential.ps1`.
2. Déposez `Deploy-WazuhAgent.ps1` et le MSI sur votre partage réseau (ex : `NETLOGON`).
3. Configurez la GPO pour lancer le script au démarrage des ordinateurs.

---

## Qualité du code et audits

- **Linter Ansible :** le projet suit les standards définis par `ansible-lint`, configuré dans `soc-infrastructure/.ansible-lint`.
- **Conformité réglementaire :** mappage des contrôles du SOC sur le guide d'hygiène de l'ANSSI et les contrôles CIS v8, disponible dans `docs/audit/audit_conformite_referentiels.md`.