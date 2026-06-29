# 🖥️ Support de Soutenance : Industrialisation et Durcissement d'un SOC souverain avec Wazuh

* **Durée recommandée :** 15 à 20 minutes
* **Cible :** Jury d'examen (correcteurs académiques et experts techniques)

---

## 📽️ Diapositive 1 : Titre et Introduction
* **Visuel :** Titre du projet, ton nom, ton Master, logo de l'école.
* **Contenu textuel :**
  * Projet de Fin d'Études : Industrialisation et Durcissement d'un SOC souverain basé sur Wazuh.
  * *Présenté par Corentin.*
* **Points clés à l'oral :**
  * Saluer le jury.
  * Introduire brièvement le sujet : la mise en place d'une visibilité de sécurité sur un réseau d'établissement d'enseignement supérieur.

---

## 📽️ Diapositive 2 : Contexte et Problématique
* **Visuel :** Schéma ou icône représentant un réseau d'école (mélange de postes d'administration et de salles de TP).
* **Contenu textuel :**
  * **Contexte :** Réseau académique hétérogène, présence d'étudiants en informatique (bruit de fond d'outils offensifs, risque élevé d'intrusion).
  * **Problématique :** Comment déployer un système de détection des menaces (SIEM/SOC) de manière souveraine, économique (Open Source), sans ralentir les postes et sans exposer les clés d'administration lors du déploiement de masse ?
* **Points clés à l'oral :**
  * Expliquer les contraintes d'un réseau d'école (parc volatil, étudiants curieux, budget limité).
  * Poser le défi : déployer un agent de sécurité partout de manière sécurisée (sans laisser traîner les mots de passe de l'API SOC).

---

## 📽️ Diapositive 3 : Choix de l'Architecture
* **Visuel :** Tableau comparatif (Splunk vs ELK vs Wazuh) ou logotype de Wazuh.
* **Contenu textuel :**
  * **Pourquoi Wazuh ?** Souveraineté, 100% open source, agent unifié (SIEM + EDR/XDR), pas de licence au volume.
  * **Composants :** Wazuh Manager (moteur), OpenSearch (base de données de logs), Wazuh Dashboard (visualisation).
* **Points clés à l'oral :**
  * Expliquer le choix rationnel de Wazuh par rapport à Splunk (coût) ou ELK seul (manque de fonctions d'EDR natives).
  * Insister sur le fait que la solution est souveraine (données stockées localement, pas de cloud propriétaire).

---

## 📽️ Diapositive 4 : Topologie Réseau et Sécurisation de l'Infrastructure
* **Visuel :** Schéma de la topologie (Manager VM sur ProxFibre, base OpenSearch, réseau de TP, tunnel d'administration).
* **Contenu textuel :**
  * Hébergement interne sur la plateforme ProxFibre (Proxmox).
  * Pare-feu local (UFW) restrictif.
  * **Sécurité Admin :** Aucun port d'administration (SSH/Dashboard 443) exposé sur le réseau de l'école. Utilisation d'un overlay réseau privé **Tailscale** (chiffrement WireGuard).
* **Points clés à l'oral :**
  * Présenter le schéma réseau.
  * Insister sur la protection de la VM Manager : un attaquant sur le réseau de l'école ne peut même pas scanner le port SSH ou tenter de pirater le Dashboard, car ils ne sont visibles que via le réseau virtuel privé Tailscale.

---

## 📽️ Diapositive 5 : Industrialisation du Déploiement (Ansible)
* **Visuel :** Capture d'écran ou extrait du code Ansible (`deploy_wazuh_manager.yml`).
* **Contenu textuel :**
  * Déploiement automatique et reproductible du Manager.
  * Gestion des secrets via **Ansible Vault** (mot de passe d'API, clés de cluster).
  * Tâche automatisée de sauvegarde quotidienne (à 2h00, rétention 14 jours) pour les fichiers de configuration et les clés cryptographiques d'agents.
* **Points clés à l'oral :**
  * Expliquer l'importance de l'IaC (Infrastructure as Code) pour éviter la dérive de configuration.
  * Parler de la politique de sauvegarde (sécurité GRC / résilience face aux pannes ProxFibre).

---

## 📽️ Diapositive 6 : Déploiement de Masse durci (GPO & PowerShell)
* **Visuel :** Schéma montrant la GPO exécutant le script PowerShell au démarrage.
* **Contenu textuel :**
  * Automatisation via Active Directory GPO (démarrage d'ordinateur en contexte `SYSTEM`).
  * **Vérification d'intégrité (SHA-256) :** Blocage des attaques de type falsification de binaire sur le partage réseau.
  * **Idempotence :** Pas de réinstallation inutile, diagnostic via l'EventLog Windows (Event IDs `8100` / `8101`).
* **Points clés à l'oral :**
  * Expliquer comment fonctionne le script PowerShell de déploiement d'agent.
  * Mettre en valeur la vérification SHA-256 : si un étudiant malveillant modifie le fichier d'installation sur le partage réseau pour y cacher un malware, le script le détecte et bloque l'installation.

---

## 📽️ Diapositive 7 : Focus Sécurité : Chiffrement DPAPI
* **Visuel :** Schéma explicatif du fonctionnement de DPAPI (clé locale liée à la machine).
* **Contenu textuel :**
  * **Le problème :** Comment stocker le mot de passe d'enrôlement de l'API sans le mettre en clair dans le script ?
  * **La solution :** Windows DPAPI (Data Protection API).
  * **Principe :** Le secret est pré-chiffré pour l'ordinateur cible. Seul le compte `SYSTEM` de cette machine peut le déchiffrer.
  * **Sécurité :** Un utilisateur standard ou un attaquant lisant le script ou le registre ne peut pas extraire le mot de passe.
* **Points clés à l'oral :**
  * C'est le cœur de la valeur ajoutée en sécurité. Expliquer comment DPAPI empêche le vol d'identifiants sur le réseau public.
  * Préciser que même si le script est volé, il est inutilisable en dehors des machines du domaine ciblées.

---

## 📽️ Diapositive 8 : Matrice de Détection et Scénarios d'Attaque
* **Visuel :** Liste ou graphique des alertes Wazuh générées lors d'un test.
* **Contenu textuel :**
  * **Scénarios testés (Red Teaming) :**
    * Exécution de commandes PowerShell encodées en Base64.
    * Tentatives d'accès suspectes au processus `LSASS` (dump de mémoire).
    * Création d'utilisateurs locaux suspects.
  * **Détection :** Règles XML personnalisées (mappées MITRE ATT&CK) sur le Manager pour filtrer le bruit.
* **Points clés à l'oral :**
  * Expliquer comment nous avons testé et validé le SOC.
  * Montrer que le SOC ne se contente pas de collecter, il réagit aux comportements suspects réels.

---

## 📽️ Diapositive 9 : Audit et Conformité Réglementaire (GRC)
* **Visuel :** Tableau de correspondance ou radar de conformité (ANSSI, NIST).
* **Contenu textuel :**
  * Alignement sur le **Guide d'hygiène de l'ANSSI** (Contrôles d'accès, journalisation, durcissement).
  * Alignement sur les contrôles **CIS v8** et le framework **NIST SP 800-53**.
  * Chiffrement des flux (TLS 1.3), restriction stricte des privilèges locaux (ACL sur `client.keys`).
* **Points clés à l'oral :**
  * Montrer la dimension gouvernance (GRC) du projet.
  * Expliquer au jury que chaque choix technique a été justifié par une norme ou un guide officiel de sécurité informatique.

---

## 📽️ Diapositive 10 : Gestion du Projet et Retours d'Expérience
* **Visuel :** Ligne temporelle ou graphique Gantt des phases du projet (Spécification -> Dev Ansible -> GPO -> Audit).
* **Contenu textuel :**
  * **Difficultés résolues :** Latence d'accès à l'Active Directory, paramétrages de certificats OpenSearch.
  * **Livrables fournis :** Code Git, Fiches admin (AD, ProxFibre), guides de déploiement et de passation.
* **Points clés à l'oral :**
  * Expliquer comment les contraintes réelles (comme les délais d'accès admin AD) ont été gérées sans bloquer le projet (avancement sur la documentation et les scripts de simulation d'attaque).

---

## 📽️ Diapositive 11 : Conclusion et Perspectives
* **Visuel :** Liste des évolutions futures envisagées.
* **Contenu textuel :**
  * **Objectifs atteints :** SOC fonctionnel, industrialisé, souverain et hautement sécurisé.
  * **Perspectives :**
    * Intégration de Sysmon pour une détection plus granulaire sur Windows.
    * Centralisation des logs des serveurs Linux (Syslog/Wazuh).
    * Intégration d'un SOAR open source (comme Shuffle) pour automatiser le blocage d'IP suspectes.
* **Points clés à l'oral :**
  * Résumer les apports du projet pour l'école.
  * Conclure sur ce que ce projet t'a apporté professionnellement.
  * Remercier le jury et ouvrir la session de questions.
