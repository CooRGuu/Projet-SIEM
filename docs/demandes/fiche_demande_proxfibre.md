# 📋 Fiche de Demande – Administrateurs ProxFibre (Proxmox)

**Projet :** Infrastructure SOC – Déploiement SIEM Wazuh  
**Demandeur :** Corentin  
**Date :** 26 juin 2026  
**Priorité :** Haute  
**Statut :** En attente de validation  

---

## 1. Contexte du projet

Dans le cadre de mon stage de Master, je mets en place une infrastructure **SOC (Security Operations Center)** basée sur le SIEM **Wazuh**. L'objectif est de superviser en temps réel les postes du réseau de l'école (logs Windows, conformité CIS, détection d'intrusions).

L'infrastructure repose sur **deux machines virtuelles** hébergées sur la plateforme **ProxFibre (Proxmox)** que vous administrez.

---

## 2. Inventaire des VM existantes

| VM | OS | IP (Tailscale) | Rôle | vCPU | RAM | Disque |
|----|----|-----------------|------|------|-----|--------|
| `wazuh-manager` | Ubuntu 22.04 LTS | 100.65.111.9 | Wazuh Manager + API + Dashboard | 4 | 8 Go | 50 Go |
| `siem-server` | Ubuntu 22.04 LTS | *(à confirmer)* | Elasticsearch / OpenSearch | 4 | 16 Go | 100 Go |

> **Note :** Si les ressources actuelles sont inférieures à ce tableau, merci de me le signaler pour que j'adapte ma configuration (réduction de la rétention des logs, etc.).

---

## 3. Demandes de configuration

### 3.1 Snapshots / Sauvegardes automatiques

| Demande | Détail |
|---------|--------|
| **Snapshot quotidien** des deux VM | Planification à **02h00** (heure creuse), rétention de **7 jours glissants**. |
| **Snapshot manuel avant maintenance** | Possibilité de déclencher un snapshot à la demande avant toute mise à jour critique. |

> **Justification :** En cas de corruption de la base Elasticsearch ou d'une mauvaise configuration du Manager, un rollback rapide est indispensable pour garantir la continuité du service SOC.

---

### 3.2 Règles réseau / Firewall

Les flux suivants doivent être **autorisés** entre les VM et le réseau de l'école :

| Port | Proto | Source | Destination | Usage |
|------|-------|--------|-------------|-------|
| **1514** | TCP | Postes Windows (réseau école) | `wazuh-manager` (100.65.111.9) | Communication agent → manager (logs) |
| **1515** | TCP | Postes Windows (réseau école) | `wazuh-manager` (100.65.111.9) | Enregistrement initial des agents |
| **55000** | TCP | Postes Windows (réseau école) | `wazuh-manager` (100.65.111.9) | API REST Wazuh (enrôlement automatisé) |
| **443** | TCP | Postes analystes SOC | `wazuh-manager` (100.65.111.9) | Dashboard Wazuh (interface web HTTPS) |
| **9200** | TCP | `wazuh-manager` uniquement | `siem-server` | Elasticsearch (indexation des alertes) |
| **41641** | UDP | `wazuh-manager` + `siem-server` | Internet (Tailscale relay) | Tunnel WireGuard (overlay Tailscale) |
| **22** | TCP | Mon poste admin uniquement | Les deux VM | SSH (administration) |

> **Important :** Les ports 9200 (Elasticsearch) et 22 (SSH) ne doivent **PAS** être exposés au réseau global de l'école. Seul le trafic entre les deux VM (9200) et depuis mon poste admin (22) doit être autorisé.

---

### 3.3 DNS interne (optionnel mais recommandé)

| Enregistrement | Type | Valeur | Usage |
|----------------|------|--------|-------|
| `wazuh.school.local` | A | 100.65.111.9 | Accès au Dashboard par nom plutôt que par IP |
| `siem.school.local` | A | *(IP siem-server)* | Accès interne Elasticsearch |

---

### 3.4 Ressources supplémentaires (si possible)

| Demande | Justification |
|---------|---------------|
| **Augmenter le disque de `siem-server` à 200 Go** | La rétention de 30 jours de logs pour ~50 postes nécessite environ 150 Go d'espace indexé. |
| **Activer le QEMU Guest Agent** sur les deux VM | Permet un arrêt propre lors des snapshots (consistency). |

---

## 4. Engagement de ma part

- Je **ne modifierai pas** la configuration réseau de Proxmox moi-même.
- Je **documenterai** toute modification apportée à mes VM (playbooks Ansible versionnés sur Git).
- Je **fournirai un guide de passation** en fin de projet pour que l'équipe ProxFibre puisse maintenir l'infrastructure si nécessaire.
- En cas d'incident, je **communiquerai immédiatement** avec l'équipe ProxFibre.

---

## 5. Planning prévisionnel

| Semaine | Action | Besoin ProxFibre |
|---------|--------|------------------|
| S+0 | Validation de cette fiche | Lecture + retour |
| S+1 | Test de connectivité réseau | Ouverture des ports (§3.2) |
| S+2 | Déploiement des agents sur les PC école | Aucun |
| S+3 | Montée en charge (50 postes) | Monitoring des ressources VM |
| S+4 | Documentation finale et passation | Snapshot final |

---

## 6. Contact

| Info | Détail |
|------|--------|
| **Nom** | Corentin |
| **Projet** | Stage Master – SOC / SIEM Wazuh |
| **Email** | *(à compléter)* |
| **Téléphone** | *(à compléter)* |

---

*Merci pour votre soutien. Ce projet bénéficiera à l'ensemble de l'école en offrant une supervision de sécurité continue du parc informatique.*
