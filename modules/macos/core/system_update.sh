#!/usr/bin/env bash
# ==============================================================================
# macOS Core Engine: System Updates & Security Patches
# ==============================================================================

apply_macos_updates() {
    log_step "Checking macOS Software Updates & Homebrew Packages..."

    if command -v brew >/dev/null 2>&1; then
        log_info "Upgrading Homebrew packages..."
        brew update && brew upgrade
    fi

    log_info "Checking Apple system software updates..."
    softwareupdate -l
    log_success "macOS update check completed."
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    detect_system_os
    apply_macos_updates "$@"
fi
