#!/usr/bin/env bash
# ==============================================================================
# Linux Core Engine: Automated Security Updates & Patching
# ==============================================================================

install_auto_updates() {
    log_step "Configuring Automatic Security Updates & Patches..."
    require_root "$@"

    pkg_update

    case "$SYSTEM_PKG_MGR" in
        apt)
            pkg_install unattended-upgrades apt-listchanges
            cat << 'EOF' > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
            service_start unattended-upgrades
            log_success "Debian/Ubuntu unattended-upgrades configured successfully."
            ;;
        dnf|yum)
            pkg_install dnf-automatic
            if [[ -f /etc/dnf/automatic.conf ]]; then
                sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf 2>/dev/null || true
            fi
            systemctl enable --now dnf-automatic.timer >/dev/null 2>&1 || true
            log_success "RHEL/CentOS dnf-automatic service configured successfully."
            ;;
        *)
            log_warn "Automated background update service not natively supported on $SYSTEM_DISTRO."
            ;;
    esac
}

is_auto_updates_active() {
    if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]] || systemctl is-enabled dnf-automatic.timer >/dev/null 2>&1; then
        return 0
    fi
    return 1
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
    install_auto_updates "$@"
fi
