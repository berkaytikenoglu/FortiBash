#!/usr/bin/env bash
# ==============================================================================
# Windows/WSL Core Engine: Windows Defender Firewall & Port Proxy Guide
# ==============================================================================

configure_windows_firewall_bridge() {
    log_step "Windows Firewall Port Proxy & Bridging Guide for WAF..."

    cat << "EOF"
To bridge incoming port 80/443 traffic from Windows Host to WSL2 WAF:

Run in Administrator PowerShell on Windows Host:
--------------------------------------------------------------------------------
# 1. Add Portproxy rule (Forwarding Port 80 from Windows to WSL IP):
$wslIp = (wsl hostname -I).Trim()
netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=$wslIp

# 2. Allow inbound port in Windows Defender Firewall:
New-NetFirewallRule -DisplayName "BashWAF HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "BashWAF HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow
--------------------------------------------------------------------------------
EOF
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    detect_system_os
    configure_windows_firewall_bridge "$@"
fi
