# soc-infrastructure

Structure Ansible de base pour déployer un SOC Wazuh.

## Utilisation du Vault

1. Recréer/changer le fichier chiffré :
   ```bash
   ansible-vault create inventories/lab/group_vars/vault.yml
   ```
2. Définir les variables `vault_*` dans ce fichier.
3. Lancer le déploiement :
   ```bash
   ansible-playbook playbooks/deploy_manager.yml -i inventories/lab/hosts.ini --ask-vault-pass
   ```
