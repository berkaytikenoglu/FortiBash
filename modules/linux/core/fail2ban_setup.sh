#!/usr/bin/env bash
# ==============================================================================
# Linux Core Engine: Fail2ban (b2fail) Intrusion Prevention & Jails
# ==============================================================================

install_fail2ban() {
    local ssh_port="${1:-22}"

    log_step "Installing & Configuring Fail2ban (b2fail) Intrusion Prevention Jails..."
    require_root "$@"

    if ! is_pkg_installed fail2ban-client; then
        pkg_install fail2ban
    fi

    local jail_conf="/etc/fail2ban/jail.local"
    cat << EOF > "$jail_conf"
# BashWAF Hardened Fail2ban Jails
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 3
banaction = iptables-multiport
backend = auto
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled  = true
port     = $ssh_port
logpath  = %(sshd_log)s
backend  = %(sshd_backend)s
maxretry = 3
bantime  = 2h

[nginx-http-auth]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log
maxretry = 3

[nginx-botsearch]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/access.log
maxretry = 2
bantime  = 12h

[nginx-limit-req]
enabled  = true
port     = http,https
logpath  = /var/log/nginx/error.log
maxretry = 5
bantime  = 1h
EOF

    service_start fail2ban

    if is_service_running fail2ban; then
        local active_jails
        active_jails="$(fail2ban-client status 2>/dev/null | grep "Number of jail:" | awk '{print $NF}' || echo "Active")"
        log_success "Fail2ban (b2fail) activated successfully (Active Jails: ${active_jails})."
    else
        log_warn "Fail2ban service could not start immediately. Please verify log paths."
    fi
}

is_fail2ban_active() {
    is_service_running fail2ban
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
    install_fail2ban "$@"
fi
