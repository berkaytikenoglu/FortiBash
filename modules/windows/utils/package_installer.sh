#!/usr/bin/env bash
# ==============================================================================
# Windows/WSL Utility: Winget & Chocolatey Security Tooling Installer
# ==============================================================================

install_windows_tools() {
    log_step "Installing Security Utilities via Winget / Chocolatey..."

    if command -v winget.exe >/dev/null 2>&1; then
        winget.exe install -e --id Insecure.Nmap --silent --accept-package-agreements --accept-source-agreements || true
        winget.exe install -e --id WiresharkFoundation.Wireshark --silent --accept-package-agreements --accept-source-agreements || true
        log_success "Windows security tools installed via Winget."
    elif command -v choco.exe >/dev/null 2>&1; then
        choco.exe install nmap wireshark curl -y || true
        log_success "Windows security tools installed via Chocolatey."
    else
        log_warn "Neither Winget nor Chocolatey found on the host."
    fi
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    detect_system_os
    install_windows_tools "$@"
fi
