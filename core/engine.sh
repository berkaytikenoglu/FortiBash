#!/usr/bin/env bash
# ==============================================================================
# BashWAF Master Engine: Multi-Platform Interactive Security Controller
# ==============================================================================
set -e

CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$CORE_DIR/.." && pwd)"

# shellcheck disable=SC1091
source "$CORE_DIR/ui.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/os_detector.sh"
# shellcheck disable=SC1091
source "$CORE_DIR/package_manager.sh"

# Source Linux Modules
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/core/auto_updates.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/core/fail2ban_setup.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/core/firewall_setup.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/core/sysctl_hardening.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/core/user_hardening.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/core/waf_setup.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/utils/service_verifier.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/utils/diagnostic_tools.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/linux/utils/baseline_audit.sh" 2>/dev/null || true

# Source macOS Modules
# shellcheck disable=SC1091
source "$APP_ROOT/modules/macos/core/system_update.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/macos/core/firewall_setup.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/macos/core/ssh_hardening.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/macos/utils/diagnostic_tools.sh" 2>/dev/null || true

# Source Windows Modules
# shellcheck disable=SC1091
source "$APP_ROOT/modules/windows/core/wsl_hardening.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/windows/core/firewall_bridge.sh" 2>/dev/null || true
# shellcheck disable=SC1091
source "$APP_ROOT/modules/windows/utils/package_installer.sh" 2>/dev/null || true

# Render Linux Status Dashboard
show_linux_status_matrix() {
    render_matrix_header

    # 1. Fail2ban
    if is_fail2ban_active; then
        render_matrix_row "Fail2ban (b2fail) Engine" "INSTALLED" "ACTIVE" "success"
    elif is_pkg_installed fail2ban-client; then
        render_matrix_row "Fail2ban (b2fail) Engine" "INSTALLED" "INACTIVE" "warn"
    else
        render_matrix_row "Fail2ban (b2fail) Engine" "NOT INSTALLED" "INACTIVE" "danger"
    fi

    # 2. Nginx WAF
    if is_waf_active; then
        render_matrix_row "Nginx Web App Firewall (WAF)" "INSTALLED" "ACTIVE (Filtered)" "success"
    elif is_service_running nginx; then
        render_matrix_row "Nginx Web Server" "INSTALLED" "NO WAF RULES" "warn"
    else
        render_matrix_row "Nginx Web App Firewall (WAF)" "NOT INSTALLED" "INACTIVE" "danger"
    fi

    # 3. Firewall
    if is_firewall_active; then
        render_matrix_row "Host Firewall (UFW/Firewalld)" "CONFIGURED" "ACTIVE" "success"
    else
        render_matrix_row "Host Firewall" "NOT CONFIGURED" "ALL OPEN" "danger"
    fi

    # 4. Kernel Sysctl
    if is_sysctl_hardened; then
        render_matrix_row "Kernel Sysctl Hardening" "CONFIGURED" "HARDENED" "success"
    else
        render_matrix_row "Kernel Sysctl Hardening" "NOT CONFIGURED" "STANDARD" "warn"
    fi

    # 5. SSH Hardening
    if is_ssh_hardened; then
        render_matrix_row "SSH Root Password Lockout" "CONFIGURED" "HARDENED" "success"
    else
        render_matrix_row "SSH Root Password Lockout" "STANDARD" "ROOT OPEN" "danger"
    fi

    # 6. Auto Updates
    if is_auto_updates_active; then
        render_matrix_row "Automated Security Updates" "CONFIGURED" "ACTIVE" "success"
    else
        render_matrix_row "Automated Security Updates" "NOT CONFIGURED" "MANUAL" "warn"
    fi

    render_matrix_footer
}

# Full Linux Hardening Pipeline
run_full_linux_hardening() {
    local target_user="${1:-}"
    local ssh_port="${2:-22}"

    log_step "Starting Full Linux Hardening Pipeline..."
    install_auto_updates
    apply_user_hardening "$target_user" "$ssh_port" "false"
    apply_sysctl_hardening
    configure_firewall "$ssh_port" "true"
    install_waf
    install_fail2ban "$ssh_port"

    log_step "Full Hardening Completed! Running Live Verification Tests:"
    run_service_verification
    log_success "BashWAF enterprise protection is active on this system! 🛡️"
}

# Run Standalone Auditor Tool
run_network_auditor() {
    if [[ -f "$APP_ROOT/auditor/auditor.sh" ]]; then
        bash "$APP_ROOT/auditor/auditor.sh" "$@"
    else
        log_error "Auditor script not found at $APP_ROOT/auditor/auditor.sh"
    fi
}

# Interactive OS Selector Dialog
select_operating_system() {
    show_banner
    printf "%b%s%b\n\n" "${UI_BOLD}${UI_COLOR_YELLOW}" "SELECT TARGET OPERATING SYSTEM / ENVIRONMENT:" "${UI_RESET}"
    printf "  %b[1]%b %bLinux%b (Ubuntu, Debian, RHEL, Rocky, Alma, Arch, Alpine)\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_WHITE}" "${UI_RESET}"
    printf "  %b[2]%b %bmacOS%b (Darwin / Homebrew Application Suite)\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_WHITE}" "${UI_RESET}"
    printf "  %b[3]%b %bWindows%b (WSL2 / PowerShell Port Proxy Bridge)\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_WHITE}" "${UI_RESET}"
    printf "  %b[A]%b %bAuto-Detect%b (Detected: %b%s%b)\n" "${UI_COLOR_GREEN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_WHITE}" "${UI_RESET}" "${UI_COLOR_CYAN}" "${SYSTEM_OS^^}" "${UI_RESET}"
    printf "  %b[0]%b Exit\n\n" "${UI_COLOR_RED}" "${UI_RESET}"

    read -r -p " Choose OS [1 / 2 / 3 / A / 0]: " os_choice
    case "$os_choice" in
        1) SELECTED_OS="linux" ;;
        2) SELECTED_OS="macos" ;;
        3) SELECTED_OS="windows" ;;
        [aA]|"") SELECTED_OS="$SYSTEM_OS" ;;
        0) exit 0 ;;
        *)
            log_warn "Invalid selection. Defaulting to detected OS: $SYSTEM_OS"
            SELECTED_OS="$SYSTEM_OS"
            ;;
    esac
}

# Linux Control Menu
linux_menu() {
    while true; do
        show_banner
        printf " %b[ENVIRONMENT]%b Linux Platform (%s / %s)\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${SYSTEM_DISTRO^^}" "${SYSTEM_PKG_MGR^^}"
        show_linux_status_matrix

        printf "%b┌── 🛡️ [CORE SECURITY ENGINES] ─────────────────────────────────────────────┐%b\n" "\033[1;38;5;46m" "${UI_RESET}"
        printf "│  %b[1]%b %b⚡ Full System Hardening (Install All Engines + WAF)%b                 │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_GREEN}" "${UI_RESET}"
        printf "│  %b[2]%b Fail2ban (b2fail) Intrusion Prevention & Bot Jails                   │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[3]%b Nginx Web Application Firewall (SQLi, XSS, Bot Blocker, Rate-Limit)  │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[4]%b Host Firewall Configuration (UFW / Firewalld)                         │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[5]%b Linux Kernel (Sysctl) Network & Memory ASLR Hardening                │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[6]%b Sudo User Creation & SSH Root Password Lockout                       │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[7]%b Automated Security Updates & Unattended Upgrades                     │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;46m" "${UI_RESET}"

        printf "%b┌── 🧰 [UTILITY & DIAGNOSTIC PACK] ─────────────────────────────────────────┐%b\n" "\033[1;38;5;208m" "${UI_RESET}"
        printf "│  %b[8]%b %b📡 Network Auditor & Vulnerability Scanner (Host & Port Inspector)%b   │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_YELLOW}" "${UI_RESET}"
        printf "│  %b[9]%b Install Diagnostic Utilities (htop, lsof, jq, curl, iftop, net-tools)│\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[10]%bLocal CIS Baseline & Configuration Security Audit                    │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;208m" "${UI_RESET}"

        printf "%b┌── 🧪 [LIVE TEST & VERIFICATION RUNNER] ───────────────────────────────────┐%b\n" "\033[1;38;5;226m" "${UI_RESET}"
        printf "│  %b[11]%b%bRun Live Verification & Status Test on Installed Engines%b             │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;226m" "${UI_RESET}"

        printf "  %b[O]%b Switch OS Mode    %b[R]%b Refresh Matrix    %b[0]%b Exit\n\n" "${UI_COLOR_YELLOW}" "${UI_RESET}" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_COLOR_RED}" "${UI_RESET}"

        read -r -p " Option [0-11 / O / R]: " choice
        case "$choice" in
            1)
                read -r -p "Target Sudo Username (Optional): " uname
                read -r -p "SSH Port [Default 22]: " port
                port="${port:-22}"
                run_full_linux_hardening "$uname" "$port"
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            2)
                read -r -p "SSH Port [22]: " port
                port="${port:-22}"
                install_fail2ban "$port"
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            3)
                install_waf
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            4)
                manage_firewall_interactive
                ;;
            5)
                apply_sysctl_hardening
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            6)
                read -r -p "Target Sudo Username: " uname
                read -r -p "SSH Port [22]: " port
                port="${port:-22}"
                apply_user_hardening "$uname" "$port"
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            7)
                install_auto_updates
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            8)
                run_network_auditor
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            9)
                install_diagnostic_tools
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            10)
                run_baseline_audit
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            11)
                run_service_verification
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            [oO])
                select_operating_system
                launch_os_menu
                return
                ;;
            [rR])
                continue
                ;;
            0)
                log_info "Exiting BashWAF Suite. Stay secure!"
                exit 0
                ;;
            *)
                log_error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# macOS Control Menu
macos_menu() {
    while true; do
        show_banner
        printf " %b[ENVIRONMENT]%b macOS Platform (Version: %s / Architecture: %s)\n\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "$SYSTEM_VERSION" "$SYSTEM_ARCH"

        printf "%b┌── 🛡️ [macOS CORE SECURITY ENGINES] ──────────────────────────────────────┐%b\n" "\033[1;38;5;46m" "${UI_RESET}"
        printf "│  %b[1]%b Configure Application Firewall & Enable Stealth Mode                │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[2]%b Harden SSH Server Configuration (sshd_config)                      │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[3]%b Check macOS Software Updates & Upgrade Homebrew Packages           │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;46m" "${UI_RESET}"

        printf "%b┌── 🧰 [UTILITY & AUDITING PACK] ───────────────────────────────────────────┐%b\n" "\033[1;38;5;208m" "${UI_RESET}"
        printf "│  %b[4]%b %b📡 Network Auditor & Vulnerability Scanner (Local & Network Host)%b     │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_YELLOW}" "${UI_RESET}"
        printf "│  %b[5]%b Install Homebrew Security Tools (htop, nmap, jq, curl, iftop)      │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;208m" "${UI_RESET}"

        printf "  %b[O]%b Switch OS Mode    %b[0]%b Exit\n\n" "${UI_COLOR_YELLOW}" "${UI_RESET}" "${UI_COLOR_RED}" "${UI_RESET}"

        read -r -p " Option [0-5 / O]: " choice
        case "$choice" in
            1)
                configure_macos_firewall
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            2)
                apply_macos_ssh_hardening
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            3)
                apply_macos_updates
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            4)
                run_network_auditor
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            5)
                install_macos_diagnostics
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            [oO])
                select_operating_system
                launch_os_menu
                return
                ;;
            0)
                log_info "Exiting BashWAF. Stay secure!"
                exit 0
                ;;
            *)
                log_error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# Windows/WSL Control Menu
windows_menu() {
    while true; do
        show_banner
        printf " %b[ENVIRONMENT]%b Windows / WSL Platform (%s)\n\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "$SYSTEM_DISTRO"

        printf "%b┌── 🛡️ [WINDOWS & WSL SECURITY ENGINES] ────────────────────────────────────┐%b\n" "\033[1;38;5;46m" "${UI_RESET}"
        printf "│  %b[1]%b Apply WSL2 Linux Instance Hardening (/etc/wsl.conf)                 │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[2]%b Windows Defender Firewall & Port Proxy Guide (Port 80/443 Bridge)  │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[3]%b Install Windows Security Utilities (Winget / Chocolatey)            │\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;46m" "${UI_RESET}"

        printf "%b┌── 🧰 [UTILITY & AUDITING PACK] ───────────────────────────────────────────┐%b\n" "\033[1;38;5;208m" "${UI_RESET}"
        printf "│  %b[4]%b %b📡 Network Auditor & Vulnerability Scanner%b                           │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_YELLOW}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;208m" "${UI_RESET}"

        printf "  %b[O]%b Switch OS Mode    %b[0]%b Exit\n\n" "${UI_COLOR_YELLOW}" "${UI_RESET}" "${UI_COLOR_RED}" "${UI_RESET}"

        read -r -p " Option [0-4 / O]: " choice
        case "$choice" in
            1)
                apply_wsl_hardening
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            2)
                configure_windows_firewall_bridge
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            3)
                install_windows_tools
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            4)
                run_network_auditor
                read -r -p "Press [ENTER] to return to menu..."
                ;;
            [oO])
                select_operating_system
                launch_os_menu
                return
                ;;
            0)
                log_info "Exiting BashWAF. Stay secure!"
                exit 0
                ;;
            *)
                log_error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

launch_os_menu() {
    case "$SELECTED_OS" in
        linux) linux_menu ;;
        macos) macos_menu ;;
        windows) windows_menu ;;
        *) linux_menu ;;
    esac
}

# Main Application Entry Point
start_engine() {
    detect_system_os

    # CLI Parameter Parsing
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --os)
                SELECTED_OS="$2"
                shift 2
                ;;
            -a|--all)
                detect_system_os
                if [[ "$SYSTEM_OS" == "linux" ]]; then
                    run_full_linux_hardening
                else
                    log_warn "Full auto-hardening pipeline is designed for Linux."
                fi
                exit 0
                ;;
            -s|--status)
                detect_system_os
                show_banner
                show_linux_status_matrix
                exit 0
                ;;
            -t|--test)
                detect_system_os
                show_banner
                run_service_verification
                exit 0
                ;;
            --scan)
                shift
                run_network_auditor "$@"
                exit 0
                ;;
            -h|--help)
                show_banner
                cat << EOF
BashWAF CLI Usage: ./main.sh [OPTIONS]

Options:
  --os <linux|macos|windows>  Force specific OS execution mode
  -a, --all                   Run full Linux hardening pipeline
  -s, --status                Display live security status matrix
  -t, --test                  Run live service verification test runner
  --scan [ARGS]               Launch Network Auditor with optional args
  -h, --help                  Display this help message

Interactive Mode:
  ./main.sh                   Launch interactive OS selector & control dashboard
EOF
                exit 0
                ;;
            *)
                log_error "Unknown parameter: $1"
                exit 1
                ;;
        esac
    done

    # If no OS specified, prompt user
    if [[ -z "$SELECTED_OS" ]]; then
        select_operating_system
    fi

    launch_os_menu
}
