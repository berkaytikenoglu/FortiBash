#!/usr/bin/env bash
# ==============================================================================
# Linux Utility: Service Verifier & Live Test Runner
# ==============================================================================

run_service_verification() {
    log_step "Running Live Service & Security Verification Tests..."

    printf "\n"
    printf "%b┌────────────────────────────────────────┬──────────────────────┬─────────────────┐%b\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
    printf "%b│%b %-38s %b│%b %-20s %b│%b %-15s %b│%b\n" \
        "${UI_COLOR_CYAN}" "${UI_BOLD}${UI_COLOR_WHITE}" "VERIFICATION TEST" \
        "${UI_COLOR_CYAN}" "${UI_BOLD}${UI_COLOR_WHITE}" "INSTALL STATUS" \
        "${UI_COLOR_CYAN}" "${UI_BOLD}${UI_COLOR_WHITE}" "TEST RESULT" "${UI_COLOR_CYAN}" "${UI_RESET}"
    printf "%b├────────────────────────────────────────┼──────────────────────┼─────────────────┤%b\n" "${UI_COLOR_CYAN}" "${UI_RESET}"

    # 1. Nginx WAF Test
    if command -v nginx >/dev/null 2>&1; then
        if nginx -t >/dev/null 2>&1; then
            render_matrix_row "Nginx WAF Rule Integrity" "INSTALLED" "PASS (Valid)" "success"
        else
            render_matrix_row "Nginx WAF Rule Integrity" "INSTALLED" "FAIL (Syntax)" "danger"
        fi
    else
        render_matrix_row "Nginx WAF Rule Integrity" "NOT INSTALLED" "SKIPPED" "warn"
    fi

    # 2. Fail2ban (b2fail) Test
    if command -v fail2ban-client >/dev/null 2>&1; then
        local f2b_ping
        f2b_ping="$(fail2ban-client ping 2>/dev/null || echo "")"
        if [[ "$f2b_ping" == "Server replied: pong" || "$f2b_ping" == "pong" ]]; then
            local jails
            jails="$(fail2ban-client status 2>/dev/null | grep "Number of jail:" | awk '{print $NF}' || echo "Active")"
            render_matrix_row "Fail2ban (b2fail) Engine" "INSTALLED" "PASS (${jails} Jails)" "success"
        else
            render_matrix_row "Fail2ban (b2fail) Engine" "INSTALLED" "FAIL (Offline)" "danger"
        fi
    else
        render_matrix_row "Fail2ban (b2fail) Engine" "NOT INSTALLED" "SKIPPED" "warn"
    fi

    # 3. Firewall Test
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        render_matrix_row "UFW Host Firewall" "INSTALLED" "PASS (Active)" "success"
    elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state 2>/dev/null | grep -q "running"; then
        render_matrix_row "Firewalld Host Firewall" "INSTALLED" "PASS (Active)" "success"
    else
        render_matrix_row "Host Firewall" "NOT CONFIGURED" "ATTENTION" "danger"
    fi

    # 4. Kernel Sysctl Hardening Test
    local syncookies
    syncookies="$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null || echo "0")"
    if [[ "$syncookies" == "1" && -f /etc/sysctl.d/99-bashwaf-hardening.conf ]]; then
        render_matrix_row "Linux Kernel Sysctl Hardening" "CONFIGURED" "PASS (Hardened)" "success"
    elif [[ "$syncookies" == "1" ]]; then
        render_matrix_row "Linux Kernel Sysctl Hardening" "PARTIAL" "WARN (Default)" "warn"
    else
        render_matrix_row "Linux Kernel Sysctl Hardening" "NOT CONFIGURED" "FAIL (Vulnerable)" "danger"
    fi

    # 5. SSH Configuration Syntax & Hardening Test
    if command -v sshd >/dev/null 2>&1; then
        if grep -q -E "^PermitRootLogin (no|prohibit-password)" /etc/ssh/sshd_config 2>/dev/null || grep -q -E "PermitRootLogin (no|prohibit-password)" /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
            render_matrix_row "SSH Root Password Lockout" "CONFIGURED" "PASS (Locked)" "success"
        else
            render_matrix_row "SSH Root Password Lockout" "STANDARD" "WARN (Root Open)" "danger"
        fi
    else
        render_matrix_row "SSH Server (sshd)" "NOT DETECTED" "SKIPPED" "info"
    fi

    # 6. Automated Security Updates Test
    if [[ -f /etc/apt/apt.conf.d/20auto-upgrades || -f /etc/dnf/automatic.conf ]]; then
        render_matrix_row "Automated Security Updates" "CONFIGURED" "PASS (Auto-Patch)" "success"
    else
        render_matrix_row "Automated Security Updates" "NOT CONFIGURED" "WARN (Manual)" "warn"
    fi

    render_matrix_footer
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
    run_service_verification "$@"
fi
