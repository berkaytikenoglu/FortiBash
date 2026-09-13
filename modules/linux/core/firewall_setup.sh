#!/usr/bin/env bash
# ==============================================================================
# Linux Core Engine: Advanced UFW / Firewalld Manager & Port Controller
# ==============================================================================

# Configure Baseline Secure Firewall
configure_firewall() {
    local ssh_port="${1:-22}"
    local allow_web="${2:-true}"

    log_step "Applying Standard Baseline Firewall Rules..."
    require_root "$@"

    if command -v ufw >/dev/null 2>&1; then
        log_info "Configuring UFW (Uncomplicated Firewall)..."
        ufw --force reset >/dev/null 2>&1
        ufw default deny incoming >/dev/null 2>&1
        ufw default allow outgoing >/dev/null 2>&1

        # Rate-limited SSH port to protect against automated brute-force attempts
        ufw limit "${ssh_port}/tcp" comment 'SSH Rate Limited' >/dev/null 2>&1

        if [[ "$allow_web" == "true" ]]; then
            ufw allow 80/tcp comment 'HTTP Web Traffic' >/dev/null 2>&1
            ufw allow 443/tcp comment 'HTTPS Web Traffic' >/dev/null 2>&1
        fi

        echo "y" | ufw enable >/dev/null 2>&1
        service_start ufw
        log_success "UFW Firewall configured with baseline policies (Default Deny Inbound, Allow Web & SSH)."

    elif command -v firewall-cmd >/dev/null 2>&1; then
        log_info "Configuring Firewalld..."
        service_start firewalld
        firewall-cmd --permanent --zone=public --set-target=DROP >/dev/null 2>&1 || true
        firewall-cmd --permanent --add-port="${ssh_port}/tcp" >/dev/null 2>&1

        if [[ "$allow_web" == "true" ]]; then
            firewall-cmd --permanent --add-service=http >/dev/null 2>&1
            firewall-cmd --permanent --add-service=https >/dev/null 2>&1
        fi

        firewall-cmd --reload >/dev/null 2>&1
        log_success "Firewalld rules applied successfully."
    else
        log_warn "Installing firewall package..."
        pkg_install ufw || pkg_install firewalld
        configure_firewall "$ssh_port" "$allow_web"
    fi
}

# Check if Firewall is Active
is_firewall_active() {
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        return 0
    elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state 2>/dev/null | grep -q "running"; then
        return 0
    fi
    return 1
}

# Print Active Firewall Rules in a Formatted Matrix
show_firewall_rules() {
    printf "\n%b┌── ACTIVE FIREWALL RULES & OPEN PORTS ──────────────────────────────────────────┐%b\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
    if command -v ufw >/dev/null 2>&1; then
        local raw_status
        raw_status="$(ufw status numbered 2>/dev/null || true)"
        if echo "$raw_status" | grep -q "Status: inactive"; then
            printf "│ %bStatus: INACTIVE (Firewall is turned off, all ports open!)%b                │\n" "${UI_COLOR_RED}" "${UI_RESET}"
        else
            printf "%s\n" "$raw_status" | sed 's/^/│ /'
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --list-all 2>/dev/null | sed 's/^/│ /'
    else
        printf "│ No supported firewall tool (UFW / Firewalld) detected.                       │\n"
    fi
    printf "%b└───────────────────────────────────────────────────────────────────────────────┘%b\n\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
}

# Interactive UFW & Port Management Console
manage_firewall_interactive() {
    require_root "$@"

    if ! command -v ufw >/dev/null 2>&1 && ! command -v firewall-cmd >/dev/null 2>&1; then
        log_info "Installing UFW Firewall package..."
        pkg_install ufw
    fi

    while true; do
        show_banner
        printf " %b[MODULE]%b %bAdvanced UFW Firewall & Port Management Console%b\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_WHITE}" "${UI_RESET}"
        printf " %b[INFO]%b Controls inbound/outbound network traffic, open ports, and IP rules.\n" "${UI_COLOR_CYAN}" "${UI_RESET}"

        show_firewall_rules

        printf "%b┌── 🔧 [FIREWALL OPERATIONS & ACTIONS] ──────────────────────────────────────┐%b\n" "\033[1;38;5;46m" "${UI_RESET}"
        printf "│  %b[1]%b %bQuick Open Port%b (e.g. 80, 443, 3000, 8080/tcp or 53/udp)           │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_GREEN}" "${UI_RESET}"
        printf "│  %b[2]%b %bDelete / Remove Rule%b (Delete rule by number safely)                  │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_RED}" "${UI_RESET}"
        printf "│  %b[3]%b %bWhitelist IP Address%b (Allow full or specific access to trusted IP)  │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_GREEN}" "${UI_RESET}"
        printf "│  %b[4]%b %bBlacklist / Block IP%b (Instantly DROP all packets from malicious IP) │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_RED}" "${UI_RESET}"
        printf "│  %b[5]%b %bEnable Port Rate-Limiting%b (Protect SSH/services from brute-force)   │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_YELLOW}" "${UI_RESET}"
        printf "│  %b[6]%b %bReset to Secure Baseline%b (Deny Inbound, Allow Outbound, Open Web)  │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_CYAN}" "${UI_RESET}"
        printf "│  %b[7]%b %bToggle Firewall State%b (Enable / Disable UFW)                         │\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_MAGENTA}" "${UI_RESET}"
        printf "%b└───────────────────────────────────────────────────────────────────────────┘%b\n" "\033[1;38;5;46m" "${UI_RESET}"

        printf "  %b[R]%b Refresh Rules    %b[0 / B]%b Return to Main Menu\n\n" "${UI_COLOR_CYAN}" "${UI_RESET}" "${UI_COLOR_RED}" "${UI_RESET}"

        read -r -p " Choose an operation [1-7 / R / 0]: " fw_choice
        case "$fw_choice" in
            1)
                printf "\n%b[TIP]%b Enter port number and optional protocol (e.g. 8080 or 8080/tcp or 53/udp).\n" "${UI_COLOR_YELLOW}" "${UI_RESET}"
                read -r -p " Port to open: " user_port
                read -r -p " Comment/Description (e.g. Node Backend): " user_comment
                if [[ -n "$user_port" ]]; then
                    if [[ -n "$user_comment" ]]; then
                        ufw allow "$user_port" comment "$user_comment"
                    else
                        ufw allow "$user_port"
                    fi
                    log_success "Port $user_port opened successfully."
                fi
                read -r -p "Press [ENTER] to continue..."
                ;;
            2)
                printf "\n%b[TIP]%b Check the rule numbers in the table above (e.g. [ 1], [ 2]).\n" "${UI_COLOR_YELLOW}" "${UI_RESET}"
                read -r -p " Rule number to delete: " rule_num
                if [[ -n "$rule_num" && "$rule_num" =~ ^[0-9]+$ ]]; then
                    echo "y" | ufw delete "$rule_num"
                    log_success "Rule #$rule_num deleted."
                else
                    log_error "Invalid rule number."
                fi
                read -r -p "Press [ENTER] to continue..."
                ;;
            3)
                printf "\n%b[TIP]%b Allows all incoming connections from a specific trusted IP or CIDR subnet (e.g. 192.168.1.100 or 10.0.0.0/24).\n" "${UI_COLOR_YELLOW}" "${UI_RESET}"
                read -r -p " Trusted IP or Subnet to whitelist: " trusted_ip
                read -r -p " Specific port only (Optional, press ENTER for all ports): " target_p
                if [[ -n "$trusted_ip" ]]; then
                    if [[ -n "$target_p" ]]; then
                        ufw allow from "$trusted_ip" to any port "$target_p" comment "Whitelist $trusted_ip on $target_p"
                    else
                        ufw allow from "$trusted_ip" comment "Whitelist $trusted_ip"
                    fi
                    log_success "Trusted IP $trusted_ip whitelisted successfully."
                fi
                read -r -p "Press [ENTER] to continue..."
                ;;
            4)
                printf "\n%b[TIP]%b Instantly drops all traffic from a suspicious or attacker IP (e.g. 203.0.113.50).\n" "${UI_COLOR_YELLOW}" "${UI_RESET}"
                read -r -p " Malicious IP to block: " block_ip
                if [[ -n "$block_ip" ]]; then
                    ufw insert 1 deny from "$block_ip" to any comment "Blocked Malicious IP $block_ip"
                    log_success "IP $block_ip blocked at highest priority (Rule #1)."
                fi
                read -r -p "Press [ENTER] to continue..."
                ;;
            5)
                printf "\n%b[TIP]%b Rate-limiting denies connections from an IP that attempts 6 or more connections within 30 seconds.\n" "${UI_COLOR_YELLOW}" "${UI_RESET}"
                read -r -p " Port to rate-limit [Default 22]: " limit_port
                limit_port="${limit_port:-22}"
                ufw limit "${limit_port}/tcp" comment "Rate Limited Port $limit_port"
                log_success "Rate-limiting enabled on port $limit_port/tcp."
                read -r -p "Press [ENTER] to continue..."
                ;;
            6)
                printf "\n%b[WARNING]%b This will reset all UFW rules to secure defaults (Deny Inbound, Allow Outbound, Open SSH & Web).\n" "${UI_COLOR_YELLOW}" "${UI_RESET}"
                read -r -p " SSH Port to keep open [22]: " reset_ssh_port
                reset_ssh_port="${reset_ssh_port:-22}"
                configure_firewall "$reset_ssh_port" "true"
                read -r -p "Press [ENTER] to continue..."
                ;;
            7)
                if is_firewall_active; then
                    ufw disable
                    log_warn "UFW Firewall is now DISABLED."
                else
                    echo "y" | ufw enable
                    log_success "UFW Firewall is now ENABLED & ACTIVE."
                fi
                read -r -p "Press [ENTER] to continue..."
                ;;
            [rR])
                continue
                ;;
            0|[bB]|q|Q)
                break
                ;;
            *)
                log_error "Invalid choice."
                sleep 1
                ;;
        esac
    done
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
    manage_firewall_interactive "$@"
fi
