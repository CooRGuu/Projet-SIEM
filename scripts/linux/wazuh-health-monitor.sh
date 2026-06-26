#!/bin/bash
# ============================================================================
#  SCRIPT DE MONITORING DE SANTÉ DU SIEM WAZUH
#  Cible : VM Ubuntu Manager (100.65.111.9)
#  Version : 1.0.0
#  Date : 2026-06-26
#
#  USAGE :
#    chmod +x wazuh-health-monitor.sh
#    ./wazuh-health-monitor.sh
#
#  CRON (toutes les 5 minutes) :
#    */5 * * * * /usr/local/bin/wazuh-health-monitor.sh >> /var/log/wazuh-health.log 2>&1
#
#  Conformité :
#    - ANSSI Mesure 38 : Surveiller les systèmes de sécurité eux-mêmes
#    - NIST SP 800-53 SI-4 : System Monitoring
#    - ISO 27001 A.8.16 : Monitoring activities
# ============================================================================

set -euo pipefail

# ── Configuration ──
WAZUH_API_URL="https://127.0.0.1:55000"
ELASTIC_URL="http://127.0.0.1:9200"
WAZUH_DIR="/var/ossec"
LOG_FILE="/var/log/wazuh-health.log"
ALERT_EMAIL="admin@school.local"    # À adapter
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ── Seuils d'alerte ──
DISK_THRESHOLD=80           # Alerte si disque > 80%
CPU_THRESHOLD=90            # Alerte si CPU > 90%
RAM_THRESHOLD=90            # Alerte si RAM > 90%
ELASTIC_YELLOW_OK=true      # Accepter le statut "yellow" (normal en single-node)
MAX_LOG_AGE_MINUTES=10      # Alerte si pas de log depuis X minutes

# ── Variables de résultat ──
ERRORS=0
WARNINGS=0
REPORT=""

# ============================================================================
# FONCTIONS
# ============================================================================

log_info()    { REPORT+="[INFO]    $TIMESTAMP | $1\n"; }
log_warn()    { REPORT+="[WARNING] $TIMESTAMP | $1\n"; WARNINGS=$((WARNINGS+1)); }
log_error()   { REPORT+="[ERROR]   $TIMESTAMP | $1\n"; ERRORS=$((ERRORS+1)); }

send_alert() {
    local subject="[ALERTE SOC] $HOSTNAME - $1"
    local body="$2"
    
    # Tentative d'envoi par mail (silencieux si mail non configuré)
    if command -v mail &>/dev/null; then
        echo -e "$body" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    
    # Journalisation syslog (toujours disponible)
    logger -t wazuh-health -p local0.err "$subject"
}

# ============================================================================
# CHECK 1 : Services Wazuh
# ============================================================================

check_wazuh_services() {
    local services=("wazuh-manager" "wazuh-analysisd" "wazuh-remoted" "wazuh-db")
    
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            log_info "Service $svc : RUNNING"
        else
            log_error "Service $svc : DOWN"
        fi
    done
}

# ============================================================================
# CHECK 2 : API Wazuh
# ============================================================================

check_wazuh_api() {
    local http_code
    http_code=$(curl -sk -o /dev/null -w "%{http_code}" "$WAZUH_API_URL/" 2>/dev/null || echo "000")
    
    if [[ "$http_code" == "200" ]]; then
        log_info "API Wazuh : ACCESSIBLE (HTTP $http_code)"
    else
        log_error "API Wazuh : INACCESSIBLE (HTTP $http_code)"
    fi
}

# ============================================================================
# CHECK 3 : Elasticsearch / OpenSearch
# ============================================================================

check_elasticsearch() {
    local health
    health=$(curl -s "$ELASTIC_URL/_cluster/health" 2>/dev/null || echo '{"status":"unreachable"}')
    
    local status
    status=$(echo "$health" | jq -r '.status' 2>/dev/null || echo "unreachable")
    
    case "$status" in
        "green")
            log_info "Elasticsearch : GREEN (cluster sain)"
            ;;
        "yellow")
            if [[ "$ELASTIC_YELLOW_OK" == "true" ]]; then
                log_info "Elasticsearch : YELLOW (normal en single-node)"
            else
                log_warn "Elasticsearch : YELLOW (réplication partielle)"
            fi
            ;;
        "red")
            log_error "Elasticsearch : RED (données potentiellement perdues !)"
            ;;
        *)
            log_error "Elasticsearch : INACCESSIBLE ($status)"
            ;;
    esac
    
    # Vérifier l'espace disque des index
    local disk_used
    disk_used=$(echo "$health" | jq -r '.active_shards // 0' 2>/dev/null || echo "0")
    log_info "Elasticsearch : $disk_used shards actifs"
}

# ============================================================================
# CHECK 4 : Agents connectés
# ============================================================================

check_agents() {
    local agents_file="$WAZUH_DIR/var/db/agents.db"
    
    if [[ -f "$agents_file" ]]; then
        # Compter les agents actifs (dernière connexion < 10 min)
        local total
        total=$(sqlite3 "$agents_file" "SELECT COUNT(*) FROM agent WHERE id != 0;" 2>/dev/null || echo "0")
        local active
        active=$(sqlite3 "$agents_file" "SELECT COUNT(*) FROM agent WHERE id != 0 AND connection_status = 'active';" 2>/dev/null || echo "0")
        
        log_info "Agents : $active/$total actifs"
        
        if [[ "$active" -eq 0 && "$total" -gt 0 ]]; then
            log_warn "Aucun agent actif sur $total enregistrés"
        fi
    else
        log_warn "Base agents introuvable ($agents_file)"
    fi
}

# ============================================================================
# CHECK 5 : Ressources système
# ============================================================================

check_system_resources() {
    # CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2 + $4)}')
    if [[ "$cpu_usage" -gt "$CPU_THRESHOLD" ]]; then
        log_error "CPU : ${cpu_usage}% (seuil: ${CPU_THRESHOLD}%)"
    else
        log_info "CPU : ${cpu_usage}%"
    fi
    
    # RAM
    local ram_usage
    ram_usage=$(free | awk 'NR==2{printf "%d", $3*100/$2}')
    if [[ "$ram_usage" -gt "$RAM_THRESHOLD" ]]; then
        log_error "RAM : ${ram_usage}% (seuil: ${RAM_THRESHOLD}%)"
    else
        log_info "RAM : ${ram_usage}%"
    fi
    
    # Disque
    local disk_usage
    disk_usage=$(df / | awk 'NR==2{print int($5)}')
    if [[ "$disk_usage" -gt "$DISK_THRESHOLD" ]]; then
        log_error "DISQUE : ${disk_usage}% (seuil: ${DISK_THRESHOLD}%)"
    else
        log_info "DISQUE : ${disk_usage}%"
    fi
}

# ============================================================================
# CHECK 6 : Fraîcheur des logs
# ============================================================================

check_log_freshness() {
    local alerts_log="$WAZUH_DIR/logs/alerts/alerts.log"
    
    if [[ -f "$alerts_log" ]]; then
        local last_modified
        last_modified=$(stat -c %Y "$alerts_log" 2>/dev/null || echo "0")
        local now
        now=$(date +%s)
        local age_minutes=$(( (now - last_modified) / 60 ))
        
        if [[ "$age_minutes" -gt "$MAX_LOG_AGE_MINUTES" ]]; then
            log_warn "Fichier alerts.log non modifié depuis ${age_minutes} minutes (seuil: ${MAX_LOG_AGE_MINUTES} min)"
        else
            log_info "Fraîcheur des logs : ${age_minutes} min (OK)"
        fi
    else
        log_warn "Fichier alerts.log introuvable"
    fi
}

# ============================================================================
# CHECK 7 : Certificat TLS (expiration)
# ============================================================================

check_tls_certificate() {
    local cert_file="$WAZUH_DIR/api/configuration/ssl/server.crt"
    
    if [[ -f "$cert_file" ]]; then
        local expiry_date
        expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
        local expiry_epoch
        expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
        local now
        now=$(date +%s)
        local days_remaining=$(( (expiry_epoch - now) / 86400 ))
        
        if [[ "$days_remaining" -lt 30 ]]; then
            log_error "Certificat TLS expire dans $days_remaining jours ! ($expiry_date)"
        elif [[ "$days_remaining" -lt 90 ]]; then
            log_warn "Certificat TLS expire dans $days_remaining jours ($expiry_date)"
        else
            log_info "Certificat TLS : valide ($days_remaining jours restants)"
        fi
    else
        log_warn "Certificat TLS introuvable ($cert_file)"
    fi
}

# ============================================================================
# EXÉCUTION
# ============================================================================

echo "========================================"
echo " Wazuh Health Monitor - $TIMESTAMP"
echo "========================================"

check_wazuh_services
check_wazuh_api
check_elasticsearch
check_agents
check_system_resources
check_log_freshness
check_tls_certificate

# ── Affichage du rapport ──
echo -e "$REPORT"

# ── Résumé ──
echo "----------------------------------------"
echo " Résumé : $ERRORS erreur(s), $WARNINGS avertissement(s)"
echo "----------------------------------------"

# ── Alerte si erreurs ──
if [[ "$ERRORS" -gt 0 ]]; then
    send_alert "$ERRORS erreur(s) détectée(s)" "$REPORT"
    echo "[ALERTE ENVOYÉE] $ERRORS erreur(s) critique(s) détectée(s)."
    exit 1
fi

exit 0
