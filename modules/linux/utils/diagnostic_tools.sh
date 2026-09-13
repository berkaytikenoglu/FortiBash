#!/usr/bin/env bash
# ==============================================================================
# Linux Utility: Diagnostic & System Analysis Tools Pack
# ==============================================================================

install_diagnostic_tools() {
    log_step "Installing Diagnostic & System Analysis Utilities..."
    require_root "$@"

    local tools=(htop lsof jq curl net-tools iproute2 rsyslog)
    pkg_install "${tools[@]}"
    log_success "Diagnostic utilities installed: ${tools[*]}."
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
    install_diagnostic_tools "$@"
fi
