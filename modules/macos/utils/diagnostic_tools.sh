#!/usr/bin/env bash
# ==============================================================================
# macOS Utility: Homebrew Security & Diagnostic Tools Installer
# ==============================================================================

install_macos_diagnostics() {
    log_step "Installing macOS Diagnostic Utilities via Homebrew..."

    if ! command -v brew >/dev/null 2>&1; then
        log_error "Homebrew is not installed. Please install Homebrew from https://brew.sh"
        return 1
    fi

    local tools=(htop jq curl nmap iftop)
    brew install "${tools[@]}"
    log_success "macOS tools installed: ${tools[*]}."
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    detect_system_os
    install_macos_diagnostics "$@"
fi
