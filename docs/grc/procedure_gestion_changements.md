# Procédure de Gestion des Changements — SOC Scolaire Wazuh

> **Projet** : Déploiement d'un SOC scolaire basé sur Wazuh  
> **Version** : 1.0  
> **Date** : 2026-06-29  
> **Auteur** : `<STAGIAIRE_NOM>`  
> **Classification** : Interne — Procédure opérationnelle  
> **Référence** : ITIL v4 — Change Enablement  

---

## 1. Objectif et périmètre

### 1.1 Objectif

Cette procédure définit le processus de gestion des changements applicable à l'infrastructure du SOC scolaire. Elle vise à :
- **Minimiser les risques** liés aux modifications de l'environnement de production
- **Assurer la traçabilité** de chaque changement via Git et documentation associée
- **Garantir la réversibilité** (rollback) de tout changement en cas d'échec
- **Maintenir la disponibilité** du SOC et la continuité de la supervision

### 1.2 Périmètre

Cette procédure s'applique à tous les changements affectant :
- Le serveur Wazuh Manager (VM Proxmox)
- Les agents Wazuh déployés sur les postes
- Les règles de détection et décodeurs
- Les scripts PowerShell de déploiement (GPO, DPAPI)
- Les playbooks Ansible
- La configuration réseau et Tailscale
- Les dashboards OpenSearch

---

## 2. Classification des changements

### 2.1 Types de changements

| Type | Description | Niveau de risque | Approbation requise | Délai minimum |
|------|-------------|:----------------:|:-------------------:|:-------------:|
| **Standard** | Changement pré-approuvé, répétitif, à faible risque | 🟢 Faible | Pré-approuvé (pas de CAB) | Immédiat |
| **Normal** | Changement planifié nécessitant une évaluation | 🟠 Moyen | CAB (revue de code + validation) | 48h minimum |
| **Urgent** | Changement critique lié à un incident de sécurité | 🔴 Élevé | Approbation accélérée (tuteur) | Immédiat, revue post-implémentation |

### 2.2 Exemples par type

| Type | Exemples concrets |
|------|-------------------|
| **Standard** | Mise à jour de la documentation, ajout d'une exclusion de faux positif, modification cosmétique d'un dashboard |
| **Normal** | Ajout d'une nouvelle règle de détection, mise à jour du script de déploiement GPO, modification de la configuration Ansible, mise à jour de version Wazuh |
| **Urgent** | Correction d'une faille de sécurité sur le manager, désactivation d'une règle causant un déni de service (flood d'alertes), restauration d'un agent défaillant |

---

## 3. Rôles dans le processus

| Rôle | Responsabilité | Titulaire |
|------|----------------|-----------|
| **Demandeur** | Initie la demande de changement, justifie le besoin | Stagiaire SOC (principal), Admin Réseau, Admin AD |
| **Évaluateur** | Analyse l'impact technique et les risques | Stagiaire SOC |
| **CAB** (Change Advisory Board) | Revue et approbation des changements normaux | Tuteur de stage + Admin Réseau (si infrastructure concernée) |
| **Approbateur** | Donne le feu vert final pour l'implémentation | Tuteur de stage |
| **Implémenteur** | Exécute le changement en environnement de production | Stagiaire SOC |
| **Vérificateur** | Valide le bon fonctionnement post-changement | Stagiaire SOC + Tuteur de stage |

---

## 4. Workflow de gestion des changements

### 4.1 Vue d'ensemble

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌─────────────────┐    ┌───────────────┐
│  1. DEMANDE  │───▶│ 2. ÉVALUATION│───▶│ 3. APPROBATION│───▶│ 4. IMPLÉMENTATION│───▶│ 5. REVUE POST │
│              │    │              │    │               │    │                  │    │  CHANGEMENT   │
└─────────────┘    └──────────────┘    └──────────────┘    └─────────────────┘    └───────────────┘
       │                  │                  │                      │                      │
       ▼                  ▼                  ▼                      ▼                      ▼
   Issue GitHub      Analyse impact     PR Review +          Merge + Deploy          Monitoring +
   + RFC template    + plan rollback    Approbation CAB      + Tests post-déploiement  Clôture
```

### 4.2 Étape 1 — Demande de changement (RFC)

**Responsable** : Demandeur

1. Créer une **Issue GitHub** avec le template `RFC - Request For Change`
2. Renseigner les informations suivantes :

```markdown
## Request For Change (RFC)

**Date** : YYYY-MM-DD
**Demandeur** : <NOM>
**Type de changement** : [ ] Standard  [ ] Normal  [ ] Urgent

### Description
[Description claire et concise du changement demandé]

### Justification
[Pourquoi ce changement est nécessaire — lien vers incident, amélioration, conformité]

### Composants impactés
- [ ] Wazuh Manager
- [ ] Agents Wazuh
- [ ] Règles de détection / Décodeurs
- [ ] Scripts PowerShell (GPO/DPAPI)
- [ ] Playbooks Ansible
- [ ] Configuration réseau / Tailscale
- [ ] Dashboards OpenSearch

### Risques identifiés
[Liste des risques potentiels]

### Plan de rollback
[Comment annuler le changement en cas d'échec]

### Fenêtre d'implémentation souhaitée
[Date et créneau horaire préférés]
```

3. Assigner le label approprié : `change:standard`, `change:normal`, ou `change:urgent`
4. Assigner l'évaluateur

### 4.3 Étape 2 — Évaluation

**Responsable** : Évaluateur (Stagiaire SOC)

1. **Analyse d'impact** :
   - Identifier tous les composants affectés
   - Évaluer l'impact sur la disponibilité du SOC
   - Estimer la durée d'implémentation
   - Identifier les dépendances avec d'autres changements

2. **Plan de test** :
   - Définir les tests de validation pré-déploiement
   - Définir les tests de validation post-déploiement
   - Identifier les critères de succès / échec

3. **Plan de rollback détaillé** :
   - Documenter la procédure de retour arrière étape par étape
   - Estimer le temps de rollback
   - Identifier les données potentiellement perdues en cas de rollback

4. Mettre à jour l'Issue GitHub avec l'analyse complète
5. Passer le statut à `En attente d'approbation`

### 4.4 Étape 3 — Approbation

**Responsable** : CAB / Approbateur

| Type de changement | Processus d'approbation |
|--------------------|------------------------|
| **Standard** | Pré-approuvé — l'implémenteur peut procéder directement |
| **Normal** | Revue par le Tuteur de stage via **Pull Request GitHub** avec code review. Approbation explicite requise. |
| **Urgent** | Approbation verbale ou par message du Tuteur de stage. Documentation et revue post-implémentation obligatoires. |

**Critères d'approbation** :
- ✅ Analyse d'impact complète
- ✅ Plan de rollback documenté
- ✅ Tests de validation définis
- ✅ Fenêtre de changement identifiée
- ✅ Code review passée (si applicable)

### 4.5 Étape 4 — Implémentation

**Responsable** : Implémenteur (Stagiaire SOC)

**Pré-requis** :
- [ ] Approbation obtenue (PR approuvée ou validation Tuteur)
- [ ] Sauvegarde/snapshot réalisée
- [ ] Tunnel Tailscale opérationnel
- [ ] Outils de rollback prêts

**Séquence d'implémentation** :

1. **Sauvegarde** : Créer un snapshot Proxmox de la VM Wazuh et/ou un backup des fichiers concernés
2. **Merge** : Fusionner la branche de changement dans `main` (ou `develop`)
3. **Déploiement** : Appliquer le changement via Ansible, GPO, ou manuellement selon le cas
4. **Tests post-déploiement** : Exécuter les tests définis à l'étape 2
5. **Validation** : Confirmer le bon fonctionnement avec le vérificateur

**En cas d'échec** → Déclencher immédiatement la procédure de rollback (§6)

### 4.6 Étape 5 — Revue post-changement (PIR)

**Responsable** : Stagiaire SOC + Tuteur de stage

1. **Monitoring** : Surveiller le SOC pendant 24h–48h après le changement
2. **Vérification des KPIs** : S'assurer qu'aucun KPI n'a été dégradé (cf. `tableau_kpis_soc.md`)
3. **Documentation** : Mettre à jour la documentation impactée
4. **Clôture** : Fermer l'Issue GitHub avec un commentaire de synthèse :

```markdown
## Post-Implementation Review (PIR)

**Date d'implémentation** : YYYY-MM-DD HH:MM
**Résultat** : [ ] Succès  [ ] Succès partiel  [ ] Échec (rollback effectué)

### Tests post-déploiement
- [x] Test 1 : [Description] — ✅ OK
- [x] Test 2 : [Description] — ✅ OK

### Impact observé
[Décrire l'impact réel vs. l'impact prévu]

### Leçons apprises
[Points d'amélioration pour les prochains changements]
```

---

## 5. Utilisation de Git

### 5.1 Stratégie de branches

```
main (production)
 ├── develop (intégration)
 │    ├── feature/wazuh-rule-xxx      (nouvelle règle de détection)
 │    ├── feature/gpo-deploy-v2       (mise à jour script déploiement)
 │    ├── fix/false-positive-xxx      (correction faux positif)
 │    └── docs/update-raci            (mise à jour documentation)
 └── hotfix/critical-fix-xxx          (correction urgente, branchée depuis main)
```

### 5.2 Convention de nommage des branches

| Préfixe | Usage | Exemple |
|---------|-------|---------|
| `feature/` | Nouvelle fonctionnalité ou règle | `feature/sysmon-process-creation-rule` |
| `fix/` | Correction de bug ou faux positif | `fix/fp-windows-update-alert` |
| `hotfix/` | Correction urgente en production | `hotfix/agent-auth-failure` |
| `docs/` | Mise à jour de documentation | `docs/update-deployment-guide` |
| `refactor/` | Refactoring sans changement fonctionnel | `refactor/ansible-playbook-structure` |

### 5.3 Processus de Pull Request

1. **Créer la branche** depuis `develop` (ou `main` pour les hotfix)
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/nom-du-changement
   ```

2. **Développer et committer** avec des messages conventionnels
   ```bash
   git commit -m "feat(rules): add Sysmon process creation detection rule

   - Add rule ID 100100 for suspicious process creation
   - Map to MITRE ATT&CK T1059.001 (PowerShell)
   - Include decoder for Sysmon Event ID 1
   
   Refs: #42"
   ```

3. **Pousser et créer la PR**
   ```bash
   git push origin feature/nom-du-changement
   ```

4. **Template de Pull Request** :
   ```markdown
   ## Description
   [Résumé du changement]

   ## Type de changement
   - [ ] Standard
   - [ ] Normal
   - [ ] Urgent (hotfix)

   ## Checklist
   - [ ] Tests locaux effectués
   - [ ] Documentation mise à jour
   - [ ] Aucune donnée sensible dans le code
   - [ ] Placeholders utilisés pour les valeurs sensibles
   - [ ] Plan de rollback documenté dans l'Issue liée

   ## Issue liée
   Closes #XX

   ## Screenshots / Logs
   [Si applicable]
   ```

5. **Code Review** : Le Tuteur de stage (ou l'Admin Réseau pour les changements d'infrastructure) effectue la revue
6. **Merge** : Après approbation, merge via **Squash and Merge** pour garder un historique propre

### 5.4 Convention de commits

Format : `<type>(<scope>): <description>`

| Type | Description |
|------|-------------|
| `feat` | Nouvelle fonctionnalité ou règle |
| `fix` | Correction de bug |
| `docs` | Documentation uniquement |
| `refactor` | Refactoring sans changement fonctionnel |
| `test` | Ajout ou modification de tests |
| `chore` | Tâches de maintenance (CI, dépendances) |
| `security` | Correction de sécurité |

---

## 6. Procédures de rollback

### 6.1 Matrice de rollback par composant

| Composant | Méthode de rollback | Temps estimé | Responsable |
|-----------|--------------------:|:------------:|:-----------:|
| VM Wazuh Manager | Restauration snapshot Proxmox | 5–10 min | Stagiaire SOC + Admin Réseau |
| Règles de détection | `git revert` + redémarrage `wazuh-manager` | 2–5 min | Stagiaire SOC |
| Scripts PowerShell (GPO) | Restauration version précédente via Git + mise à jour du SYSVOL | 5–15 min | Stagiaire SOC + Admin AD |
| Playbooks Ansible | `git revert` + re-exécution du playbook précédent | 5–10 min | Stagiaire SOC |
| Configuration agents | Redéploiement de la configuration via `agent.conf` centralisé | 10–20 min | Stagiaire SOC |
| Dashboards OpenSearch | Import du fichier JSON de sauvegarde | 2–5 min | Stagiaire SOC |
| Configuration Tailscale | Restauration du fichier de configuration + redémarrage du service | 2–5 min | Stagiaire SOC + Admin Réseau |

### 6.2 Procédure de rollback — Règles Wazuh

```bash
# 1. Identifier le commit à annuler
git log --oneline -10

# 2. Revert du commit
git revert <COMMIT_HASH> --no-edit

# 3. Pousser le revert
git push origin main

# 4. Appliquer sur le serveur
ssh <WAZUH_USER>@<MANAGER_IP> << 'EOF'
  # Copier les règles restaurées
  sudo cp /path/to/repo/rules/local_rules.xml /var/ossec/etc/rules/local_rules.xml
  
  # Vérifier la syntaxe
  sudo /var/ossec/bin/wazuh-analysisd -t
  
  # Redémarrer le service
  sudo systemctl restart wazuh-manager
  
  # Vérifier le statut
  sudo systemctl status wazuh-manager
EOF

# 5. Vérifier la détection
# Consulter les dashboards pour confirmer le retour à la normale
```

### 6.3 Procédure de rollback — VM Proxmox

```bash
# 1. Se connecter à l'hyperviseur Proxmox
ssh <PROXMOX_USER>@<PROXMOX_IP>

# 2. Arrêter la VM Wazuh
qm stop <VM_ID>

# 3. Lister les snapshots disponibles
qm listsnapshot <VM_ID>

# 4. Restaurer le snapshot pré-changement
qm rollback <VM_ID> <SNAPSHOT_NAME>

# 5. Démarrer la VM
qm start <VM_ID>

# 6. Vérifier la connectivité
ping <MANAGER_IP>
curl -k -u <API_USER>:<API_PASSWORD> https://<MANAGER_IP>:55000/security/user/authenticate
```

---

## 7. Exemples concrets de changements

### 7.1 Exemple 1 — Ajout d'une règle de détection Wazuh

| Étape | Action | Détail |
|-------|--------|--------|
| **Demande** | Issue GitHub `#47` | « Ajouter une règle de détection pour les tentatives de brute-force RDP (Event ID 4625) » |
| **Type** | Normal | Risque moyen — impact potentiel sur le volume d'alertes |
| **Branche** | `feature/rdp-bruteforce-rule` | Créée depuis `develop` |
| **Fichiers modifiés** | `rules/local_rules.xml`, `docs/rules_mapping.md` | Ajout de la règle ID 100200 + documentation |
| **Tests** | Simulation de 5 tentatives de connexion RDP échouées | Validation : l'alerte est bien générée |
| **PR** | `#48` — Revue par le Tuteur | Code review + validation MITRE mapping |
| **Déploiement** | Merge → copie sur le manager → redémarrage | Via playbook Ansible `deploy-rules.yml` |
| **PIR** | Monitoring 24h | Aucune régression, 2 alertes légitimes détectées |

### 7.2 Exemple 2 — Mise à jour du script de déploiement GPO

| Étape | Action | Détail |
|-------|--------|--------|
| **Demande** | Issue GitHub `#52` | « Mettre à jour le script PowerShell pour supporter le déploiement silencieux de Wazuh 4.x avec nouveau format de certificat » |
| **Type** | Normal | Risque moyen — impact sur les futurs déploiements d'agents |
| **Branche** | `feature/gpo-deploy-v2` | Créée depuis `develop` |
| **Fichiers modifiés** | `scripts/deploy/Install-WazuhAgent.ps1`, `gpo/wazuh-deploy.xml` | Mise à jour du script + GPO associée |
| **Tests** | Déploiement sur 1 poste pilote dans l'OU `<OU_TEST>` | Vérification : agent installé, connecté, version correcte |
| **PR** | `#53` — Revue par le Tuteur + Admin AD | Validation du script + des paramètres GPO |
| **Déploiement** | Merge → copie vers SYSVOL `\\<DOMAINE_AD>\SYSVOL\` → `gpupdate /force` sur le poste test | Puis extension à l'OU de production |
| **Rollback prévu** | Restauration de `Install-WazuhAgent.ps1` v1 via `git revert` + mise à jour SYSVOL | Temps estimé : 10 min |
| **PIR** | Monitoring 48h | Validation sur 5 postes supplémentaires avant déploiement massif |

### 7.3 Exemple 3 — Modification de la configuration Ansible

| Étape | Action | Détail |
|-------|--------|--------|
| **Demande** | Issue GitHub `#58` | « Modifier le playbook Ansible pour ajouter la configuration de rotation des logs Wazuh (logrotate) » |
| **Type** | Standard | Pré-approuvé — modification mineure de configuration |
| **Branche** | `feature/logrotate-config` | Créée depuis `develop` |
| **Fichiers modifiés** | `ansible/roles/wazuh-manager/tasks/main.yml`, `ansible/roles/wazuh-manager/templates/logrotate-wazuh.j2` | Ajout de la tâche de configuration logrotate |
| **Tests** | Exécution du playbook en mode `--check` (dry-run) puis application | Vérification : fichier `/etc/logrotate.d/wazuh` créé avec les bons paramètres |
| **Déploiement** | Merge direct (standard pré-approuvé) → exécution Ansible | `ansible-playbook -i inventory/production site.yml --tags logrotate` |
| **PIR** | Vérification le lendemain que la rotation a fonctionné | Contrôle : taille des logs, fichiers archivés |

---

## 8. Registre des changements

Tous les changements sont tracés dans le tableau suivant (maintenu à jour dans le repository) :

| # | Date | Type | Description | Issue | PR | Résultat | Implémenteur |
|---|------|------|-------------|-------|----|----------|--------------|
| 001 | `<DATE>` | Normal | Déploiement initial du manager Wazuh | #1 | #2 | ✅ Succès | `<STAGIAIRE_NOM>` |
| 002 | `<DATE>` | Normal | Première vague de déploiement agents | #5 | #6 | ✅ Succès | `<STAGIAIRE_NOM>` |
| ... | ... | ... | ... | ... | ... | ... | ... |

---

## 9. Indicateurs de suivi du processus

| KPI | Formule | Objectif |
|-----|---------|----------|
| Taux de succès des changements | `(changements réussis / total changements) × 100` | ≥ 95% |
| Nombre de rollbacks | Comptage mensuel | < 2 / mois |
| Délai moyen d'approbation | `Σ(T_approbation - T_demande) / N` | < 48h |
| Taux de changements urgents | `(changements urgents / total) × 100` | < 10% |
| Changements ayant causé un incident | Comptage | 0 |

---

## 10. Données sensibles — Rappel

> ⚠️ Ce document est hébergé sur un **repository GitHub public**. Toutes les données sensibles sont remplacées par des **placeholders**.

| Placeholder | Description |
|-------------|-------------|
| `<STAGIAIRE_NOM>` | Nom complet du stagiaire |
| `<MANAGER_IP>` | Adresse IP du serveur Wazuh |
| `<PROXMOX_IP>` | Adresse IP de l'hyperviseur Proxmox |
| `<PROXMOX_USER>` | Utilisateur Proxmox |
| `<WAZUH_USER>` | Utilisateur SSH du serveur Wazuh |
| `<VM_ID>` | ID de la VM Wazuh dans Proxmox |
| `<DOMAINE_AD>` | Nom de domaine Active Directory |
| `<OU_TEST>` | OU Active Directory de test |
| `<API_USER>` | Utilisateur API Wazuh |
| `<API_PASSWORD>` | Mot de passe API Wazuh |
| `<SNAPSHOT_NAME>` | Nom du snapshot Proxmox |
| `<ECOLE_NOM>` | Nom de l'établissement scolaire |

---

## 11. Historique des révisions

| Version | Date | Auteur | Modifications |
|---------|------|--------|---------------|
| 1.0 | 2026-06-29 | `<STAGIAIRE_NOM>` | Création initiale du document |

---

*Document généré dans le cadre du projet SOC scolaire — `<ECOLE_NOM>`*
