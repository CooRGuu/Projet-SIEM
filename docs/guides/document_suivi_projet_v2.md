# DOCUMENT DE SUIVI DE PROJET : INFRASTRUCTURE SOC HYBRIDE

**PÃ©rimÃ¨tre technique :** Wazuh SIEM (WSL2 Debian) â†” Windows 11 Host (Agent physique)  
**MÃ©thodologie :** DevSecOps, Infrastructure as Code (Ansible), Durcissement (CIS Benchmarks)

---

## Phase actuelle : Architecture, Interconnexion et Durcissement

### ðŸ“„ Mise Ã  jour : 19 mai 2026

**1. Objectifs de la PÃ©riode**
* Cadrage architectural du projet de centralisation et de supervision des logs.
* Initialisation de l'environnement de dÃ©veloppement et de staging local.
* Mise en place de la chaÃ®ne de dÃ©ploiement automatisÃ©e (IaC) et sÃ©curisation des secrets.

**2. RÃ©alisations Techniques & Jalons ValidÃ©s**
* **Architecture & Versioning :**
  * CrÃ©ation du dÃ©pÃ´t Git (soc-infrastructure) : Initialisation d'une arborescence modulaire respectant les standards industriels Ansible.
  * Configuration d'un fichier `.ansible-lint` pour appliquer de maniÃ¨re stricte les bonnes pratiques de dÃ©veloppement IaC.
  * RÃ©daction d'un fichier `.gitignore` robuste interdisant le commit de fichiers volatils ou critiques (`.vault_pass`).
* **Gestion des Secrets (SecOps) :**
  * Mise en Å“uvre d'Ansible Vault : Isolation stricte des donnÃ©es sensibles. Chiffrement AES-256 du fichier `vault.yml`.
* **DÃ©veloppement des RÃ´les de DÃ©ploiement (IaC) :**
  * Ã‰criture du rÃ´le `wazuh-agent` : CrÃ©ation du fichier `main.yml` automatisant le cycle de vie de l'agent.

**3. Arbitrages Techniques & Gestion des Risques (Pivots)**
* **Refus de l'architecture Docker pour les agents :** Analyse technique dÃ©montrant l'incompatibilitÃ© majeure d'un conteneur pour simuler un agent SOC (absence de Systemd).
* **Pivot vers le Staging WSL2 (Systemd Enforced) :** Validation d'une infrastructure de staging sous WSL2 Debian ARM64, modification de `wsl.conf` pour activer Systemd en PID 1.
* **Acceptation de la dette technique rÃ©seau :** Sacrifice temporaire du cloisonnement rÃ©seau (VLANs) Ã  cause des limites de routage WSL2.

---

### ðŸ“„ Mise Ã  jour : 20 mai 2026

**1. Objectifs de la PÃ©riode**
* DÃ©ploiement et initialisation du Wazuh Manager via la chaÃ®ne IaC Ansible.
* RÃ©solution des problÃ©matiques de routage rÃ©seau entre l'hÃ´te physique et WSL2.
* EnrÃ´lement sÃ©curisÃ© du premier agent Windows.

**2. RÃ©alisations Techniques & Jalons ValidÃ©s**
* **Infrastructure & Automatisation Backend (WSL2) :**
  * DisponibilitÃ© des services (`wazuh-manager`, `wazuh-authd`, `wazuh-db`, `wazuh-analysisd`).
  * Validation de l'API (port 55000), Dashboard en statut Active.
* **Routage RÃ©seau & NAT :**
  * Ouverture des flux via `netsh interface portproxy` pour les ports 1514 et 1515.
* **Gestion des Secrets & SÃ©curisation (SecOps) :**
  * GÃ©nÃ©ration manuelle d'une clÃ© AES-256 via `agent-auth.exe`.
* **RÃ©solution du Bind RÃ©seau :**
  * Modification de `ossec.conf` du Manager pour Ã©couter sur `0.0.0.0` au lieu de `127.0.0.1`.

**3. Arbitrages Techniques & Gestion des Risques (Pivots)**
* **Rupture de protocole Ansible sur l'hÃ´te Windows :** Maintien de l'automatisation stricte pour le backend (WSL2) et dÃ©ploiement d'un MSI natif durci manuellement pour le poste de travail.
* **Verrouillage de la configuration de l'agent :** ForÃ§age de `<enrollment><enabled>no</enabled>` pour contrer les requÃªtes d'authentification parasites.

---

### ðŸ“„ Mise Ã  jour : 21 mai 2026

**1. Objectifs de la PÃ©riode**
* ClÃ´turer la dette technique sur le pipeline Filebeat â†” OpenSearch.
* DÃ©ployer le module d'audit de conformitÃ© (SCA) face au benchmark CIS.
* RÃ©soudre les risques de disponibilitÃ© (stockage) et de performance (fatigue d'alerte).

**2. RÃ©alisations Techniques & Jalons ValidÃ©s**
* **RÃ©solution de l'Incident Critique d'Ingestion :**
  * Injection de `compatibility.override_main_response_version: true` dans OpenSearch.
  * Plus de 380 Ã©vÃ©nements correctement indexÃ©s (`wazuh-alerts-*`).
* **Cas d'Usage de DÃ©tection OpÃ©rationnel :**
  * Simulation d'attaque ciblant la persistance (T1547.001) via l'injection de la clÃ© `EvilCalc`, levant une alerte de niveau 12.
* **Audit et Durcissement (Gouvernance & GRC) :**
  * Scan initial CIS Windows 11 Enterprise (Score : 24%).
  * Cycle de remÃ©diation tactique via PowerShell (Score amÃ©liorÃ© Ã  25%).

**3. Traitement Proactif des Risques (Pivots)**
* **[RISQUE DISPONIBILITÃ‰] :** CrÃ©ation d'une politique ISM (`wazuh_retention_policy`) avec rÃ©tention glissante Ã  7 jours.
* **[RISQUE OPÃ‰RATIONNEL] :** Filtrage Ã  la source XPath (`EventID != 4624`) dans `agent.conf` pour rÃ©duire la fatigue d'alerte.

---

### ðŸ“„ Mise Ã  jour : 23 juin 2026 (SÃ©ance Courante)

**1. Objectifs de la PÃ©riode**
* Remplacer l'approche manuelle de dÃ©ploiement de l'agent Windows par une solution industrielle, robuste et "Zero-Touch", compatible avec un environnement Active Directory (GPO).
* SÃ©curiser la gestion des identifiants API (Wazuh) cÃ´tÃ© endpoint (Windows) pour aligner le niveau d'exigence SecOps avec celui du backend.

**2. RÃ©alisations Techniques & Jalons ValidÃ©s**
* **CrÃ©ation d'un script de dÃ©ploiement "Zero-Touch" GPO (PowerShell) :**
  * *Automatisation intÃ©grale :* TÃ©lÃ©chargement centralisÃ© du MSI, installation silencieuse et configuration post-dÃ©ploiement.
  * *SÃ©curitÃ© Supply Chain :* VÃ©rification de l'intÃ©gritÃ© du binaire MSI via comparaison de hash SHA-256 avant toute exÃ©cution.
  * *EnrÃ´lement API dynamique :* Remplacement de l'utilitaire manuel `agent-auth.exe` par des appels REST authentifiÃ©s vers l'API du Manager (port 55000) pour gÃ©nÃ©rer, rÃ©cupÃ©rer et injecter la clÃ© de l'agent (gestion des conflits et idempotence).
  * *TolÃ©rance aux pannes (Race Conditions) :* ImplÃ©mentation d'une boucle d'attente active validant la disponibilitÃ© du tunnel d'overlay (Tailscale/WireGuard) avant l'exÃ©cution de la cinÃ©matique rÃ©seau.
* **Durcissement Cryptographique de l'Endpoint (SecOps) :**
  * Fin de l'exposition des mots de passe en clair. Les identifiants du compte de service API (`svc_enrollment`) sont chiffrÃ©s via la **Data Protection API (DPAPI)** de Windows (scope `LocalMachine`). 
  * Mise en place de rÃ¨gles de contrÃ´le d'accÃ¨s strictes (ACLs NTFS restreintes Ã  `SYSTEM` et `Administrateurs`) sur le binaire chiffrÃ© gÃ©nÃ©rÃ©.
* **TraÃ§abilitÃ© et Monitoring (SIEM) :**
  * CrÃ©ation d'une source Windows EventLog dÃ©diÃ©e (`WazuhDeploy`) gÃ©nÃ©rant des Ã©vÃ©nements locaux pour chaque phase de l'installation, auditables directement depuis le SOC.

**3. ClÃ´ture des Objectifs PrÃ©cÃ©dents**
* **[RÃ©solu] PrioritÃ© Moyenne â€” GRC :** L'objectif d'*industrialisation de la remÃ©diation* est atteint. La documentation mÃ©thodologique a Ã©tÃ© rÃ©digÃ©e, dÃ©taillant le paramÃ©trage du "Computer Startup Script" GPO et proposant une conceptualisation cible (Option 3 : API Proxy Kerberos) pour contourner les limites actuelles de DPAPI lors d'un dÃ©ploiement massif industriel.

---

### Prochaines Ã‰tapes ImmÃ©diates (Sprint Suivant)

1. **[PrioritÃ© Haute â€” SecOps] Durcissement avancÃ© du Endpoint :** Poursuivre la rÃ©duction de la surface d'attaque du poste de travail pour faire grimper le score SCA en appliquant la politique de verrouillage de compte aprÃ¨s Ã©checs successifs (RÃ¨gle CIS 26005 via `net accounts /lockoutthreshold:5`).
2. **[PrioritÃ© Haute â€” SOC] Analyse de scÃ©narios d'attaques complexes :** ExÃ©cuter les scÃ©narios prÃ©vus (brute force SSH, scan Nmap, Ã©lÃ©vation de privilÃ¨ges) et dÃ©velopper de nouvelles rÃ¨gles de dÃ©tection affinÃ©es.

