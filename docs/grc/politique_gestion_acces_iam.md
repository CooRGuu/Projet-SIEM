# Politique de Gestion des Accès et des Identités (IAM)

**Projet** : SOC Scolaire — Déploiement Wazuh  
**Version** : 1.0  
**Date** : 29/06/2026  
**Classification** : Diffusion restreinte  
**Auteur** : `<NOM_AUTEUR>`  
**Établissement** : `<NOM_ETABLISSEMENT>`  

---

## Table des matières

1. [Objet et champ d'application](#1-objet-et-champ-dapplication)
2. [Principes directeurs](#2-principes-directeurs)
3. [Rôles et responsabilités organisationnels](#3-rôles-et-responsabilités-organisationnels)
4. [Matrice des rôles et permissions](#4-matrice-des-rôles-et-permissions)
5. [Cycle de vie des comptes](#5-cycle-de-vie-des-comptes)
6. [Politique d'authentification](#6-politique-dauthentification)
7. [Gestion des comptes de service](#7-gestion-des-comptes-de-service)
8. [Revue périodique des accès](#8-revue-périodique-des-accès)
9. [Traçabilité et audit des accès](#9-traçabilité-et-audit-des-accès)
10. [Gestion des accès privilégiés (PAM)](#10-gestion-des-accès-privilégiés-pam)
11. [Non-conformités et sanctions](#11-non-conformités-et-sanctions)
12. [Annexes](#12-annexes)

---

## 1. Objet et champ d'application

### 1.1 Objet

La présente politique définit les règles de gestion des identités et des accès (IAM — *Identity and Access Management*) applicables à l'infrastructure SOC scolaire basée sur Wazuh. Elle vise à garantir que :

- Chaque accès au système d'information est **identifié**, **authentifié** et **autorisé**
- Le principe du **moindre privilège** est appliqué systématiquement
- Les accès sont **traçables** et **auditables**
- La conformité **RGPD** est assurée pour les données personnelles

### 1.2 Champ d'application

Cette politique s'applique à l'ensemble des composants du SOC scolaire :

| Périmètre | Composants couverts |
|---|---|
| **Infrastructure SOC** | Wazuh Manager, Wazuh Indexer, Wazuh Dashboard |
| **Infrastructure système** | Serveur Proxmox, Active Directory |
| **Réseau** | Tunnel Tailscale, réseau LAN scolaire |
| **Automatisation** | Scripts PowerShell (GPO), API Wazuh |
| **Personnes concernées** | Administrateurs, analystes, personnel, prestataires |

### 1.3 Documents de référence

| Document | Référence |
|---|---|
| Analyse de risques EBIOS RM | `analyse_risques_ebios_rm.md` |
| Plan de continuité et de reprise | `plan_continuite_reprise_activite.md` |
| RGPD — Règlement (UE) 2016/679 | Articles 5, 25, 32 |
| Guide ANSSI — Recommandations pour l'administration sécurisée des SI | ANSSI-PA-022 |
| Norme ISO 27001:2022 | Annexe A — Contrôles A.5.15 à A.5.18, A.8.2 à A.8.5 |

---

## 2. Principes directeurs

### 2.1 Principe du moindre privilège (*Least Privilege*)

Chaque utilisateur, administrateur ou compte de service ne dispose que des **droits strictement nécessaires** à l'exécution de ses fonctions. Tout privilège supplémentaire doit faire l'objet d'une demande justifiée et approuvée.

### 2.2 Séparation des tâches (*Separation of Duties*)

Les rôles critiques sont séparés pour éviter qu'une seule personne ne puisse compromettre l'ensemble du système :

| Incompatibilité | Justification |
|---|---|
| Administrateur SOC ≠ DPO | L'administrateur technique ne peut pas s'auto-auditer sur la conformité RGPD |
| Créateur de compte ≠ Validateur | La création de comptes nécessite une validation par un responsable distinct |
| Opérateur de sauvegarde ≠ Opérateur de restauration | Prévention de la suppression intentionnelle de données |

### 2.3 Besoin d'en connaître (*Need to Know*)

L'accès aux données (alertes de sécurité, journaux, données personnelles) est restreint aux seules personnes ayant un besoin opérationnel justifié.

### 2.4 Défense en profondeur

L'authentification et l'autorisation reposent sur **plusieurs couches de contrôle** :

```
┌─────────────────────────────────────────────────┐
│  Couche 1 — Authentification Active Directory    │
│  (Kerberos, politique de mots de passe)         │
├─────────────────────────────────────────────────┤
│  Couche 2 — Authentification Tailscale (MFA)     │
│  (Accès réseau overlay, ACL par nœud)           │
├─────────────────────────────────────────────────┤
│  Couche 3 — Authentification applicative         │
│  (Wazuh API, Dashboard, Proxmox)                │
├─────────────────────────────────────────────────┤
│  Couche 4 — Autorisation RBAC                    │
│  (Rôles Wazuh, groupes AD, ACL Tailscale)       │
├─────────────────────────────────────────────────┤
│  Couche 5 — Traçabilité et audit                 │
│  (Journaux Wazuh, logs AD, logs Tailscale)      │
└─────────────────────────────────────────────────┘
```

---

## 3. Rôles et responsabilités organisationnels

### 3.1 Matrice RACI — Gestion des accès

| Activité | SOC Admin | Analyste SOC | DSI | DPO | Direction |
|---|---|---|---|---|---|
| Création de comptes utilisateurs | **R** | — | **A** | **I** | — |
| Attribution des rôles applicatifs | **R** | — | **A** | **C** | — |
| Revue périodique des accès | **R** | **C** | **A** | **R** | **I** |
| Gestion des comptes de service | **R** | — | **A** | **I** | — |
| Gestion des accès privilégiés | **R** | — | **A** | **C** | **I** |
| Audit de conformité des accès | **C** | — | **C** | **R** | **A** |
| Révocation des accès (départ) | **R** | — | **A** | **I** | **I** |

*R = Responsable, A = Approbateur, C = Consulté, I = Informé*

### 3.2 Descriptions des rôles

| Rôle | Description | Nombre max. |
|---|---|---|
| **SOC Admin** | Administration complète de l'infrastructure SOC (Wazuh, Proxmox, AD, Tailscale) | 2 |
| **Analyste SOC** | Analyse des alertes, investigation des incidents, pas de modification de configuration | 3 |
| **Lecteur SOC** | Consultation en lecture seule des tableaux de bord et des alertes | 5 |
| **DPO** | Accès aux rapports de conformité et aux journaux d'accès aux données personnelles | 1 |
| **Prestataire externe** | Accès temporaire et limité pour maintenance ou support | Selon besoin |

---

## 4. Matrice des rôles et permissions

### 4.1 Permissions Wazuh Dashboard / API

| Permission | SOC Admin | Analyste SOC | Lecteur SOC | DPO | Prestataire |
|---|---|---|---|---|---|
| Consulter les alertes | ✅ | ✅ | ✅ | ✅ (anonymisées) | ❌ |
| Consulter les tableaux de bord | ✅ | ✅ | ✅ | ✅ | ❌ |
| Créer des visualisations personnalisées | ✅ | ✅ | ❌ | ❌ | ❌ |
| Modifier les règles de détection | ✅ | ❌ | ❌ | ❌ | ❌ |
| Modifier les décodeurs | ✅ | ❌ | ❌ | ❌ | ❌ |
| Gérer les agents (ajout, suppression, groupes) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Accéder à l'API Wazuh (`/security/*`) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Accéder à l'API Wazuh (`/agents/*` — lecture) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Exporter des rapports | ✅ | ✅ | ✅ | ✅ | ❌ |
| Gérer les utilisateurs Wazuh | ✅ | ❌ | ❌ | ❌ | ❌ |

### 4.2 Permissions Active Directory

| Permission | SOC Admin | Analyste SOC | Lecteur SOC | DPO | Prestataire |
|---|---|---|---|---|---|
| Gestion des GPO de déploiement Wazuh | ✅ | ❌ | ❌ | ❌ | ❌ |
| Consultation des propriétés des objets AD | ✅ | ✅ (lecture seule) | ❌ | ❌ | ❌ |
| Création / suppression de comptes | ✅ | ❌ | ❌ | ❌ | ❌ |
| Gestion des groupes de sécurité SOC | ✅ | ❌ | ❌ | ❌ | ❌ |
| Accès au contrôleur de domaine (RDP/SSH) | ✅ | ❌ | ❌ | ❌ | ❌ |

### 4.3 Permissions Proxmox

| Permission | SOC Admin | Analyste SOC | Lecteur SOC | DPO | Prestataire |
|---|---|---|---|---|---|
| Accès à l'interface web Proxmox | ✅ | ❌ | ❌ | ❌ | ⚠️ Temporaire |
| Gestion des VM (création, suppression, snapshot) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Console VM (accès au terminal des VM) | ✅ | ❌ | ❌ | ❌ | ⚠️ Temporaire |
| Gestion du stockage et des sauvegardes | ✅ | ❌ | ❌ | ❌ | ❌ |
| Configuration réseau | ✅ | ❌ | ❌ | ❌ | ❌ |

### 4.4 Permissions Tailscale

| Permission | SOC Admin | Analyste SOC | Lecteur SOC | DPO | Prestataire |
|---|---|---|---|---|---|
| Administration du réseau Tailscale (ACL, nœuds) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Accès au réseau Tailscale (nœud autorisé) | ✅ | ✅ | ❌ | ❌ | ⚠️ Temporaire |
| Consultation des logs Tailscale | ✅ | ✅ | ❌ | ❌ | ❌ |
| Modification des ACL | ✅ | ❌ | ❌ | ❌ | ❌ |

### 4.5 Mapping des groupes Active Directory

| Groupe AD | Rôle SOC | Membres type |
|---|---|---|
| `GG_SOC_Admins` | SOC Admin | `<ADMIN_SOC_1>`, `<ADMIN_SOC_2>` |
| `GG_SOC_Analystes` | Analyste SOC | `<ANALYSTE_1>`, `<ANALYSTE_2>` |
| `GG_SOC_Lecteurs` | Lecteur SOC | `<LECTEUR_1>`, personnel encadrant |
| `GG_SOC_DPO` | DPO | `<DPO>` |
| `GG_SOC_Prestataires` | Prestataire externe | Comptes temporaires |

---

## 5. Cycle de vie des comptes

### 5.1 Processus de création de compte

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  1. Demande  │───→│ 2. Validation│───→│ 3. Création  │───→│ 4. Activation│
│  (Formulaire)│    │    (DSI)     │    │  (SOC Admin) │    │   (Remise)   │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

| Étape | Description | Responsable | Délai |
|---|---|---|---|
| **1. Demande** | Soumission du formulaire de demande d'accès (identité, rôle demandé, justification) | Demandeur + Manager | — |
| **2. Validation** | Vérification de la légitimité de la demande et du rôle | DSI / Référent numérique | 2 jours ouvrés max. |
| **3. Création** | Création du compte AD, ajout aux groupes de sécurité, configuration Wazuh | SOC Admin | 1 jour ouvré |
| **4. Activation** | Remise sécurisée des identifiants (mot de passe temporaire, MFA) | SOC Admin | 1 jour ouvré |
| **5. Confirmation** | Vérification que l'utilisateur peut accéder aux ressources nécessaires | Utilisateur + SOC Admin | 1 jour ouvré |

### 5.2 Modification des droits

| Déclencheur | Action | Processus |
|---|---|---|
| Changement de fonction | Ajustement des groupes AD et rôles Wazuh | Nouvelle demande d'accès + validation DSI |
| Besoin temporaire d'accès élevé | Accès privilégié temporaire avec date d'expiration | Demande justifiée + approbation DSI + alerte automatique à expiration |
| Ajout d'un nouveau composant | Extension des droits si nécessaire | Revue du rôle + validation |

### 5.3 Révocation des accès

| Déclencheur | Délai de révocation | Actions |
|---|---|---|
| **Départ définitif** (fin de contrat, mutation) | **Immédiat** (jour du départ) | Désactivation du compte AD, suppression du nœud Tailscale, révocation des tokens API |
| **Fin de mission prestataire** | **Immédiat** (fin de mission) | Suppression du compte, révocation des accès temporaires |
| **Absence longue durée** (> 30 jours) | Dans les 48h | Désactivation du compte (maintien en lecture pour retour) |
| **Incident de sécurité** | **Immédiat** | Verrouillage du compte, changement des mots de passe, investigation |
| **Non-utilisation** (> 90 jours) | Automatique | Désactivation automatique, notification au responsable |

### 5.4 Checklist de départ

- [ ] Désactiver le compte Active Directory
- [ ] Retirer l'utilisateur de tous les groupes de sécurité SOC (`GG_SOC_*`)
- [ ] Supprimer l'utilisateur du réseau Tailscale
- [ ] Révoquer les tokens API Wazuh associés
- [ ] Révoquer l'accès Proxmox
- [ ] Récupérer les équipements (laptop, tokens MFA physiques)
- [ ] Changer les mots de passe des comptes partagés auxquels l'utilisateur avait accès
- [ ] Documenter la révocation dans le registre des accès
- [ ] Informer le DPO si l'utilisateur avait accès à des données personnelles

---

## 6. Politique d'authentification

### 6.1 Politique de mots de passe Active Directory

| Paramètre | Valeur | Justification |
|---|---|---|
| **Longueur minimale** | 12 caractères | Recommandation ANSSI |
| **Complexité** | Majuscule + minuscule + chiffre + caractère spécial | Résistance au brute-force |
| **Durée de vie maximale** | 90 jours | Rotation régulière |
| **Historique** | 12 derniers mots de passe | Empêcher la réutilisation |
| **Verrouillage après échecs** | 5 tentatives en 15 minutes → verrouillage 30 minutes | Protection contre le brute-force |
| **Mots de passe interdits** | Liste de mots de passe courants + nom de l'établissement | Prévention des mots de passe faibles |

### 6.2 Authentification multi-facteurs (MFA)

| Composant | MFA requis | Type de MFA | Condition |
|---|---|---|---|
| **Tailscale** | ✅ Obligatoire | TOTP (application d'authentification) ou clé de sécurité FIDO2 | Pour tous les nœuds admin |
| **Proxmox** | ✅ Obligatoire | TOTP | Pour tous les comptes admin |
| **Wazuh Dashboard** | ⚠️ Recommandé | Via proxy d'authentification ou SSO | Selon la maturité de l'infrastructure |
| **Active Directory (RDP)** | ✅ Obligatoire | Smart card ou TOTP (pour les comptes admin) | Accès au contrôleur de domaine |
| **API Wazuh** | ❌ Non applicable | Authentification par token JWT | Tokens avec durée de vie limitée |

### 6.3 Protection des secrets — DPAPI

Les scripts PowerShell déployés via GPO utilisent **DPAPI** (Data Protection API) pour la gestion des secrets :

| Secret | Méthode de protection | Accès |
|---|---|---|
| Clé d'enregistrement Wazuh | Chiffrée via DPAPI (contexte machine) | Déchiffrée uniquement par le poste cible |
| Token API Wazuh (scripts d'automatisation) | Chiffrée via DPAPI (contexte utilisateur de service) | Déchiffrée uniquement par le compte de service |
| Mot de passe de service | Stocké dans un Managed Service Account (gMSA) ou DPAPI | Rotation automatique |

> **⚠️ Important** : Les scripts PowerShell ne doivent **jamais** contenir de secrets en clair. Le dépôt GitHub étant public, tout secret doit être un placeholder `<PLACEHOLDER>` dans le code source. Les valeurs réelles sont injectées via DPAPI au moment de l'exécution.

### 6.4 Gestion des sessions

| Paramètre | Valeur | Composant |
|---|---|---|
| **Timeout de session Dashboard** | 30 minutes d'inactivité | Wazuh Dashboard |
| **Timeout de session Proxmox** | 15 minutes d'inactivité | Proxmox VE |
| **Durée de vie token JWT API** | 900 secondes (15 minutes) | API Wazuh |
| **Nombre max. de sessions simultanées** | 2 par utilisateur | Wazuh Dashboard |
| **Verrouillage automatique du poste** | 10 minutes d'inactivité | GPO Active Directory |

---

## 7. Gestion des comptes de service

### 7.1 Inventaire des comptes de service

| ID | Compte de service | Composant | Fonction | Type | Privilèges |
|---|---|---|---|---|---|
| SVC-01 | `svc_wazuh_api` | API Wazuh | Appels API automatisés (scripts de maintenance) | Compte local Wazuh | API `/agents/*`, `/manager/*` (lecture + écriture limitée) |
| SVC-02 | `svc_wazuh_deploy` | GPO / AD | Déploiement des agents via script PowerShell | gMSA (Group Managed Service Account) | Lecture GPO, installation logicielle sur les postes |
| SVC-03 | `svc_backup_wazuh` | Sauvegardes | Exécution des scripts de sauvegarde (Wazuh Manager, Indexer) | Compte local Linux | Accès lecture aux fichiers de configuration et aux snapshots |
| SVC-04 | `svc_tailscale_mgmt` | Tailscale | Gestion automatisée des nœuds Tailscale | API Key Tailscale | Lecture de l'état des nœuds |
| SVC-05 | `svc_proxmox_backup` | Proxmox | Exécution des tâches vzdump planifiées | Compte PVE | `Datastore.Allocate` + `VM.Backup` |

### 7.2 Règles de gestion des comptes de service

| Règle | Description |
|---|---|
| **Inventaire obligatoire** | Chaque compte de service est référencé dans le registre ci-dessus avec sa justification |
| **Moindre privilège** | Les comptes de service n'ont accès qu'aux ressources strictement nécessaires à leur fonction |
| **Pas d'usage interactif** | Les comptes de service ne doivent pas être utilisés pour des connexions interactives (RDP, console) |
| **Rotation des secrets** | Les mots de passe / tokens des comptes de service sont renouvelés tous les 90 jours |
| **gMSA privilégié** | Utiliser les Group Managed Service Accounts (gMSA) pour les comptes AD quand possible |
| **Surveillance** | Toute connexion interactive avec un compte de service déclenche une alerte Wazuh de niveau critique |
| **Propriétaire désigné** | Chaque compte de service a un propriétaire humain identifié responsable de sa gestion |

### 7.3 Rotation des secrets des comptes de service

| Compte | Méthode de rotation | Fréquence | Automatisé |
|---|---|---|---|
| SVC-01 (`svc_wazuh_api`) | Régénération du token via API | 90 jours | Oui (script cron) |
| SVC-02 (`svc_wazuh_deploy`) | Rotation automatique gMSA | 30 jours (par défaut AD) | Oui (gMSA natif) |
| SVC-03 (`svc_backup_wazuh`) | Changement de mot de passe + mise à jour scripts | 90 jours | Non (manuel) |
| SVC-04 (`svc_tailscale_mgmt`) | Régénération de l'API Key Tailscale | 90 jours | Non (manuel) |
| SVC-05 (`svc_proxmox_backup`) | Changement de mot de passe via PVE | 90 jours | Non (manuel) |

---

## 8. Revue périodique des accès

### 8.1 Calendrier des revues

| Type de revue | Fréquence | Périmètre | Responsable | Livrable |
|---|---|---|---|---|
| **Revue des comptes actifs** | Mensuelle | Tous les comptes AD (groupes `GG_SOC_*`) | SOC Admin | Liste des comptes actifs/inactifs |
| **Revue des droits applicatifs** | Trimestrielle | Rôles Wazuh, Proxmox, Tailscale | SOC Admin + DSI | Matrice de conformité |
| **Revue des comptes de service** | Trimestrielle | Tous les comptes `svc_*` | SOC Admin | Rapport de rotation des secrets |
| **Revue des accès privilégiés** | Trimestrielle | Comptes `GG_SOC_Admins` | DSI + DPO | Rapport d'audit |
| **Audit de conformité IAM** | Annuelle | Politique IAM complète | DPO + auditeur externe | Rapport d'audit formel |

### 8.2 Processus de revue

| Étape | Action | Responsable |
|---|---|---|
| 1 | Extraction de la liste des comptes et de leurs droits (AD, Wazuh, Proxmox) | SOC Admin |
| 2 | Comparaison avec la matrice de rôles et permissions autorisés | SOC Admin |
| 3 | Identification des écarts (comptes inactifs, droits excessifs, comptes orphelins) | SOC Admin |
| 4 | Proposition de corrections (désactivation, modification de droits) | SOC Admin |
| 5 | Validation des corrections par le DSI | DSI |
| 6 | Application des corrections | SOC Admin |
| 7 | Documentation et archivage du rapport de revue | SOC Admin + DPO |

### 8.3 Indicateurs de suivi (KPI)

| Indicateur | Cible | Fréquence de mesure |
|---|---|---|
| Nombre de comptes inactifs (> 90 jours) | 0 | Mensuelle |
| Nombre de comptes avec droits excessifs identifiés en revue | 0 | Trimestrielle |
| Taux de conformité des rotations de secrets (comptes de service) | 100% | Trimestrielle |
| Délai moyen de révocation après départ | < 24h | Continue |
| Nombre de comptes partagés / génériques | 0 | Mensuelle |
| Taux de déploiement MFA sur les comptes admin | 100% | Mensuelle |

---

## 9. Traçabilité et audit des accès

### 9.1 Événements journalisés

| Événement | Source de journalisation | Niveau d'alerte Wazuh | Rétention |
|---|---|---|---|
| Connexion réussie (interactive) | AD (Event ID 4624) | Informationnel | 90 jours |
| Échec d'authentification | AD (Event ID 4625) | Avertissement (× 1), Alerte (× 5+) | 90 jours |
| Verrouillage de compte | AD (Event ID 4740) | Alerte élevée | 180 jours |
| Création de compte | AD (Event ID 4720) | Alerte élevée | 365 jours |
| Modification de groupe de sécurité | AD (Event ID 4728, 4732) | Alerte élevée | 365 jours |
| Suppression de compte | AD (Event ID 4726) | Alerte critique | 365 jours |
| Connexion au Wazuh Dashboard | Logs Wazuh Dashboard | Informationnel | 90 jours |
| Appel API Wazuh (écriture) | Logs API Wazuh | Avertissement | 180 jours |
| Connexion à Proxmox | Logs Proxmox (`pveproxy`) | Alerte élevée | 180 jours |
| Connexion Tailscale (nouveau nœud) | Logs Tailscale | Alerte élevée | 180 jours |
| Connexion interactive avec compte de service | AD (Event ID 4624 + filtre) | **Alerte critique** | 365 jours |
| Modification de GPO | AD (Event ID 5136) | **Alerte critique** | 365 jours |
| Accès aux données personnelles (export) | Wazuh Dashboard | Alerte élevée | 365 jours |

### 9.2 Règles Wazuh de détection IAM

| ID Règle | Description | Condition | Niveau |
|---|---|---|---|
| `100100` | Tentatives de brute-force AD | ≥ 5 Event ID 4625 en 5 minutes (même source) | 10 (Critique) |
| `100101` | Connexion interactive avec compte de service | Event ID 4624 + compte `svc_*` + Type Logon 2 ou 10 | 12 (Critique) |
| `100102` | Ajout d'un utilisateur au groupe `GG_SOC_Admins` | Event ID 4728 + groupe cible `GG_SOC_Admins` | 10 (Critique) |
| `100103` | Modification de GPO de déploiement | Event ID 5136 + DN contenant `Wazuh` | 10 (Critique) |
| `100104` | Connexion Tailscale depuis un nœud non autorisé | Log Tailscale + nœud non listé dans l'ACL | 12 (Critique) |
| `100105` | Accès API Wazuh avec token expiré ou invalide | Log API Wazuh + HTTP 401 | 8 (Élevé) |
| `100106` | Création de compte AD en dehors des heures ouvrées | Event ID 4720 + heure ∉ [08:00-18:00] | 10 (Critique) |

### 9.3 Conservation et archivage

| Type de journal | Rétention en ligne (Indexer) | Archivage hors ligne | Format |
|---|---|---|---|
| Logs d'authentification | 90 jours | 1 an | JSON (OpenSearch) |
| Logs d'administration (création/suppression) | 365 jours | 3 ans | JSON (OpenSearch) |
| Rapports de revue des accès | — | 5 ans | PDF signé |
| Logs de conformité RGPD | 365 jours | 5 ans | JSON + PDF |

---

## 10. Gestion des accès privilégiés (PAM)

### 10.1 Comptes à privilèges identifiés

| Compte | Système | Niveau de privilège | Détenteur |
|---|---|---|---|
| `Administrator` (AD) | Active Directory | Domain Admin | `<ADMIN_SOC_1>` |
| `root` (Proxmox) | Serveur Proxmox | Root | `<ADMIN_SOC_1>` |
| `root` (VM Wazuh) | VM Linux Wazuh | Root | `<ADMIN_SOC_1>` |
| `admin` (Wazuh API) | API Wazuh | Admin API | `<ADMIN_SOC_1>`, `<ADMIN_SOC_2>` |
| `admin@tailscale` | Tailscale | Admin réseau | `<ADMIN_SOC_1>` |

### 10.2 Règles d'utilisation des comptes à privilèges

| Règle | Description |
|---|---|
| **Comptes nominatifs** | Chaque administrateur utilise son compte nominatif pour les tâches courantes ; le compte `root`/`Administrator` n'est utilisé qu'en dernier recours |
| **Élévation temporaire** | L'utilisation de `sudo` ou `runas` est privilégiée par rapport à la connexion directe en root/admin |
| **Journalisation renforcée** | Toutes les sessions privilégiées sont intégralement journalisées (commandes exécutées) |
| **Accès conditionnel** | L'accès aux comptes à privilèges nécessite le MFA + une connexion depuis un réseau autorisé (Tailscale) |
| **Pas de stockage de mots de passe** | Les mots de passe des comptes à privilèges ne sont pas stockés en clair (utilisation de DPAPI ou coffre-fort) |
| **Break-glass** | Une procédure d'accès d'urgence (*break-glass*) est documentée pour les cas où les comptes nominatifs sont indisponibles |

### 10.3 Procédure break-glass (accès d'urgence)

| Étape | Action | Responsable |
|---|---|---|
| 1 | Constat de l'impossibilité d'accéder au système avec les comptes nominatifs | SOC Admin |
| 2 | Récupération du mot de passe d'urgence stocké dans l'enveloppe scellée `<LOCALISATION_COFFRE>` | DSI ou Direction |
| 3 | Connexion avec le compte d'urgence | SOC Admin |
| 4 | Résolution de l'incident | SOC Admin |
| 5 | Changement immédiat du mot de passe d'urgence | SOC Admin |
| 6 | Nouvelle mise sous enveloppe scellée | DSI |
| 7 | Documentation de l'usage dans le registre des incidents | SOC Admin + DPO |

---

## 11. Non-conformités et sanctions

### 11.1 Niveaux de non-conformité

| Niveau | Description | Exemples | Action corrective |
|---|---|---|---|
| **Mineur** | Écart sans impact immédiat sur la sécurité | Mot de passe non renouvelé dans les délais | Rappel écrit + renouvellement forcé |
| **Significatif** | Écart pouvant exposer le SI à un risque | Partage d'identifiants, contournement du MFA | Avertissement formel + revue des droits |
| **Majeur** | Violation délibérée de la politique ou incident de sécurité | Utilisation abusive de droits admin, accès non autorisé | Suspension des accès + enquête + sanctions disciplinaires |
| **Critique** | Compromission avérée du SI ou fuite de données | Exfiltration de données, compromission de compte | Suspension immédiate + notification CNIL si RGPD + procédure disciplinaire |

### 11.2 Processus de traitement

| Étape | Action | Responsable | Délai |
|---|---|---|---|
| 1 | Détection de la non-conformité (alerte Wazuh, revue, signalement) | SOC Admin / Wazuh | Immédiat |
| 2 | Évaluation du niveau de non-conformité | SOC Admin + DSI | < 4h |
| 3 | Mesures conservatoires (suspension d'accès si nécessaire) | SOC Admin | Immédiat si Majeur/Critique |
| 4 | Investigation et collecte de preuves | SOC Admin + DPO | < 48h |
| 5 | Décision et action corrective | Direction + DSI + DPO | < 7 jours |
| 6 | Documentation et retour d'expérience | SOC Admin | < 14 jours |

---

## 12. Annexes

### Annexe A — Formulaire de demande d'accès

```
═══════════════════════════════════════════════════
       FORMULAIRE DE DEMANDE D'ACCÈS SOC
═══════════════════════════════════════════════════

Date de la demande    : ____/____/________
Demandeur             : _____________________________
Fonction              : _____________________________
Manager / Responsable : _____________________________

Rôle SOC demandé :
  [ ] SOC Admin
  [ ] Analyste SOC
  [ ] Lecteur SOC
  [ ] DPO
  [ ] Prestataire externe (durée : _____________)

Justification de la demande :
__________________________________________________
__________________________________________________

Composants nécessaires :
  [ ] Wazuh Dashboard      [ ] API Wazuh
  [ ] Active Directory     [ ] Proxmox
  [ ] Tailscale            [ ] Autre : ____________

Validation DSI :
  Nom : _________________  Date : ____/____/________
  Signature : _______________

Création effectuée par :
  Nom : _________________  Date : ____/____/________
═══════════════════════════════════════════════════
```

### Annexe B — Correspondance ISO 27001:2022

| Contrôle ISO 27001 | Couvert par | Section |
|---|---|---|
| A.5.15 — Contrôle d'accès | Principes directeurs, matrice RBAC | §2, §4 |
| A.5.16 — Gestion des identités | Cycle de vie des comptes | §5 |
| A.5.17 — Informations d'authentification | Politique de mots de passe, MFA, DPAPI | §6 |
| A.5.18 — Droits d'accès | Matrice des permissions, revue | §4, §8 |
| A.8.2 — Droits d'accès privilégiés | Gestion PAM, break-glass | §10 |
| A.8.3 — Restriction d'accès à l'information | Besoin d'en connaître | §2.3 |
| A.8.4 — Accès au code source | Scripts PowerShell (GitHub public) | §6.3 |
| A.8.5 — Authentification sécurisée | MFA, sessions, tokens | §6 |
| A.8.15 — Journalisation | Traçabilité des accès | §9 |

### Annexe C — Historique des versions

| Version | Date | Auteur | Modifications |
|---|---|---|---|
| 1.0 | 29/06/2026 | `<NOM_AUTEUR>` | Création initiale |
| | | | |

---

> **Note** : Ce document est hébergé sur un dépôt GitHub public. Toutes les données sensibles (noms, comptes, adresses) sont remplacées par des placeholders `<PLACEHOLDER>`. Avant tout usage opérationnel, ces valeurs doivent être renseignées dans un document classifié séparé.
