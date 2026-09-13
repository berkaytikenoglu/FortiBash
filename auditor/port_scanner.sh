#!/usr/bin/env bash
# ==============================================================================
# BashWAF Auditor: Multi-Threaded TCP Port Scanner
# ==============================================================================

export AUDITOR_DEFAULT_PORTS="21,22,23,25,53,80,110,143,443,445,1433,2049,3306,3389,5432,6379,8080,8443,9200,27017"

resolve_service_name() {
    local port="$1"
    case "$port" in
        21)    echo "FTP" ;;
        22)    echo "SSH" ;;
        23)    echo "Telnet" ;;
        25)    echo "SMTP" ;;
        53)    echo "DNS" ;;
        80)    echo "HTTP" ;;
        110)   echo "POP3" ;;
        143)   echo "IMAP" ;;
        443)   echo "HTTPS" ;;
        445)   echo "SMB" ;;
        1433)  echo "MS-SQL" ;;
        2049)  echo "NFS" ;;
        3306)  echo "MySQL/MariaDB" ;;
        3389)  echo "RDP" ;;
        5432)  echo "PostgreSQL" ;;
        6379)  echo "Redis" ;;
        8080)  echo "HTTP-Proxy" ;;
        8443)  echo "HTTPS-Alt" ;;
        9200)  echo "Elasticsearch" ;;
        27017) echo "MongoDB" ;;
        *)     echo "Custom-Port" ;;
    esac
}

# Check TCP Port Reachability
test_port_open() {
    local ip="$1"
    local port="$2"
    local timeout_sec=1

    if command -v nc >/dev/null 2>&1; then
        nc -z -w "$timeout_sec" "$ip" "$port" >/dev/null 2>&1
        return $?
    elif command -v curl >/dev/null 2>&1; then
        curl -s --connect-timeout "$timeout_sec" "telnet://${ip}:${port}" >/dev/null 2>&1
        return $?
    fi
    return 1
}

# Scan Ports on Target Host
scan_target_ports() {
    local ip="$1"
    local port_list="${2:-$AUDITOR_DEFAULT_PORTS}"
    local temp_file
    temp_file="$(mktemp -t target_ports-XXXXXX)"

    IFS=',' read -ra ports <<< "$port_list"
    for port in "${ports[@]}"; do
        (
            if test_port_open "$ip" "$port"; then
                local svc
                svc="$(resolve_service_name "$port")"
                echo "${port}:${svc}" >> "$temp_file"
            fi
        ) &
    done
    wait

    if [[ -f "$temp_file" ]]; then
        sort -n -t: -k1 "$temp_file"
        rm -f "$temp_file"
    fi
}
