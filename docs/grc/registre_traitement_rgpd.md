# Registre de Traitement RGPD

## 1. Introduction
Ce registre décrit les traitements de données personnelles réalisés dans le cadre du projet de SOC scolaire basé sur Wazuh. Il sert de conformité au Règlement Général sur la Protection des Données (RGPD).

## 2. Informations générales
- **Responsable du traitement** : École XYZ (adresse fictive, contact générique)
- **DPO** : Nom [Placeholder], email [dpo@example.com]
- **Finalité du traitement** : Collecte de logs de sécurité, alertes, informations d’inventaire des postes.
- **Base légale** : Intérêt légitime de l’établissement pour assurer la sécurité du réseau et la conformité légale.

## 3. Description des traitements
| N° | Type de données | Source | Destination | Finalité | Durée de conservation |
|---|----------------|--------|--------------|----------|-----------------------|
| 1 | Adresse IP, identifiant de l’appareil, logs d’audit | Poste client | Serveur Wazuh Manager | Détection d’incidents, audit de conformité | 12 mois (ou jusqu’à la fin du projet) |
| 2 | Identifiants utilisateurs (nom d’utilisateur AD) | Active Directory | Wazuh | Enrichissement des événements | 12 mois |
| 3 | Données de connexion VPN (Tailscale) | Client VPN | Serveur de log | Analyse de trafic, détection d’anomalies | 6 mois |

## 4. Mesures de sécurité
- Chiffrement des logs en transit via TLS.
- Stockage des logs sur serveur dédié, accès restreint aux administrateurs.
- Utilisation de DPAPI pour protéger les mots‑de‑passe des scripts de déploiement.
- Anonymisation des adresses IP dans les rapports publics.

## 5. Droits des personnes concernées
- Accès, rectification, suppression sur demande via le DPO.
- Procédure de réponse aux demandes disponible dans le **Plan de Réponse aux Incidents**.

## 6. Contacts
- **Délégué à la protection des données** : [Placeholder] – dpo@example.com
- **Responsable Sécurité** : [Placeholder] – security@example.com

*Toutes les informations spécifiques à l’établissement sont remplacées par des placeholders afin de ne pas publier de données sensibles.*
