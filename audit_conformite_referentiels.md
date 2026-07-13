# 🛡️ Audit de Conformité : Mapping Projet SOC ↔ Référentiels de Cybersécurité

**Projet :** Infrastructure SOC – SIEM Wazuh  
**Date :** 26 juin 2026  
**Objectif :** Démontrer que chaque action technique réalisée dans ce projet s'appuie sur des standards internationaux reconnus.

---

## Référentiels utilisés

| Sigle | Nom complet | Émetteur | Portée |
|-------|-------------|----------|--------|
| **ANSSI** | Guide d'Hygiène Informatique (42 mesures) | Agence Nationale de la Sécurité des Systèmes d'Information (France) | Référentiel national obligatoire pour les OIV, recommandé pour tous |
| **NIST CSF** | Cybersecurity Framework v2.0 | National Institute of Standards and Technology (USA) | Standard international de gestion des risques cyber |
| **NIST SP 800-53** | Security and Privacy Controls | NIST (USA) | Catalogue de contrôles de sécurité |
| **ISO 27001** | Système de Management de la Sécurité de l'Information (SMSI) | ISO/IEC | Norme certifiable internationale |
| **CIS** | Center for Internet Security Benchmarks | CIS (USA) | Guides de durcissement technique par OS/application |
| **MITRE ATT&CK** | Adversarial Tactics, Techniques & Common Knowledge | MITRE Corporation | Référentiel de techniques d'attaque |
| **RGPD** | Règlement Général sur la Protection des Données | Union Européenne | Protection des données personnelles |

---

## 1. Déploiement du SIEM (Collecte centralisée des logs)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Installation d'un SIEM Wazuh centralisé | **ANSSI** | Mesure 33 – *Mettre en place une journalisation centralisée* | L'ANSSI exige la centralisation des logs pour permettre la détection d'incidents et l'investigation post-mortem. |
| | **NIST CSF** | DE.CM-1 – *Monitor networks and systems* | La fonction "Detect" du NIST CSF repose sur une supervision continue. |
| | **ISO 27001** | A.8.15 – *Logging* | Les journaux d'événements doivent être produits, conservés et régulièrement analysés. |
| | **NIST SP 800-53** | AU-6 – *Audit Record Review, Analysis, and Reporting* | Les enregistrements d'audit doivent être examinés et analysés. |

---

## 2. Chiffrement des secrets (DPAPI)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Chiffrement du mot de passe API via DPAPI (AES-256) | **ANSSI** | Mesure 16 – *Protéger les mots de passe stockés sur les systèmes* | Interdiction formelle de stocker des mots de passe en clair. |
| | **NIST SP 800-53** | IA-5(7) – *Authenticator Management: No Embedded Unencrypted Static Authenticators* | Les authentifiants ne doivent jamais être embarqués en clair dans les scripts. |
| | **ISO 27001** | A.8.24 – *Use of cryptography* | Les informations sensibles doivent être protégées par des mécanismes cryptographiques. |
| Utilisation d'Ansible Vault (AES-256) côté serveur | **ANSSI** | Mesure 16 | Même principe appliqué côté backend Linux. |

---

## 3. Compte de service à moindre privilège (svc_enrollment)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Création d'un compte dédié `svc_enrollment` sans droits admin | **ANSSI** | Mesure 3 – *Attribuer les bons droits sur les ressources sensibles du SI* | Principe du moindre privilège : le compte ne peut qu'enrôler des agents, pas administrer le Manager. |
| | **NIST SP 800-53** | AC-6 – *Least Privilege* | Les utilisateurs et processus ne doivent disposer que des privilèges strictement nécessaires. |
| | **ISO 27001** | A.8.2 – *Privileged access rights* | Les droits d'accès privilégiés doivent être restreints et contrôlés. |
| | **CIS Controls v8** | Contrôle 6.8 – *Define and Maintain Role-Based Access Control* | Séparer les rôles (admin vs. service d'enrôlement). |

---

## 4. Vérification d'intégrité du MSI (SHA-256)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Calcul et comparaison du hash SHA-256 du MSI avant installation | **ANSSI** | Mesure 26 – *Contrôler la conformité des logiciels déployés* | Tout logiciel déployé doit être vérifié pour détecter une altération (attaque supply chain). |
| | **NIST SP 800-53** | SI-7 – *Software, Firmware, and Information Integrity* | L'intégrité des logiciels doit être vérifiée par des mécanismes cryptographiques. |
| | **MITRE ATT&CK** | T1195 – *Supply Chain Compromise* | Notre vérification de hash protège contre cette technique d'attaque. |
| | **CIS Controls v8** | Contrôle 2.5 – *Allowlist Authorized Software* | Seuls les logiciels autorisés et vérifiés doivent être installés. |

---

## 5. Durcissement du poste (verrouillage de compte / CIS Benchmark)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| `net accounts /lockoutthreshold:5` (verrouillage après 5 échecs) | **CIS Benchmark** | Règle 1.2.2 – *Ensure 'Account lockout threshold' ≤ 5* | Recommandation CIS officielle pour Windows 11 Enterprise. |
| | **ANSSI** | Mesure 10 – *Définir et appliquer une politique de mots de passe* | L'ANSSI recommande un seuil de verrouillage entre 3 et 5 tentatives. |
| | **NIST SP 800-53** | AC-7 – *Unsuccessful Logon Attempts* | Le système doit appliquer un verrouillage après un nombre défini d'échecs. |
| Scan SCA (Security Configuration Assessment) | **ISO 27001** | A.8.8 – *Management of technical vulnerabilities* | L'audit continu de la configuration est requis pour identifier les écarts. |

---

## 6. Déploiement automatisé via GPO (Zero-Touch)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Script PowerShell exécuté en contexte `SYSTEM` via GPO Computer Startup | **ANSSI** | Mesure 34 – *Assurer la sécurité de l'administration du SI* | L'administration doit être centralisée et automatisée pour réduire les erreurs humaines. |
| | **NIST SP 800-53** | CM-2 – *Baseline Configuration* | Les systèmes doivent être déployés depuis une configuration de référence documentée. |
| | **CIS Controls v8** | Contrôle 4.1 – *Establish and Maintain a Secure Configuration Process* | Processus automatisé de configuration sécurisée. |
| Idempotence du script (ne réinstalle pas si déjà présent) | **NIST SP 800-53** | CM-3 – *Configuration Change Control* | Les changements de configuration doivent être contrôlés et tracés. |

---

## 7. Journalisation locale (EventLog WazuhDeploy)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Création d'une source EventLog dédiée `WazuhDeploy` traçant chaque phase du déploiement | **ANSSI** | Mesure 33 – *Mettre en place une journalisation* | Chaque action critique doit générer un log exploitable. |
| | **NIST SP 800-53** | AU-2 – *Event Logging* | Les événements liés à la sécurité doivent être consignés. |
| | **ISO 27001** | A.8.15 – *Logging* | Les journaux doivent inclure les activités des administrateurs et des systèmes. |

---

## 8. Règles de détection personnalisées

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Règle 5601 – Détection PowerShell suspect | **MITRE ATT&CK** | T1059.001 – *Command and Scripting Interpreter: PowerShell* | Technique d'exécution la plus courante sur Windows. |
| Règle 5802 – Modification du registre | **MITRE ATT&CK** | T1112 – *Modify Registry* | Technique de persistance et d'évasion. |
| Règle 5901 – Création de service | **MITRE ATT&CK** | T1543.003 – *Create or Modify System Process: Windows Service* | Technique de persistance courante des malwares. |
| Règle 5700 – Verrouillage de compte | **MITRE ATT&CK** | T1110 – *Brute Force* | Détection d'attaques par force brute. |
| | **NIST CSF** | DE.AE-2 – *Analyze detected events for attack patterns* | Les événements détectés doivent être analysés pour identifier des schémas d'attaque. |

---

## 9. Playbooks d'attaques contrôlées (Red Team)

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Exécution de scénarios d'attaque documentés (Nmap, Hydra, PowerShell) | **ANSSI** | Mesure 40 – *Réaliser des exercices de gestion de crise* | Les tests de détection permettent de valider l'efficacité du SOC. |
| | **NIST CSF** | PR.IP-10 – *Response and recovery plans are tested* | Les capacités de détection doivent être testées régulièrement. |
| | **ISO 27001** | A.5.35 – *Independent review of information security* | La sécurité doit faire l'objet de revues indépendantes (dont les tests d'intrusion). |
| Mapping des techniques dans une matrice de détection | **MITRE ATT&CK** | Framework complet | Standard de l'industrie pour documenter la couverture de détection. |

---

## 10. Sauvegarde et continuité

| Ce qu'on a fait | Référentiel | Contrôle précis | Justification |
|----------------|-------------|-----------------|---------------|
| Script de backup cron quotidien (Ansible) | **ANSSI** | Mesure 37 – *Mettre en place des sauvegardes régulières* | Les sauvegardes doivent être automatisées et testées. |
| | **NIST SP 800-53** | CP-9 – *Information System Backup* | Les backups doivent être planifiés, exécutés et vérifiés. |
| | **ISO 27001** | A.8.13 – *Information backup* | Des copies de sauvegarde doivent être réalisées et testées régulièrement. |
| Demande de snapshots Proxmox aux admins ProxFibre | **ISO 27001** | A.8.14 – *Redundancy of information processing facilities* | Redondance des données pour assurer la continuité de service. |

---

## 11. Protection des données personnelles (RGPD)

| Ce qu'on a fait | Référentiel | Article | Justification |
|----------------|-------------|---------|---------------|
| Collecte limitée aux logs de sécurité Windows (pas de données utilisateur) | **RGPD** | Art. 5.1.c – *Minimisation des données* | Seules les données nécessaires à la finalité (sécurité) sont collectées. |
| Rétention limitée à 30 jours (configurable) | **RGPD** | Art. 5.1.e – *Limitation de la conservation* | Les données ne sont pas conservées au-delà de ce qui est nécessaire. |
| Chiffrement des flux (TLS/Tailscale WireGuard) | **RGPD** | Art. 32 – *Sécurité du traitement* | Les données en transit doivent être protégées par des mesures techniques appropriées. |
| Contrôle d'accès au Dashboard (RBAC Wazuh) | **RGPD** | Art. 32 – *Sécurité du traitement* | L'accès aux données doit être restreint aux personnes habilitées. |

---

## Synthèse de couverture

| Référentiel | Contrôles couverts | Couverture estimée |
|-------------|-------------------|--------------------|
| **ANSSI (42 mesures)** | 8 mesures directement adressées | ~19% (excellent pour un projet de stage) |
| **NIST CSF** | Fonctions Identify, Protect, Detect couvertes | 3/5 fonctions |
| **NIST SP 800-53** | 11 contrôles adressés | Sélection pertinente |
| **ISO 27001 (Annexe A)** | 9 contrôles adressés | Sélection pertinente |
| **CIS Controls v8** | 4 contrôles adressés | Focus endpoint |
| **MITRE ATT&CK** | 6 techniques couvertes par les règles de détection | Base solide |
| **RGPD** | 3 articles adressés | Conformité de base |

---

> **Conclusion pour la soutenance :** Ce projet ne se contente pas de "faire fonctionner un outil". Chaque décision technique (du chiffrement DPAPI au verrouillage de compte en passant par le hash SHA-256 du MSI) est **justifiable par au moins deux référentiels internationaux de cybersécurité**. C'est cette approche "GRC-first" (Gouvernance, Risques, Conformité) qui distingue un ingénieur cybersécurité d'un simple administrateur système.
