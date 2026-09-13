#!/usr/bin/env bash
# ==============================================================================
# macOS Core Engine: SSH Server Hardening
# ==============================================================================

apply_macos_ssh_hardening() {
    log_step "Hardening macOS SSH Server Configuration..."
    require_root "$@"

    local sshd_config="/etc/ssh/sshd_config"
    if [[ ! -f "$sshd_config" ]]; then
        log_error "SSH configuration not found: $sshd_config"
        return 1
    fi

    sed -i '' -E 's/^#?PermitRootLogin .*/PermitRootLogin no/' "$sshd_config" 2>/dev/null || true
    sed -i '' -E 's/^#?PermitEmptyPasswords .*/PermitEmptyPasswords no/' "$sshd_config" 2>/dev/null || true
    sed -i '' -E 's/^#?PasswordAuthentication .*/PasswordAuthentication no/' "$sshd_config" 2>/dev/null || true

    log_success "macOS SSH Server hardened (Root Login: NO, Password Auth: NO)."
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    detect_system_os
    apply_macos_ssh_hardening "$@"
fi
