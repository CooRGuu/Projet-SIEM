# Chronogramme du Projet — SOC Wazuh Scolaire

> **Projet** : Déploiement d'un SOC scolaire basé sur Wazuh  
> **Version** : 1.0  
> **Date** : Juin 2026  
> **Durée totale** : 8 semaines  
> **Classification** : Document académique — Usage pédagogique

---

## Vue d'ensemble

Ce document présente le chronogramme détaillé du projet de déploiement d'un SOC (Security Operations Center) basé sur Wazuh dans un environnement scolaire. Le projet s'étend sur **8 semaines** et couvre l'ensemble du cycle de vie : de l'analyse des besoins à la soutenance finale.

Le diagramme de Gantt ci-dessous illustre l'enchaînement des phases, les dépendances entre tâches et les jalons clés du projet.

---

## Diagramme de Gantt

```mermaid
gantt
    title Chronogramme — Projet SOC Wazuh Scolaire
    dateFormat  YYYY-MM-DD
    axisFormat  %d/%m
    todayMarker off

    section Phase 1 — Cadrage
    Analyse des besoins et objectifs           :p1a, 2026-05-04, 5d
    Étude de l'existant (infra, réseau, AD)    :p1b, 2026-05-04, 5d
    Benchmark solutions SIEM                   :p1c, 2026-05-07, 4d
    Rédaction du cahier des charges            :p1d, after p1c, 3d
    Choix et validation de Wazuh               :milestone, m1, after p1d, 0d

    section Phase 2 — Conception
    Architecture technique détaillée           :p2a, after p1d, 4d
    Schéma réseau et flux de données           :p2b, after p1d, 3d
    Demandes d'accès AD et ProxFibre           :p2c, after p1d, 2d
    Installation et configuration Proxmox VE   :p2d, after p2c, 3d
    Provisionnement VM manager Wazuh           :p2e, after p2d, 2d
    Validation architecture                    :milestone, m2, after p2a, 0d

    section Phase 3 — Déploiement Manager
    Écriture playbooks Ansible                 :p3a, after p2e, 3d
    Déploiement Wazuh Manager via Ansible      :p3b, after p3a, 2d
    Configuration initiale ossec.conf          :p3c, after p3b, 2d
    Intégration Tailscale tunnel admin         :p3d, after p3b, 1d
    Configuration TLS et certificats           :p3e, after p3c, 1d
    Dashboard OpenSearch setup initial         :p3f, after p3c, 2d
    Tests de connectivité manager              :p3g, after p3e, 1d

    section Phase 4 — Scripts et GPO
    Développement Deploy-WazuhAgent.ps1        :p4a, after p3g, 3d
    Implémentation DPAPI gestion secrets       :p4b, after p4a, 2d
    Création GPO déploiement agent             :p4c, after p4b, 1d
    Tests en environnement lab VM de test      :p4d, after p4c, 3d
    Premier agent déployé et communicant       :milestone, m3, after p4d, 0d

    section Phase 5 — Déploiement Agents
    Déploiement progressif sur les postes      :p5a, after p4d, 4d
    Configuration des règles custom Wazuh      :p5b, after p4d, 5d
    Création des decoders personnalisés        :p5c, after p5b, 2d
    Configuration dashboards et visualisations :p5d, after p5a, 3d
    Intégration logs firewall et proxy Syslog  :p5e, after p5b, 2d
    Vérification couverture MITRE ATT&CK      :p5f, after p5b, 2d

    section Phase 6 — Tests et Tuning
    Simulations attaques brute-force malware   :p6a, after p5c, 3d
    Simulations avancées lateral movement      :p6b, after p6a, 2d
    Tuning des règles faux positifs négatifs   :p6c, after p6a, 4d
    Définition et mesure des KPIs              :p6d, after p6a, 3d
    Tests de charge et performance             :p6e, after p6b, 2d
    SOC opérationnel                           :milestone, m4, after p6c, 0d

    section Phase 7 — Documentation GRC
    Rédaction PSSI du SOC                      :p7a, after p6c, 3d
    Analyse de risques EBIOS RM simplifiée     :p7b, after p6c, 3d
    Rédaction rapport de stage                 :p7c, after p6c, 5d
    Matrice RACI et procédures exploitation    :p7d, after p7a, 2d
    Conformité RGPD registre DPIA             :p7e, after p7a, 2d
    Préparation support de soutenance          :p7f, after p7c, 3d
    Répétition soutenance                      :p7g, after p7f, 1d

    section Phase 8 — Clôture
    Remise du rapport de stage                 :p8a, after p7g, 1d
    Soutenance                                 :milestone, m5, after p8a, 0d
```

---

## Description détaillée des phases

### Phase 1 — Cadrage et analyse (Semaines 1-2)

| Élément | Détail |
|---------|--------|
| **Objectif** | Comprendre le contexte, analyser l'existant et valider le choix de la solution SIEM |
| **Activités clés** | Entretiens avec l'équipe IT, cartographie de l'infrastructure existante (AD, réseau, postes), benchmark des solutions SIEM open source (Wazuh, ELK Stack/Security, Splunk Free), rédaction du cahier des charges |
| **Livrables** | Cahier des charges, note de cadrage, compte-rendu de benchmark |
| **Jalon** | ✅ **Choix et validation de Wazuh** comme solution SIEM retenue |
| **Dépendances** | Aucune — phase initiale du projet |
| **Risques** | Accès limité à la documentation de l'infrastructure existante, indisponibilité des interlocuteurs |

**Points d'attention** :
- L'étude de l'existant doit inventorier précisément : nombre de postes, version Windows, structure AD (OUs), topologie réseau (VLANs), équipements de sécurité en place
- Le benchmark doit évaluer les critères : coût (open source vs propriétaire), facilité de déploiement, communauté, intégration AD/GPO, conformité RGPD
- La validation du choix de Wazuh nécessite l'accord du tuteur technique et du responsable informatique de l'école

---

### Phase 2 — Conception et architecture (Semaines 2-3)

| Élément | Détail |
|---------|--------|
| **Objectif** | Concevoir l'architecture technique complète et préparer l'infrastructure de virtualisation |
| **Activités clés** | Design de l'architecture (manager, agents, flux réseau), création des schémas techniques, demandes d'accès (AD admin, ProxFibre), installation de Proxmox VE, provisionnement de la VM |
| **Livrables** | Dossier d'architecture technique (DAT), schémas réseau, matrice des flux |
| **Jalon** | ✅ **Validation de l'architecture** par le tuteur technique |
| **Dépendances** | Phase 1 (choix de la solution validé) |
| **Risques** | Délais d'obtention des accès AD/ProxFibre, contraintes réseau (ports bloqués, VLANs non configurés) |

**Points d'attention** :
- L'architecture doit prévoir : la VM manager (CPU, RAM, stockage), les flux réseau (1514/TCP, 1515/TCP, 443/TCP), la segmentation réseau (VLAN serveurs), le tunnel Tailscale
- Les demandes d'accès doivent être anticipées car les délais administratifs peuvent être longs en environnement scolaire
- Le dimensionnement de la VM dépend du nombre d'agents prévu (estimer 50-200 postes)

---

### Phase 3 — Déploiement du Manager Wazuh (Semaines 3-4)

| Élément | Détail |
|---------|--------|
| **Objectif** | Déployer et configurer le manager Wazuh de manière automatisée et reproductible |
| **Activités clés** | Écriture des playbooks Ansible (installation Wazuh, configuration `ossec.conf`, TLS, Tailscale), déploiement du manager, configuration du dashboard OpenSearch, tests de connectivité |
| **Livrables** | Playbooks Ansible versionnés, manager Wazuh opérationnel, dashboard accessible, documentation de déploiement |
| **Jalon** | Manager Wazuh fonctionnel et accessible via Tailscale |
| **Dépendances** | Phase 2 (VM provisionnée, accès réseau configurés) |
| **Risques** | Problèmes de compatibilité Ansible/OS, certificats TLS invalides, tunnel Tailscale instable |

**Points d'attention** :
- Les playbooks doivent être **idempotents** : relancer le déploiement ne doit pas casser la configuration existante
- Le fichier `ossec.conf` doit utiliser des placeholders (`{{WAZUH_MANAGER_IP}}`, `{{CLUSTER_KEY}}`) pour le repository public
- L'intégration Tailscale doit être testée depuis un réseau externe pour valider l'accès distant
- Les certificats TLS doivent être générés et distribués de manière sécurisée

---

### Phase 4 — Scripts GPO et tests en lab (Semaines 4-5)

| Élément | Détail |
|---------|--------|
| **Objectif** | Créer les scripts de déploiement automatisé des agents et les valider en environnement contrôlé |
| **Activités clés** | Développement du script `Deploy-WazuhAgent.ps1`, implémentation du chiffrement DPAPI pour les secrets, création de la GPO de déploiement, tests sur VMs de lab |
| **Livrables** | Script PowerShell validé, GPO configurée, rapport de tests lab |
| **Jalon** | ✅ **Premier agent déployé** et communicant avec le manager |
| **Dépendances** | Phase 3 (manager opérationnel et joignable) |
| **Risques** | Incompatibilités PowerShell entre versions Windows, blocage par l'antivirus, droits insuffisants sur l'AD |

**Points d'attention** :
- Le script doit gérer : le téléchargement du MSI, l'installation silencieuse, la configuration de l'agent (`ossec.conf`), l'enregistrement auprès du manager, le démarrage du service
- DPAPI est utilisé pour stocker la clé d'enregistrement (`authd`) de manière sécurisée dans le contexte machine
- Les tests en lab doivent couvrir : Windows 10/11, poste déjà équipé d'un agent, poste sans connectivité au manager, double exécution de la GPO (idempotence)
- La GPO doit cibler une OU de test avant le déploiement généralisé

---

### Phase 5 — Déploiement des agents et personnalisation (Semaines 5-6)

| Élément | Détail |
|---------|--------|
| **Objectif** | Déployer les agents sur l'ensemble des postes et personnaliser la détection |
| **Activités clés** | Déploiement progressif (par OU/VLAN), création de règles custom Wazuh, développement de decoders personnalisés, configuration des dashboards de supervision, intégration des logs tiers (firewall, proxy) |
| **Livrables** | Agents déployés sur X postes, règles custom documentées, dashboards opérationnels, matrice de couverture MITRE ATT&CK |
| **Jalon** | Couverture complète des postes cibles |
| **Dépendances** | Phase 4 (script et GPO validés en lab) |
| **Risques** | Surcharge réseau lors du déploiement massif, faux positifs excessifs, incompatibilité avec certains postes |

**Points d'attention** :
- Le déploiement doit être **progressif** : commencer par 10-20 postes, valider le fonctionnement, puis étendre par vagues
- Les règles custom doivent cibler les menaces pertinentes en contexte scolaire : installation de logiciels non autorisés, tentatives de contournement du proxy, brute-force sur les comptes élèves
- Les dashboards doivent offrir une vue synthétique : nombre d'alertes par criticité, top 10 des règles déclenchées, postes les plus alertants, couverture MITRE ATT&CK
- L'intégration Syslog (firewall, proxy) enrichit la corrélation et permet la détection de menaces réseau

---

### Phase 6 — Tests de détection et tuning (Semaines 6-7)

| Élément | Détail |
|---------|--------|
| **Objectif** | Valider la capacité de détection du SOC et optimiser les règles pour réduire les faux positifs |
| **Activités clés** | Simulations d'attaques structurées (Kill Chain), tests de brute-force, exécution de malware de test (EICAR), mouvement latéral simulé, tuning des règles, définition et mesure des KPIs de performance |
| **Livrables** | Rapport de tests de détection, matrice de couverture validée, KPIs documentés, règles optimisées |
| **Jalon** | ✅ **SOC opérationnel** — taux de détection validé, faux positifs maîtrisés |
| **Dépendances** | Phase 5 (agents déployés, règles configurées) |
| **Risques** | Simulations d'attaques déclenchant des alertes réelles (communication préalable nécessaire), tuning insuffisant générant de la fatigue d'alerte |

**Points d'attention** :
- Les simulations doivent être **autorisées et encadrées** : accord écrit du responsable IT, fenêtre de test définie, postes de test isolés si possible
- Scénarios de test recommandés :
  - 🔴 **Brute-force** : tentatives de connexion multiples sur un compte AD
  - 🔴 **Malware** : exécution du fichier test EICAR, scripts PowerShell obfusqués
  - 🔴 **Mouvement latéral** : utilisation de PsExec, WMI remote, pass-the-hash
  - 🔴 **Exfiltration** : transfert de fichiers volumineux, tunneling DNS
  - 🔴 **Persistence** : création de tâches planifiées, modification du registre Run
- KPIs à mesurer : MTTD (Mean Time To Detect), taux de faux positifs, taux de couverture ATT&CK, nombre d'alertes par jour/par criticité

---

### Phase 7 — Documentation et GRC (Semaines 7-8)

| Élément | Détail |
|---------|--------|
| **Objectif** | Produire la documentation de gouvernance, rédiger le rapport de stage et préparer la soutenance |
| **Activités clés** | Rédaction de la PSSI du SOC, analyse de risques EBIOS RM, rédaction du rapport de stage, création de la matrice RACI, conformité RGPD (registre de traitement, DPIA), préparation du support de soutenance |
| **Livrables** | PSSI, analyse de risques, rapport de stage complet, matrice RACI, registre de traitement RGPD, support de soutenance |
| **Jalon** | Documentation complète validée par le tuteur |
| **Dépendances** | Phase 6 (SOC opérationnel, résultats des tests disponibles) |
| **Risques** | Manque de temps pour la rédaction, retours tardifs du tuteur |

**Points d'attention** :
- Le rapport de stage doit couvrir : contexte et problématique, état de l'art, architecture technique, réalisations, tests et résultats, bilan et perspectives
- La PSSI doit être adaptée au contexte scolaire et rester opérationnelle (pas un document théorique)
- L'analyse EBIOS RM peut être simplifiée (3 ateliers sur 5) pour rester proportionnée au périmètre du projet
- Prévoir au minimum **une répétition** de la soutenance avec le tuteur

---

### Phase 8 — Clôture et soutenance (Semaine 8)

| Élément | Détail |
|---------|--------|
| **Objectif** | Soutenir le projet devant le jury et remettre l'ensemble des livrables |
| **Activités clés** | Finalisation et remise du rapport de stage, soutenance orale (présentation + questions du jury) |
| **Livrables** | Rapport de stage final (version imprimée et numérique), support de soutenance |
| **Jalon** | ✅ **Soutenance** — présentation devant le jury |
| **Dépendances** | Phase 7 (documentation complète, rapport validé) |
| **Risques** | Stress, problèmes techniques lors de la démo live |

**Points d'attention** :
- Préparer une **démo live** du dashboard Wazuh montrant des alertes en temps réel
- Avoir un **plan B** (captures d'écran, vidéo) en cas de problème de connectivité
- Structurer la soutenance : 5 min contexte, 10 min réalisations techniques, 5 min résultats et KPIs, 5 min bilan et perspectives, 10-15 min questions

---

## Matrice des dépendances

Le tableau ci-dessous synthétise les dépendances entre les phases du projet :

```mermaid
flowchart LR
    P1["Phase 1 Cadrage"] --> P2["Phase 2 Conception"]
    P2 --> P3["Phase 3 Manager Wazuh"]
    P3 --> P4["Phase 4 Scripts GPO"]
    P4 --> P5["Phase 5 Déploiement Agents"]
    P5 --> P6["Phase 6 Tests Tuning"]
    P6 --> P7["Phase 7 Documentation GRC"]
    P7 --> P8["Phase 8 Soutenance"]

    P1 -. "Benchmark Choix Wazuh" .-> P3
    P2 -. "Accès AD" .-> P4
    P3 -. "Manager UP" .-> P5
    P6 -. "Résultats tests" .-> P7

    style P1 fill:#4a90d9,stroke:#2c5aa0,color:#fff
    style P2 fill:#50b5a9,stroke:#3a8a80,color:#fff
    style P3 fill:#e8a838,stroke:#c48820,color:#fff
    style P4 fill:#e07040,stroke:#b85830,color:#fff
    style P5 fill:#9b59b6,stroke:#7d3c98,color:#fff
    style P6 fill:#e74c3c,stroke:#c0392b,color:#fff
    style P7 fill:#2ecc71,stroke:#27ae60,color:#fff
    style P8 fill:#1abc9c,stroke:#16a085,color:#fff
```

| Phase amont | Phase aval | Nature de la dépendance |
|-------------|-----------|------------------------|
| Phase 1 — Cadrage | Phase 2 — Conception | Le choix de la solution SIEM conditionne l'architecture technique |
| Phase 2 — Conception | Phase 3 — Manager | La VM Proxmox et les accès réseau doivent être provisionnés |
| Phase 3 — Manager | Phase 4 — Scripts & GPO | Le manager doit être opérationnel pour tester l'enregistrement des agents |
| Phase 4 — Scripts & GPO | Phase 5 — Déploiement | Le script et la GPO doivent être validés en lab avant le déploiement en production |
| Phase 5 — Déploiement | Phase 6 — Tests | Les agents doivent être déployés pour exécuter les simulations d'attaques |
| Phase 6 — Tests | Phase 7 — Documentation | Les résultats des tests alimentent le rapport de stage et les documents GRC |
| Phase 7 — Documentation | Phase 8 — Soutenance | Le rapport et le support de soutenance doivent être finalisés avant la soutenance |
| Phase 2 — Conception | Phase 4 — Scripts & GPO | Les accès AD sont nécessaires pour créer la GPO (dépendance transverse) |
| Phase 3 — Manager | Phase 5 — Déploiement | Le manager doit rester accessible pendant toute la durée du déploiement |

---

## Jalons clés du projet

| # | Jalon | Phase | Date prévisionnelle | Critères de validation |
|---|-------|-------|--------------------|-----------------------|
| M1 | **Choix et validation de Wazuh** | Phase 1 | Fin semaine 2 | Cahier des charges validé, benchmark documenté, accord du tuteur |
| M2 | **Validation de l'architecture** | Phase 2 | Fin semaine 3 | DAT validé, VM provisionnée, accès AD et ProxFibre obtenus |
| M3 | **Premier agent déployé** | Phase 4 | Fin semaine 5 | Agent communicant avec le manager, logs visibles dans le dashboard |
| M4 | **SOC opérationnel** | Phase 6 | Fin semaine 7 | Taux de détection ≥ 80%, faux positifs < 20%, dashboards opérationnels |
| M5 | **Soutenance** | Phase 8 | Semaine 8 | Rapport remis, présentation effectuée, questions du jury traitées |

---

## Indicateurs de suivi

Pour assurer le bon déroulement du projet, les indicateurs suivants sont suivis hebdomadairement :

| Indicateur | Cible | Méthode de mesure |
|------------|-------|-------------------|
| Avancement global | Selon planning Gantt | % de tâches terminées par phase |
| Nombre d'agents déployés | 100% des postes cibles | Dashboard Wazuh — agents connectés |
| Taux de détection | ≥ 80% des scénarios de test | Ratio alertes générées / attaques simulées |
| Taux de faux positifs | < 20% des alertes totales | Analyse manuelle des alertes sur 7 jours |
| Couverture MITRE ATT&CK | ≥ 15 techniques couvertes | Matrice de couverture documentée |
| Respect des délais | 0 jour de retard | Comparaison planning prévisionnel / réel |

---

> **Note** : Ce chronogramme est un document de référence, ajustable en fonction des contraintes rencontrées en cours de projet. Toute modification significative du planning doit être validée avec le tuteur technique et documentée dans le rapport de stage.
