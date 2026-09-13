#!/usr/bin/env bash
# ==============================================================================
# BashWAF Core Package & Service Manager Abstraction
# ==============================================================================

# Update Package Repository Lists
pkg_update() {
    log_info "Updating system package repositories (${SYSTEM_PKG_MGR})..."
    case "$SYSTEM_PKG_MGR" in
        apt)
            DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1
            ;;
        dnf|yum)
            "$SYSTEM_PKG_MGR" check-update -y >/dev/null 2>&1 || true
            ;;
        pacman)
            pacman -Sy --noconfirm >/dev/null 2>&1
            ;;
        apk)
            apk update >/dev/null 2>&1
            ;;
        brew)
            brew update >/dev/null 2>&1
            ;;
        *)
            log_warn "Manual package update may be required on this platform."
            ;;
    esac
}

# Install Packages Silently
pkg_install() {
    local packages=("$@")
    if [[ ${#packages[@]} -eq 0 ]]; then return 0; fi

    log_info "Installing packages: ${packages[*]}..."
    case "$SYSTEM_PKG_MGR" in
        apt)
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}" >/dev/null 2>&1
            ;;
        dnf|yum)
            "$SYSTEM_PKG_MGR" install -y "${packages[@]}" >/dev/null 2>&1
            ;;
        pacman)
            pacman -S --noconfirm --needed "${packages[@]}" >/dev/null 2>&1
            ;;
        apk)
            apk add --no-cache "${packages[@]}" >/dev/null 2>&1
            ;;
        brew)
            brew install "${packages[@]}" >/dev/null 2>&1
            ;;
        winget)
            for pkg in "${packages[@]}"; do
                winget.exe install -e --id "$pkg" --silent --accept-package-agreements --accept-source-agreements >/dev/null 2>&1 || true
            done
            ;;
        choco)
            choco.exe install "${packages[@]}" -y >/dev/null 2>&1 || true
            ;;
        *)
            log_error "Unsupported package manager for automated installation: $SYSTEM_PKG_MGR"
            return 1
            ;;
    esac
}

# Check if a Binary/Package is Installed
is_pkg_installed() {
    local binary_or_pkg="$1"
    command -v "$binary_or_pkg" >/dev/null 2>&1
}

# Start and Enable System Service
service_start() {
    local service_name="$1"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable "$service_name" >/dev/null 2>&1 || true
        systemctl restart "$service_name" >/dev/null 2>&1 || systemctl start "$service_name" >/dev/null 2>&1 || true
    elif command -v service >/dev/null 2>&1; then
        service "$service_name" restart >/dev/null 2>&1 || service "$service_name" start >/dev/null 2>&1 || true
    elif command -v brew >/dev/null 2>&1 && [[ "$SYSTEM_OS" == "macos" ]]; then
        brew services restart "$service_name" >/dev/null 2>&1 || true
    fi
}

# Check Service Execution State
is_service_running() {
    local service_name="$1"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-active --quiet "$service_name" 2>/dev/null
        return $?
    elif command -v service >/dev/null 2>&1; then
        service "$service_name" status >/dev/null 2>&1
        return $?
    fi
    return 1
}
