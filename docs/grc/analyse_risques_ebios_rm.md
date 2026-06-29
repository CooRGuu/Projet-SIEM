# Analyse de Risques — Méthode EBIOS Risk Manager (ANSSI)

**Projet** : SOC Scolaire — Déploiement Wazuh  
**Version** : 1.0  
**Date** : 29/06/2026  
**Classification** : Diffusion restreinte  
**Auteur** : `<NOM_AUTEUR>`  
**Établissement** : `<NOM_ETABLISSEMENT>`  

---

## Table des matières

1. [Introduction et contexte](#1-introduction-et-contexte)
2. [Atelier 1 — Cadrage et socle de sécurité](#2-atelier-1--cadrage-et-socle-de-sécurité)
3. [Atelier 2 — Sources de risques](#3-atelier-2--sources-de-risques)
4. [Atelier 3 — Scénarios stratégiques](#4-atelier-3--scénarios-stratégiques)
5. [Atelier 4 — Scénarios opérationnels](#5-atelier-4--scénarios-opérationnels)
6. [Atelier 5 — Traitement des risques](#6-atelier-5--traitement-des-risques)
7. [Synthèse et conclusions](#7-synthèse-et-conclusions)
8. [Annexes](#8-annexes)

---

## 1. Introduction et contexte

### 1.1 Objet du document

Le présent document constitue l'analyse de risques du projet de SOC (Security Operations Center) scolaire déployé au sein de l'établissement `<NOM_ETABLISSEMENT>`. L'analyse suit la méthode **EBIOS Risk Manager** publiée par l'ANSSI (Agence Nationale de la Sécurité des Systèmes d'Information) en octobre 2018.

### 1.2 Périmètre de l'étude

Le périmètre couvre l'ensemble de l'infrastructure SOC :

| Composant | Description | Localisation |
|---|---|---|
| **Wazuh Manager** | Serveur central de collecte et corrélation (v4.x) | VM sur Proxmox — `<IP_MANAGER>` |
| **Wazuh Indexer** | Elasticsearch/OpenSearch pour l'indexation des alertes | VM sur Proxmox — `<IP_INDEXER>` |
| **Wazuh Dashboard** | Interface web d'administration et de visualisation | VM sur Proxmox — `<IP_DASHBOARD>` |
| **Agents Wazuh** | Agents déployés via GPO Active Directory | Postes Windows du parc scolaire |
| **Active Directory** | Contrôleur de domaine pour la gestion des GPO | `<IP_DC>` |
| **Tunnel Tailscale** | VPN mesh pour l'administration distante | Overlay réseau |
| **Scripts PowerShell** | Automatisation du déploiement (DPAPI pour les secrets) | Exécutés via GPO |

### 1.3 Parties prenantes

| Partie prenante | Rôle | Contact |
|---|---|---|
| Responsable projet SOC | Pilotage technique et opérationnel | `<EMAIL_RESPONSABLE>` |
| DSI / Référent numérique | Validation des choix d'architecture | `<EMAIL_DSI>` |
| DPO (Délégué à la Protection des Données) | Conformité RGPD | `<EMAIL_DPO>` |
| Direction de l'établissement | Sponsor du projet | `<EMAIL_DIRECTION>` |
| Équipe pédagogique | Utilisateurs finaux | — |

### 1.4 Valeurs métier

Les valeurs métier identifiées dans le cadre du SOC scolaire sont :

- **VM1** — Continuité pédagogique : disponibilité des postes et du réseau pour l'enseignement
- **VM2** — Protection des données personnelles : données élèves, notes, dossiers (RGPD)
- **VM3** — Intégrité du système d'information : fiabilité des configurations et des journaux
- **VM4** — Image et réputation de l'établissement : confiance des familles et de la tutelle

---

## 2. Atelier 1 — Cadrage et socle de sécurité

### 2.1 Biens supports

| Identifiant | Bien support | Type | Valeur métier associée |
|---|---|---|---|
| BS-01 | Serveur Proxmox (hyperviseur) | Matériel | VM1, VM3 |
| BS-02 | VM Wazuh Manager | Logiciel / Système | VM1, VM3 |
| BS-03 | VM Wazuh Indexer (OpenSearch) | Logiciel / Système | VM2, VM3 |
| BS-04 | VM Wazuh Dashboard | Logiciel / Système | VM3 |
| BS-05 | Contrôleur de domaine Active Directory | Logiciel / Système | VM1, VM2 |
| BS-06 | Postes de travail Windows (agents) | Matériel | VM1 |
| BS-07 | Réseau local (LAN scolaire) | Réseau | VM1 |
| BS-08 | Tunnel Tailscale | Réseau | VM3 |
| BS-09 | Scripts PowerShell (GPO/DPAPI) | Logiciel | VM1, VM3 |
| BS-10 | Sauvegardes (configurations, index) | Données | VM2, VM3 |

### 2.2 Socle de sécurité — Mesures existantes

| Référence | Mesure de sécurité | Statut | Couverture |
|---|---|---|---|
| SEC-01 | Chiffrement des communications agent ↔ manager (TLS 1.2+) | ✅ Implémenté | Confidentialité |
| SEC-02 | Authentification des agents par clé d'enregistrement | ✅ Implémenté | Authentification |
| SEC-03 | Protection des secrets via DPAPI (scripts PowerShell) | ✅ Implémenté | Confidentialité |
| SEC-04 | Administration via tunnel Tailscale (MagicDNS, ACL) | ✅ Implémenté | Confidentialité, Intégrité |
| SEC-05 | GPO de déploiement avec droits restreints | ✅ Implémenté | Intégrité |
| SEC-06 | Journalisation centralisée (Wazuh) | ✅ Implémenté | Traçabilité |
| SEC-07 | Politique de mots de passe Active Directory | ⚠️ Partiel | Authentification |
| SEC-08 | Sauvegardes régulières du Wazuh Manager | ⚠️ Partiel | Disponibilité |
| SEC-09 | Segmentation réseau (VLAN) | ⚠️ Partiel | Confinement |
| SEC-10 | MFA pour l'accès Tailscale admin | ✅ Implémenté | Authentification |
| SEC-11 | Durcissement du serveur Proxmox | ⚠️ Partiel | Intégrité |
| SEC-12 | Mises à jour de sécurité automatisées | ❌ Non implémenté | Intégrité |

### 2.3 Écarts identifiés par rapport au référentiel

Les écarts sont évalués par rapport au **Guide d'Hygiène Informatique de l'ANSSI** (42 mesures) :

| Mesure ANSSI | Écart | Criticité |
|---|---|---|
| Mesure 8 — Identifier chaque personne accédant au SI | Comptes génériques encore présents sur certains postes | Élevée |
| Mesure 15 — Protéger la messagerie | Pas de filtre anti-phishing dédié | Moyenne |
| Mesure 22 — Mettre à jour les composants | Pas de processus formalisé de patch management | Élevée |
| Mesure 34 — Mettre en œuvre un plan de sauvegarde | Sauvegardes non testées régulièrement | Élevée |
| Mesure 36 — Préparer la gestion de crise cyber | Pas de procédure formalisée de réponse à incident | Moyenne |

---

## 3. Atelier 2 — Sources de risques

### 3.1 Identification des sources de risques (SR) et objectifs visés (OV)

| ID | Source de risque | Type | Motivation | Ressources | Pertinence |
|---|---|---|---|---|---|
| SR-01 | Élève curieux / malveillant | Interne | Défi technique, perturbation, triche | Faibles (accès physique, outils en ligne) | Élevée |
| SR-02 | Personnel non sensibilisé | Interne | Non intentionnel (erreur humaine) | Faibles | Élevée |
| SR-03 | Cybercriminel opportuniste | Externe | Gain financier (ransomware, revente de données) | Moyennes (outils automatisés, kits d'exploitation) | Moyenne |
| SR-04 | Hacktiviste | Externe | Idéologique, atteinte à l'image | Moyennes | Faible |
| SR-05 | Ancien employé / prestataire | Externe/Interne | Vengeance, accès résiduel | Moyennes (connaissance du SI) | Moyenne |
| SR-06 | Attaquant avancé (APT) | Externe | Espionnage, données sensibles | Élevées | Très faible |

### 3.2 Couples SR/OV retenus

| Couple | Source de risque | Objectif visé | Niveau de menace |
|---|---|---|---|
| SR-01 / OV-A | Élève malveillant | Perturber le réseau scolaire, accéder à des notes | 3 / 4 |
| SR-02 / OV-B | Personnel non sensibilisé | Compromettre involontairement un poste (phishing) | 3 / 4 |
| SR-03 / OV-C | Cybercriminel opportuniste | Déployer un ransomware, exfiltrer des données élèves | 2 / 4 |
| SR-03 / OV-D | Cybercriminel opportuniste | Compromettre le Wazuh Manager pour masquer ses traces | 2 / 4 |
| SR-05 / OV-E | Ancien employé | Accéder à des données via des comptes non révoqués | 2 / 4 |

---

## 4. Atelier 3 — Scénarios stratégiques

### 4.1 Cartographie des scénarios stratégiques

Les scénarios stratégiques décrivent les chemins d'attaque de haut niveau permettant d'atteindre les objectifs visés.

#### SS-01 — Compromission du réseau scolaire via un poste élève

| Attribut | Description |
|---|---|
| **Source de risque** | SR-01 (Élève malveillant) ou SR-03 (Cybercriminel) |
| **Objectif visé** | Perturbation de la continuité pédagogique (VM1) |
| **Chemin stratégique** | Exploitation d'un poste non durci → mouvement latéral → atteinte de services critiques |
| **Parties prenantes de l'écosystème** | Fournisseur d'accès Internet, éditeurs logiciels |
| **Gravité** | Sérieuse (3/4) |

#### SS-02 — Exfiltration de données personnelles (RGPD)

| Attribut | Description |
|---|---|
| **Source de risque** | SR-03 (Cybercriminel) ou SR-05 (Ancien employé) |
| **Objectif visé** | Vol de données élèves/personnels (VM2) |
| **Chemin stratégique** | Accès à l'AD → extraction de données depuis les applications métier ou les journaux Wazuh |
| **Parties prenantes de l'écosystème** | CNIL, familles, rectorat |
| **Gravité** | Critique (4/4) |

#### SS-03 — Neutralisation du SOC (anti-forensique)

| Attribut | Description |
|---|---|
| **Source de risque** | SR-03 (Cybercriminel) |
| **Objectif visé** | Compromission du Wazuh Manager pour masquer une intrusion (VM3) |
| **Chemin stratégique** | Exploitation d'une vulnérabilité du manager ou du tunnel Tailscale → suppression/altération des journaux |
| **Parties prenantes de l'écosystème** | Hébergeur Proxmox, Tailscale Inc. |
| **Gravité** | Critique (4/4) |

#### SS-04 — Déni de service sur l'infrastructure pédagogique

| Attribut | Description |
|---|---|
| **Source de risque** | SR-01 (Élève) ou SR-04 (Hacktiviste) |
| **Objectif visé** | Rendre les postes ou le réseau indisponibles (VM1, VM4) |
| **Chemin stratégique** | Saturation réseau, boucle de fork via GPO détournée, ou attaque DDoS externe |
| **Parties prenantes de l'écosystème** | FAI, hébergeur |
| **Gravité** | Sérieuse (3/4) |

### 4.2 Matrice de criticité des scénarios stratégiques

| Scénario | Vraisemblance | Gravité | Niveau de risque |
|---|---|---|---|
| SS-01 — Compromission poste élève | Très probable (4/4) | Sérieuse (3/4) | **Élevé** |
| SS-02 — Exfiltration données RGPD | Probable (3/4) | Critique (4/4) | **Élevé** |
| SS-03 — Neutralisation du SOC | Peu probable (2/4) | Critique (4/4) | **Modéré** |
| SS-04 — Déni de service | Probable (3/4) | Sérieuse (3/4) | **Modéré** |

---

## 5. Atelier 4 — Scénarios opérationnels

### 5.1 Scénarios opérationnels détaillés

#### SO-01 — Phishing → Mouvement latéral → Exfiltration

| Étape | Action de l'attaquant | Bien support ciblé | Mesure existante |
|---|---|---|---|
| 1 | Envoi d'un e-mail de phishing à un membre du personnel | Messagerie | Aucune (pas de filtre anti-phishing) |
| 2 | Exécution d'un payload sur le poste compromis | BS-06 (Poste Windows) | Agent Wazuh (détection) |
| 3 | Récupération de credentials AD (Mimikatz, LSASS dump) | BS-05 (Active Directory) | SEC-07 (politique MDP partielle) |
| 4 | Mouvement latéral via PsExec / WMI | BS-06, BS-07 (LAN) | SEC-09 (segmentation partielle) |
| 5 | Accès aux données élèves ou aux journaux Wazuh | BS-03 (Indexer) | SEC-01 (TLS), SEC-06 (journaux) |
| 6 | Exfiltration via HTTPS vers un C2 | BS-07 (Réseau) | Aucune (pas d'IDS sortant) |

**Vraisemblance opérationnelle** : 3/4 — **Difficulté technique** : Moyenne

#### SO-02 — Brute-force / Password Spraying sur Active Directory

| Étape | Action de l'attaquant | Bien support ciblé | Mesure existante |
|---|---|---|---|
| 1 | Énumération des comptes AD (LDAP, enum4linux) | BS-05 (AD) | Aucune spécifique |
| 2 | Attaque par dictionnaire / password spraying | BS-05 (AD) | SEC-07 (politique MDP partielle) |
| 3 | Connexion avec un compte compromis | BS-05, BS-06 | SEC-06 (détection Wazuh) |
| 4 | Élévation de privilèges (Kerberoasting, DCSync) | BS-05 (AD) | Aucune spécifique |

**Vraisemblance opérationnelle** : 3/4 — **Difficulté technique** : Faible à moyenne

#### SO-03 — Compromission du Wazuh Manager via le réseau

| Étape | Action de l'attaquant | Bien support ciblé | Mesure existante |
|---|---|---|---|
| 1 | Reconnaissance du réseau (scan de ports) | BS-07, BS-08 | SEC-04 (Tailscale ACL) |
| 2 | Exploitation d'une CVE sur Wazuh Manager ou OpenSearch | BS-02, BS-03 | SEC-12 (❌ non implémenté) |
| 3 | Accès au serveur Wazuh Manager | BS-02 | SEC-11 (durcissement partiel) |
| 4 | Suppression ou altération des journaux et alertes | BS-03, BS-10 | SEC-08 (sauvegardes partielles) |
| 5 | Persistance via crontab ou service système | BS-02 | SEC-06 (détection Wazuh — mais compromis) |

**Vraisemblance opérationnelle** : 2/4 — **Difficulté technique** : Élevée

#### SO-04 — Détournement des GPO pour déployer du code malveillant

| Étape | Action de l'attaquant | Bien support ciblé | Mesure existante |
|---|---|---|---|
| 1 | Compromission d'un compte avec droits GPO | BS-05 (AD) | SEC-07 |
| 2 | Modification d'une GPO existante ou création d'une nouvelle | BS-09 (Scripts GPO) | SEC-05 (droits restreints) |
| 3 | Déploiement automatique du payload sur tous les postes | BS-06 (Postes) | Agent Wazuh (détection) |
| 4 | Exécution massive (ransomware, cryptominer) | BS-06, BS-07 | SEC-06 (alertes) |

**Vraisemblance opérationnelle** : 2/4 — **Difficulté technique** : Moyenne

#### SO-05 — Exploitation du tunnel Tailscale

| Étape | Action de l'attaquant | Bien support ciblé | Mesure existante |
|---|---|---|---|
| 1 | Compromission du compte Tailscale admin | BS-08 (Tailscale) | SEC-10 (MFA) |
| 2 | Ajout d'un nœud illégitime au réseau Tailscale | BS-08 | ACL Tailscale |
| 3 | Accès direct au Wazuh Manager via le tunnel | BS-02 | SEC-04 |
| 4 | Actions malveillantes sur l'infrastructure SOC | BS-02, BS-03 | SEC-06 |

**Vraisemblance opérationnelle** : 1/4 — **Difficulté technique** : Élevée

### 5.2 Synthèse des scénarios opérationnels

| ID | Scénario opérationnel | Vraisemblance | Difficulté | Lien SS |
|---|---|---|---|---|
| SO-01 | Phishing → Latéral → Exfiltration | 3/4 | Moyenne | SS-01, SS-02 |
| SO-02 | Brute-force Active Directory | 3/4 | Faible | SS-01, SS-02 |
| SO-03 | Compromission Wazuh Manager | 2/4 | Élevée | SS-03 |
| SO-04 | Détournement GPO | 2/4 | Moyenne | SS-01, SS-04 |
| SO-05 | Exploitation Tailscale | 1/4 | Élevée | SS-03 |

---

## 6. Atelier 5 — Traitement des risques

### 6.1 Évaluation des risques bruts et résiduels

L'échelle d'évaluation utilisée est la suivante :

- **Vraisemblance** : 1 (Minime) — 2 (Peu probable) — 3 (Probable) — 4 (Très probable)
- **Impact** : 1 (Négligeable) — 2 (Limité) — 3 (Important) — 4 (Critique)
- **Risque** = Vraisemblance × Impact → Faible (1-4) / Modéré (5-8) / Élevé (9-12) / Critique (13-16)

| ID Risque | Scénario | Vrais. brute | Impact brut | Risque brut | Mesures de traitement | Vrais. résid. | Impact résid. | Risque résiduel |
|---|---|---|---|---|---|---|---|---|
| R-01 | SO-01 — Phishing → Exfiltration | 3 | 4 | **12 (Élevé)** | Filtre anti-phishing, sensibilisation, segmentation VLAN, IDS sortant | 2 | 3 | **6 (Modéré)** |
| R-02 | SO-02 — Brute-force AD | 3 | 3 | **9 (Élevé)** | Politique MDP renforcée, verrouillage de compte, alerte Wazuh spécifique | 1 | 3 | **3 (Faible)** |
| R-03 | SO-03 — Compromission Manager | 2 | 4 | **8 (Modéré)** | Patch management, durcissement Proxmox, sauvegardes hors-ligne, supervision du manager | 1 | 3 | **3 (Faible)** |
| R-04 | SO-04 — Détournement GPO | 2 | 4 | **8 (Modéré)** | Audit des GPO, restriction des droits, alerte sur modification GPO, signature des scripts | 1 | 3 | **3 (Faible)** |
| R-05 | SO-05 — Exploitation Tailscale | 1 | 4 | **4 (Faible)** | MFA renforcé, revue des ACL, monitoring des connexions Tailscale | 1 | 2 | **2 (Faible)** |

### 6.2 Plan de traitement des risques

| ID | Mesure de traitement | Type | Priorité | Responsable | Échéance | Coût estimé |
|---|---|---|---|---|---|---|
| T-01 | Déployer un filtre anti-phishing (passerelle mail) | Réduire | Haute | `<RESPONSABLE_IT>` | T3 2026 | Moyen |
| T-02 | Campagne de sensibilisation du personnel et des élèves | Réduire | Haute | `<RESPONSABLE_IT>` / DPO | T3 2026 | Faible |
| T-03 | Renforcer la politique de mots de passe AD (12 caractères min., complexité, historique) | Réduire | Haute | `<ADMIN_AD>` | T3 2026 | Nul |
| T-04 | Implémenter le verrouillage de compte après 5 tentatives échouées | Réduire | Haute | `<ADMIN_AD>` | T3 2026 | Nul |
| T-05 | Mettre en place un processus de patch management (Wazuh, Proxmox, Windows) | Réduire | Critique | `<RESPONSABLE_IT>` | T3 2026 | Faible |
| T-06 | Finaliser la segmentation VLAN (pédagogie / administration / SOC) | Réduire | Haute | `<ADMIN_RESEAU>` | T4 2026 | Moyen |
| T-07 | Durcir le serveur Proxmox (CIS Benchmark) | Réduire | Moyenne | `<ADMIN_INFRA>` | T4 2026 | Faible |
| T-08 | Mettre en place des sauvegardes automatisées et testées (cf. PCA/PRA) | Réduire | Critique | `<ADMIN_INFRA>` | T3 2026 | Moyen |
| T-09 | Créer des règles Wazuh spécifiques (brute-force, modification GPO, accès Tailscale) | Réduire | Haute | `<ANALYSTE_SOC>` | T3 2026 | Nul |
| T-10 | Formaliser une procédure de réponse à incident | Réduire | Moyenne | `<RESPONSABLE_IT>` | T4 2026 | Faible |
| T-11 | Signer numériquement les scripts PowerShell (GPO) | Réduire | Moyenne | `<ADMIN_AD>` | T4 2026 | Nul |
| T-12 | Souscrire une assurance cyber (transfert de risque) | Transférer | Basse | Direction | T1 2027 | Variable |
| T-13 | Accepter le risque résiduel sur l'exploitation Tailscale (R-05) | Accepter | — | RSSI / Direction | — | — |

### 6.3 Stratégie de traitement par risque

| Risque | Stratégie | Justification |
|---|---|---|
| R-01 | **Réduire** | Risque élevé, mesures techniques et organisationnelles réalisables |
| R-02 | **Réduire** | Risque élevé, mesures simples à implémenter (configuration AD) |
| R-03 | **Réduire** | Impact critique sur le SOC, nécessite un patch management rigoureux |
| R-04 | **Réduire** | Impact critique, mesures de contrôle d'intégrité à renforcer |
| R-05 | **Accepter** | Risque faible après MFA, vraisemblance très basse |

---

## 7. Synthèse et conclusions

### 7.1 Cartographie des risques

```
Impact ↑
  4 │           R-03,R-04     R-01
    │              ●           ●
  3 │                         R-02
    │                          ●
  2 │  R-05
    │   ●
  1 │
    └──────────────────────────────→ Vraisemblance
       1          2          3    4
```

*Légende : ● Risque brut — Après traitement, tous les risques se déplacent vers le quadrant inférieur gauche (risque résiduel ≤ Modéré).*

### 7.2 Indicateurs de suivi

| Indicateur | Fréquence | Cible | Responsable |
|---|---|---|---|
| Nombre de vulnérabilités non patchées (> 30 jours) | Mensuelle | 0 critique | `<RESPONSABLE_IT>` |
| Taux de réussite des campagnes de phishing simulées | Trimestrielle | < 10% | `<RESPONSABLE_IT>` |
| Délai moyen de détection d'un incident (MTTD) | Mensuelle | < 1h | `<ANALYSTE_SOC>` |
| Taux de complétion des sauvegardes | Hebdomadaire | 100% | `<ADMIN_INFRA>` |
| Nombre de comptes AD inactifs (> 90 jours) | Mensuelle | 0 | `<ADMIN_AD>` |

### 7.3 Conclusion

L'analyse EBIOS RM met en évidence **5 risques principaux** dont 2 de niveau élevé (R-01 et R-02) avant traitement. Les mesures de traitement proposées permettent de ramener l'ensemble des risques à un niveau **modéré ou faible**. Les priorités immédiates sont :

1. **Patch management** (T-05) — Critique pour la protection du Wazuh Manager et de l'infrastructure
2. **Sauvegardes automatisées** (T-08) — Garantie de résilience
3. **Sensibilisation** (T-02) — Réduction du facteur humain
4. **Politique de mots de passe** (T-03, T-04) — Protection de l'Active Directory

Le risque résiduel global est jugé **acceptable** sous réserve de la mise en œuvre effective du plan de traitement dans les délais définis.

---

## 8. Annexes

### Annexe A — Échelles EBIOS RM utilisées

| Niveau | Vraisemblance | Impact |
|---|---|---|
| 1 | Minime — Scénario très peu réaliste | Négligeable — Aucune conséquence significative |
| 2 | Peu probable — Scénario possible mais nécessitant des conditions particulières | Limité — Conséquences gérables sans impact durable |
| 3 | Probable — Scénario réaliste avec des conditions réunies | Important — Conséquences significatives nécessitant une intervention |
| 4 | Très probable — Scénario quasi certain ou déjà observé | Critique — Conséquences majeures, atteinte aux missions essentielles |

### Annexe B — Matrice de criticité

|  | Impact 1 | Impact 2 | Impact 3 | Impact 4 |
|---|---|---|---|---|
| **Vrais. 4** | Modéré (4) | Élevé (8) | Élevé (12) | Critique (16) |
| **Vrais. 3** | Faible (3) | Modéré (6) | Élevé (9) | Élevé (12) |
| **Vrais. 2** | Faible (2) | Modéré (4) | Modéré (6) | Élevé (8) |
| **Vrais. 1** | Faible (1) | Faible (2) | Faible (3) | Modéré (4) |

### Annexe C — Références

- **EBIOS Risk Manager** — ANSSI, octobre 2018 : [https://www.ssi.gouv.fr/guide/la-methode-ebios-risk-manager/](https://www.ssi.gouv.fr/guide/la-methode-ebios-risk-manager/)
- **Guide d'hygiène informatique** — ANSSI, 42 mesures : [https://www.ssi.gouv.fr/guide/guide-dhygiene-informatique/](https://www.ssi.gouv.fr/guide/guide-dhygiene-informatique/)
- **RGPD** — Règlement (UE) 2016/679
- **Documentation Wazuh** : [https://documentation.wazuh.com/](https://documentation.wazuh.com/)
- **Tailscale ACL Documentation** : [https://tailscale.com/kb/1018/acls/](https://tailscale.com/kb/1018/acls/)

---

> **Note** : Ce document est hébergé sur un dépôt GitHub public. Toutes les données sensibles (adresses IP, noms, e-mails) sont remplacées par des placeholders `<PLACEHOLDER>`. Avant tout usage opérationnel, ces valeurs doivent être renseignées dans un document classifié séparé.
