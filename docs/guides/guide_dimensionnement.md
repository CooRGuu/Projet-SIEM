# Guide de Dimensionnement et Prérequis Matériels (Sizing Guide)

Ce guide est destiné à l'équipe d'architecture et de production informatique (équipe ProxFibre / Réseau). Il permet de planifier les ressources nécessaires à l'hébergement du serveur SIEM Wazuh en fonction de l'évolution du parc informatique supervisé.

## 1. Principes de Dimensionnement
L'architecture proposée par défaut dans ce package est de type **All-in-One (AIO)** : le serveur centralise le Wazuh Manager, le moteur d'indexation (OpenSearch) et l'interface Web (Dashboard).

Les ressources matérielles requises dépendent directement de trois facteurs :
1. **Le nombre d'agents déployés** (volumétrie des événements).
2. **Le type d'équipement supervisé** (un serveur de base de données génère beaucoup plus de logs qu'un poste étudiant).
3. **La politique de rétention à chaud** (le nombre de jours pendant lesquels les logs restent interrogeables via l'interface).

---

## 2. Recommandations Matérielles (Architecture All-in-One)

Voici les gabarits (T-Shirt sizing) recommandés pour la Machine Virtuelle sous **Proxmox** :

| Taille | Nombre d'Agents cibles | CPU (vCores) | Mémoire (RAM) | Stockage (Disque OS + Logs) |
|---|---|---|---|---|
| **POC / Labo** | 1 à 25 | 4 vCores | 8 Go | 100 Go (SSD) |
| **Small (Taille cible)** | 25 à 100 | 8 vCores | 16 Go | 250 Go (SSD ou NVMe) |
| **Medium** | 100 à 500 | 16 vCores | 32 Go | 500 Go à 1 To (NVMe) |
| **Large** | > 500 | *Voir §4 (Architecture Distribuée)* | - | - |

> [!WARNING] 
> **Important :** L'utilisation de disques SSD (ou NVMe) est **obligatoire** pour le moteur d'indexation OpenSearch. L'utilisation de disques HDD mécaniques entraînera des timeouts lors des recherches dans le dashboard et des pertes d'événements.

---

## 3. Calcul du Stockage (Politique de Rétention)

Le volume de logs généré est variable, mais pour les postes Windows avec Sysmon (ce qui est configuré par défaut dans le package), on observe la métrique moyenne suivante :
* **Un agent génère entre 2 et 3 Mo de logs indexés par jour.**

### Formule de calcul d'espace disque :
`Espace Requis = (Nombre d'Agents × 3 Mo) × Rétention (en jours) + 50 Go (OS et buffer)`

**Exemple concret pour l'école :**
- Déploiement sur 150 postes (TP + Administration).
- Rétention souhaitée : 90 jours.
- Calcul : `(150 × 3 Mo) × 90 = 40 500 Mo` (soit ~40 Go purs d'index).
- Prévision matérielle avec marge : Allouer un disque de **100 Go**.

---

## 4. Évolutivité (Au-delà de 500 agents)

Si l'école décide d'étendre la supervision à plusieurs campus ou au Wi-Fi public, dépassant ainsi la barre des 500 agents, l'architecture "All-in-One" atteindra ses limites (notamment au niveau de la RAM consommée par OpenSearch).

Le package Ansible est conçu pour permettre une migration vers une **Architecture Distribuée** :
1. **Un serveur dédié Wazuh Manager** (qui réceptionne les logs et évalue les règles).
2. **Un cluster de 3 nœuds OpenSearch** (pour la haute disponibilité et la scalabilité de l'indexation).

*Il suffira de modifier l'inventaire Ansible pour séparer ces rôles sur plusieurs IPs.*
