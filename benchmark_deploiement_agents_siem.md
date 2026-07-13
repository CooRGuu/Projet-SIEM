# 📊 Benchmark : Méthodes de Déploiement de l'Agent SIEM sur le Parc Académique

L'objectif de ce document est de comparer les différentes approches techniques pour déployer de manière industrielle l'agent Wazuh sur l'ensemble des ordinateurs (salles de TP, administration, serveurs) de l'établissement.

---

## 🗺️ Tableau Comparatif Synthétique

| Méthode | Praticité / Scalabilité | Coût Financier | Sécurité des Identifiants | Conformité ANSSI / NIST | Profil Idéal |
|---|---|---|---|---|---|
| **GPO Active Directory** | 🟢 Excellente (parc AD) | 🟢 Gratuit (inclus Windows) | 🟡 Risqué (sauf si DPAPI/GPO durcie) | 🟢 Excellente (si durcie) | Postes Windows du domaine (TP, Admin) |
| **Ansible (WinRM / SSH)** | 🟡 Moyenne (difficile sur clients) | 🟢 Gratuit (Open Source) | 🔴 Risqué (centralisation d'admin) | 🟡 Moyenne (durcissement WinRM requis) | Serveurs Windows/Linux stables |
| **MECM (SCCM) / Intune** | 🟢 Excellente (multi-sites) | 🔴 Élevé (Licences M365) | 🟢 Excellente | 🟢 Excellente | Flotte hybride Windows/macOS (BYOD/Intune) |
| **Scripts PsExec / WMI** | 🔴 Mauvaise (non scalable) | 🟢 Gratuit (inclus Windows) | 🔴 Critique (flux en clair) | 🔴 Non conforme | Petit laboratoire isolé (< 10 machines) |
| **Déploiement Manuel (Technicien)** | 🔴 Inacceptable (chronophage) | 🔴 Élevé (temps homme) | 🟡 Risqué (saisie de mot de passe) | 🔴 Non conforme | Cas d'exclusion réseau / Postes hors domaine |

---

## 🔍 Analyse Détaillée par Solution

### 1. Stratégie de Groupe (GPO) Active Directory (Choix du Projet)
La GPO permet d'associer un script de démarrage (ordinateur) qui s'exécute silencieusement en arrière-plan à chaque boot de la machine cible.

* **Avantages :**
  * **Gratuit et natif :** Aucun outil tiers à installer ou à acheter, l'Active Directory est déjà en place à l'école.
  * **Exécution SYSTEM :** Le script tourne en contexte `NT AUTHORITY\SYSTEM`, ce qui évite d'utiliser ou d'exposer un compte administrateur du domaine sur les postes clients.
  * **Mises à jour simplifiées :** Remplacer le binaire MSI sur le partage réseau met à jour automatiquement le parc au redémarrage suivant.
* **Inconvénients :**
  * **Windows uniquement :** Ne gère pas les serveurs pédagogiques Linux ou les macOS.
  * **Dépendance réseau AD :** La machine doit être connectée au réseau physique pour appliquer la GPO (problématique pour les PC portables en télétravail ou hors domaine).
* **Risques de Sécurité :**
  * Si le secret d'API (mot de passe d'enrôlement) est écrit en clair dans le script PowerShell hébergé sur `NETLOGON` (partage lisible par tous), n'importe quel étudiant peut usurper l'identité du SOC.
  * **Mesure corrective appliquée :** Chiffrement asymétrique localisé avec la clé machine via **DPAPI** (notre implémentation).
* **Respect des Normes :**
  * **ANSSI R15 / R16 :** Respecté (centralisation automatique et transparente des journaux).
  * **NIST AU-2 / AU-9 :** Excellent (les agents sont verrouillés contre la désactivation par les utilisateurs non-admins).

---

### 2. Ansible (WinRM pour Windows / SSH pour Linux)
Ansible est un outil d'automatisation sans agent (agentless) qui se connecte aux machines distantes pour pousser l'installation.

* **Avantages :**
  * **Multiplateforme :** Un seul playbook peut déployer l'agent sur Windows (TP) et Linux (serveurs).
  * **Gestion fine des configurations :** Idéal pour pousser des fichiers de configuration personnalisés (`ossec.conf`) post-installation.
* **Inconvénients :**
  * **Pré-requis WinRM :** Windows n'active pas WinRM (Windows Remote Management) par défaut sur les systèmes clients. L'activer sur 150 postes de TP nécessite lui-même... une GPO ou une manipulation manuelle.
  * **Parc volatile :** Si un ordinateur de TP est éteint au moment où Ansible tourne, il est ignoré. Il faut relancer le script en boucle.
* **Risques de Sécurité :**
  * Ansible nécessite de stocker un compte ayant des droits d'administration locale sur toutes les cibles (Domain Admin ou Local Admin) sur la machine de contrôle. Si le serveur Ansible est compromis, **c'est toute l'école qui tombe**.
  * WinRM doit être configuré en HTTPS (port 5986) avec certificat pour éviter l'interception de secrets en clair sur le réseau académique.
* **Respect des Normes :**
  * Conforme à la traçabilité des déploiements, mais complexifie la conformité sur le principe de "réduction de la surface d'attaque" (l'ouverture de WinRM sur chaque client Windows ajoute un port d'écoute ouvert).

---

### 3. Microsoft Intune (MDM) / MECM (SCCM)
Outils de gestion de flotte d'entreprise de l'écosystème Microsoft.

* **Avantages :**
  * **Puissance industrielle :** Rapports graphiques complets de réussite/échec, gestion de la bande passante (peer-to-peer cache pour ne pas saturer le lien internet lors des téléchargements).
  * **Intune (Cloud) :** Permet d'enrôler des machines même hors du réseau de l'école (étudiants chez eux ou ordinateurs portables de l'administration).
* **Inconvénients :**
  * **Coût prohibitif :** Nécessite des licences Microsoft 365 (Academic A3/A5) ou des serveurs SCCM complexes à maintenir, ce qui contredit la contrainte de souveraineté et de gratuité de ce projet.
* **Risques de Sécurité :**
  * Très sécurisé (flux chiffrés gérés par Microsoft, intégration des secrets dans le package d'application Intune non lisible par l'utilisateur).
* **Respect des Normes :**
  * Totalement conforme aux plus hauts standards de l'ANSSI, du NIST et de l'ISO 27001.

---

### 4. Scripts PsExec / WMI
L'administrateur utilise un script local qui se connecte de manière séquentielle sur chaque IP du réseau de l'école et lance l'installation via PsExec ou WMI.

* **Avantages :**
  * Rapide à coder pour un besoin ponctuel sur un périmètre restreint (ex: 5 machines).
* **Inconvénients :**
  * **Absence totale de scalabilité :** Si le poste cible est éteint, le script échoue. Il faut tenir à jour une liste d'IP valides.
  * Blocage systématique par le pare-feu local Windows Defender (qui bloque le trafic WMI et le partage administratif `ADMIN$`).
* **Risques de Sécurité :**
  * **Critique :** PsExec transmet par défaut les requêtes en clair sur le réseau local. Un étudiant équipé de Wireshark sur le même commutateur réseau peut intercepter le mot de passe administrateur Windows.
* **Respect des Normes :**
  * **Non conforme** aux recommandations ANSSI (vulnérabilités de protocoles hérités, pas de chiffrement des flux d'administration).

---

### 5. Installation Manuelle (Clé USB / Intervention humaine)
Un technicien passe physiquement sur chaque machine de l'école ou se connecte en RDP pour installer l'agent manuellement.

* **Avantages :**
  * Aucun pré-requis réseau ou AD.
* **Inconvénients :**
  * **Temps de travail colossal :** Plus de 100 heures cumulées pour 180 machines.
  * Risque d'erreur humaine (oubli d'une étape, mauvaise adresse IP du manager).
  * Impossible de gérer les mises à jour majeures de l'agent.
* **Risques de Sécurité :**
  * L'usage de clés USB sur l'ensemble du parc est un vecteur historique majeur de propagation de malwares (ex: BadUSB, vol d'identifiants).
  * Saisie de mots de passe administrateur devant les utilisateurs ou étudiants.
* **Respect des Normes :**
  * Non conforme (absence de reproductibilité, non-respect de la politique d'usage des supports amovibles).

---

## 📌 Conclusion et Recommandation pour le Projet

Le choix de la **GPO Active Directory combinée au durcissement PowerShell + DPAPI** s'impose comme le meilleur compromis pour le réseau de l'école :
1. **Économique :** Exploite l'Active Directory existant sans aucun coût supplémentaire de licence.
2. **Pratique :** Automatisation transparente pour l'utilisateur (installation au démarrage de la machine).
3. **Sécurisé :** Grâce à notre développement sur le chiffrement DPAPI, nous comblons la faille de sécurité majeure de la GPO classique en interdisant l'exfiltration du secret d'enrôlement par les étudiants.
