#!/usr/bin/env bash
# ==============================================================================
# Linux Core Engine: Kernel & Network Sysctl Hardening
# ==============================================================================

apply_sysctl_hardening() {
    log_step "Hardening Linux Kernel & Network Stack Parameters..."
    require_root "$@"

    local target_conf="/etc/sysctl.d/99-bashwaf-hardening.conf"
    local source_conf="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../config" && pwd)/sysctl_hardening.conf"

    if [[ -f "$source_conf" ]]; then
        cp "$source_conf" "$target_conf"
    else
        # Embedded fallback
        cat << 'EOF' > "$target_conf"
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
kernel.randomize_va_space = 2
fs.suid_dumpable = 0
EOF
    fi

    if sysctl --system >/dev/null 2>&1 || sysctl -p "$target_conf" >/dev/null 2>&1; then
        log_success "Sysctl parameters applied (SYN Cookies: ON, ASLR: ON, RP Filter: ON)."
    else
        log_warn "Some sysctl parameters could not be applied due to virtualization constraints."
    fi
}

is_sysctl_hardened() {
    local syncookies
    syncookies="$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null || echo "0")"
    [[ "$syncookies" == "1" && -f /etc/sysctl.d/99-bashwaf-hardening.conf ]]
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
    apply_sysctl_hardening "$@"
fi
