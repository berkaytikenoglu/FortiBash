#!/usr/bin/env bash
# ==============================================================================
# BashWAF Auditor: Network Discovery & Vulnerability Scanner CLI
# ==============================================================================
set -e

AUDITOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# shellcheck disable=SC1091
source "$AUDITOR_DIR/discovery.sh"
# shellcheck disable=SC1091
source "$AUDITOR_DIR/port_scanner.sh"
# shellcheck disable=SC1091
source "$AUDITOR_DIR/vuln_checker.sh"
# shellcheck disable=SC1091
source "$AUDITOR_DIR/reporter.sh"

show_auditor_banner() {
    clear 2>/dev/null || true
    cat << "EOF"
 [35m
 ███╗   ██╗███████╗████████╗     █████╗ ██╗   ██╗██████╗ ██╗████████╗ ██████╗ ██████╗ 
 ████╗  ██║██╔════╝╚══██╔══╝    ██╔══██╗██║   ██║██╔══██╗██║╚══██╔══╝██╔═══██╗██╔══██╗
 ██╔██╗ ██║█████╗     ██║       ███████║██║   ██║██║  ██║██║   ██║   ██║   ██║██████╔╝
 ██║╚██╗██║██╔══╝     ██║       ██╔══██║██║   ██║██║  ██║██║   ██║   ██║   ██║██╔══██╗
 ██║ ╚████║███████╗   ██║       ██║  ██║╚██████╔╝██████╔╝██║   ██║   ╚██████╔╝██║  ██║
 ╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
 [0m
 [1;36m   » BashWAF Network Device Discovery & Vulnerability Auditor « [0m
 [2m   Multi-Platform Host Discovery, Port Inspection & Security Posture Check [0m
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

show_usage() {
    cat << EOF
Usage: bash auditor.sh [OPTIONS]

Options:
  -t, --target <IP/Subnet>  Target IP address or CIDR range (e.g. 192.168.1.10 or 192.168.1.0/24)
  -p, --ports <PortList>    Comma-separated ports to scan (e.g. 22,80,443,6379,3306)
  -j, --json <FilePath>     Export results to JSON file (e.g. audit-report.json)
  -h, --help                Show this help message

Examples:
  bash auditor.sh
  bash auditor.sh --target 192.168.1.50 --ports 22,80,443,6379
  bash auditor.sh --target 10.0.0.0/24 --json report.json
EOF
}

main() {
    local target=""
    local custom_ports="$AUDITOR_DEFAULT_PORTS"
    local json_output=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--target)
                target="$2"
                shift 2
                ;;
            -p|--ports)
                custom_ports="$2"
                shift 2
                ;;
            -j|--json)
                json_output="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    show_auditor_banner

    local live_hosts=()
    local local_ip=""
    local local_cidr=""

    if [[ -z "$target" ]]; then
        local detected
        detected="$(get_local_subnet_info)"
        local_cidr="$(echo "$detected" | cut -d'|' -f1)"
        local_ip="$(echo "$detected" | cut -d'|' -f2)"

        printf " %b[INFO]%b Local IP: %b%s%b | Subnet: %b%s%b\n\n" "\033[36m" "\033[0m" "\033[1m" "$local_ip" "\033[0m" "\033[1m" "$local_cidr" "\033[0m"

        while IFS= read -r host; do
            [[ -n "$host" ]] && live_hosts+=("$host")
        done < <(scan_live_hosts "$local_cidr")
    elif [[ "$target" == *"/"* ]]; then
        while IFS= read -r host; do
            [[ -n "$host" ]] && live_hosts+=("$host")
        done < <(scan_live_hosts "$target")
    else
        live_hosts=("$target")
    fi

    local host_count=${#live_hosts[@]}
    printf "\n %b[RESULT]%b %b%d%b active network host(s) discovered.\n\n" "\033[32m" "\033[0m" "\033[1m" "$host_count" "\033[0m"

    if [[ $host_count -eq 0 ]]; then
        printf " %b[WARNING]%b No responsive hosts found on the specified network.\n\n" "\033[33m" "\033[0m"
        exit 0
    fi

    # Resolve Hostnames
    local host_names=()
    for host in "${live_hosts[@]}"; do
        local hname
        hname="$(resolve_hostname "$host" "$local_ip")"
        host_names+=("$hname")
    done

    # Interactive Scanning Loop
    while true; do
        printf "%b┌──────┬──────────────────┬─────────────────────────────┬──────────────────────────┐%b\n" "\033[36m" "\033[0m"
        printf "%b│%b %-4s %b│%b %-16s %b│%b %-27s %b│%b %-24s %b│%b\n" \
            "\033[36m" "\033[1;37m" "NO" \
            "\033[36m" "\033[1;37m" "DEVICE IP" \
            "\033[36m" "\033[1;37m" "HOSTNAME / RESOLVED NAME" \
            "\033[36m" "\033[1;37m" "DEVICE ROLE / STATUS" "\033[36m" "\033[0m"
        printf "%b├──────┼──────────────────┼─────────────────────────────┼──────────────────────────┤%b\n" "\033[36m" "\033[0m"

        local idx=1
        for i in "${!live_hosts[@]}"; do
            local host="${live_hosts[$i]}"
            local hname="${host_names[$i]}"
            local host_type="Active Network Node"

            if [[ "$host" == "$local_ip" || "$host" == "127.0.0.1" ]]; then
                host_type="This Machine (Host)"
            elif [[ "$host" == *".1" ]]; then
                host_type="Modem / Gateway Router"
            fi

            local short_ip="$(printf "%-16.16s" "$host")"
            local short_hname="$(printf "%-27.27s" "$hname")"
            local short_type="$(printf "%-24.24s" "$host_type")"

            printf "%b│%b [%-2d] %b│%b %s %b│%b %s %b│%b %s %b│%b\n" \
                "\033[36m" "\033[1;33m" "$idx" "\033[36m" "\033[1;37m" "$short_ip" \
                "\033[36m" "\033[36m" "$short_hname" \
                "\033[36m" "\033[2m" "$short_type" "\033[36m" "\033[0m"
            ((idx++))
        done
        printf "%b└──────┴──────────────────┴─────────────────────────────┴──────────────────────────┘%b\n\n" "\033[36m" "\033[0m"

        local selected_hosts=()
        if [[ -z "$target" || "$target" == *"/"* ]]; then
            printf "%b%s%b\n" "\033[1;33m" "Select target device to inspect:" "\033[0m"
            printf "  %b[1-%d]%b Audit specific host\n" "\033[36m" "$host_count" "\033[0m"
            printf "  %b[A]%b    Audit ALL discovered hosts\n" "\033[32m" "\033[0m"
            printf "  %b[0 / B]%b Back / Exit\n\n" "\033[31m" "\033[0m"

            read -r -p " Choice [1-$host_count / A / 0]: " host_choice

            case "$host_choice" in
                0|[bB]|q|Q)
                    printf " %b[INFO]%b Exiting auditor.\n\n" "\033[33m" "\033[0m"
                    break
                    ;;
                [aA])
                    selected_hosts=("${live_hosts[@]}")
                    ;;
                *)
                    if [[ "$host_choice" =~ ^[0-9]+$ ]] && [ "$host_choice" -ge 1 ] && [ "$host_choice" -le "$host_count" ]; then
                        local target_idx=$((host_choice - 1))
                        selected_hosts=("${live_hosts[$target_idx]}")
                    else
                        printf " %b[ERROR]%b Invalid choice!\n\n" "\033[31m" "\033[0m"
                        continue
                    fi
                    ;;
            esac

            printf "\n%bPort Selection:%b Press [ENTER] for default 20 critical ports, or enter custom ports (e.g. 22,80,443,6379):\n" "\033[1;36m" "\033[0m"
            read -r -p " Ports [Default: Critical Services]: " user_ports
            local active_ports="$AUDITOR_DEFAULT_PORTS"
            if [[ -n "$user_ports" ]]; then
                active_ports="$user_ports"
            fi
        else
            selected_hosts=("${live_hosts[@]}")
            local active_ports="$custom_ports"
        fi

        printf "\n %b[STARTING]%b Auditing %d host(s)...\n" "\033[36m" "\033[0m" "${#selected_hosts[@]}"

        print_report_header

        local findings_json=()

        for host in "${selected_hosts[@]}"; do
            local open_ports
            open_ports="$(scan_target_ports "$host" "$active_ports")"

            if [[ -z "$open_ports" ]]; then
                print_report_row "$host" "-" "INFO" "No Open Ports Detected" "Scanned ports are closed or firewalled."
                continue
            fi

            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                local port svc
                port="$(echo "$line" | cut -d: -f1)"
                svc="$(echo "$line" | cut -d: -f2)"

                local audit_res
                audit_res="$(inspect_service_security "$host" "$port" "$svc")"

                IFS='|' read -r sev title detail <<< "$audit_res"
                print_report_row "$host" "${port}/${svc}" "$sev" "$title" "$detail"

                if [[ -n "$json_output" ]]; then
                    findings_json+=("{\"ip\":\"$host\",\"port\":$port,\"service\":\"$svc\",\"severity\":\"$sev\",\"title\":\"$title\",\"detail\":\"$detail\"}")
                fi
            done <<< "$open_ports"
        done

        print_report_footer

        if [[ -n "$json_output" ]]; then
            local joined_json
            joined_json="$(IFS=,; echo "${findings_json[*]}")"
            printf "{\n  \"timestamp\": \"%s\",\n  \"scanned_hosts\": %d,\n  \"findings\": [%s]\n}\n" \
                "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${#selected_hosts[@]}" "$joined_json" > "$json_output"
            printf " %b[SAVED]%b Audit report exported to: %b%s%b\n\n" "\033[32m" "\033[0m" "\033[1m" "$json_output" "\033[0m"
        fi

        if [[ -n "$target" && "$target" != *"/"* ]]; then
            break
        fi

        printf "\n%b[RETURN]%b Press [ENTER] to return to host list or enter [0] to exit: " "\033[1;36m" "\033[0m"
        read -r back_choice
        if [[ "$back_choice" == "0" || "$back_choice" == "b" || "$back_choice" == "B" || "$back_choice" == "q" ]]; then
            break
        fi
        printf "\n"
    done
}

main "$@"
