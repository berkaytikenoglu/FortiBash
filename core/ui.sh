#!/usr/bin/env bash
# ==============================================================================
# BashWAF Core UI & Terminal Styling Library
# ==============================================================================

# ANSI Color & Style Constants
export UI_RESET="\033[0m"
export UI_BOLD="\033[1m"
export UI_DIM="\033[2m"
export UI_UNDERLINE="\033[4m"

export UI_COLOR_BLACK="\033[30m"
export UI_COLOR_RED="\033[31m"
export UI_COLOR_GREEN="\033[32m"
export UI_COLOR_YELLOW="\033[33m"
export UI_COLOR_BLUE="\033[34m"
export UI_COLOR_MAGENTA="\033[35m"
export UI_COLOR_CYAN="\033[36m"
export UI_COLOR_WHITE="\033[37m"

# Status Badges
export BADGE_SUCCESS="${UI_COLOR_GREEN}✔ INSTALLED${UI_RESET}"
export BADGE_ACTIVE="${UI_COLOR_GREEN}✔ ACTIVE${UI_RESET}"
export BADGE_MISSING="${UI_COLOR_RED}✖ NOT INSTALLED${UI_RESET}"
export BADGE_INACTIVE="${UI_COLOR_RED}✖ INACTIVE${UI_RESET}"
export BADGE_WARN="${UI_COLOR_YELLOW}⚠ ATTENTION${UI_RESET}"
export BADGE_INFO="${UI_COLOR_CYAN}ℹ OPTIONAL${UI_RESET}"

# Logging Functions
log_info() {
    printf " %b  %b[INFO]%b %s\n" "${UI_COLOR_CYAN}ℹ${UI_RESET}" "${UI_COLOR_CYAN}" "${UI_RESET}" "$*"
}

log_success() {
    printf " %b  %b[SUCCESS]%b %s\n" "${UI_COLOR_GREEN}✔${UI_RESET}" "${UI_COLOR_GREEN}" "${UI_RESET}" "$*"
}

log_warn() {
    printf " %b  %b[WARNING]%b %s\n" "${UI_COLOR_YELLOW}⚠${UI_RESET}" "${UI_COLOR_YELLOW}" "${UI_RESET}" "$*"
}

log_error() {
    printf " %b  %b[ERROR]%b %s\n" "${UI_COLOR_RED}✖${UI_RESET}" "${UI_COLOR_RED}" "${UI_RESET}" "$*"
}

log_step() {
    printf "\n%b==>%b %b%s%b\n" "${UI_COLOR_BLUE}" "${UI_RESET}" "${UI_BOLD}${UI_COLOR_WHITE}" "$*" "${UI_RESET}"
}

# Master Banner
show_banner() {
    clear 2>/dev/null || true
    cat << "EOF"
 [38;5;39m
 █▀▀█ █▀▀█ █▀▀█ ▀▀█▀▀ █▀▀ █▀▀ ▀▀█▀▀   █▀▀█ █▀▀▄ █▀▀▄   █▀▀█ █  █ █▀▀▄ ░▀░ ▀▀█▀▀
 █▄▄█ █▄▄▀ █  █   █   █▀▀ █      █     █▄▄█ █  █ █  █   █▄▄█ █  █ █  █ ▀█▀   █  
 █    ▀ ▀▀ ▀▀▀▀   ▀   ▀▀▀ ▀▀▀    ▀     ▀  ▀ ▀  ▀ ▀▀▀    ▀  ▀ ░▀▀▀ ▀▀▀  ▀▀▀   ▀  
 [0m
 [1;38;5;46m [🛡️ CORE SECURITY ENGINES] [0m   [1;38;5;208m[🧰 UTILITY & DIAGNOSTIC PACK] [0m   [1;38;5;226m[🧪 TEST RUNNER] [0m
 [2;37m ───────────────────────────────────────────────────────────────────────────────── [0m
EOF
}

# Status Matrix Header
render_matrix_header() {
    printf "\n"
    printf "%b┌────────────────────────────────────────┬──────────────────────┬─────────────────┐%b\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
    printf "%b│%b %-38s %b│%b %-20s %b│%b %-15s %b│%b\n" \
        "${UI_COLOR_CYAN}" "${UI_BOLD}${UI_COLOR_WHITE}" "SECURITY MODULE / COMPONENT" \
        "${UI_COLOR_CYAN}" "${UI_BOLD}${UI_COLOR_WHITE}" "INSTALL STATUS" \
        "${UI_COLOR_CYAN}" "${UI_BOLD}${UI_COLOR_WHITE}" "SERVICE STATE" "${UI_COLOR_CYAN}" "${UI_RESET}"
    printf "%b├────────────────────────────────────────┼──────────────────────┼─────────────────┤%b\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
}

# Status Matrix Row
render_matrix_row() {
    local component="$1"
    local install_status="$2"
    local service_state="$3"
    local status_type="$4"

    local badge=""
    case "$status_type" in
        success) badge="${UI_COLOR_GREEN}✔ $(printf "%-18.18s" "$install_status")${UI_RESET}" ;;
        danger)  badge="${UI_COLOR_RED}✖ $(printf "%-18.18s" "$install_status")${UI_RESET}" ;;
        warn)    badge="${UI_COLOR_YELLOW}⚠ $(printf "%-18.18s" "$install_status")${UI_RESET}" ;;
        *)       badge="${UI_COLOR_CYAN}ℹ $(printf "%-18.18s" "$install_status")${UI_RESET}" ;;
    esac

    local comp_fmt
    comp_fmt=$(printf "%-38.38s" "$component")
    local state_fmt
    state_fmt=$(printf "%-15.15s" "$service_state")

    printf "%b│%b %s %b│%b %b %b│%b %s %b│%b\n" \
        "${UI_COLOR_CYAN}" "${UI_COLOR_WHITE}" "$comp_fmt" \
        "${UI_COLOR_CYAN}" "${UI_RESET}" "$badge" \
        "${UI_COLOR_CYAN}" "${UI_DIM}${state_fmt}${UI_RESET}" "${UI_COLOR_CYAN}" "${UI_RESET}"
}

# Status Matrix Footer
render_matrix_footer() {
    printf "%b└────────────────────────────────────────┴──────────────────────┴─────────────────┘%b\n\n" "${UI_COLOR_CYAN}" "${UI_RESET}"
}
