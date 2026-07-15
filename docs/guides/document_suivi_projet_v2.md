# Document de suivi de projet : infrastructure SOC hybride

**Périmètre technique :** Wazuh SIEM (WSL2 Debian) ↔ Windows 11 Host (Agent physique)
**Méthodologie :** DevSecOps, Infrastructure as Code (Ansible), Durcissement (CIS Benchmarks)

---

## Phase actuelle : architecture, interconnexion et durcissement

### Mise à jour : 19 mai 2026

**1. Objectifs de la période**

On s'est concentrés sur le cadrage architectural du projet, l'initialisation de l'environnement de développement local, et la mise en place de la chaîne de déploiement automatisée avec sécurisation des secrets.

**2. Réalisations techniques**

Côté architecture et versioning, on a créé le dépôt Git `soc-infrastructure` avec une arborescence modulaire suivant les standards Ansible. Un fichier `.ansible-lint` a été configuré pour appliquer les bonnes pratiques IaC, et le `.gitignore` interdit le commit de fichiers sensibles comme `.vault_pass`.

Pour la gestion des secrets, on a mis en œuvre Ansible Vault avec chiffrement AES-256 du fichier `vault.yml` — isolation stricte des données sensibles.

Le rôle `wazuh-agent` a été écrit (`main.yml`) pour automatiser le cycle de vie de l'agent.

**3. Arbitrages techniques**

On a refusé l'architecture Docker pour les agents après une analyse montrant l'incompatibilité d'un conteneur pour simuler un agent SOC (pas de Systemd). À la place, on a pivoté vers un staging WSL2 Debian ARM64 en modifiant `wsl.conf` pour activer Systemd en PID 1. On a aussi accepté une dette technique réseau temporaire : pas de cloisonnement par VLANs à cause des limites de routage WSL2.

---

### Mise à jour : 20 mai 2026

**1. Objectifs de la période**

Déployer et initialiser le Wazuh Manager via Ansible, résoudre les problèmes de routage réseau WSL2 ↔ hôte, et enrôler le premier agent Windows.

**2. Réalisations techniques**

Côté infrastructure, les services sont opérationnels (`wazuh-manager`, `wazuh-authd`, `wazuh-db`, `wazuh-analysisd`). L'API (port 55000) répond, le Dashboard est en statut Active.

Pour le routage, on a ouvert les flux via `netsh interface portproxy` sur les ports 1514 et 1515. La clé AES-256 a été générée manuellement via `agent-auth.exe`. Il a aussi fallu modifier `ossec.conf` du Manager pour écouter sur `0.0.0.0` au lieu de `127.0.0.1` — un problème de bind réseau qui bloquait la communication.

**3. Arbitrages techniques**

On a fait le choix de maintenir l'automatisation Ansible pour le backend WSL2, mais de déployer le MSI natif manuellement sur le poste Windows — Ansible sur un hôte Windows posait trop de problèmes de compatibilité. La configuration de l'agent a été verrouillée avec `<enrollment><enabled>no</enabled>` pour éviter les requêtes d'authentification parasites.

---

### Mise à jour : 21 mai 2026

**1. Objectifs de la période**

Résoudre la dette technique sur le pipeline Filebeat ↔ OpenSearch, déployer le module d'audit SCA face au benchmark CIS, et traiter les risques de stockage et de fatigue d'alerte.

**2. Réalisations techniques**

L'incident critique d'ingestion a été résolu en injectant `compatibility.override_main_response_version: true` dans OpenSearch. Résultat : plus de 380 événements correctement indexés dans `wazuh-alerts-*`.

On a réussi à faire fonctionner un cas de détection opérationnel : simulation d'une attaque de persistance (T1547.001) via l'injection de la clé `EvilCalc`, qui a levé une alerte de niveau 12.

Le scan CIS Windows 11 Enterprise initial a donné un score de 24%. Après un premier cycle de remédiation via PowerShell, on est montés à 25% — c'est peu, mais ça valide le pipeline de remédiation.

**3. Traitement des risques**

Risque de disponibilité : on a créé une politique ISM (`wazuh_retention_policy`) avec rétention glissante à 7 jours.
Risque opérationnel : filtrage à la source XPath (`EventID != 4624`) dans `agent.conf` pour réduire le bruit.

---

### Mise à jour : 23 juin 2026 (séance courante)

**1. Objectifs de la période**

Remplacer l'approche manuelle de déploiement par une solution automatisée compatible Active Directory (GPO), et sécuriser la gestion des identifiants API côté endpoint Windows.

**2. Réalisations techniques**

On a créé un script de déploiement GPO PowerShell avec automatisation complète : téléchargement centralisé du MSI, installation silencieuse, configuration post-déploiement. La vérification d'intégrité SHA-256 du binaire MSI est faite avant toute exécution. L'enrôlement passe maintenant par des appels REST authentifiés vers l'API du Manager (port 55000) au lieu de l'utilitaire `agent-auth.exe`, avec gestion des conflits et idempotence. Une boucle d'attente valide aussi la disponibilité du tunnel Tailscale/WireGuard avant de lancer les appels réseau.

Côté sécurité, les identifiants du compte `svc_enrollment` sont désormais chiffrés via DPAPI (scope `LocalMachine`). Plus de mots de passe en clair. Des ACLs NTFS restreignent l'accès au binaire chiffré à `SYSTEM` et aux administrateurs.

Pour la traçabilité, on a créé une source EventLog dédiée (`WazuhDeploy`) qui génère des événements locaux à chaque étape de l'installation, auditables directement depuis le SOC.

**3. Clôture des objectifs précédents**

L'objectif d'industrialisation de la remédiation est atteint. La documentation méthodologique détaille le paramétrage du « Computer Startup Script » GPO et propose une conceptualisation cible (Option 3 : API Proxy Kerberos) pour contourner les limites de DPAPI lors d'un déploiement massif.

---

### Prochaines étapes

1. **Durcissement avancé du endpoint :** poursuivre la réduction de la surface d'attaque pour améliorer le score SCA — en priorité, la politique de verrouillage de compte après échecs (règle CIS 26005 via `net accounts /lockoutthreshold:5`).
2. **Scénarios d'attaques complexes :** exécuter les scénarios prévus (brute force SSH, scan Nmap, élévation de privilèges) et développer de nouvelles règles de détection.
