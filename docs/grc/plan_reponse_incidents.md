# Plan de Réponse aux Incidents (Playbook)

## 1. Objectif
Définir les étapes à suivre pour détecter, analyser, contenir, éradiquer et récupérer suite à un incident de sécurité au sein du SOC scolaire utilisant Wazuh.

## 2. Portée
Tous les incidents affectant les postes clients, le serveur Wazuh Manager, le réseau interne et les tunnels Tailscale.

## 3. Rôles et responsabilités
| Rôle | Responsable | Contact | Description |
|------|-------------|---------|-------------|
| **Responsable SOC** | [Placeholder] | soc_lead@example.com | Coordination globale de la réponse. |
| **Analyste SOC** | [Placeholder] | analyst@example.com | Analyse des alertes, enrichissement des événements. |
| **Administrateur AD** | [Placeholder] | adadmin@example.com | Gestion des comptes, isolation des postes. |
| **Responsable Sécurité Réseau** | [Placeholder] | netsec@example.com | Gestion du tunnel Tailscale, firewall. |
| **DPO** | [Placeholder] | dpo@example.com | Gestion des données personnelles lors de l’incident. |

## 4. Processus de réponse
1. **Détection** – Alertes générées par Wazuh (rule IDs, syslog, etc.).
2. **Qualification** – Vérification du niveau de sévérité (Low/Medium/High/Critical).
3. **Notification** – Envoi d’un ticket dans le système de suivi (ex. GitHub Issues) et alerte au Responsable SOC.
4. **Confinement** – 
   - Isolement du poste via GPO (désactivation de l’accès réseau). 
   - Blocage du tunnel Tailscale si compromise.
5. **Analyse** – Collecte de logs détaillés, exécution de scripts d’investigation (`scripts/windows/Collect-IncidentData.ps1`).
6. **Eradication** – Suppression du malware, remise à zéro du compte compromis, rotation des mots‑de‑passe (scripts `Rotate-WazuhApiPassword.ps1`).
7. **Récupération** – Réintégration du poste dans le domaine, re‑déploiement de l’agent Wazuh si nécessaire.
8. **Clôture** – Documentation de l’incident, mise à jour du registre d’incidents, recommandations d’amélioration.

## 5. Communication
- **Interne** : Slack channel `#soc-incidents`, e‑mail résumé quotidien.
- **Externe** : Notification aux autorités compétentes si données personnelles compromises (DPO coordonne).

## 6. Outils
- Wazuh Manager & Dashboard
- PowerShell scripts (déploiement, collecte)
- Tailscale admin console
- GitHub Issues pour le suivi

## 7. Reporting & Amélioration Continue
- Revue post‑incident mensuelle.
- Mise à jour du Playbook et des règles Wazuh.
- Formation du personnel sur les nouvelles menaces.

*Toutes les informations spécifiques (noms, contacts, adresses) sont remplacées par des placeholders afin de préserver la confidentialité.*
