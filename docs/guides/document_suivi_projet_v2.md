# DOCUMENT DE SUIVI DE PROJET : INFRASTRUCTURE SOC HYBRIDE

**Périmètre technique :** Wazuh SIEM (WSL2 Debian) ↔ Windows 11 Host (Agent physique)  
**Méthodologie :** DevSecOps, Infrastructure as Code (Ansible), Durcissement (CIS Benchmarks)

---

## Phase actuelle : Architecture, Interconnexion et Durcissement

### 📄 Mise à jour : 19 mai 2026

**1. Objectifs de la Période**
* Cadrage architectural du projet de centralisation et de supervision des logs.
* Initialisation de l'environnement de développement et de staging local.
* Mise en place de la chaîne de déploiement automatisée (IaC) et sécurisation des secrets.

**2. Réalisations Techniques & Jalons Validés**
* **Architecture & Versioning :**
  * Création du dépôt Git (soc-infrastructure) : Initialisation d'une arborescence modulaire respectant les standards industriels Ansible.
  * Configuration d'un fichier `.ansible-lint` pour appliquer de manière stricte les bonnes pratiques de développement IaC.
  * Rédaction d'un fichier `.gitignore` robuste interdisant le commit de fichiers volatils ou critiques (`.vault_pass`).
* **Gestion des Secrets (SecOps) :**
  * Mise en œuvre d'Ansible Vault : Isolation stricte des données sensibles. Chiffrement AES-256 du fichier `vault.yml`.
* **Développement des Rôles de Déploiement (IaC) :**
  * Écriture du rôle `wazuh-agent` : Création du fichier `main.yml` automatisant le cycle de vie de l'agent.

**3. Arbitrages Techniques & Gestion des Risques (Pivots)**
* **Refus de l'architecture Docker pour les agents :** Analyse technique démontrant l'incompatibilité majeure d'un conteneur pour simuler un agent SOC (absence de Systemd).
* **Pivot vers le Staging WSL2 (Systemd Enforced) :** Validation d'une infrastructure de staging sous WSL2 Debian ARM64, modification de `wsl.conf` pour activer Systemd en PID 1.
* **Acceptation de la dette technique réseau :** Sacrifice temporaire du cloisonnement réseau (VLANs) à cause des limites de routage WSL2.

---

### 📄 Mise à jour : 20 mai 2026

**1. Objectifs de la Période**
* Déploiement et initialisation du Wazuh Manager via la chaîne IaC Ansible.
* Résolution des problématiques de routage réseau entre l'hôte physique et WSL2.
* Enrôlement sécurisé du premier agent Windows.

**2. Réalisations Techniques & Jalons Validés**
* **Infrastructure & Automatisation Backend (WSL2) :**
  * Disponibilité des services (`wazuh-manager`, `wazuh-authd`, `wazuh-db`, `wazuh-analysisd`).
  * Validation de l'API (port 55000), Dashboard en statut Active.
* **Routage Réseau & NAT :**
  * Ouverture des flux via `netsh interface portproxy` pour les ports 1514 et 1515.
* **Gestion des Secrets & Sécurisation (SecOps) :**
  * Génération manuelle d'une clé AES-256 via `agent-auth.exe`.
* **Résolution du Bind Réseau :**
  * Modification de `ossec.conf` du Manager pour écouter sur `0.0.0.0` au lieu de `127.0.0.1`.

**3. Arbitrages Techniques & Gestion des Risques (Pivots)**
* **Rupture de protocole Ansible sur l'hôte Windows :** Maintien de l'automatisation stricte pour le backend (WSL2) et déploiement d'un MSI natif durci manuellement pour le poste de travail.
* **Verrouillage de la configuration de l'agent :** Forçage de `<enrollment><enabled>no</enabled>` pour contrer les requêtes d'authentification parasites.

---

### 📄 Mise à jour : 21 mai 2026

**1. Objectifs de la Période**
* Clôturer la dette technique sur le pipeline Filebeat ↔ OpenSearch.
* Déployer le module d'audit de conformité (SCA) face au benchmark CIS.
* Résoudre les risques de disponibilité (stockage) et de performance (fatigue d'alerte).

**2. Réalisations Techniques & Jalons Validés**
* **Résolution de l'Incident Critique d'Ingestion :**
  * Injection de `compatibility.override_main_response_version: true` dans OpenSearch.
  * Plus de 380 événements correctement indexés (`wazuh-alerts-*`).
* **Cas d'Usage de Détection Opérationnel :**
  * Simulation d'attaque ciblant la persistance (T1547.001) via l'injection de la clé `EvilCalc`, levant une alerte de niveau 12.
* **Audit et Durcissement (Gouvernance & GRC) :**
  * Scan initial CIS Windows 11 Enterprise (Score : 24%).
  * Cycle de remédiation tactique via PowerShell (Score amélioré à 25%).

**3. Traitement Proactif des Risques (Pivots)**
* **[RISQUE DISPONIBILITÉ] :** Création d'une politique ISM (`wazuh_retention_policy`) avec rétention glissante à 7 jours.
* **[RISQUE OPÉRATIONNEL] :** Filtrage à la source XPath (`EventID != 4624`) dans `agent.conf` pour réduire la fatigue d'alerte.

---

### 📄 Mise à jour : 23 juin 2026 (Séance Courante)

**1. Objectifs de la Période**
* Remplacer l'approche manuelle de déploiement de l'agent Windows par une solution industrielle, robuste et "Zero-Touch", compatible avec un environnement Active Directory (GPO).
* Sécuriser la gestion des identifiants API (Wazuh) côté endpoint (Windows) pour aligner le niveau d'exigence SecOps avec celui du backend.

**2. Réalisations Techniques & Jalons Validés**
* **Création d'un script de déploiement "Zero-Touch" GPO (PowerShell) :**
  * *Automatisation intégrale :* Téléchargement centralisé du MSI, installation silencieuse et configuration post-déploiement.
  * *Sécurité Supply Chain :* Vérification de l'intégrité du binaire MSI via comparaison de hash SHA-256 avant toute exécution.
  * *Enrôlement API dynamique :* Remplacement de l'utilitaire manuel `agent-auth.exe` par des appels REST authentifiés vers l'API du Manager (port 55000) pour générer, récupérer et injecter la clé de l'agent (gestion des conflits et idempotence).
  * *Tolérance aux pannes (Race Conditions) :* Implémentation d'une boucle d'attente active validant la disponibilité du tunnel d'overlay (Tailscale/WireGuard) avant l'exécution de la cinématique réseau.
* **Durcissement Cryptographique de l'Endpoint (SecOps) :**
  * Fin de l'exposition des mots de passe en clair. Les identifiants du compte de service API (`svc_enrollment`) sont chiffrés via la **Data Protection API (DPAPI)** de Windows (scope `LocalMachine`). 
  * Mise en place de règles de contrôle d'accès strictes (ACLs NTFS restreintes à `SYSTEM` et `Administrateurs`) sur le binaire chiffré généré.
* **Traçabilité et Monitoring (SIEM) :**
  * Création d'une source Windows EventLog dédiée (`WazuhDeploy`) générant des événements locaux pour chaque phase de l'installation, auditables directement depuis le SOC.

**3. Clôture des Objectifs Précédents**
* **[Résolu] Priorité Moyenne — GRC :** L'objectif d'*industrialisation de la remédiation* est atteint. La documentation méthodologique a été rédigée, détaillant le paramétrage du "Computer Startup Script" GPO et proposant une conceptualisation cible (Option 3 : API Proxy Kerberos) pour contourner les limites actuelles de DPAPI lors d'un déploiement massif industriel.

---

### Prochaines Étapes Immédiates (Sprint Suivant)

1. **[Priorité Haute — SecOps] Durcissement avancé du Endpoint :** Poursuivre la réduction de la surface d'attaque du poste de travail pour faire grimper le score SCA en appliquant la politique de verrouillage de compte après échecs successifs (Règle CIS 26005 via `net accounts /lockoutthreshold:5`).
2. **[Priorité Haute — SOC] Analyse de scénarios d'attaques complexes :** Exécuter les scénarios prévus (brute force SSH, scan Nmap, élévation de privilèges) et développer de nouvelles règles de détection affinées.
