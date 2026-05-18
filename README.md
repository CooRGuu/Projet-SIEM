# Projet de Déploiement d'un SOC avec Ansible

Ce projet contient l'infrastructure as code (IaC) pour déployer un SIEM basé sur Wazuh en utilisant Ansible. Il est conçu pour être déployé dans un environnement de laboratoire (`lab`) et facilement adaptable à un environnement de production (`prod`) grâce à des inventaires et des variables séparés.

## Prérequis

- **Ansible:** Version 2.12+
- **Python:** Version 3.8+
- **Git:** Pour cloner le projet.
- **Accès SSH** aux machines cibles avec des clés SSH (recommandé).

## Structure du Projet

```
Projet-SIEM/
├── README.md               # Ce fichier
└── soc-infrastructure/
    ├── .ansible-lint       # Configuration du linter pour la qualité du code
    ├── .gitignore          # Fichiers à ignorer par Git (TRÈS IMPORTANT)
    ├── ansible.cfg         # Configuration générale d'Ansible
    ├── inventories/
    │   ├── lab/            # Environnement de Laboratoire
    │   │   ├── hosts.ini
    │   │   └── group_vars/
    │   │       ├── all.yml
    │   │       └── vault.yml
    │   └── prod/           # Environnement de Production
    │       ├── hosts.ini
    │       └── group_vars/
    │           ├── all.yml
    │           └── vault.yml
    ├── playbooks/
    │   └── deploy_manager.yml
    ├── requirements.yml    # Dépendances externes (collections/rôles Ansible)
    └── roles/
        └── wazuh-manager/  # Rôle pour déployer le manager Wazuh
```

## Guide de Démarrage Rapide

### 1. Installation des dépendances Ansible

Si le projet utilise des collections ou des rôles externes, installez-les avec `ansible-galaxy`.

```bash
cd soc-infrastructure
ansible-galaxy install -r requirements.yml
```

### 2. Configuration du Coffre-fort (Ansible Vault)

Les secrets (mots de passe, clés d'API) sont stockés de manière chiffrée dans les fichiers `vault.yml`.

**a. Créer un fichier de mot de passe (Recommandé)**

Pour éviter de taper le mot de passe à chaque fois, créez un fichier `.vault_pass` **à la racine du projet `Projet-SIEM` (en dehors de `soc-infrastructure`)**.

```bash
# Depuis la racine Projet-SIEM/
echo "VOTRE_MOT_DE_PASSE_SECRET" > .vault_pass
chmod 600 .vault_pass
```
**Attention :** Le fichier `.gitignore` est configuré pour ignorer `.vault_pass`. Ne le commitez jamais.

**b. Créer et éditer le coffre-fort du laboratoire**

```bash
# Depuis le répertoire soc-infrastructure/
ansible-vault create inventories/lab/group_vars/vault.yml --vault-password-file ../.vault_pass
```
Ajoutez-y les secrets nécessaires (ex: `wazuh_cluster_key`, `wazuh_api_password`).

### 3. Configuration de l'inventaire

Modifiez le fichier d'inventaire de votre environnement pour définir les machines cibles.

**Pour le laboratoire :** `inventories/lab/hosts.ini`

```ini
[wazuh_manager]
wazuh-manager-lab ansible_host=192.168.X.X ansible_user=votre_user_ssh
```
Remplacez `192.168.X.X` par l'IP de votre VM et `votre_user_ssh` par votre utilisateur de connexion.

### 4. Lancement d'un Playbook

Pour déployer le manager Wazuh dans l'environnement de laboratoire :

```bash
# Depuis le répertoire soc-infrastructure/
ansible-playbook -i inventories/lab/hosts.ini playbooks/deploy_manager.yml --vault-password-file ../.vault_pass
```

### 5. Analyse du code (Linting)

Pour vérifier la qualité et la conformité de votre code Ansible :

```bash
# Depuis le répertoire soc-infrastructure/
ansible-lint
```
