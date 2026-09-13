#!/usr/bin/env bash
# ==============================================================================
# BashWAF Auditor: Vulnerability & Misconfiguration Inspector
# ==============================================================================

# SSH Protocol & Security Posture Audit
audit_ssh_service() {
    local ip="$1"
    local port="$2"

    local ssh_banner
    ssh_banner="$(nc -w 2 "$ip" "$port" 2>/dev/null | head -n1 || echo "")"

    if [[ -z "$ssh_banner" ]]; then
        echo "INFO|SSH Port Open|Port $port is open but banner was not returned."
        return
    fi

    # SSH-1 Check
    if echo "$ssh_banner" | grep -qi "SSH-1"; then
        echo "CRITICAL|Legacy SSH-1 Protocol Active|Vulnerable SSH-1 protocol enabled. Must be upgraded to SSH-2."
        return
    fi

    # Authentication Probe (Password vs Publickey)
    if command -v ssh >/dev/null 2>&1; then
        local auth_probe
        auth_probe="$(ssh -o PreferredAuthentications=none -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p "$port" "probe_test@$ip" 2>&1 || true)"
        if echo "$auth_probe" | grep -qi "password\|keyboard-interactive"; then
            echo "HIGH|SSH Password Authentication Active|Server accepts password auth. Vulnerable to brute-force; enforce 'PasswordAuthentication no'."
            return
        elif echo "$auth_probe" | grep -qi "publickey"; then
            echo "INFO|SSH Secure (Public Key Only)|Server strictly requires SSH key authentication. Password auth is disabled."
            return
        fi
    fi

    # OS Banner Leakage
    if echo "$ssh_banner" | grep -qi "Ubuntu\|Debian\|CentOS\|RedHat\|Alpine"; then
        echo "LOW|SSH OS Banner Leakage|SSH banner leaks OS details: $ssh_banner"
    else
        echo "INFO|SSH Service Active|Standard SSH-2 service detected: $ssh_banner"
    fi
}

# General Service Security Audit Dispatcher
inspect_service_security() {
    local ip="$1"
    local port="$2"
    local svc_name="$3"

    case "$port" in
        22|2222|2200|2022)
            audit_ssh_service "$ip" "$port"
            ;;
        23)
            echo "CRITICAL|Telnet Service Open|Telnet transmits credentials and commands in unencrypted plaintext. Replace with SSH."
            ;;
        21)
            local ftp_banner
            ftp_banner="$( (echo "USER anonymous"; echo "PASS anonymous@test.com"; echo "QUIT") | nc -w 2 "$ip" 21 2>/dev/null || true )"
            if echo "$ftp_banner" | grep -qi "230"; then
                echo "CRITICAL|FTP Anonymous Login Enabled|Anonymous FTP login permitted. Potential unauthorized data access or tampering."
            else
                echo "MEDIUM|FTP Service Open|FTP uses cleartext data channels. Consider SFTP or FTPS."
            fi
            ;;
        6379)
            local redis_resp
            redis_resp="$( (echo "PING"; echo "QUIT") | nc -w 2 "$ip" 6379 2>/dev/null || true )"
            if echo "$redis_resp" | grep -q "+PONG"; then
                echo "CRITICAL|Unauthenticated Redis Database|Redis responds to commands without password. Critical remote data exposure."
            else
                echo "HIGH|Redis Port Open|Redis exposed to network. Bind to 127.0.0.1 or secure via firewall/VPN."
            fi
            ;;
        9200)
            local es_resp
            es_resp="$(curl -s --connect-timeout 2 "http://${ip}:9200/" 2>/dev/null || true)"
            if echo "$es_resp" | grep -q "cluster_name"; then
                echo "CRITICAL|Unauthenticated Elasticsearch Instance|Cluster metrics and indices are publicly accessible without authentication."
            else
                echo "HIGH|Elasticsearch Port Open|Elasticsearch service exposed to the network."
            fi
            ;;
        27017)
            echo "HIGH|MongoDB Port Open|Default MongoDB port is accessible. Verify auth mechanisms and network bind."
            ;;
        3306|5432|1433)
            echo "MEDIUM|Database Port Open (${svc_name})|Database port exposed directly. Restrict to authorized application IPs."
            ;;
        445|2049)
            echo "HIGH|File Sharing Port (${svc_name})|SMB/NFS network share port open. Misconfigured shares can leak sensitive files."
            ;;
        80|8080|443|8443)
            local proto="http"
            [[ "$port" == "443" || "$port" == "8443" ]] && proto="https"

            local env_check
            env_check="$(curl -s -k --connect-timeout 2 "${proto}://${ip}:${port}/.env" 2>/dev/null || true)"
            if echo "$env_check" | grep -q -E "(DB_PASSWORD|APP_KEY|SECRET_KEY|DATABASE_URL)"; then
                echo "CRITICAL|Exposed .env Configuration File|Sensitive environment file containing database passwords/keys is publicly accessible!"
                return
            fi

            local headers
            headers="$(curl -s -k -I --connect-timeout 2 "${proto}://${ip}:${port}/" 2>/dev/null || true)"
            if [[ -n "$headers" ]]; then
                local missing=()
                echo "$headers" | grep -qi "X-Frame-Options" || missing+=("X-Frame-Options")
                echo "$headers" | grep -qi "X-Content-Type-Options" || missing+=("X-Content-Type-Options")
                echo "$headers" | grep -qi "Content-Security-Policy" || missing+=("CSP")

                local server_hdr
                server_hdr="$(echo "$headers" | grep -i "^Server:" | tr -d '\r')"

                if [[ ${#missing[@]} -gt 0 ]]; then
                    echo "LOW|Missing HTTP Security Headers|Missing: ${missing[*]} | ${server_hdr}"
                else
                    echo "INFO|Web Service Active|Standard HTTP response received."
                fi
            fi
            ;;
        *)
            echo "INFO|Open Port (${svc_name})|Active service responding on port ${port}."
            ;;
    esac
}
