#!/usr/bin/env bash
# ==============================================================================
# BashWAF Core Multi-Platform OS Detector
# ==============================================================================

detect_system_os() {
    SYSTEM_OS="unknown"
    SYSTEM_DISTRO="unknown"
    SYSTEM_VERSION="unknown"
    SYSTEM_ARCH="$(uname -m 2>/dev/null || echo "unknown")"
    SYSTEM_PKG_MGR="unknown"

    local uname_out
    uname_out="$(uname -s 2>/dev/null || echo "unknown")"

    case "$uname_out" in
        Linux*)
            SYSTEM_OS="linux"
            if [[ -f /proc/version ]] && grep -qi "microsoft\|wsl" /proc/version; then
                SYSTEM_DISTRO="wsl"
            elif [[ -f /etc/os-release ]]; then
                # shellcheck disable=SC1091
                source /etc/os-release
                SYSTEM_DISTRO="${ID:-linux}"
                SYSTEM_VERSION="${VERSION_ID:-unknown}"
            elif [[ -f /etc/redhat-release ]]; then
                SYSTEM_DISTRO="rhel"
            elif [[ -f /etc/debian_version ]]; then
                SYSTEM_DISTRO="debian"
            fi

            case "$SYSTEM_DISTRO" in
                ubuntu|debian|kali|pop|mint|raspbian)
                    SYSTEM_PKG_MGR="apt"
                    ;;
                centos|rhel|rocky|almalinux|fedora|ol)
                    if command -v dnf >/dev/null 2>&1; then
                        SYSTEM_PKG_MGR="dnf"
                    else
                        SYSTEM_PKG_MGR="yum"
                    fi
                    ;;
                arch|manjaro|endeavouros)
                    SYSTEM_PKG_MGR="pacman"
                    ;;
                alpine)
                    SYSTEM_PKG_MGR="apk"
                    ;;
                wsl)
                    if command -v apt-get >/dev/null 2>&1; then
                        SYSTEM_PKG_MGR="apt"
                    elif command -v dnf >/dev/null 2>&1; then
                        SYSTEM_PKG_MGR="dnf"
                    fi
                    ;;
                *)
                    if command -v apt-get >/dev/null 2>&1; then
                        SYSTEM_PKG_MGR="apt"
                    elif command -v dnf >/dev/null 2>&1; then
                        SYSTEM_PKG_MGR="dnf"
                    elif command -v pacman >/dev/null 2>&1; then
                        SYSTEM_PKG_MGR="pacman"
                    elif command -v apk >/dev/null 2>&1; then
                        SYSTEM_PKG_MGR="apk"
                    fi
                    ;;
            esac
            ;;
        Darwin*)
            SYSTEM_OS="macos"
            SYSTEM_DISTRO="macos"
            SYSTEM_VERSION="$(sw_vers -productVersion 2>/dev/null || echo "unknown")"
            if command -v brew >/dev/null 2>&1; then
                SYSTEM_PKG_MGR="brew"
            else
                SYSTEM_PKG_MGR="none"
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            SYSTEM_OS="windows"
            SYSTEM_DISTRO="windows_gitbash"
            if command -v winget.exe >/dev/null 2>&1; then
                SYSTEM_PKG_MGR="winget"
            elif command -v choco.exe >/dev/null 2>&1; then
                SYSTEM_PKG_MGR="choco"
            fi
            ;;
        *)
            SYSTEM_OS="generic"
            SYSTEM_DISTRO="generic"
            ;;
    esac

    export SYSTEM_OS SYSTEM_DISTRO SYSTEM_VERSION SYSTEM_ARCH SYSTEM_PKG_MGR
}

# Root Privilege Verification
is_root() {
    [[ $EUID -eq 0 ]]
}

require_root() {
    if ! is_root; then
        if command -v sudo >/dev/null 2>&1; then
            log_warn "Administrator/Root privilege required. Elevating via sudo..."
            exec sudo bash "$0" "$@"
        else
            log_error "This operation must be executed with root/sudo privileges!"
            exit 1
        fi
    fi
}

# Active Network Interface Detection
get_active_interface() {
    local iface=""
    if command -v ip >/dev/null 2>&1; then
        iface="$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)"
    elif command -v route >/dev/null 2>&1; then
        iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || echo "")"
    fi
    echo "${iface:-en0}"
}
