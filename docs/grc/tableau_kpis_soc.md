# Tableau de Bord KPIs — SOC Scolaire Wazuh

> **Projet** : Déploiement d'un SOC scolaire basé sur Wazuh  
> **Version** : 1.0  
> **Date** : 2026-06-29  
> **Auteur** : `<STAGIAIRE_NOM>`  
> **Classification** : Interne — Indicateurs de performance  

---

## 1. Objectif du document

Ce document définit les **indicateurs clés de performance (KPIs)** du SOC scolaire. Chaque KPI est décrit avec sa formule de calcul, sa fréquence de mesure, ses seuils d'alerte et ses objectifs cibles. Ce tableau de bord permet de piloter l'efficacité opérationnelle du SOC et de démontrer la valeur ajoutée du projet lors de la soutenance académique.

---

## 2. KPIs Opérationnels

### 2.1 Tableau synthétique

| ID | KPI | Formule de calcul | Unité | Fréquence | Valeur initiale | Objectif cible | Seuil 🟢 | Seuil 🟠 | Seuil 🔴 |
|----|-----|--------------------|-------|-----------|-----------------|----------------|-----------|-----------|-----------|
| OP-01 | **MTTD** (Mean Time To Detect) | `Σ(timestamp_alerte - timestamp_événement) / nb_détections` | Minutes | Quotidienne | N/A (pas de SOC) | < 15 min | ≤ 15 min | 15–60 min | > 60 min |
| OP-02 | **MTTR** (Mean Time To Respond) | `Σ(timestamp_résolution - timestamp_alerte) / nb_incidents` | Minutes | Quotidienne | N/A | < 30 min | ≤ 30 min | 30–120 min | > 120 min |
| OP-03 | **Alertes/jour — Critique** (Niveau ≥ 12) | `COUNT(alertes WHERE level >= 12) / nb_jours` | Nombre | Quotidienne | 0 | Suivi | < 5 | 5–15 | > 15 |
| OP-04 | **Alertes/jour — Haute** (Niveau 8–11) | `COUNT(alertes WHERE level BETWEEN 8 AND 11) / nb_jours` | Nombre | Quotidienne | 0 | Suivi | < 20 | 20–50 | > 50 |
| OP-05 | **Alertes/jour — Moyenne** (Niveau 4–7) | `COUNT(alertes WHERE level BETWEEN 4 AND 7) / nb_jours` | Nombre | Quotidienne | 0 | Suivi | < 100 | 100–300 | > 300 |
| OP-06 | **Alertes/jour — Basse** (Niveau ≤ 3) | `COUNT(alertes WHERE level <= 3) / nb_jours` | Nombre | Hebdomadaire | 0 | Suivi | < 500 | 500–1000 | > 1000 |
| OP-07 | **Taux de faux positifs** | `(nb_faux_positifs / nb_total_alertes) × 100` | % | Hebdomadaire | ~80% (estimé) | < 20% | ≤ 20% | 20–50% | > 50% |
| OP-08 | **Couverture MITRE ATT&CK** | `(nb_techniques_couvertes / nb_techniques_pertinentes) × 100` | % | Mensuelle | 0% | ≥ 40% | ≥ 40% | 20–40% | < 20% |

### 2.2 Détail des formules

#### OP-01 — MTTD (Mean Time To Detect)

```
MTTD = Σ (T_alerte_i - T_événement_i) / N

Où :
  T_alerte_i    = Horodatage de génération de l'alerte Wazuh pour l'événement i
  T_événement_i = Horodatage de l'événement source (log Windows, Sysmon, etc.)
  N             = Nombre total de détections sur la période de mesure
```

> **Source de données** : Index Wazuh `wazuh-alerts-*`, champs `timestamp` et `data.win.system.systemTime`

#### OP-02 — MTTR (Mean Time To Respond)

```
MTTR = Σ (T_résolution_i - T_alerte_i) / N

Où :
  T_résolution_i = Horodatage de clôture de l'incident (ticket/journal)
  T_alerte_i     = Horodatage de l'alerte initiale
  N              = Nombre d'incidents traités sur la période
```

> **Source de données** : Journal des incidents SOC + index Wazuh

#### OP-07 — Taux de faux positifs

```
Taux_FP = (FP / (FP + VP)) × 100

Où :
  FP = Nombre d'alertes identifiées comme faux positifs après analyse
  VP = Nombre d'alertes identifiées comme vrais positifs
```

> **Méthode de classification** : Revue manuelle hebdomadaire d'un échantillon d'alertes (minimum 50 alertes par revue)

#### OP-08 — Couverture MITRE ATT&CK

```
Couverture = (T_couvertes / T_pertinentes) × 100

Où :
  T_couvertes    = Nombre de techniques ATT&CK pour lesquelles au moins une règle Wazuh est active
  T_pertinentes  = Nombre de techniques ATT&CK applicables à l'environnement Windows/AD scolaire
```

> **Référence** : Matrice ATT&CK for Enterprise — plateforme Windows (https://attack.mitre.org/)

---

## 3. KPIs de Déploiement

### 3.1 Tableau synthétique

| ID | KPI | Formule de calcul | Unité | Fréquence | Valeur initiale | Objectif cible | Seuil 🟢 | Seuil 🟠 | Seuil 🔴 |
|----|-----|--------------------|-------|-----------|-----------------|----------------|-----------|-----------|-----------|
| DP-01 | **% de postes avec agent installé** | `(nb_postes_agent / nb_postes_total) × 100` | % | Quotidienne | 0% | 100% | ≥ 95% | 80–95% | < 80% |
| DP-02 | **% d'agents connectés (actifs)** | `(nb_agents_active / nb_agents_total) × 100` | % | Quotidienne | 0% | ≥ 95% | ≥ 95% | 80–95% | < 80% |
| DP-03 | **Temps moyen de déploiement par poste** | `Σ(T_fin_install_i - T_début_install_i) / N` | Minutes | Par vague | N/A | < 10 min | ≤ 10 min | 10–30 min | > 30 min |
| DP-04 | **Taux d'échec de déploiement** | `(nb_échecs / nb_tentatives) × 100` | % | Par vague | N/A | < 5% | ≤ 5% | 5–15% | > 15% |
| DP-05 | **Taux d'agents à jour** | `(nb_agents_version_courante / nb_agents_total) × 100` | % | Hebdomadaire | N/A | 100% | ≥ 95% | 80–95% | < 80% |
| DP-06 | **Disponibilité du manager Wazuh** | `(uptime_minutes / total_minutes_période) × 100` | % | Mensuelle | N/A | ≥ 99.5% | ≥ 99.5% | 98–99.5% | < 98% |

### 3.2 Détail des formules

#### DP-01 — Couverture de déploiement

```
Couverture_déploiement = (A_installés / P_total) × 100

Où :
  A_installés = Nombre de postes avec l'agent Wazuh installé (vérifiable via GPO ou SCCM)
  P_total     = Nombre total de postes dans le périmètre (OU Active Directory ciblées)
```

> **Source de données** : API Wazuh `GET /agents?status=all` + inventaire AD via `Get-ADComputer`

#### DP-02 — Agents actifs

```
Taux_actif = (A_active / A_total) × 100

Où :
  A_active = Agents avec statut "active" dans le manager Wazuh
  A_total  = Nombre total d'agents enregistrés
```

> **Source de données** : API Wazuh `GET /agents/summary/status`  
> **Script de collecte** : `scripts/monitoring/check_agents_status.ps1`

#### DP-06 — Disponibilité manager

```
Disponibilité = ((T_total - T_downtime) / T_total) × 100

Où :
  T_total    = Durée totale de la période de mesure (en minutes)
  T_downtime = Durée cumulée des interruptions de service (en minutes)
```

> **Source de données** : Monitoring Proxmox + healthcheck Wazuh API

---

## 4. KPIs de Conformité

### 4.1 Tableau synthétique

| ID | KPI | Formule de calcul | Unité | Fréquence | Valeur initiale | Objectif cible | Seuil 🟢 | Seuil 🟠 | Seuil 🔴 |
|----|-----|--------------------|-------|-----------|-----------------|----------------|-----------|-----------|-----------|
| CO-01 | **% de contrôles ISO 27001 couverts** | `(nb_contrôles_implémentés / nb_contrôles_applicables) × 100` | % | Mensuelle | 0% | ≥ 60% | ≥ 60% | 40–60% | < 40% |
| CO-02 | **Conformité RGPD** | Score qualitatif basé sur la checklist RGPD | Score /10 | Mensuelle | 2/10 | ≥ 8/10 | ≥ 8 | 5–8 | < 5 |
| CO-03 | **Ancienneté des règles de détection** | `MAX(date_courante - date_dernière_mise_à_jour_règle)` | Jours | Hebdomadaire | N/A | < 90 jours | ≤ 90 j | 90–180 j | > 180 j |
| CO-04 | **% de documentation à jour** | `(nb_docs_à_jour / nb_docs_total) × 100` | % | Mensuelle | 0% | 100% | ≥ 90% | 70–90% | < 70% |
| CO-05 | **Taux de révision des accès** | `(nb_accès_révisés / nb_accès_total) × 100` | % | Trimestrielle | 0% | 100% | 100% | 80–100% | < 80% |
| CO-06 | **Délai de notification d'incident** | `T_notification - T_détection` | Heures | Par incident | N/A | < 24h | ≤ 24h | 24–72h | > 72h |

### 4.2 Détail des formules

#### CO-01 — Couverture ISO 27001

```
Couverture_ISO = (C_implémentés / C_applicables) × 100

Où :
  C_implémentés = Contrôles de l'Annexe A ISO 27001:2022 effectivement mis en œuvre
  C_applicables = Contrôles jugés applicables après la Déclaration d'Applicabilité (SoA)

Contrôles principalement couverts par le SOC Wazuh :
  - A.5.24  Planification et préparation de la gestion des incidents
  - A.5.25  Évaluation des événements de sécurité et prise de décision
  - A.5.28  Collecte de preuves
  - A.8.15  Journalisation
  - A.8.16  Activités de surveillance
```

#### CO-02 — Checklist conformité RGPD

| # | Critère | Pondération |
|---|---------|:-----------:|
| 1 | Registre des traitements documenté | 1 pt |
| 2 | Analyse d'impact (PIA) réalisée | 1 pt |
| 3 | Base légale identifiée (intérêt légitime) | 1 pt |
| 4 | Durée de rétention des logs définie | 1 pt |
| 5 | Pseudonymisation/anonymisation appliquée | 1 pt |
| 6 | Accès aux données limité (moindre privilège) | 1 pt |
| 7 | Procédure d'exercice des droits (accès, effacement) | 1 pt |
| 8 | Chiffrement des données en transit (TLS) | 1 pt |
| 9 | Chiffrement des données au repos | 1 pt |
| 10 | Procédure de notification de violation (72h) | 1 pt |

> **Score RGPD** = Somme des critères satisfaits (sur 10)

---

## 5. Tableau de synthèse global

| Catégorie | ID | KPI | Objectif | Statut actuel | Tendance |
|-----------|----|-----|----------|:-------------:|:--------:|
| **Opérationnel** | OP-01 | MTTD | < 15 min | 🔴 N/A | — |
| | OP-02 | MTTR | < 30 min | 🔴 N/A | — |
| | OP-07 | Taux de faux positifs | < 20% | 🔴 ~80% | — |
| | OP-08 | Couverture ATT&CK | ≥ 40% | 🔴 0% | — |
| **Déploiement** | DP-01 | Postes avec agent | 100% | 🔴 0% | — |
| | DP-02 | Agents connectés | ≥ 95% | 🔴 0% | — |
| | DP-06 | Disponibilité manager | ≥ 99.5% | 🔴 N/A | — |
| **Conformité** | CO-01 | Couverture ISO 27001 | ≥ 60% | 🔴 0% | — |
| | CO-02 | Conformité RGPD | ≥ 8/10 | 🟠 2/10 | — |
| | CO-03 | Ancienneté des règles | < 90 jours | 🟢 N/A | — |

> **Légende tendance** : ↗️ Amélioration | → Stable | ↘️ Dégradation | — Non mesuré

---

## 6. Processus de collecte et reporting

### 6.1 Fréquences de collecte

| Fréquence | KPIs concernés | Responsable | Outil de collecte |
|-----------|----------------|-------------|-------------------|
| **Quotidienne** | OP-01 à OP-06, DP-01, DP-02 | Stagiaire SOC | Scripts automatisés + API Wazuh |
| **Hebdomadaire** | OP-07, DP-05, CO-03 | Stagiaire SOC | Revue manuelle + dashboards |
| **Mensuelle** | OP-08, DP-06, CO-01, CO-02, CO-04 | Stagiaire SOC + Tuteur | Rapport mensuel |
| **Par événement** | DP-03, DP-04, CO-06 | Stagiaire SOC | Journal des événements |
| **Trimestrielle** | CO-05 | Stagiaire SOC + DPO | Audit des accès |

### 6.2 Dashboards OpenSearch

Les KPIs opérationnels et de déploiement sont visualisés via des dashboards OpenSearch Dashboards intégrés à Wazuh :

| Dashboard | KPIs affichés | Rafraîchissement |
|-----------|---------------|------------------|
| `SOC-Overview` | OP-01 à OP-06 | Temps réel (5s) |
| `SOC-Deployment` | DP-01 à DP-06 | 5 minutes |
| `SOC-MITRE` | OP-08 | 1 heure |
| `SOC-Compliance` | CO-01, CO-02 | Quotidien |

---

## 7. Données sensibles — Rappel

> ⚠️ Ce document est hébergé sur un **repository GitHub public**. Les valeurs réelles des KPIs contenant des données sensibles (adresses IP, noms de postes, identifiants) ne doivent **jamais** être commitées. Utiliser les placeholders définis dans le projet.

---

## 8. Historique des révisions

| Version | Date | Auteur | Modifications |
|---------|------|--------|---------------|
| 1.0 | 2026-06-29 | `<STAGIAIRE_NOM>` | Création initiale du document |

---

*Document généré dans le cadre du projet SOC scolaire — `<ECOLE_NOM>`*
