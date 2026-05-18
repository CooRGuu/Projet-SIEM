# Projet-SIEM

## Analyse critique (Production)
1. VirtualBox + logique “labo” : inacceptable pour la production école (pas de HA sérieuse, limites réseau/stockage, maintenance fragile). Base attendue : hyperviseur entreprise (Proxmox/ESXi), segmentation réseau et plan de reprise.
2. Stack SIEM monolithique “Elastic de base + scripts Python” : trop artisanal. Il faut une architecture Wazuh durable (manager/indexer séparés selon charge), pipeline de logs gouverné (rétention, priorisation, coût stockage) et supervision de capacité.
3. Exploitation non cadrée : sans RBAC strict, runbooks (maintenance/rollback), gestion des secrets/TLS et stratégie de sauvegarde/restauration testée, ton SOC n’est pas exploitable en production.

## Première question bloquante (S1-S2)
Donne l’inventaire **réel** disponible à l’école pour héberger le SOC :
- nombre de serveurs physiques,
- CPU (modèle + cœurs),
- RAM,
- stockage (type, capacité, IOPS mesurés),
- hyperviseur autorisé (Proxmox/ESXi),
- contraintes réseau (VLAN, pare-feu, IP disponibles),
- exigence de disponibilité (RPO/RTO).
