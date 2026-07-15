# Support de soutenance : industrialisation et durcissement d'un SOC avec Wazuh

* **Durée recommandée :** 15 à 20 minutes
* **Cible :** Jury d'examen (correcteurs académiques et experts techniques)

---

## Diapositive 1 : Titre et introduction
* **Visuel :** Titre du projet, nom, Master, logo de l'école.
* **Contenu :**
  * Projet de Fin d'Études : industrialisation et durcissement d'un SOC basé sur Wazuh.
  * Présenté par Corentin.
* **À l'oral :**
  * Saluer le jury.
  * Introduire le sujet : mettre en place une visibilité de sécurité sur un réseau d'école.

---

## Diapositive 2 : Contexte et problématique
* **Visuel :** Schéma d'un réseau d'école (postes admin + salles de TP).
* **Contenu :**
  * Réseau académique hétérogène, étudiants en info qui utilisent des outils offensifs en TP, risque d'intrusion élevé.
  * Comment déployer un SIEM open source sans ralentir les postes et sans exposer les clés d'administration lors du déploiement de masse ?
* **À l'oral :**
  * Expliquer les contraintes concrètes : parc volatil, étudiants curieux, budget limité.
  * Poser le défi principal : déployer un agent de sécurité partout sans que les mots de passe de l'API traînent en clair.

---

## Diapositive 3 : Choix de l'architecture
* **Visuel :** Tableau comparatif Splunk vs ELK vs Wazuh (ou logo Wazuh).
* **Contenu :**
  * Pourquoi Wazuh : 100% open source, agent unifié (SIEM + EDR/XDR), pas de licence au volume.
  * Composants : Wazuh Manager (moteur), OpenSearch (base de logs), Wazuh Dashboard (visualisation).
* **À l'oral :**
  * Expliquer le choix rationnel : Splunk trop cher, ELK seul n'a pas d'EDR natif.
  * Les données restent stockées localement, pas de cloud externe.

---

## Diapositive 4 : Topologie réseau et sécurisation
* **Visuel :** Schéma de la topologie (Manager VM sur ProxFibre, OpenSearch, réseau TP, tunnel admin).
* **Contenu :**
  * Hébergement interne sur ProxFibre (Proxmox).
  * Pare-feu UFW restrictif.
  * Aucun port d'administration exposé sur le réseau de l'école — on passe par un overlay Tailscale (WireGuard).
* **À l'oral :**
  * Présenter le schéma réseau.
  * Insister : un attaquant sur le réseau de l'école ne peut même pas scanner le port SSH ou tenter de pirater le Dashboard, ils ne sont visibles que via le VPN.

---

## Diapositive 5 : Industrialisation du déploiement (Ansible)
* **Visuel :** Extrait du code Ansible (`deploy_wazuh_manager.yml`).
* **Contenu :**
  * Déploiement automatique et reproductible du Manager.
  * Secrets gérés via Ansible Vault (mot de passe API, clés de cluster).
  * Sauvegarde quotidienne automatisée (2h00, rétention 14 jours) des configs et clés d'agents.
* **À l'oral :**
  * Expliquer pourquoi l'IaC est important (éviter la dérive de configuration).
  * Mentionner la politique de sauvegarde comme élément de résilience.

---

## Diapositive 6 : Déploiement de masse durci (GPO & PowerShell)
* **Visuel :** Schéma GPO → script PowerShell au démarrage.
* **Contenu :**
  * Automatisation via GPO AD (démarrage d'ordinateur en contexte `SYSTEM`).
  * Vérification d'intégrité SHA-256 : blocage si le binaire a été falsifié sur le partage réseau.
  * Idempotence, diagnostic via EventLog Windows (Event IDs `8100` / `8101`).
* **À l'oral :**
  * Expliquer le fonctionnement du script PowerShell.
  * Mettre en avant la vérification SHA-256 : si un étudiant malveillant modifie le MSI sur le partage pour y cacher un malware, le script le détecte et bloque tout.

---

## Diapositive 7 : Focus sécurité — chiffrement DPAPI
* **Visuel :** Schéma du fonctionnement DPAPI (clé locale liée à la machine).
* **Contenu :**
  * Le problème : comment stocker le mot de passe d'enrôlement sans le mettre en clair dans le script ?
  * La solution : DPAPI (Data Protection API). Le secret est pré-chiffré pour la machine cible. Seul le compte `SYSTEM` peut le déchiffrer.
  * Un utilisateur standard ne peut pas extraire le mot de passe, même en lisant le script.
* **À l'oral :**
  * C'est le point clé en termes de valeur ajoutée sécurité. Expliquer comment DPAPI empêche le vol d'identifiants.
  * Même si le script est volé, il est inutilisable en dehors des machines du domaine ciblées.

---

## Diapositive 8 : Matrice de détection et scénarios d'attaque
* **Visuel :** Liste ou graphique des alertes Wazuh générées lors des tests.
* **Contenu :**
  * Scénarios testés : PowerShell encodé en Base64, accès suspect à LSASS, création d'utilisateurs suspects.
  * Règles XML personnalisées mappées MITRE ATT&CK sur le Manager.
* **À l'oral :**
  * Expliquer comment on a testé et validé le SOC.
  * Montrer que le SOC ne se contente pas de collecter — il réagit aux comportements suspects.

---

## Diapositive 9 : Audit et conformité réglementaire
* **Visuel :** Tableau de correspondance ou radar de conformité.
* **Contenu :**
  * Alignement sur le guide d'hygiène de l'ANSSI (accès, journalisation, durcissement).
  * Alignement sur les contrôles CIS v8 et NIST SP 800-53.
  * Chiffrement TLS 1.3, restriction des privilèges locaux (ACL sur `client.keys`).
* **À l'oral :**
  * Montrer la dimension GRC du projet.
  * Chaque choix technique a été justifié par une norme ou un guide officiel.

---

## Diapositive 10 : Gestion du projet et retours d'expérience
* **Visuel :** Ligne temporelle ou Gantt (Spécification → Dev Ansible → GPO → Audit).
* **Contenu :**
  * Difficultés résolues : latence d'accès à l'AD, paramétrages OpenSearch.
  * Livrables fournis : code Git, fiches admin, guides de déploiement et de passation.
* **À l'oral :**
  * Expliquer comment les contraintes réelles (délais d'accès admin AD) ont été gérées sans bloquer le projet.

---

## Diapositive 11 : Conclusion et perspectives
* **Visuel :** Liste des évolutions futures.
* **Contenu :**
  * Objectifs atteints : SOC fonctionnel, industrialisé et sécurisé.
  * Perspectives : intégration de Sysmon, centralisation des logs Linux, ajout d'un SOAR (Shuffle) pour automatiser le blocage d'IP suspectes.
* **À l'oral :**
  * Résumer les apports du projet pour l'école.
  * Conclure sur ce que ce projet a apporté professionnellement.
  * Remercier le jury et ouvrir les questions.
