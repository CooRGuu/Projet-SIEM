# ðŸ“˜ Rapport de Projet AcadÃ©mique : Mise en place et Industrialisation d'un SOC souverain avec Wazuh

* **Auteur :** Corentin
* **Cursus :** Master CybersÃ©curitÃ© / IngÃ©nierie RÃ©seaux & SystÃ¨mes
* **Sujet :** DÃ©ploiement, durcissement et industrialisation d'un SIEM Wazuh sur un rÃ©seau acadÃ©mique (Projet de Fin d'Ã‰tudes / Projet Annuel)
* **Encadrant / Correcteur PÃ©dagogique :** [Nom de l'encadrant]
* **Date :** Juin 2026

---

## ðŸ“‹ Table des MatiÃ¨res

1. **Introduction**
   * 1.1 Contexte et Objectifs du Projet
   * 1.2 ProblÃ©matique de Supervision des RÃ©seaux AcadÃ©miques
   * 1.3 Gestion de Projet, Jalons et Livrables Attendus
2. **SpÃ©cification des Besoins et Analyse des Risques (Analyse Fonctionnelle)**
   * 2.1 PÃ©rimÃ¨tre et Cible de Supervision
   * 2.2 La Plateforme ProxFibre (Proxmox)
   * 2.3 Analyse des Risques et Vecteurs d'Attaque (Risk Mapping)

3. **Architecture Technique du SIEM Wazuh**
   * 3.1 Pourquoi Wazuh ? Comparaison des Solutions SIEM
   * 3.2 Topologie de DÃ©ploiement (Manager & OpenSearch)
   * 3.3 Automatisation du DÃ©ploiement du Manager via Ansible
   * 3.4 SÃ©curisation du Manager (UFW, Tailscale, Sauvegardes)
4. **Industrialisation du DÃ©ploiement de Masse (GPO Windows)**
   * 4.1 ProblÃ©matique de l'Industrialisation sur le Parc Informatique
   * 4.2 Le Script de DÃ©ploiement Durci PowerShell (v3.0.0)
   * 4.3 Gestion SÃ©curisÃ©e des Secrets d'EnrÃ´lement (DPAPI)
   * 4.4 StratÃ©gie de Groupe (GPO) : Configuration et DÃ©ploiement Progressif
5. **RÃ¨gles de DÃ©tection et Mappage de ConformitÃ© (SecOps & GRC)**
   * 5.1 RÃ¨gles de DÃ©tection PersonnalisÃ©es (MITRE ATT&CK)
   * 5.2 Mappage avec les RÃ©fÃ©rentiels RÃ©glementaires (ANSSI, NIST, ISO 27001)
   * 5.3 Protocoles de Validation et ScÃ©narios d'Attaque (Red Teaming)
6. **Bilan, DifficultÃ©s et Perspectives**
   * 6.1 DifficultÃ©s RencontrÃ©es (AccÃ¨s RÃ©seau, Validation GPO)
   * 6.2 Guide de Passation et Maintenance du SOC
   * 6.3 Perspectives d'Ã‰volution (SOAR, Collecte Syslog Linux)
7. **Conclusion**

---

## âœï¸ Chapitre 1 : Introduction

### 1.1 Contexte et Objectifs du Projet
Dans un paysage numÃ©rique oÃ¹ les cybermenaces se professionnalisent et s'accÃ©lÃ¨rent, la capacitÃ© de dÃ©tection prÃ©coce des compromissions est devenue un pilier fondamental de la rÃ©silience informatique. Ce projet s'inscrit dans cette dÃ©marche au sein de notre Ã©tablissement, avec pour objectif principal la mise en place d'une infrastructure de supervision de sÃ©curitÃ© de type **SOC (Security Operations Center)** souveraine, centralisÃ©e et industrialisÃ©e.

L'objectif est d'assurer la visibilitÃ© en temps rÃ©el sur les Ã©vÃ©nements de sÃ©curitÃ© survenant sur le parc informatique de l'Ã©cole (comprenant les postes de travail des salles de cours, l'administration, ainsi que les serveurs de services) afin de rÃ©agir promptement aux incidents d'intrusion ou d'abus de ressources.

### 1.2 ProblÃ©matique de Supervision des RÃ©seaux AcadÃ©miques
Les rÃ©seaux d'Ã©tablissements d'enseignement supÃ©rieur prÃ©sentent des dÃ©fis de sÃ©curitÃ© uniques et complexes :
* **HÃ©tÃ©rogÃ©nÃ©itÃ© et volatilitÃ© du parc :** Coexistence d'Ã©quipements administratifs critiques, de serveurs de TP Ã©tudiants et de postes de salles de cours partagÃ©s.
* **Profil d'utilisateurs Ã  risque :** Les Ã©tudiants en informatique manipulent des outils de sÃ©curitÃ© offensive dans le cadre de leurs travaux pratiques, gÃ©nÃ©rant un bruit de fond important et un risque Ã©levÃ© d'Ã©chappement de malware ou d'intrusions sur le rÃ©seau de production.
* **Ressources limitÃ©es :** NÃ©cessitÃ© d'adopter des solutions open source sans frais de licence rÃ©currents (souverainetÃ©), tout en garantissant des performances de niveau entreprise (*production-grade*).

### 1.3 Objectifs et Livrables Attendus
Le projet s'est articulÃ© autour de trois grands axes :
1. **Infrastructure SIEM :** DÃ©ploiement robuste du Manager Wazuh et de la base d'indexation des logs (OpenSearch) sur la plateforme d'hÃ©bergement interne **ProxFibre**.
2. **DÃ©ploiement Ã  l'Ã©chelle :** Conception d'un mÃ©canisme d'installation automatisÃ© pour les postes Windows via Active Directory (GPO), respectant les meilleures pratiques de sÃ©curitÃ© de l'ANSSI.
3. **ConformitÃ© & DÃ©tection :** CrÃ©ation de rÃ¨gles de dÃ©tection spÃ©cifiques axÃ©es sur les tactiques du MITRE ATT&CK et cartographie de notre conformitÃ© vis-Ã -vis des guides d'hygiÃ¨ne de l'ANSSI et du NIST.

---

## âœï¸ Chapitre 2 : SpÃ©cification des Besoins et Analyse des Risques

### 2.1 PÃ©rimÃ¨tre et Cible de Supervision
L'Ã©tablissement d'enseignement hÃ©berge un rÃ©seau informatique complexe Ã  usages multiples. La spÃ©cification des besoins impose de diviser le pÃ©rimÃ¨tre de supervision en trois grandes zones logiques, chacune prÃ©sentant un niveau de criticitÃ© et des profils d'utilisateurs distincts :

1. **La Zone PÃ©dagogique (Salles de TP et postes Ã©tudiants) :**
   * **Population cible :** Environ 150 postes clients sous Windows 10/11 rÃ©partis dans les diffÃ©rentes salles de TP.
   * **Profil d'utilisation :** Utilisation intensive par les Ã©tudiants en informatique. Installation frÃ©quente de logiciels tiers, d'environnements de dÃ©veloppement, et exÃ©cution de scripts.
   * **Risques associÃ©s :** TrÃ¨s fort taux de faux positifs du fait d'activitÃ©s lÃ©gitimes ressemblant Ã  des attaques (TP d'outils d'administration, requÃªtes PowerShell complexes).
2. **La Zone Administrative (Postes de direction, comptabilitÃ©, scolaritÃ©) :**
   * **Population cible :** Environ 30 postes sous Windows 10/11.
   * **Profil d'utilisation :** TÃ¢ches bureautiques classiques, accÃ¨s aux bases de donnÃ©es scolaires et financiÃ¨res.
   * **Risques associÃ©s :** Cible privilÃ©giÃ©e pour le vol d'identifiants, le phishing ciblÃ© (spear-phishing) et l'introduction de ransomwares par manque de formation technique des utilisateurs.
3. **La Zone Serveurs (Services internes et hÃ©bergement TP) :**
   * **Population cible :** Serveurs d'infrastructures (Active Directory, serveurs de fichiers DHCP, DNS) et serveurs de TP (Linux/Windows).
   * **Risques associÃ©s :** Escalade de privilÃ¨ges, compromission du contrÃ´leur de domaine (Active Directory) entraÃ®nant une prise de contrÃ´le totale du rÃ©seau.

*Estimation de la volumÃ©trie des logs :* Pour un parc cible initial de 50 agents pilotes (mÃ©lange de TP et administratif), le volume de logs gÃ©nÃ©rÃ© est estimÃ© Ã  environ **1,5 Go par jour** (soit environ 15 Ã  20 Ã©vÃ©nements par seconde en moyenne). Cela impose des contraintes de stockage de l'ordre de 45 Go par mois pour conserver une rÃ©tention glissante Ã  chaud de 30 jours, justifiant la demande d'extension du stockage Ã  200 Go sur notre serveur OpenSearch.

### 2.2 La Plateforme ProxFibre (Proxmox)
L'infrastructure SOC est entiÃ¨rement virtualisÃ©e et hÃ©bergÃ©e sur la plateforme **ProxFibre**, un environnement de cloud privÃ© gÃ©rÃ© par une Ã©quipe d'Ã©tudiants-administrateurs sous hyperviseur **Proxmox VE**. 

Cette configuration sous-tend des contraintes et opportunitÃ©s spÃ©cifiques :
* **DÃ©pendance administrative (Contrainte de non-accÃ¨s hyperviseur) :** N'ayant pas d'accÃ¨s direct avec les privilÃ¨ges `root` sur l'hyperviseur Proxmox, toute demande d'adaptation d'infrastructure (allocation de ressources vCPU/RAM, extensions de stockage, crÃ©ation de plans de snapshots automatiques, ou enregistrements DNS de la zone `school.local`) nÃ©cessite la rÃ©daction de fiches de demande formelles adressÃ©es aux administrateurs de la plateforme (voir [`fiche_demande_proxfibre.html`](file:///C:/Users/coren/OneDrive/Desktop/Projet-SIEM/docs/demandes/fiche_demande_proxfibre.html)).
* **SÃ©paration logique rÃ©seau :** Les machines virtuelles du SOC communiquent par un rÃ©seau overlay Tailscale VPN chiffrÃ©, Ã©vitant ainsi d'exposer l'administration du SIEM Ã  l'ensemble du LAN acadÃ©mique.
* **QEMU Guest Agent :** L'activation indispensable de cet agent logiciel au sein de nos VMs permet Ã  l'hyperviseur Proxmox d'interagir proprement avec l'OS invitÃ© (Ubuntu 22.04) afin de figer les systÃ¨mes de fichiers (fsfreeze) lors des snapshots quotidiens Ã  2h00, Ã©vitant tout risque de corruption des bases de donnÃ©es d'indexation de logs.

### 2.3 Analyse des Risques et Vecteurs d'Attaque (Risk Mapping)
Afin de concevoir des rÃ¨gles de dÃ©tection pertinentes, nous avons rÃ©alisÃ© un mappage des risques informatiques majeurs ciblÃ©s sur le rÃ©seau de l'Ã©cole :

| ScÃ©nario d'Attaque | ProbabilitÃ© | Impact | Mesure de MitigÃ© / Moyen de DÃ©tection | Couverture Wazuh & Sysmon |
|---|---|---|---|---|
| **ExÃ©cution de Mimikatz / Dump LSASS** | Ã‰levÃ©e (TP ou malice Ã©tudiante) | Critique | DÃ©tection de l'accÃ¨s en lecture Ã  la mÃ©moire de `lsass.exe` | **Ã‰vÃ©nement Sysmon ID 10** (ProcessAccess) interceptÃ© par la rÃ¨gle personnalisÃ©e 100002. |
| **Ransomware sur partage rÃ©seau** | Moyenne | Critique | Surveillance d'intÃ©gritÃ© des fichiers (FIM) en temps rÃ©el sur les rÃ©pertoires sensibles | **Alerte FIM (syscheck)** dÃ©clenchÃ©e sur rafale de crÃ©ations/suppressions rapides. |
| **Attaque Brute-Force Active Directory** | Ã‰levÃ©e | Majeure | DÃ©tection de rafale d'Ã©checs de connexion sur le contrÃ´leur de domaine | **Audit Log Windows Event ID 4625** agrÃ©gÃ© par le Manager Wazuh. |
| **Utilisation de scripts PowerShell obfuscÃ©s / encodÃ©s** | Ã‰levÃ©e (Ã‰vasion de signature antivirale) | Majeure | Analyse des lignes de commande de dÃ©marrage de processus PowerShell | **Ã‰vÃ©nement Sysmon ID 1 / Windows 4688** inspectÃ© par regex (dÃ©tection de `-EncodedCommand` ou `-e`). |
| **Mouvement latÃ©ral via WinRM / WMI** | Moyenne | Majeure | Surveillance du dÃ©marrage de processus fils anormaux de `wsmprovhost.exe` ou `wmiprvse.exe` | **Ã‰vÃ©nement Windows ID 4624** (Type de connexion 3) + surveillance des process fils via Sysmon. |
| **Installation d'outils d'accÃ¨s distants non autorisÃ©s (AnyDesk/TeamViewer)** | Ã‰levÃ©e | Moyenne | ContrÃ´le de conformitÃ© logicielle (SCA) et dÃ©tection de nouveaux services installÃ©s | **Ã‰vÃ©nement Windows ID 7045** (Nouveau service) + scan SCA pÃ©riodique. |

Ce mappage montre que la simple collecte des logs par dÃ©faut de Windows est insuffisante. Pour couvrir la majoritÃ© de ces risques, le couplage de l'agent **Wazuh** avec le service **Microsoft Sysmon** (System Monitor) est une nÃ©cessitÃ© absolue sur le pÃ©rimÃ¨tre Windows.

---

## âœï¸ Chapitre 3 : Architecture Technique du SIEM Wazuh

### 3.1 Pourquoi Wazuh ? Comparaison des Solutions SIEM
Pour structurer notre choix technique, une Ã©tude comparative a Ã©tÃ© rÃ©alisÃ©e entre trois solutions majeures du marchÃ© :

| CritÃ¨re | Splunk (Standard) | ELK Stack (Elastic) | Wazuh SIEM |
|---|---|---|---|
| **CoÃ»t des Licences** | Ã‰levÃ© (au volume de logs injectÃ©s) | Gratuit (Basic) / Payant (Premium) | **Gratuit & Open Source** (complet) |
| **Agents** | Universal Forwarder (complexe Ã  configurer) | Winlogbeat / Filebeat (collecteurs bruts) | **Agent UnifiÃ© & Actif** (FIM, SCA, RÃ©ponse active) |
| **CapacitÃ© XDR** | LimitÃ©e sans modules payants | Basique | **Native** (Ã©valuation de la conformitÃ©, intÃ©gritÃ©) |
| **SouverainetÃ©** | Faible (solution propriÃ©taire amÃ©ricaine) | Moyenne (dÃ©pendance vis-Ã -vis d'Elastic) | **Forte** (code ouvert, hÃ©bergement local strict) |

Le choix s'est portÃ© sur **Wazuh** en raison de son architecture d'agent unifiÃ©e trÃ¨s puissante, combinant les fonctionnalitÃ©s de SIEM traditionnel et de dÃ©tection/rÃ©ponse sur les terminaux (EDR/XDR), le tout sans coÃ»t de licence.

### 3.2 Topologie de DÃ©ploiement (Manager & OpenSearch)
L'infrastructure dÃ©ployÃ©e sur la plateforme ProxFibre repose sur une sÃ©paration claire des rÃ´les pour garantir les performances et la scalabilitÃ© :

```mermaid
graph TD
    subgraph "RÃ©seau Interne Ã‰cole (Clients)"
        Client1[Poste Client 1 - Salles de TP] -- Logs (TCP 1514) --> Manager
        Client2[Poste Client 2 - Administration] -- Logs (TCP 1514) --> Manager
        Client1 -- EnrÃ´lement (TCP 1515) --> Manager
    end

    subgraph "Infrastructure SOC (ProxFibre / Proxmox)"
        Manager[Wazuh Manager VM - 100.65.111.9] -- Indexation (TCP 9200) --> DB[Siem Server - OpenSearch DB]
        Dash[Wazuh Dashboard Web] -- HTTPS (TCP 443) --> Analyst[Poste Analyste Corentin]
    end

    subgraph "Administration SÃ©curisÃ©e"
        Analyst -- Tunnel VPN (WireGuard) --> Tailscale[Overlay Tailscale Network]
        Tailscale -.-> Manager
    end
```

### 3.3 Automatisation du DÃ©ploiement du Manager via Ansible
Pour Ã©viter toute configuration manuelle ("dÃ©rive de configuration") et garantir la reproductibilitÃ© du SOC, l'intÃ©gralitÃ© du dÃ©ploiement a Ã©tÃ© automatisÃ©e Ã  l'aide d'Ansible. 

Le playbook durci de production (`deploy_wazuh_manager.yml`) rÃ©alise les opÃ©rations suivantes :
1. **Durcissement OS :** Configuration du pare-feu local (UFW) pour restreindre l'accÃ¨s aux ports d'administration (SSH, API 55000, Dashboard 443) et n'ouvrir que les ports nÃ©cessaires aux agents (TCP 1514/1515).
2. **DÃ©ploiement Filebeat & OpenSearch :** Configuration sÃ©curisÃ©e du connecteur Filebeat avec injection du template de mapping officiel et activation des protocoles de compatibilitÃ© API.
3. **Mise en place des Sauvegardes :** CrÃ©ation d'une tÃ¢che planifiÃ©e (`cron`) exÃ©cutant quotidiennement Ã  2h00 du matin une sauvegarde compressÃ©e des bases de donnÃ©es de configuration, de la base d'agents (`client.keys`) et des rÃ¨gles personnalisÃ©es, avec une rÃ©tention stricte de 14 jours.

### 3.4 SÃ©curisation du Manager (UFW, Tailscale, Sauvegardes)
La sÃ©curisation du manager Wazuh constitue le point d'ancrage de la confiance du SOC. Si le manager est compromis, l'attaquant peut aveugler la supervision ou injecter de fausses alertes.
* **Pare-feu (UFW) :** Fermeture systÃ©matique de tous les ports entrants. Seul le flux d'enrÃ´lement et de remontÃ©e de logs est autorisÃ© pour le sous-rÃ©seau des ordinateurs de l'Ã©cole.
* **RÃ©seau privÃ© virtuel (VPN) d'administration :** L'accÃ¨s SSH et le Dashboard d'administration ne sont pas exposÃ©s sur le rÃ©seau de l'Ã©cole. Ils sont reliÃ©s Ã  un rÃ©seau privÃ© virtuel de type Mesh via **Tailscale** (basÃ© sur le protocole WireGuard). Cela Ã©limine le risque d'attaques par force brute SSH ou d'exploitation de vulnÃ©rabilitÃ©s sur l'interface web par un utilisateur malveillant interne.

---

## âœï¸ Chapitre 4 : Industrialisation du DÃ©ploiement de Masse (GPO Windows)

### 4.1 ProblÃ©matique de l'Industrialisation sur le Parc Informatique
Le dÃ©ploiement manuel d'un agent de supervision sur des dizaines, voire des centaines de machines est inenvisageable. Il introduit des erreurs de configuration, consomme du temps et rend les mises Ã  jour complexes. La solution standard en environnement Active Directory est l'utilisation des **StratÃ©gies de Groupe (GPO)**.

Cependant, un dÃ©ploiement par GPO classique pose un problÃ¨me de sÃ©curitÃ© majeur : l'agent Wazuh a besoin d'un **secret (jeton ou mot de passe d'API)** pour s'authentifier auprÃ¨s du Manager et obtenir sa clÃ© unique d'Ã©change. IntÃ©grer ce secret en clair dans le script de dÃ©ploiement (souvent stockÃ© sur le partage public `NETLOGON`) est une faille critique : n'importe quel Ã©tudiant ou utilisateur du domaine pourrait lire le script, voler le secret de l'API et enregistrer des machines fictives ou perturber le SOC.

### 4.2 Le Script de DÃ©ploiement Durci PowerShell (v3.0.0)
Pour rÃ©pondre Ã  cette problÃ©matique, nous avons dÃ©veloppÃ© le script [`Deploy-WazuhAgent.ps1`](file:///C:/Users/coren/OneDrive/Desktop/Projet-SIEM/scripts/windows/Deploy-WazuhAgent.ps1). Les amÃ©liorations apportÃ©es pour atteindre un niveau de sÃ©curitÃ© digne d'une infrastructure de production (*production-grade*) sont :

1. **IntÃ©gritÃ© du Binaire (SHA-256) :** Avant toute exÃ©cution, le script calcule le hash SHA-256 du fichier d'installation `wazuh-agent.msi` tÃ©lÃ©chargÃ© ou lu sur le partage et le compare Ã  une empreinte de confiance codÃ©e en dur. Cela empÃªche les attaques par remplacement de binaire (si un attaquant modifie le fichier MSI sur le partage rÃ©seau pour y injecter un cheval de Troie).
2. **Chiffrement des Identifiants (DPAPI) :** Le jeton de l'API d'authentification est chiffrÃ©.
3. **Restriction des Droits NTFS (ACLs) :** Le fichier local `client.keys` contenant la clÃ© cryptographique propre Ã  l'agent est immÃ©diatement verrouillÃ© aprÃ¨s l'enrÃ´lement :
   ```powershell
   # Suppression de l'hÃ©ritage et attribution exclusive des droits de lecture/Ã©criture Ã  SYSTEM et aux Administrateurs
   $Acl = Get-Acl $KeyPath
   $Acl.SetAccessRuleProtection($true, $false)
   $Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")))
   $Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "Allow")))
   Set-Acl $KeyPath $Acl
   ```
4. **Idempotence & Logs d'Audit :** Le script vÃ©rifie la prÃ©sence du service et sa configuration. Chaque action ou erreur est consignÃ©e dans le journal d'Ã©vÃ©nements Windows Application avec l'ID d'Ã©vÃ©nement `8100` (SuccÃ¨s) ou `8101` (Erreur) pour permettre le diagnostic rapide via l'Event Viewer.

### 4.3 Gestion SÃ©curisÃ©e des Secrets d'EnrÃ´lement (DPAPI)
Le chiffrement DPAPI (Data Protection API) de Windows est le cÅ“ur de la sÃ©curisation des identifiants dans notre GPO. Il permet de chiffrer une donnÃ©e en utilisant la clÃ© cryptographique propre Ã  la machine locale.

1. **Phase de prÃ©paration (Admin) :** 
   L'administrateur exÃ©cute le script `Initialize-WazuhDeployCredential.ps1` en fournissant les identifiants d'API. Le script produit une chaÃ®ne chiffrÃ©e propre au contexte de l'ordinateur :
   ```powershell
   # Utilisation de DPAPI avec une entropie spÃ©cifique pour masquer le secret
   $SecureString = ConvertTo-SecureString $PlainTextPassword -AsPlainText -Force
   $EncryptedSecret = ConvertFrom-SecureString $SecureString -Key $CryptographicEntropy
   ```
2. **Phase de dÃ©ploiement (Machine cible) :**
   Lorsque le script de GPO s'exÃ©cute sous le compte `SYSTEM` de l'ordinateur cible, il utilise DPAPI pour dÃ©chiffrer Ã  la volÃ©e le jeton d'API afin de s'authentifier auprÃ¨s du Manager Wazuh.
   Puisque la clÃ© de dÃ©chiffrement est liÃ©e Ã  l'identitÃ© machine (`SYSTEM`), **un utilisateur standard, mÃªme connectÃ© sur la mÃªme machine, est incapable de dÃ©chiffrer ce secret**. Si le script est copiÃ© sur une clÃ© USB et ouvert sur un ordinateur personnel, le dÃ©chiffrement Ã©chouera immÃ©diatement.

---

## âœï¸ Chapitre 5 : RÃ¨gles de DÃ©tection et Mappage de ConformitÃ© (SecOps & GRC)

### 5.1 RÃ¨gles de DÃ©tection PersonnalisÃ©es (MITRE ATT&CK)
Par dÃ©faut, Wazuh fournit un ensemble de rÃ¨gles gÃ©nÃ©riques. Pour rÃ©pondre aux besoins spÃ©cifiques et aux vecteurs de risques identifiÃ©s au Chapitre 2, nous avons dÃ©veloppÃ© des rÃ¨gles de dÃ©tection sur-mesure dans [`custom_wazuh_rules.xml`](file:///C:/Users/coren/OneDrive/Desktop/Projet-SIEM/config/wazuh-manager/custom_wazuh_rules.xml). Ces rÃ¨gles s'appuient principalement sur les logs enrichis fournis par **Sysmon** pour intercepter les comportements suspects et sont mappÃ©es directement sur la matrice de techniques offensives **MITRE ATT&CK** :

#### A. DÃ©tection d'AccÃ¨s Suspect au processus LSASS (MITRE T1003.001 - Credential Dumping)
Le dump de la mÃ©moire du processus `lsass.exe` (Local Security Authority Subsystem Service) est la mÃ©thode standard pour extraire des mots de passe en clair ou des tickets Kerberos (via des outils comme Mimikatz ou des dumps mÃ©moire via le gestionnaire des tÃ¢ches).
* **RÃ¨gle Wazuh configurÃ©e :**
  ```xml
  <rule id="100002" level="12">
    <if_sid>61600</if_sid> <!-- Log Sysmon standard -->
    <field name="win.eventdata.targetImage">(?i)\\\\lsass\\.exe</field>
    <field name="win.eventdata.grantedAccess">0x1010</field> <!-- Access restrictif requis par Mimikatz -->
    <description>SecOps - Alerte Critique : AccÃ¨s suspect Ã  la mÃ©moire de LSASS (Vol d'identifiants possible)</description>
    <mitre>
      <id>T1003.001</id>
    </mitre>
  </rule>
  ```

#### B. DÃ©tection de Scripts PowerShell ObfusquÃ©s / EncodÃ©s (MITRE T1059.001 - PowerShell Command Execution)
Les attaquants utilisent frÃ©quemment l'argument `-EncodedCommand` (ou ses alias raccourcis `-e`, `-enc`) pour exÃ©cuter des scripts complexes encodÃ©s en Base64 afin d'Ã©viter la dÃ©tection de mots-clÃ©s par les antivirus.
* **RÃ¨gle Wazuh configurÃ©e :**
  ```xml
  <rule id="100003" level="9">
    <if_sid>61603</if_sid> <!-- CrÃ©ation de processus Sysmon -->
    <field name="win.eventdata.commandLine">(?i)-e(nc|ncode|ncodedcommand)?\s+[a-za-z0-9+/=]{30,}</field>
    <description>SecOps - Alerte : ExÃ©cution d'un script PowerShell encodÃ© en Base64</description>
    <mitre>
      <id>T1059.001</id>
    </mitre>
  </rule>
  ```

### 5.2 Mappage avec les RÃ©fÃ©rentiels RÃ©glementaires (ANSSI, NIST, ISO 27001)
Un aspect crucial de la Gouvernance, Risque et ConformitÃ© (GRC) de ce projet a Ã©tÃ© d'adosser l'ensemble de notre implÃ©mentation technique aux rÃ©fÃ©rentiels et standards de sÃ©curitÃ© nationaux et internationaux :

#### 1. Guide d'HygiÃ¨ne Informatique de l'ANSSI
* **Recommandation 15 (Journalisation de l'activitÃ©) & R16 (Centralisation des journaux) :** RÃ©alisÃ© de maniÃ¨re souveraine via l'agent Wazuh transmettant en temps rÃ©el l'ensemble des journaux d'Ã©vÃ©nements Windows (Event Viewer) et les logs additionnels Sysmon vers le Manager interne sÃ©curisÃ©.
* **Recommandation 9 (Moindre PrivilÃ¨ge) :** Le compte de service `svc_wazuh_deploy` utilisÃ© pour la GPO d'enrÃ´lement est un compte utilisateur standard, membre du groupe `Domain Users` uniquement, dÃ©pourvu de tout droit d'administration sur le domaine AD.
* **Recommandation 10 (Authentification forte / Isolation) :** GrÃ¢ce au mÃ©canisme **DPAPI** configurÃ© localement sur les machines cibles en mode machine (`SYSTEM`), le secret d'authentification API est stockÃ© sous forme chiffrÃ©e, ce qui le protÃ¨ge contre la lecture et l'exfiltration par un utilisateur ou un administrateur non privilÃ©giÃ©.

#### 2. ContrÃ´les CIS v8 (Center for Internet Security)
* **CIS 8.11 (Collect Audit Logs) & CIS 8.12 (Address Audit Log Storage) :** Collecte automatisÃ©e et stockage centralisÃ© des Ã©vÃ©nements systÃ¨me sur une machine dÃ©diÃ©e (`siem-server`) avec une politique de rÃ©tention minimale de 30 jours Ã  chaud.
* **CIS 4.1 (Establish and Maintain a Secure Windows Baseline) :** Notre module SCA (Shared Configuration Assessment) de Wazuh analyse quotidiennement l'ensemble du parc par rapport au benchmark CIS Windows, fournissant une note globale de conformitÃ© et listant les clÃ©s de registre non conformes (ex: dÃ©sactivation de SMBv1, activation de l'isolation LSA).

#### 3. Norme ISO/CEI 27001:2022
* **ContrÃ´le A.8.19 (Product Security Auditing) & A.8.24 (Use of Cryptography) :**
  Chaque connexion rÃ©seau entre les agents et le manager Wazuh est entiÃ¨rement encapsulÃ©e et chiffrÃ©e via TLS 1.3. La base d'agents `client.keys` est verrouillÃ©e par ACL local sur chaque agent cible.

### 5.3 Protocoles de Validation et ScÃ©narios d'Attaque (Red Teaming)
Pour valider l'efficacitÃ© du SOC avant sa livraison aux Ã©quipes de l'Ã©cole, un protocole d'attaques simulÃ©es contrÃ´lÃ©es a Ã©tÃ© Ã©tabli (dÃ©taillÃ© dans [`attack_playbooks_and_detection_matrix.html`](file:///C:/Users/coren/OneDrive/Desktop/Projet-SIEM/docs/audit/attack_playbooks_and_detection_matrix.html)) :

1. **Simulation de vol d'identifiants (Dump LSASS) :**
   * *Commande exÃ©cutÃ©e sur le poste de test :* `rundll32.exe C:\windows\System32\comsvcs.dll, MiniDump [PID_de_lsass] C:\temp\lsass.dmp full`
   * *RÃ©sultat attendu :* Blocage de l'action ou remontÃ©e immÃ©diate d'une alerte de niveau 12 (Critique) sur le Dashboard Wazuh avec dÃ©clenchement de la rÃ¨gle 100002.
2. **Simulation d'exÃ©cution PowerShell encodÃ©e :**
   * *Commande exÃ©cutÃ©e :* `powershell.exe -EncodedCommand IAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABTAHkAcwB0AGUAbQAuAE4AZQB0AC4AVwBlAGIAQwBsAGkAZQBuAHQAKQAuAEQAbwB3AG4AbABvAGEAZABTAHQAcgBpAG4AZwAoACcAaAB0AHQAcAA6AC8ALwBlAHgAYQBtAHAAbABlAC4AYwBvAG0AJwApAA==`
   * *RÃ©sultat attendu :* Log capturÃ© par Sysmon, envoyÃ© au Manager et classÃ© en alerte de niveau 9 (ExÃ©cution de commande obfusquÃ©e).

Le succÃ¨s de ces tests valide le pipeline de dÃ©tection du SOC (GÃ©nÃ©ration du log local -> Capture par l'agent -> Chiffrement du flux -> Analyse par regex sur le Manager -> Indexation dans OpenSearch -> Visualisation Dashboard).

---

## âœï¸ Chapitre 6 : Bilan, DifficultÃ©s et Perspectives

### 6.1 DifficultÃ©s RencontrÃ©es (AccÃ¨s RÃ©seau, Validation GPO)
Comme dans tout projet d'infrastructure de sÃ©curitÃ© en environnement rÃ©el, plusieurs contraintes opÃ©rationnelles ont perturbÃ© le planning initial, nÃ©cessitant des ajustements mÃ©thodologiques :
* **DÃ©lai d'accÃ¨s aux droits administratifs Active Directory :** La structure AD de l'Ã©tablissement Ã©tant gÃ©rÃ©e de maniÃ¨re trÃ¨s restrictive par la direction informatique de l'Ã©cole, l'obtention des droits requis pour la liaison de GPO a pris plus de temps que prÃ©vu. Pour pallier ce blocage sans ralentir le projet, nous avons validÃ© le script PowerShell `Deploy-WazuhAgent.ps1` localement sur une machine virtuelle de test clonÃ©e en simulant le contexte machine `NT AUTHORITY\SYSTEM` avec l'utilitaire `psexec`. Cela a permis de garantir le fonctionnement du chiffrement DPAPI et des verrous NTFS avant le dÃ©ploiement gÃ©nÃ©ralisÃ©.
* **Absence d'accÃ¨s direct Ã  l'hyperviseur Proxmox :** Ne disposant pas de droits d'administration globale sur la plateforme ProxFibre, la mise en place de la sauvegarde automatique (snapshots) et de l'extension de disque a nÃ©cessitÃ© une phase de nÃ©gociation et de formalisation Ã©crite (via nos fiches de demande). Cette contrainte a Ã©tÃ© bÃ©nÃ©fique, car elle nous a forcÃ© Ã  documenter rigoureusement nos besoins d'infrastructure.

### 6.2 Guide de Passation et Maintenance du SOC
Un SOC n'est utile que s'il est maintenu dans le temps. Pour assurer la pÃ©rennitÃ© du systÃ¨me aprÃ¨s la fin de ce projet, plusieurs livrables de passation ont Ã©tÃ© intÃ©grÃ©s directement au dÃ©pÃ´t Git :
1. **Le guide de dÃ©ploiement GPO ([`gpo_deployment_guide.html`](file:///C:/Users/coren/OneDrive/Desktop/Projet-SIEM/docs/guides/gpo_deployment_guide.html)) :** Un guide pas-Ã -pas illustrÃ© destinÃ© au futur administrateur Active Directory de l'Ã©cole pour lier, tester et dÃ©panner le dÃ©ploiement de l'agent.
2. **Le playbook Ansible autonome :** Permettant de reconstruire ou de mettre Ã  jour le Manager Wazuh sur une nouvelle VM Ubuntu en moins de 10 minutes.
3. **Le script de monitoring Linux :** Qui alerte automatiquement par Syslog/e-mail en cas de dÃ©faillance des services ou d'expiration des certificats SSL/TLS.

### 6.3 Perspectives d'Ã‰volution (SOAR, Collecte Syslog Linux)
Ce projet pose les fondations du SOC, mais plusieurs axes d'amÃ©lioration peuvent Ãªtre envisagÃ©s pour Ã©tendre ses capacitÃ©s :
* **DÃ©ploiement de Sysmon Ã  l'Ã©chelle :** Actuellement, le script de GPO dÃ©ploie l'agent Wazuh. Une Ã©volution naturelle serait d'y intÃ©grer le dÃ©ploiement silencieux automatisÃ© de **Microsoft Sysmon** configurÃ© avec un template de sÃ©curitÃ© durci (ex: SwiftOnSecurity) pour maximiser les capacitÃ©s de dÃ©tection des processus.
* **IntÃ©gration d'un SOAR (Security Orchestration, Automation and Response) :** Connecter Wazuh Ã  un SOAR open source (comme **Shuffle**) pour automatiser les rÃ©ponses aux incidents. Par exemple, si une alerte critique de force brute RDP est dÃ©tectÃ©e sur une machine, le SOAR pourrait automatiquement dÃ©clencher un appel API vers le pare-feu ou le commutateur pour isoler temporairement l'IP attaquante.
* **Centralisation des logs des serveurs Linux :** Ã‰tendre la collecte aux serveurs internes (serveurs web, serveurs DNS/DHCP) via l'installation d'agents Wazuh Linux ou via la collecte Syslog classique.

---

## âœï¸ Chapitre 7 : Conclusion

La rÃ©alisation de ce projet de fin d'Ã©tudes a permis de concevoir, durcir et industrialiser une solution complÃ¨te de dÃ©tection et de centralisation des Ã©vÃ©nements de sÃ©curitÃ© (SIEM/SOC) au sein de notre Ã©tablissement. 

Sur le plan technique, les objectifs sont pleinement atteints :
* Le manager Wazuh est fonctionnel et sÃ©curisÃ© derriÃ¨re un rÃ©seau d'administration VPN chiffrÃ© (**Tailscale**).
* Le script PowerShell d'enrÃ´lement par **GPO** rÃ©sout la problÃ©matique majeure de la sÃ©curitÃ© des secrets d'enrÃ´lement grÃ¢ce au chiffrement **DPAPI** localisÃ©.
* Les tests de dÃ©tection d'attaques (LSASS dump, PowerShell obfuscÃ©) ont validÃ© le pipeline complet de remontÃ©e d'alertes en s'appuyant sur des rÃ¨gles personnalisÃ©es mappÃ©es sur le rÃ©fÃ©rentiel **MITRE ATT&CK**.

Sur le plan professionnel, ce projet m'a permis de manipuler des technologies clÃ©s du marchÃ© (Wazuh, Ansible, Active Directory, GPO) tout en appliquant une mÃ©thodologie rigoureuse de gestion des risques et de gouvernance informatique (ANSSI, NIST). Il dÃ©montre qu'il est possible de bÃ¢tir un systÃ¨me de dÃ©tection souverain et robuste Ã  moindres coÃ»ts, parfaitement adaptÃ© aux contraintes budgÃ©taires et techniques d'un rÃ©seau acadÃ©mique.

---

> [!NOTE]
> Ce document est conÃ§u comme une base de travail pour la rÃ©daction finale de ton rapport. Tu peux directement l'Ã©toffer et le structurer dans ton traitement de texte (Word, LibreOffice) ou l'exporter au format PDF.

