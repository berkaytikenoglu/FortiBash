#!/usr/bin/env bash
# ==============================================================================
# Windows/WSL Core Engine: WSL2 Linux Subsystem Hardening
# ==============================================================================

apply_wsl_hardening() {
    log_step "Hardening Windows Subsystem for Linux (WSL2) Instance..."

    # Configure /etc/wsl.conf
    local wsl_conf="/etc/wsl.conf"
    cat << 'EOF' > "$wsl_conf"
[boot]
systemd=true

[network]
generateResolvConf=true

[interop]
enabled=true
appendWindowsPath=false
EOF

    log_success "WSL configuration updated (/etc/wsl.conf systemd=true, isolated path)."
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    detect_system_os
    apply_wsl_hardening "$@"
fi
