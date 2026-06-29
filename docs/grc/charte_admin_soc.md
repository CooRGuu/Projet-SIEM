# Charte d'Administration et d'Analyse du SOC

## 1. Objectif
Définir les principes, responsabilités et processus d’administration et d’analyse du Security Operations Center (SOC) mis en place dans le cadre du projet scolaire basé sur Wazuh.

## 2. Champ d'application
Cette charte s’applique à :
- Tous les administrateurs système et réseaux impliqués dans le déploiement et la maintenance des agents Wazuh.
- Les analystes SOC qui effectuent l’analyse des alertes et la production de rapports.
- Le personnel du laboratoire informatique qui utilise le tunnel Tailscale pour accéder aux serveurs.

## 3. Principes fondamentaux
| Principe | Description |
|----------|-------------|
| **Confidentialité** | Les données de logs sont considérées comme sensibles et sont protégées en transit (TLS) et au repos (chiffrement). |
| **Intégrité** | Toute modification des configurations SOC doit être versionnée (Git) et approuvée via une PR. |
| **Disponibilité** | Les services critiques (Wazuh Manager, tunnel Tailscale) doivent être redondants ou disposés à un plan de continuité. |
| **Traçabilité** | Toutes les actions d’administration sont consignées dans le journal d’audit (EventLog). |

## 4. Rôles et responsabilités
| Rôle | Responsable | Tâches principales |
|------|------------|-------------------|
| **Responsable SOC** | [Placeholder] | Supervision globale, validation des incidents, coordination avec le DPO. |
| **Administrateur Wazuh** | [Placeholder] | Déploiement des agents via GPO, mise à jour des règles, gestion du manager. |
| **Analyste SOC** | [Placeholder] | Analyse des alertes, enrichissement contextuel, rédaction des rapports d’incident. |
| **Administrateur Réseau** | [Placeholder] | Gestion du tunnel Tailscale, firewall, segmentation réseau. |
| **DPO** | [Placeholder] | Vérification de la conformité RGPD, réponses aux demandes d’accès. |

## 5. Processus d’administration
1. **Gestion de la configuration** – Tous les changements sont codés dans des scripts PowerShell ou Ansible et placés sous contrôle de version.
2. **Revue de configuration** – Une revue de code (pull‑request) est obligatoire avant le merge sur `main`.
3. **Déploiement** – Utilisation de GPO pour pousser le script `Deploy‑WazuhAgent.ps1` sur les postes.
4. **Monitoring** – Le script `wazuh-health-monitor.sh` surveille l’état du manager et envoie des alertes.
5. **Gestion des incidents** – Se référer au **Plan de Réponse aux Incidents**.

## 6. Processus d’analyse
- **Collecte** – Les logs sont automatiquement centralisés dans le manager.
- **Enrichissement** – Les identifiants AD sont corrélés via les inventaires.
- **Détection** – Règles Wazuh custom (voir `custom_wazuh_rules.xml`).
- **Reporting** – Dashboard Wazuh, rapports automatisés (script `generate_report.ps1`).

## 7. Sécurité des accès
- Authentification forte via AD et DPAPI pour les mots‑de‑passe.
- Accès au manager limité aux comptes du groupe `SOC_Admins`.
- Utilisation du tunnel Tailscale pour les accès distants, avec authentification à deux facteurs.

## 8. Formation et Sensibilisation
- Sessions mensuelles de formation sur les bonnes pratiques SOC.
- Documentation mise à jour dans le répertoire `docs/` du repository.

## 9. Révision de la Charte
- Revue annuelle par le Responsable SOC et le DPO.
- Mise à jour en fonction des évolutions du projet ou des exigences légales.

*Toutes les informations identifiantes sont remplacées par des placeholders afin de préserver la confidentialité du repository public.*
