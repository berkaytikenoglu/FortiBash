#!/usr/bin/env bash
# ==============================================================================
# BashWAF Auditor: Terminal Matrix & JSON Report Generator
# ==============================================================================

print_report_header() {
    printf "\n"
    printf "%b┌──────────────────┬──────────────┬────────────┬─────────────────────────────┬────────────────────────────────────────────────────────┐%b\n" "\033[36m" "\033[0m"
    printf "%b│%b %-16s %b│%b %-12s %b│%b %-10s %b│%b %-27s %b│%b %-54s %b│%b\n" \
        "\033[36m" "\033[1;37m" "TARGET IP" \
        "\033[36m" "\033[1;37m" "PORT/SERVICE" \
        "\033[36m" "\033[1;37m" "SEVERITY" \
        "\033[36m" "\033[1;37m" "FINDING / ISSUE" \
        "\033[36m" "\033[1;37m" "DETAILS / REMEDIATION" "\033[36m" "\033[0m"
    printf "%b├──────────────────┼──────────────┼────────────┼─────────────────────────────┼────────────────────────────────────────────────────────┤%b\n" "\033[36m" "\033[0m"
}

print_report_row() {
    local ip="$1"
    local port_svc="$2"
    local severity="$3"
    local title="$4"
    local detail="$5"

    local sev_fmt=""
    case "$severity" in
        CRITICAL) sev_fmt="\033[1;41;37m CRITICAL \033[0m" ;;
        HIGH)     sev_fmt="\033[1;31m   HIGH   \033[0m" ;;
        MEDIUM)   sev_fmt="\033[1;33m  MEDIUM  \033[0m" ;;
        LOW)      sev_fmt="\033[36m   LOW    \033[0m" ;;
        *)        sev_fmt="\033[2m   INFO   \033[0m" ;;
    esac

    local short_ip="$(printf "%-16.16s" "$ip")"
    local short_port="$(printf "%-12.12s" "$port_svc")"
    local short_title="$(printf "%-27.27s" "$title")"
    local short_detail="$(printf "%-54.54s" "$detail")"

    printf "\033[36m│\033[0m %s \033[36m│\033[0m %s \033[36m│\033[0m %b \033[36m│\033[0m %s \033[36m│\033[0m %s \033[36m│\033[0m\n" \
        "$short_ip" "$short_port" "$sev_fmt" "$short_title" "$short_detail"
}

print_report_footer() {
    printf "%b└──────────────────┴──────────────┴────────────┴─────────────────────────────┴────────────────────────────────────────────────────────┘%b\n\n" "\033[36m" "\033[0m"
}
