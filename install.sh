#!/usr/bin/env bash
# ==============================================================================
# BashWAF: Remote Bootstrap & Universal Installer
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# If executed via pipe/curl without local tree, pull repository structure
if [[ ! -d "$SCRIPT_DIR/core" ]]; then
    TEMP_DIR="$(mktemp -d -t bashwaf-XXXXXX)"
    cd "$TEMP_DIR"
    RAW_BASE="https://raw.githubusercontent.com/berkaytikenoglu/bashwaf/main"

    mkdir -p bin config core modules/linux/core modules/linux/utils modules/macos/core modules/macos/utils modules/windows/core modules/windows/utils auditor

    # Download Core & Configs
    curl -sSL "${RAW_BASE}/core/ui.sh" -o core/ui.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/core/os_detector.sh" -o core/os_detector.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/core/package_manager.sh" -o core/package_manager.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/core/engine.sh" -o core/engine.sh 2>/dev/null || true

    curl -sSL "${RAW_BASE}/config/waf_rules.conf" -o config/waf_rules.conf 2>/dev/null || true
    curl -sSL "${RAW_BASE}/config/bad_bots.conf" -o config/bad_bots.conf 2>/dev/null || true
    curl -sSL "${RAW_BASE}/config/security_headers.conf" -o config/security_headers.conf 2>/dev/null || true
    curl -sSL "${RAW_BASE}/config/sysctl_hardening.conf" -o config/sysctl_hardening.conf 2>/dev/null || true

    # Download Linux Modules
    curl -sSL "${RAW_BASE}/modules/linux/core/auto_updates.sh" -o modules/linux/core/auto_updates.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/core/fail2ban_setup.sh" -o modules/linux/core/fail2ban_setup.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/core/firewall_setup.sh" -o modules/linux/core/firewall_setup.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/core/sysctl_hardening.sh" -o modules/linux/core/sysctl_hardening.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/core/user_hardening.sh" -o modules/linux/core/user_hardening.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/core/waf_setup.sh" -o modules/linux/core/waf_setup.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/utils/service_verifier.sh" -o modules/linux/utils/service_verifier.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/utils/diagnostic_tools.sh" -o modules/linux/utils/diagnostic_tools.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/modules/linux/utils/baseline_audit.sh" -o modules/linux/utils/baseline_audit.sh 2>/dev/null || true

    # Download Auditor Modules
    curl -sSL "${RAW_BASE}/auditor/auditor.sh" -o auditor/auditor.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/auditor/discovery.sh" -o auditor/discovery.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/auditor/port_scanner.sh" -o auditor/port_scanner.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/auditor/vuln_checker.sh" -o auditor/vuln_checker.sh 2>/dev/null || true
    curl -sSL "${RAW_BASE}/auditor/reporter.sh" -o auditor/reporter.sh 2>/dev/null || true

    chmod +x core/*.sh modules/linux/*/*.sh auditor/*.sh 2>/dev/null || true
    SCRIPT_DIR="$TEMP_DIR"
fi

# shellcheck disable=SC1091
source "$SCRIPT_DIR/core/engine.sh"
start_engine "$@"
