#!/usr/bin/env bash
# ==============================================================================
# Linux Core Engine: Nginx Web Application Firewall (WAF) & Rate Limiter
# ==============================================================================

install_waf() {
    log_step "Installing & Configuring Nginx Web Application Firewall (WAF)..."
    require_root "$@"

    pkg_install nginx

    local waf_dir="/etc/nginx/waf"
    mkdir -p "$waf_dir"

    local cfg_source="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../config" && pwd)"

    # Copy rules from config directory or write default templates
    if [[ -d "$cfg_source" ]]; then
        cp "$cfg_source/waf_rules.conf" "$waf_dir/waf_rules.conf" 2>/dev/null || true
        cp "$cfg_source/bad_bots.conf" "$waf_dir/bad_bots.conf" 2>/dev/null || true
        cp "$cfg_source/security_headers.conf" "$waf_dir/security_headers.conf" 2>/dev/null || true
    fi

    # Fallback if config files are missing
    if [[ ! -f "$waf_dir/waf_rules.conf" ]]; then
        cat << 'EOF' > "$waf_dir/waf_rules.conf"
if ($query_string ~* "(\bunion\b.*\bselect\b|\bselect\b.*\bfrom\b|\binsert\b.*\binto\b)") { return 403; }
if ($query_string ~* "(<script|%3Cscript|javascript:|onerror=)") { return 403; }
if ($query_string ~* "(\.\./|\.\.\\|etc/passwd|/proc/self)") { return 403; }
EOF
    fi

    # Anti-DDoS Rate Limiting & Buffer Hardening
    cat << 'EOF' > /etc/nginx/conf.d/00_bashwaf_ratelimit.conf
limit_req_zone $binary_remote_addr zone=waf_rate_limit:20m rate=20r/s;
limit_req_zone $binary_remote_addr zone=waf_login_limit:10m rate=3r/s;
limit_conn_zone $binary_remote_addr zone=waf_conn_limit:10m;

client_body_buffer_size 128k;
client_max_body_size 25M;
client_header_buffer_size 1k;
large_client_header_buffers 4 8k;
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;
EOF

    # Default WAF-Protected Server Block
    cat << 'EOF' > /etc/nginx/conf.d/default_bashwaf.conf
include /etc/nginx/waf/bad_bots.conf;

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    include /etc/nginx/waf/security_headers.conf;
    include /etc/nginx/waf/waf_rules.conf;

    if ($blocked_bot) {
        return 403 "BashWAF: Malicious crawler or scanner blocked.\n";
    }

    limit_req zone=waf_rate_limit burst=30 nodelay;
    limit_conn waf_conn_limit 25;

    location / {
        root /var/www/html;
        index index.html index.htm;
        try_files $uri $uri/ =404;
    }
}
EOF

    if nginx -t >/dev/null 2>&1; then
        service_start nginx
        log_success "Nginx WAF installed and activated (SQLi/XSS filters, Bad-bot blocker & Rate-limiting)."
    else
        log_error "Nginx configuration syntax test failed! Please check 'nginx -t'."
        return 1
    fi
}

is_waf_active() {
    is_service_running nginx && [[ -f /etc/nginx/waf/waf_rules.conf ]]
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/package_manager.sh"
    detect_system_os
    install_waf "$@"
fi
