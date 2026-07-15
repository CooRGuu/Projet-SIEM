# Audit de conformité réglementaire — Projet SOC Wazuh

> [!IMPORTANT]
> Ce rapport a été généré en analysant 18 fichiers du projet (rapport, scripts, playbooks Ansible, politiques GRC, règles de détection, registre RGPD, PCA/PRA, etc.)

---

## Précision importante : SOC 1 vs SOC 2

Attention à ne pas confondre SOC 1 et SOC 2 :
- **SOC 1 (SSAE 18)** concerne les contrôles sur les rapports financiers (comptabilité). Ça n'a rien à voir avec un projet SIEM.
- **SOC 2 Type II** concerne les contrôles de sécurité, disponibilité et confidentialité — c'est celui qui s'applique ici.

> [!TIP]
> En soutenance, si vous citez « SOC », dites SOC 2 et non SOC 1. Un jury vous corrigera immédiatement si vous confondez les deux.

---

## Synthèse globale

| Référentiel | Couvert | Partiel | Non couvert | Taux estimé |
|-------------|:-------:|:-------:|:-----------:|:----------------:|
| ISO 27001:2022 (93 contrôles Annexe A) | ~30 | ~7 | ~40+ | ~32% |
| NIS 2 (Art. 21 & 23) | 6 | 6 | 2 | ~55% |
| SOC 2 Type II (TSC) | ~18 | ~7 | ~4 | ~65% |
| ANSSI Hygiène (42 mesures) | ~10 | ~8 | ~24 | ~24% |
| CIS Controls v8 (18 groupes) | 14 | 7 | ~9 | ~50% |
| RGPD (articles pertinents) | 10 | 5 | 1-2 | ~75% |
| NIST CSF 2.0 (6 fonctions) | 5 | 1 | 0 | ~75% |

---

## Points forts du projet

Les éléments ci-dessous sont bien couverts et constituent les arguments les plus solides en soutenance :

| Domaine | Preuves dans le projet | Référentiels satisfaits |
|---------|----------------------|------------------------|
| Journalisation & monitoring | Wazuh SIEM centralisé, 8 règles custom, 20 KPIs opérationnels | ISO A.8.15-16, NIST DE, SOC 2 CC7, CIS 8, ANSSI R15/R33 |
| Gestion des accès (IAM) | Politique IAM de 533 lignes, RBAC, MFA, PAM, break-glass | ISO A.5.15-18, A.8.2-5, NIS2 Art.21§2(i) |
| Continuité d'activité | PCA/PRA de 492 lignes, RPO/RTO, 5 scénarios de sinistre | ISO A.5.29-30, NIST RC, NIS2 Art.21§2(c) |
| Analyse de risques | EBIOS RM complète (5 ateliers, 5 risques, 13 mesures) | ISO A.5.8, NIST ID.RA, SOC 2 CC3 |
| Gestion des changements | Procédure ITIL v4, workflow Git, PR/revue de code | ISO A.8.32, SOC 2 CC8.1, CIS 4 |
| Chiffrement | TLS 1.2+, DPAPI AES-256, Ansible Vault, WireGuard | ISO A.8.24, NIS2 Art.21§2(h), NIST PR.DS |

---

## Détail par référentiel

### 1. ISO/IEC 27001:2022 — Annexe A (~32%)

#### Contrôles couverts (30)

| Contrôle | Intitulé | Preuve |
|----------|---------|--------|
| A.5.1 | Politiques de sécurité | PSSI journalisation, charte admin SOC, politique IAM |
| A.5.2 | Rôles et responsabilités | Matrice RACI (31 activités, 6 rôles) |
| A.5.8 | Sécurité dans la gestion de projet | EBIOS RM réalisée pendant le projet |
| A.5.9 | Inventaire des actifs | Enrôlement Wazuh = inventaire automatisé ; EBIOS liste 10 biens supports |
| A.5.15-18 | Contrôle d'accès, identité, authentification, droits | Politique IAM complète (RBAC, cycle de vie, MFA) |
| A.5.24-26 | Gestion des incidents | Plan de réponse en 7 étapes aligné NIST |
| A.5.28 | Collecte de preuves | Logs centralisés horodatés, intégrité HMAC SHA-256 |
| A.5.29-30 | Continuité, tests de reprise | PCA/PRA avec 5 scénarios, calendrier de tests |
| A.5.37 | Procédures d'exploitation documentées | Playbook Ansible, guide GPO, procédure de changement |
| A.8.1 | Équipements utilisateurs | Agents Wazuh déployés via GPO, SCA CIS |
| A.8.8-9 | Vulnérabilités, configuration | Module SCA, Ansible IaC, gestion des changements |
| A.8.13 | Sauvegardes | Cron quotidien 02h00, rétention 14j, règle 3-2-1 |
| A.8.15-16 | Journalisation, surveillance | SIEM Wazuh, règles custom, dashboards, KPIs |
| A.8.20 | Sécurité réseau | UFW deny-all, Tailscale WireGuard |
| A.8.24-25 | Cryptographie, cycle de développement sécurisé | TLS, DPAPI, audit DevSecOps, Git workflow |
| A.8.28 | Codage sécurisé | Scripts durcis (DPAPI, SHA-256, ACL, idempotence) |

#### Contrôles partiellement couverts (7)

| Contrôle | Intitulé | Lacune |
|----------|---------|--------|
| A.5.10 | Utilisation acceptable des actifs | Charte SOC pour admins uniquement, pas pour les utilisateurs finaux |
| A.5.36 | Conformité aux politiques | Auto-évaluation réalisée mais pas d'audit indépendant |
| A.6.3 | Sensibilisation et formation | Formation mensuelle mentionnée sans preuves |
| A.8.7 | Protection contre les malwares | FIM et règles de détection mais pas d'anti-malware dédié |
| A.5.7 | Renseignement sur les menaces | Mapping MITRE ATT&CK mais pas de flux de threat intelligence |
| A.5.14 | Transfert d'informations | TLS agent→manager mais pas de politique formelle de transfert |
| A.8.23 | Filtrage web | Non adressé |

#### Contrôles non couverts (~40+)

Les lacunes les plus significatives :
- A.5.12-13 — Classification et étiquetage de l'information
- A.5.19-22 — Sécurité des fournisseurs et supply chain
- A.6.1-2, A.6.6 — Vérification des antécédents, accords de confidentialité
- A.7.1-7.14 — Sécurité physique (aucun contrôle documenté)
- A.8.10-12 — Suppression des données, masquage, prévention des fuites (DLP)
- A.8.17 — Synchronisation d'horloge (NTP)
- A.8.22 — Segmentation réseau (VLANs marqués « partiels »)

---

### 2. NIS 2 — Directive (UE) 2022/2555 (~55%)

#### Article 21 — Mesures de gestion des risques

| Sous-article | Exigence | Statut | Preuve |
|-------------|----------|:------:|--------|
| 21§2(a) | Politiques d'analyse des risques et de sécurité SI | Couvert | EBIOS RM, PSSI, IAM, charte |
| 21§2(b) | Gestion des incidents | Couvert | Plan IR 7 étapes, PCA/PRA |
| 21§2(c) | Continuité, sauvegardes, reprise | Couvert | PCA/PRA, politique de sauvegarde 3-2-1 |
| 21§2(d) | Sécurité de la chaîne d'approvisionnement | Partiel | Vérification SHA-256 du MSI mais pas de gestion supply chain globale |
| 21§2(e) | Sécurité dans l'acquisition et développement, gestion des vulnérabilités | Partiel | Ansible IaC, SCA mais pas de patch management formel |
| 21§2(f) | Évaluation de l'efficacité des mesures | Couvert | 20 KPIs, calendrier de tests PCA/PRA, playbooks Red Team |
| 21§2(g) | Pratiques de cyberhygiène et formation | Partiel | CIS benchmarks via SCA ; formation mentionnée mais non prouvée |
| 21§2(h) | Cryptographie et chiffrement | Couvert | TLS 1.2+, DPAPI AES-256, Ansible Vault, WireGuard |
| 21§2(i) | Sécurité RH, contrôle d'accès, gestion des actifs | Couvert | Politique IAM, RBAC, cycle de vie comptes, inventaire agents |
| 21§2(j) | Authentification multi-facteur, communications sécurisées | Partiel | MFA pour Tailscale/Proxmox mais pas pour le Dashboard Wazuh |

#### Article 23 — Obligations de signalement

| Sous-article | Exigence | Statut |
|-------------|----------|:------:|
| 23§4(a) | Alerte précoce sous 24h | Partiel (timings définis mais mappés CNIL, pas CSIRT NIS2) |
| 23§4(b) | Notification d'incident sous 72h | Partiel (72h mentionné pour la CNIL, adaptable) |
| 23§4(c) | Rapport intermédiaire | Non couvert |
| 23§4(d) | Rapport final sous 1 mois | Non couvert |

---

### 3. SOC 2 Type II (~65%)

| Critère | Exigence | Statut |
|---------|----------|:------:|
| CC3 (Évaluation des risques) | Analyse de risques, traitement | Couvert — EBIOS RM |
| CC4 (Activités de surveillance) | Monitoring continu | Couvert — Wazuh SIEM, 20 KPIs |
| CC5 (Activités de contrôle) | Gestion des changements | Couvert — ITIL v4, Git |
| CC6.1 (Accès logique et physique) | Contrôles d'accès | Partiel — logique couvert, physique non |
| CC6.2-6.6 (Identité, RBAC) | Gestion des identités | Couvert — IAM, RBAC, cycle de vie |
| CC7.1-7.4 (Détection, réponse) | Monitoring, incidents | Couvert — règles custom, IR plan |
| CC8.1 (Gestion des changements) | Changements autorisés | Couvert — RFC, CAB, PIR |
| CC9.2 (Risques fournisseurs) | Gestion tiers | Non couvert |
| A1 (Disponibilité) | Infrastructure, reprise | Couvert — PCA/PRA, Ansible |
| C1 (Confidentialité) | Classification, suppression | Partiel — registre RGPD mais pas de classification formelle |

---

### 4. ANSSI Guide d'hygiène (~24%)

**Couvertes :** R3 (droits), R9 (moindre privilège), R10 (mots de passe), R15 (journalisation), R16 (mots de passe stockés), R26 (conformité logicielle), R33 (centralisation), R34 (admin sécurisée), R37 (sauvegardes), R40 (exercices de crise)

**Partielles :** R1 (sensibilisation), R2 (formation), R4 (données sensibles), R8 (identification nominative), R14 (périphériques amovibles), R22 (mises à jour), R25 (réseau interne), R36 (gestion de crise)

**Non couvertes :** R5 (schéma réseau formel), R7 (certificats), R11 (protocoles sécurisés — certificats auto-signés), R17-R21, R23 (durcissement serveurs Proxmox), R27-R32 (mail, web, DNS), R39 (audits indépendants), R42 (filtrage web)

---

### 5. CIS Controls v8 (~50%)

14 contrôles couverts : CIS 1 (inventaire), 2.5 (SHA-256), 3.10 (chiffrement transit), 4.1 (configuration sécurisée), 6.8 (RBAC), 8.2/8.5/8.9/8.11/8.12 (logs), 11.1/11.2/11.4 (sauvegarde), 17.4 (incidents)

7 partiels : CIS 2.1, 3.3, 4.2, 5, 7, 13, 14

~9 groupes non couverts : CIS 9 (email/web), 10 (malware), 12 (infra réseau), 15 (fournisseurs), 16 (sécurité applicative), 18 (pentest)

---

### 6. RGPD (~75%)

Bien couvert : Art. 5.1 (principes), Art. 6 (base légale = intérêt légitime), Art. 24-25 (responsabilité, privacy by design), Art. 30 (registre des traitements), Art. 32 (sécurité), Art. 33 (notification CNIL <72h)

Partiel : Art. 12-14 (information des personnes), Art. 15-22 (droits des personnes), Art. 28 (sous-traitant — Tailscale Inc.), Art. 35 (PIA/DPIA)

---

### 7. NIST CSF 2.0 (~75%)

| Fonction | Statut | Commentaire |
|----------|:------:|-------------|
| IDENTIFY | Couvert | EBIOS RM, inventaire des actifs |
| PROTECT | Couvert | IAM, chiffrement, SCA, sauvegardes |
| DETECT | Couvert | Wazuh SIEM, règles custom, MITRE ATT&CK |
| RESPOND | Couvert | Plan IR 7 étapes, matrice de communication |
| RECOVER | Couvert | 5 PRAs détaillés, tests planifiés |
| GOVERN | Partiel | Politiques existantes mais gouvernance légère |

---

## Top 5 des lacunes à adresser

| # | Lacune | Référentiels impactés |
|---|--------|----------------------|
| 1 | Gestion des correctifs (Patch Management) — marqué non implémenté dans l'EBIOS RM (SEC-12) | ISO A.8.8, CIS 7, ANSSI R22, NIS2 Art.21§2(e) |
| 2 | Sécurité physique — aucun contrôle documenté (salle serveur, accès physique) | ISO A.7.1-7.14, SOC 2 CC6.1 |
| 3 | Segmentation réseau — VLANs marqués « partiels » (SEC-09) | ISO A.8.22, CIS 12, ANSSI R25 |
| 4 | Classification des données — pas de schéma formel | ISO A.5.12-13, ANSSI R4/R13 |
| 5 | Gestion des risques fournisseurs — aucune politique | ISO A.5.19-22, CIS 15, SOC 2 CC9.2 |

> [!NOTE]
> Ces lacunes sont normales et attendues pour un projet académique déployé sur un périmètre de staging. Un SOC de production nécessiterait 12 à 18 mois supplémentaires pour atteindre une couverture ISO 27001 complète. Le travail réalisé ici couvre les piliers principaux (détection, accès, continuité, risques) de manière solide pour un projet de fin d'études.

---

## Verdict final

> Le projet ne peut pas prétendre être « conforme ISO 27001 » ou « conforme NIS 2 » — la conformité implique un audit formel par un organisme accrédité. En revanche, le projet s'aligne fortement sur les exigences de ces référentiels, et le travail de documentation GRC est très complet pour un projet académique.

**Formulation recommandée en soutenance :**

> *« Ce projet s'inscrit dans une démarche d'alignement avec les référentiels ISO 27001, NIS 2, NIST CSF et les recommandations de l'ANSSI. Sans prétendre à une certification formelle, il implémente les contrôles de détection, de gestion des accès, de continuité d'activité et de gouvernance des risques exigés par ces standards. »*
