#!/bin/bash
# ==============================================================================
# Script : simulate_deployment.sh
# Rôle : Simulation (Dry-Run) du déploiement Ansible
# Objectif : Valider la configuration IaC sans impacter les machines cibles.
# Contexte : Projet SOC Wazuh (Validation de changement)
# ==============================================================================

set -e

echo "🛡️ [DevSecOps] Initialisation de la simulation de déploiement (Mode Dry-Run)..."
echo "----------------------------------------------------------------------"

# Vérification du répertoire courant
if [ ! -d "soc-infrastructure" ]; then
    echo "❌ Erreur : Veuillez lancer ce script depuis la racine du dépôt Git."
    exit 1
fi

cd soc-infrastructure

# Vérification de l'existence du vault password (pour lab ou prod)
if [ ! -f "../.vault_pass" ]; then
    echo "⚠️ Avertissement : Le fichier ../.vault_pass n'existe pas."
    echo "Génération d'un vault_pass temporaire factice pour permettre la simulation..."
    echo "TEST_PASSWORD" > ../.vault_pass_temp
    VAULT_FILE="../.vault_pass_temp"
else
    VAULT_FILE="../.vault_pass"
fi

# Choix de l'environnement (Lab par défaut pour le test)
ENV_INVENTORY="inventories/lab/hosts.ini"

echo "✅ Environnement ciblé : $ENV_INVENTORY"
echo "🚀 Lancement d'Ansible avec le flag --check (Dry-Run) et --diff (Changements)"
echo "----------------------------------------------------------------------"

# Exécution d'Ansible en mode Check
ansible-playbook -i "$ENV_INVENTORY" playbooks/deploy_manager.yml --vault-password-file "$VAULT_FILE" --check --diff

# Nettoyage
if [ -f "../.vault_pass_temp" ]; then
    rm ../.vault_pass_temp
fi

echo "----------------------------------------------------------------------"
echo "✅ Simulation terminée."
echo "Si des erreurs sont remontées, veuillez corriger les playbooks avant un vrai déploiement."