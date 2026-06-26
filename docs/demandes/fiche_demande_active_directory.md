# 📋 Fiche de Demande – Responsable Active Directory

**Projet :** Infrastructure SOC – Déploiement automatisé des agents Wazuh  
**Demandeur :** Corentin  
**Date :** 26 juin 2026  
**Priorité :** Haute  
**Statut :** En attente de validation  

---

## 1. Contexte

Dans le cadre de mon stage de Master, je déploie un **SIEM Wazuh** pour superviser la sécurité du parc informatique de l'école. Le Manager Wazuh est opérationnel (hébergé sur ProxFibre). L'étape suivante consiste à **installer automatiquement l'agent de supervision** sur les postes Windows du domaine via une **stratégie de groupe (GPO)**.

Cette approche est **non intrusive** : l'agent Wazuh collecte uniquement les logs de sécurité Windows (EventLog) et effectue un audit de conformité CIS. Il ne modifie aucun fichier utilisateur, n'intercepte pas le trafic réseau et ne ralentit pas les postes.

---

## 2. Ce dont j'ai besoin

### 2.1 Unité d'Organisation (OU) dédiée

| Élément | Détail |
|---------|--------|
| **Nom de l'OU** | `OU=SOC_Monitored,OU=Computers,DC=school,DC=local` *(à adapter au naming de l'école)* |
| **Contenu** | Les comptes ordinateur des postes à superviser |
| **Pourquoi** | Isoler le périmètre de déploiement. Seuls les PC dans cette OU recevront l'agent Wazuh. Permet un **déploiement progressif** (10 postes pilotes → tout le parc). |

> **Alternative :** Si la création d'une OU n'est pas souhaitée, un **groupe de sécurité** (ex: `GRP_SOC_Monitored`) filtré sur la GPO via "Security Filtering" convient aussi.

---

### 2.2 Compte de service

| Élément | Détail |
|---------|--------|
| **Nom du compte** | `svc_wazuh_deploy` |
| **Type** | Compte de service managé (gMSA) ou compte utilisateur standard |
| **Mot de passe** | Ne doit **jamais expirer** (ou géré par gMSA) |
| **Groupes** | Membre de `Domain Users` uniquement (aucun droit admin) |
| **Usage** | Le script GPO utilise ce compte pour s'authentifier auprès de l'API Wazuh (port 55000) et enregistrer le poste. Le compte n'a **aucun droit sur l'AD** lui-même. |

> **Sécurité :** Ce compte est utilisé uniquement par le script PowerShell exécuté en contexte `SYSTEM` au démarrage du poste. Le mot de passe est chiffré localement via **DPAPI** (Data Protection API) et n'est jamais stocké en clair.

---

### 2.3 Partage réseau pour les fichiers de déploiement

| Élément | Détail |
|---------|--------|
| **Chemin UNC** | `\\SRV-FICHIERS\Deploy$\Wazuh\` *(ou `\\NETLOGON\Wazuh\`)* |
| **Contenu** | `Deploy-WazuhAgent.ps1` (≈ 15 Ko) + `wazuh-agent-4.10.4-1.msi` (≈ 9 Mo) |
| **Droits NTFS** | Voir tableau ci-dessous |
| **Droits de partage** | `Authenticated Users` : Lecture |

**Droits NTFS requis :**

| Principal | Droit | Raison |
|-----------|-------|--------|
| `Domain Admins` | Contrôle total | Administration du partage |
| `Domain Computers` | Lecture + Exécution | Le script est exécuté par le compte `SYSTEM` du poste (qui s'identifie comme `POSTE01$`) |
| `Authenticated Users` | Lecture | Accès en lecture seule pour vérification |

> **Pourquoi `Domain Computers` ?** Le script GPO est exécuté **avant** l'ouverture de session de l'utilisateur, en contexte `NT AUTHORITY\SYSTEM`. À ce moment, seule l'identité machine (`POSTE01$@DOMAIN.LOCAL`) est active.

---

### 2.4 Création d'une GPO

| Élément | Détail |
|---------|--------|
| **Nom de la GPO** | `SEC_DEP_WazuhAgent` |
| **Liaison** | Liée à l'OU `SOC_Monitored` (voir §2.1) |
| **Type** | `Configuration ordinateur > Stratégies > Paramètres Windows > Scripts (démarrage/arrêt) > Démarrage` |
| **Script** | `\\SRV-FICHIERS\Deploy$\Wazuh\Deploy-WazuhAgent.ps1` |
| **Paramètres** | *(aucun)* |
| **Option** | Cocher **"Exécuter les scripts Windows PowerShell en premier"** |

**Paramètres GPO complémentaires recommandés :**

| Chemin GPO | Paramètre | Valeur | Raison |
|-----------|-----------|--------|--------|
| `Computer Configuration > Admin Templates > System > Scripts` | Délai d'exécution max des scripts | `600 secondes` | Laisser le temps au script d'attendre le réseau (Tailscale) |
| `Computer Configuration > Admin Templates > System > Scripts` | Exécuter les scripts de manière asynchrone | `Désactivé` | Le script doit terminer avant le logon |

---

### 2.5 Règles de pare-feu (GPO ou Firewall central)

Les postes Windows doivent pouvoir joindre le Manager Wazuh :

| Port | Proto | Source | Destination | Usage |
|------|-------|--------|-------------|-------|
| **1514** | TCP | Postes Windows | 100.65.111.9 | Envoi des logs au Manager |
| **55000** | TCP | Postes Windows | 100.65.111.9 | API REST (enrôlement) |

> **Option :** Ces règles peuvent être déployées via une **GPO de pare-feu Windows** (`Computer Configuration > Windows Settings > Security Settings > Windows Defender Firewall > Outbound Rules`).

---

## 3. Ce que le script fait (transparence)

Pour votre information, voici exactement ce que fait le script `Deploy-WazuhAgent.ps1` lorsqu'il s'exécute au démarrage d'un poste :

| Phase | Action | Impact sur le poste |
|-------|--------|---------------------|
| 1 | Vérifie que le tunnel réseau (Tailscale) est actif | Aucun (lecture seule) |
| 2 | Teste la connectivité vers l'API Wazuh (port 55000) | Aucun (test TCP) |
| 3 | Déchiffre le credential DPAPI local | Aucun (lecture mémoire) |
| 4 | S'authentifie auprès de l'API Wazuh | Aucun (appel HTTPS sortant) |
| 5 | Enregistre le poste comme agent Wazuh | Aucun (appel API) |
| 6 | Copie le MSI depuis le partage réseau | Écriture dans `C:\Wazuh_Deploy\` (≈ 9 Mo) |
| 7 | Installe le MSI silencieusement | Installation de `Wazuh Agent` dans `C:\Program Files (x86)\ossec-agent\` |
| 8 | Démarre le service `WazuhSvc` | Service Windows (démarrage automatique) |

**Le script est entièrement idempotent** : s'il détecte que l'agent est déjà installé et fonctionnel, il ne fait rien et se termine immédiatement (< 1 seconde).

---

## 4. Déploiement progressif proposé

| Étape | Périmètre | Durée | Validation |
|-------|-----------|-------|------------|
| **Pilote** | 3 postes de test (salle info) | 1 semaine | Vérifier que l'agent fonctionne, pas d'impact sur les performances |
| **Extension** | 1 salle complète (≈ 20 postes) | 1 semaine | Vérifier la charge sur le Manager Wazuh |
| **Production** | Tout le parc (≈ 50-100 postes) | 2 semaines | Monitoring continu |

> **Rollback :** En cas de problème, il suffit de **délier la GPO** de l'OU. Les agents déjà installés continueront de fonctionner mais aucun nouveau poste ne sera provisionné. Pour désinstaller un agent : `msiexec /x wazuh-agent-4.10.4-1.msi /qn`.

---

## 5. Engagement de ma part

- Le script PowerShell est **open-source** et je fournirai le code source complet pour revue avant déploiement.
- Aucune donnée personnelle n'est collectée : uniquement les **logs de sécurité Windows** (EventLog Security, System, PowerShell).
- Je **documenterai** toute la procédure et fournirai un **guide de passation** en fin de projet.
- Le **compte de service** n'a aucun privilège sur l'AD.
- Je me tiens disponible pour une **démonstration en direct** si nécessaire.

---

## 6. Contact

| Info | Détail |
|------|--------|
| **Nom** | Corentin |
| **Projet** | Stage Master – SOC / SIEM Wazuh |
| **Email** | *(à compléter)* |
| **Téléphone** | *(à compléter)* |
| **Tuteur de stage** | *(à compléter)* |

---

*Ce déploiement permettra à l'école de disposer d'une supervision de sécurité en temps réel, conforme aux recommandations de l'ANSSI et alignée sur le référentiel CIS.*
