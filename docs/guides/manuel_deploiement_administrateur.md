# Manuel de Déploiement Administrateur : Package SOC Wazuh

Ce document est destiné à l'équipe informatique en charge du déploiement final de la solution SIEM sur l'infrastructure de production. Il détaille pas à pas l'utilisation du "Kit de Déploiement SOC" fourni.

## 📦 Contenu du Kit de Déploiement

Le kit (présent dans ce dépôt Git) contient tous les éléments nécessaires à l'industrialisation de la solution :
- **Dossier `soc-infrastructure/`** : Playbooks Ansible pour le déploiement automatisé du serveur Wazuh Manager.
- **Dossier `scripts/windows/`** : Scripts PowerShell pour l'intégration Active Directory, le déploiement GPO et la sécurisation des secrets (DPAPI).
- **Fichier `custom_wazuh_rules.xml`** : Règles de détection spécifiques (alerting adapté au réseau de l'école).

---

## 🛠️ Prérequis

Avant de débuter l'installation, assurez-vous de disposer des éléments suivants :
1. **Accès Proxmox / ProxFibre** : Droits de création de VM pour héberger le serveur Linux (Ubuntu 22.04 LTS ou Debian 12 recommandé).
2. **Accès Active Directory** : Privilèges de niveau *Domain Admin* ou délégation sur la création de GPO.
3. **Machine d'administration** : Un poste disposant de `git`, `ansible`, et `powershell`.
4. **Réseau** : Les flux réseaux entre le VLAN Serveur (Wazuh) et le VLAN Utilisateurs (postes clients) doivent autoriser le port **1514/TCP** (communication des agents) et **1515/TCP** (enrôlement).

---

## 🚀 Étape 1 : Déploiement du Serveur Wazuh Manager

Le cœur du SIEM est déployé via Infrastructure as Code (Ansible) pour garantir une installation propre, reproductible et documentée.

1. **Préparation de la VM :**
   Créez une VM sous Linux sur Proxmox. Attribuez-lui une adresse IP statique (ex: `10.0.0.50`).
2. **Configuration de l'inventaire Ansible :**
   Éditez le fichier `soc-infrastructure/inventories/production/hosts.ini` et remplacez l'IP par celle de votre nouvelle VM.
3. **Lancement du Playbook :**
   Depuis votre machine d'administration, lancez la commande suivante :
   \`\`\`bash
   ansible-playbook -i soc-infrastructure/inventories/production/hosts.ini deploy_wazuh_manager.yml -K
   \`\`\`
4. **Validation :**
   Vérifiez que l'interface Web est accessible via `https://<IP_DU_MANAGER>` (les identifiants par défaut vous seront communiqués de manière sécurisée).

---

## 🔐 Étape 2 : Préparation de l'Active Directory (DPAPI)

Pour des raisons de sécurité (PSSI), le mot de passe d'enrôlement de l'API Wazuh ne doit jamais figurer en clair dans la GPO. Nous utilisons l'API de protection des données Windows (DPAPI) rattachée au compte `SYSTEM`.

1. Sur le contrôleur de domaine, ouvrez une invite PowerShell en tant qu'Administrateur.
2. Exécutez le script d'initialisation :
   \`\`\`powershell
   .\scripts\windows\Initialize-WazuhDeployCredential.ps1
   \`\`\`
3. Le script vous demandera de saisir le mot de passe de l'API Wazuh. Il va ensuite générer un fichier chiffré (`wazuh_api_secret.txt`) dans le dossier partagé `SYSVOL`. Ce fichier ne pourra être déchiffré que par le compte `SYSTEM` des machines du domaine.

---

## 💻 Étape 3 : Déploiement des Agents via GPO

Une fois le secret chiffré stocké sur le réseau, vous pouvez paramétrer la GPO de déploiement.

1. **Création de la GPO :**
   Ouvrez la console de gestion des stratégies de groupe (GPMC) et créez une nouvelle GPO nommée `Déploiement_Agent_Wazuh`.
2. **Liaison :**
   Liez cette GPO à l'Unité d'Organisation (OU) contenant les postes de travail cibles.
3. **Configuration du script de démarrage :**
   Allez dans `Configuration ordinateur > Stratégies > Paramètres Windows > Scripts (Démarrage/Arrêt)`.
   Ajoutez le script `Deploy-WazuhAgent.ps1` (copiez-le au préalable dans le dossier des scripts de la GPO).
4. **Paramètres du script :**
   Dans le champ "Paramètres de script", ajoutez :
   \`\`\`text
   -ManagerIP "10.0.0.50"
   \`\`\`
5. **Application :**
   La GPO s'appliquera au prochain redémarrage des postes. Les agents seront automatiquement téléchargés, installés, inscrits auprès du Manager (grâce au secret DPAPI), et démarrés.

---

## ✅ Étape 4 : Validation et Tests

Pour vérifier que la livraison est fonctionnelle :

1. Connectez-vous à l'interface Wazuh Dashboard.
2. Allez dans l'onglet **Agents** et vérifiez que les postes de l'AD remontent avec le statut `Active`.
3. *(Optionnel)* Pour valider le bon fonctionnement des règles de sécurité, exécutez le script de simulation fourni en environnement restreint :
   \`\`\`powershell
   .\scripts\tests\Simulate-Attacks.ps1
   \`\`\`
   Vérifiez que les alertes correspondantes s'affichent sur le tableau de bord Wazuh.

---

## 📞 Support et Maintenance

Le kit de déploiement inclut également des outils de maintenance dans le répertoire de scripts :
- `Rotate-WazuhApiPassword.ps1` : À utiliser si le mot de passe de l'API du manager est compromis ou modifié.
- `wazuh-health-monitor.sh` : Script à planifier via cron sur le manager pour surveiller la santé des services.

Pour toute question relative à l'architecture, veuillez vous référer au document `docs/guides/rapport_projet_soc_wazuh.md`.
