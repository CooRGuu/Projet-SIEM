# Politique de Sauvegarde et Restauration

## 1. Objectif
Ce document définit la stratégie, les procédures et les responsabilités liées à la sauvegarde et à la restauration des composants du SOC scolaire basé sur Wazuh. L'objectif est de garantir la disponibilité et l'intégrité des données en cas d'incident (panne matérielle, corruption, cyberattaque).

## 2. Périmètre
Les composants couverts par cette politique sont :
- **Wazuh Manager** (configurations, règles personnalisées, certificats)
- **Elasticsearch / Indexer** (données de journalisation, alertes, tableaux de bord)
- **Playbooks Ansible** (utilisés pour le déploiement de l'infrastructure)
- **Scripts PowerShell** (utilisés pour le déploiement GPO)
- **Configurations Tailscale** (règles ACL si gérées localement)

## 3. Stratégie de Sauvegarde (Règle 3-2-1)
Le projet applique le principe de la règle 3-2-1 :
- **3 copies** des données (1 en production, 2 sauvegardes).
- **2 supports différents** (stockage local sur le serveur de backup, et NAS distant).
- **1 copie hors site** (réplication chiffrée sur un espace cloud ou serveur de secours externe).

## 4. Types et Fréquences de Sauvegarde

| Composant | Type de Sauvegarde | Fréquence | Rétention | Support de Destination |
|-----------|--------------------|-----------|-----------|------------------------|
| Scripts & Playbooks (Git) | Complète (Commit/Push) | Quotidienne (si modif) | Infinie | GitHub (Cloud) |
| Elasticsearch Indexer | Snapshots incrémentaux | Quotidienne | 3 mois | NAS Local / NFS |
| Wazuh Manager (Config) | Complète (archive tar.gz) | Hebdomadaire | 1 an | NAS Local -> Cloud |
| Proxmox VM (Wazuh) | Snapshot complet (VM) | Hebdomadaire | 4 semaines | Datastore Proxmox |

## 5. Procédures de Sauvegarde

### 5.1. Sauvegarde des configurations Wazuh
La configuration de Wazuh, située dans `/var/ossec/etc/`, doit être sauvegardée régulièrement. Un script cron est mis en place pour archiver ce dossier.
\`\`\`bash
tar -czf /backups/wazuh/wazuh_config_$(date +%F).tar.gz /var/ossec/etc /var/ossec/ruleset/user
\`\`\`

### 5.2. Snapshots Elasticsearch / OpenSearch
La création de snapshots pour les données d'indexation est configurée via l'API, nécessitant l'enregistrement préalable d'un dépôt de sauvegarde (repository type `fs` pointant vers le NAS).

## 6. Procédures de Restauration

### 6.1. Restauration d'un fichier de configuration
1. Identifier la dernière archive de configuration valide.
2. Extraire l'archive : `tar -xzf wazuh_config_DATE.tar.gz -C /tmp/`
3. Remplacer les fichiers corrompus dans `/var/ossec/etc/` ou `/var/ossec/ruleset/user/`.
4. Redémarrer le service Wazuh Manager : `systemctl restart wazuh-manager`.

### 6.2. Restauration des données d'indexation
1. Vérifier l'état du cluster.
2. Utiliser l'API de snapshot pour restaurer un index spécifique ou l'ensemble des données depuis le dépôt NAS.

### 6.3. Restauration complète de la VM (PCA)
En cas de perte totale du serveur Proxmox, restaurer le dernier snapshot complet de la VM depuis le datastore de backup Proxmox.

## 7. Tests de Restauration
Des tests de restauration doivent être effectués **trimestriellement** par l'Administrateur SOC.
- **Critères de succès :** Temps de restauration inférieur au RTO défini (voir PCA/PRA), intégrité des données validée, reprise de la collecte des logs des agents.
- Les résultats des tests doivent être consignés dans un journal de maintenance.

## 8. Chiffrement et Sécurité
Toutes les sauvegardes externalisées (hors site/cloud) doivent être chiffrées au repos (AES-256) pour garantir la confidentialité des logs et configurations. Les accès aux dépôts de sauvegarde sont restreints selon le principe du moindre privilège.

## 9. Responsabilités
- **Administrateur SOC ([Placeholder])** : Configuration, supervision et tests des sauvegardes.
- **Administrateur Réseau ([Placeholder])** : Mise à disposition et supervision de l'espace NAS et des transferts réseau.

*Document à intégrer dans le processus de gestion documentaire du projet SOC.*
