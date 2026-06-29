# Politique de Sécurité (PSSI) – Section Journalisation & Audit

## 1. Objectif
Définir les exigences de journalisation et d’audit nécessaires pour assurer la traçabilité, la détection d’incidents et la conformité aux référentiels (ISO 27001, RGPD) dans le cadre du SOC scolaire basé sur Wazuh.

## 2. Champ d'application
Cette section s’applique à :
- Tous les serveurs du réseau scolaire (Wazuh Manager, serveurs de fichiers, contrôleurs AD).
- Tous les postes clients Windows déployés dans le laboratoire.
- Le tunnel d’accès distant Tailscale.

## 3. Principes de journalisation
| Principe | Exigence |
|----------|----------|
| **Intégrité** | Les journaux sont signés avec HMAC SHA‑256 et stockés sur un serveur dédié en écriture seule. |
| **Confidentialité** | Chiffrement TLS en transit et chiffrement au repos (AES‑256). |
| **Disponibilité** | Rétention minimum de 30 jours, sauvegarde quotidienne, réplication hors site. |
| **Traçabilité** | Chaque événement doit comporter un horodatage (UTC), l’identifiant de l’appareil, le compte utilisateur, et le code de règle Wazuh. |
| **Limitation d’accès** | Accès en lecture seule aux membres du groupe `SOC_Admins`; accès en écriture limité au `Wazuh_Manager` et aux scripts de collecte via DPAPI. |

## 4. Types de journaux à collecter
1. **Journaux systèmes Windows** – EventLog (Security, System, Application).
2. **Journaux d’audit AD** – Modifications de comptes, changements de groupes.
3. **Journaux Wazuh** – Alertes, métriques d’intégrité, résultats d’analyse.
4. **Journaux du tunnel Tailscale** – Connexions, adresses IP, durée de session.
5. **Journaux d’accès aux fichiers** – Partages réseau critiques (audit de SMB).

## 5. Processus de collecte
- **Agents** : Le script `Deploy-WazuhAgent.ps1` configure les agents pour envoyer les logs au manager via TLS.
- **Configuration** : Fichier `ossec.conf` indique les modules d’audit (`<localfile>` sections) correspondant aux types de journaux ci‑dessus.
- **Intégrité** : Le manager applique des règles de validation de la signature des journaux.

## 6. Rétention et archivage
| Type de journal | Durée de rétention | Méthode d’archivage |
|----------------|--------------------|--------------------|
| Logs Wazuh (alertes) | 12 mois | Stockage dans Elasticsearch, snapshots quotidiens. |
| EventLog Windows | 12 mois | Export vers fichier .evtx compressé, sauvegarde sur serveur de logs. |
| Tailscale logs | 6 mois | Export CSV, sauvegarde sur stockage cloud chiffré. |

## 7. Analyse et corrélation
- Utilisation de **Wazuh Rules** personnalisées (`custom_wazuh_rules.xml`) pour identifier les comportements suspects.
- Tableaux de bord Kibana pour visualiser les tendances et détecter les anomalies.
- Scripts de corrélation (`scripts/windows/Correlate-Logs.ps1`) exécutés weekly pour produire des rapports d’audit.

## 8. Reporting et revue
- **Rapport quotidien** : Envoi automatisé d’un résumé d’incidents au canal Slack `#soc‑incidents`.
- **Rapport mensuel** : Export PDF du tableau de bord d’audit, stocké dans le dépôt `docs/audit/`.
- **Revue trimestrielle** : Audit de conformité ISO 27001 mené par le Responsable Sécurité, avec mise à jour du PSSI.

## 9. Gestion des incidents liés aux logs
- **Compromission de journal** – Isolation immédiate du serveur concerné, analyse de l’intégrité, restauration depuis backup.
- **Perte de logs** – Déclenchement d’un ticket d’incident, enquête selon le **Plan de Réponse aux Incidents**.

## 10. Conformité et références légales
- **ISO 27001** – Clause A.12.4 (Journalisation) et A.18.1 (Conformité légale).
- **RGPD** – Article 30 (Registre des activités de traitement) – logs comme preuve de conformité.
- **NIS 2** – Obligations de détection et de notification d’incidents.

## 11. Révision de la politique
- Revue annuelle par le Responsable SOC et le DPO.
- Mise à jour en fonction des nouvelles exigences légales ou techniques.

*Toutes les informations spécifiques (noms, contacts, adresses) sont remplacées par des placeholders afin de préserver la confidentialité du repository public.*
