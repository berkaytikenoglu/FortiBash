#!/usr/bin/env bash
# ==============================================================================
# macOS Core Engine: Host Application Firewall & Stealth Mode
# ==============================================================================

configure_macos_firewall() {
    log_step "Configuring macOS Application Firewall (ALF) & Stealth Mode..."
    require_root "$@"

    local alf="/usr/libexec/ApplicationFirewall/socketfilterfw"

    if [[ -x "$alf" ]]; then
        "$alf" --setglobalstate on >/dev/null 2>&1
        "$alf" --setstealthmode on >/dev/null 2>&1
        "$alf" --setallowsigned on >/dev/null 2>&1
        "$alf" --setallowsignedapp on >/dev/null 2>&1
        log_success "macOS Application Firewall enabled with Stealth Mode (ICMP Blocked)."
    else
        log_warn "macOS socketfilterfw binary not found."
    fi
}

is_macos_firewall_active() {
    local alf="/usr/libexec/ApplicationFirewall/socketfilterfw"
    if [[ -x "$alf" ]]; then
        "$alf" --getglobalstate 2>/dev/null | grep -q "enabled"
        return $?
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
    detect_system_os
    configure_macos_firewall "$@"
fi
