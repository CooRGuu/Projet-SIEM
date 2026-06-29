# Matrice RACI — Projet SOC Scolaire Wazuh

> **Projet** : Déploiement d'un SOC scolaire basé sur Wazuh  
> **Version** : 1.0  
> **Date** : 2026-06-29  
> **Auteur** : `<STAGIAIRE_NOM>`  
> **Classification** : Interne — Document de gestion de projet  

---

## 1. Objectif du document

Ce document définit la **matrice RACI** (Responsible, Accountable, Consulted, Informed) du projet de déploiement d'un SOC scolaire. Il clarifie les responsabilités de chaque intervenant pour l'ensemble des activités identifiées, de l'analyse initiale des besoins jusqu'à la soutenance académique.

---

## 2. Définition des rôles

| Code | Rôle                       | Périmètre                                                                 |
|------|----------------------------|---------------------------------------------------------------------------|
| **S**    | Stagiaire SOC              | Responsable opérationnel du projet, implémentation technique              |
| **T**    | Tuteur de stage            | Supervision technique et méthodologique, validation des livrables         |
| **AR**   | Admin Réseau École         | Gestion de l'infrastructure réseau, accès Proxmox, tunnel Tailscale      |
| **AD**   | Admin Active Directory     | Gestion du domaine AD, GPO, comptes de service                           |
| **D**    | DPO (Délégué à la Protection des Données) | Conformité RGPD, analyse d'impact, validation des traitements |
| **RP**   | Responsable Pédagogique    | Validation académique, suivi du stage, évaluation finale                  |

---

## 3. Légende RACI

| Lettre | Signification | Description |
|--------|---------------|-------------|
| **R** | Responsible (Réalisateur) | Personne qui **exécute** l'activité. Peut être partagé entre plusieurs rôles. |
| **A** | Accountable (Approbateur) | Personne qui **valide et assume la responsabilité finale**. Un seul A par activité. |
| **C** | Consulted (Consulté) | Personne dont l'**avis est sollicité** avant ou pendant l'exécution (communication bidirectionnelle). |
| **I** | Informed (Informé) | Personne **tenue informée** de l'avancement ou du résultat (communication unidirectionnelle). |

---

## 4. Matrice RACI complète

### 4.1 Phase 1 — Cadrage et conception

| # | Activité | Stagiaire SOC (S) | Tuteur (T) | Admin Réseau (AR) | Admin AD (AD) | DPO (D) | Resp. Péda. (RP) |
|---|----------|:------------------:|:----------:|:------------------:|:-------------:|:-------:|:-----------------:|
| 1.1 | Analyse des besoins de sécurité | R | A | C | C | C | I |
| 1.2 | Étude de l'existant (inventaire postes, réseau) | R | C | C | C | I | I |
| 1.3 | Analyse d'impact RGPD (PIA) | R | C | I | I | A | I |
| 1.4 | Définition du périmètre de supervision | R | A | C | C | C | I |
| 1.5 | Rédaction du cahier des charges technique | R | A | C | C | I | I |
| 1.6 | Conception de l'architecture SOC | R | A | C | C | I | I |
| 1.7 | Choix et validation des technologies | R | A | C | I | I | I |
| 1.8 | Planning et jalons du projet | R | A | I | I | I | C |

### 4.2 Phase 2 — Déploiement infrastructure

| # | Activité | Stagiaire SOC (S) | Tuteur (T) | Admin Réseau (AR) | Admin AD (AD) | DPO (D) | Resp. Péda. (RP) |
|---|----------|:------------------:|:----------:|:------------------:|:-------------:|:-------:|:-----------------:|
| 2.1 | Déploiement du manager Wazuh sur Proxmox | R | A | C | I | I | I |
| 2.2 | Configuration réseau et pare-feu | R | C | A | I | I | I |
| 2.3 | Mise en place du tunnel Tailscale | R | C | A | I | I | I |
| 2.4 | Configuration Ansible (playbooks) | R | A | C | I | I | I |
| 2.5 | Durcissement du serveur Wazuh | R | A | C | I | I | I |
| 2.6 | Configuration TLS/SSL des communications | R | A | C | I | I | I |

### 4.3 Phase 3 — Déploiement des agents

| # | Activité | Stagiaire SOC (S) | Tuteur (T) | Admin Réseau (AR) | Admin AD (AD) | DPO (D) | Resp. Péda. (RP) |
|---|----------|:------------------:|:----------:|:------------------:|:-------------:|:-------:|:-----------------:|
| 3.1 | Création des scripts PowerShell (DPAPI) | R | A | I | C | I | I |
| 3.2 | Création et configuration des GPO de déploiement | R | C | I | A | I | I |
| 3.3 | Test de déploiement sur poste pilote | R | A | C | C | I | I |
| 3.4 | Déploiement massif des agents Wazuh | R | A | C | C | I | I |
| 3.5 | Validation de la connectivité agent → manager | R | A | C | I | I | I |
| 3.6 | Gestion des certificats d'authentification | R | A | C | C | I | I |

### 4.4 Phase 4 — Configuration et détection

| # | Activité | Stagiaire SOC (S) | Tuteur (T) | Admin Réseau (AR) | Admin AD (AD) | DPO (D) | Resp. Péda. (RP) |
|---|----------|:------------------:|:----------:|:------------------:|:-------------:|:-------:|:-----------------:|
| 4.1 | Configuration des règles de détection Wazuh | R | A | I | I | I | I |
| 4.2 | Mapping MITRE ATT&CK des règles | R | A | I | I | I | I |
| 4.3 | Configuration des décodeurs personnalisés | R | A | I | I | I | I |
| 4.4 | Création des dashboards Kibana/OpenSearch | R | A | I | I | I | I |
| 4.5 | Configuration des alertes et notifications | R | A | C | I | I | I |
| 4.6 | Tests de détection (red team basique) | R | A | C | C | I | I |
| 4.7 | Tuning des règles (réduction faux positifs) | R | A | I | I | I | I |
| 4.8 | Validation de la couverture de détection | R | A | C | I | I | I |

### 4.5 Phase 5 — Documentation et gouvernance

| # | Activité | Stagiaire SOC (S) | Tuteur (T) | Admin Réseau (AR) | Admin AD (AD) | DPO (D) | Resp. Péda. (RP) |
|---|----------|:------------------:|:----------:|:------------------:|:-------------:|:-------:|:-----------------:|
| 5.1 | Rédaction de la documentation technique | R | A | C | I | I | I |
| 5.2 | Rédaction des procédures opérationnelles | R | A | C | C | I | I |
| 5.3 | Rédaction de la documentation GRC | R | A | I | I | C | I |
| 5.4 | Rédaction de la politique de sécurité SOC | R | A | C | I | C | I |
| 5.5 | Création du registre des traitements | R | C | I | I | A | I |
| 5.6 | Rédaction du rapport de stage | R | I | I | I | I | A |
| 5.7 | Préparation des supports de soutenance | R | C | I | I | I | A |

### 4.6 Phase 6 — Validation et clôture

| # | Activité | Stagiaire SOC (S) | Tuteur (T) | Admin Réseau (AR) | Admin AD (AD) | DPO (D) | Resp. Péda. (RP) |
|---|----------|:------------------:|:----------:|:------------------:|:-------------:|:-------:|:-----------------:|
| 6.1 | Recette fonctionnelle complète | R | A | C | C | I | I |
| 6.2 | Audit de sécurité de la solution | R | A | C | I | C | I |
| 6.3 | Transfert de compétences | R | A | C | C | I | I |
| 6.4 | Soutenance académique | R | I | I | I | I | A |
| 6.5 | Bilan et retour d'expérience | R | A | I | I | I | C |

---

## 5. Synthèse par rôle

| Rôle | Nb d'activités R | Nb d'activités A | Nb d'activités C | Nb d'activités I |
|------|:-----------------:|:-----------------:|:-----------------:|:-----------------:|
| Stagiaire SOC | 31 | 0 | 0 | 0 |
| Tuteur de stage | 0 | 24 | 7 | 0 |
| Admin Réseau École | 0 | 2 | 18 | 11 |
| Admin AD | 0 | 1 | 12 | 18 |
| DPO | 0 | 2 | 5 | 24 |
| Responsable Pédagogique | 0 | 2 | 2 | 27 |

---

## 6. Règles d'utilisation

1. **Un seul A par activité** : il ne peut y avoir qu'un seul approbateur final par tâche.
2. **Au moins un R par activité** : chaque tâche doit avoir un réalisateur identifié.
3. **Communication** : les personnes en C doivent être sollicitées **avant** la prise de décision ; les personnes en I sont notifiées **après**.
4. **Escalade** : en cas de désaccord, le Tuteur de stage est l'arbitre technique ; le Responsable Pédagogique est l'arbitre académique.
5. **Mise à jour** : cette matrice doit être révisée à chaque changement de périmètre du projet.

---

## 7. Données sensibles — Rappel

> ⚠️ Ce document est hébergé sur un **repository GitHub public**. Toutes les données sensibles (noms réels, adresses IP, noms de domaine AD, identifiants) sont remplacées par des **placeholders** au format `<PLACEHOLDER_DESCRIPTION>`.

| Placeholder | Description |
|-------------|-------------|
| `<STAGIAIRE_NOM>` | Nom complet du stagiaire |
| `<ECOLE_NOM>` | Nom de l'établissement scolaire |
| `<MANAGER_IP>` | Adresse IP du serveur Wazuh |
| `<DOMAINE_AD>` | Nom de domaine Active Directory |
| `<TAILSCALE_NET>` | Réseau Tailscale |

---

## 8. Historique des révisions

| Version | Date | Auteur | Modifications |
|---------|------|--------|---------------|
| 1.0 | 2026-06-29 | `<STAGIAIRE_NOM>` | Création initiale du document |

---

*Document généré dans le cadre du projet SOC scolaire — `<ECOLE_NOM>`*
