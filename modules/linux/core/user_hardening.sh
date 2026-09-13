#!/usr/bin/env bash
# ==============================================================================
# Linux Core Engine: User Management & SSH Hardening
# ==============================================================================

apply_user_hardening() {
    local target_user="${1:-}"
    local ssh_port="${2:-22}"
    local disable_password_auth="${3:-false}"

    log_step "Applying Sudo User Hardening & SSH Security Parameters..."
    require_root "$@"

    local sshd_config="/etc/ssh/sshd_config"
    if [[ ! -f "$sshd_config" ]]; then
        log_error "SSH configuration file not found: $sshd_config"
        return 1
    fi

    # Backup original configuration
    if [[ ! -f "${sshd_config}.bak_bashwaf" ]]; then
        cp "$sshd_config" "${sshd_config}.bak_bashwaf"
        log_info "Original SSH configuration backed up: ${sshd_config}.bak_bashwaf"
    fi

    # Sudo User Provisioning
    if [[ -n "$target_user" && "$target_user" != "root" ]]; then
        if id "$target_user" >/dev/null 2>&1; then
            log_info "User '$target_user' exists. Verifying sudo privileges..."
        else
            log_info "Creating secure sudo user: $target_user"
            useradd -m -s /bin/bash "$target_user"
            log_warn "Please set a secure password for user '$target_user':"
            passwd "$target_user"
        fi

        if getent group sudo >/dev/null 2>&1; then
            usermod -aG sudo "$target_user"
        elif getent group wheel >/dev/null 2>&1; then
            usermod -aG wheel "$target_user"
        fi

        local user_ssh_dir="/home/$target_user/.ssh"
        mkdir -p "$user_ssh_dir"
        chmod 700 "$user_ssh_dir"
        touch "$user_ssh_dir/authorized_keys"
        chmod 600 "$user_ssh_dir/authorized_keys"
        chown -R "$target_user:$target_user" "$user_ssh_dir"
        log_success "Sudo user '$target_user' and SSH key directory configured."
    fi

    # Legal Security Banner
    cat << 'EOF' > /etc/issue.net
*******************************************************************************
*                     AUTHORIZED ACCESS ONLY - BASHWAF                         *
* All activities on this system are logged and monitored. Unauthorized        *
* access will be prosecuted to the fullest extent of applicable law.          *
*******************************************************************************
EOF

    # Hardening SSH Daemon Options
    local dropin_dir="/etc/ssh/sshd_config.d"
    if [[ -d "$dropin_dir" ]]; then
        cat << EOF > "$dropin_dir/99-bashwaf-hardening.conf"
# BashWAF SSH Security Hardening
Port $ssh_port
PermitRootLogin prohibit-password
PermitEmptyPasswords no
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowTcpForwarding no
Banner /etc/issue.net
LogLevel VERBOSE
EOF
        if [[ "$disable_password_auth" == "true" ]]; then
            echo "PasswordAuthentication no" >> "$dropin_dir/99-bashwaf-hardening.conf"
            echo "KbdInteractiveAuthentication no" >> "$dropin_dir/99-bashwaf-hardening.conf"
        fi
    else
        sed -i -E "s/^#?Port .*/Port $ssh_port/" "$sshd_config"
        sed -i -E "s/^#?PermitRootLogin .*/PermitRootLogin prohibit-password/" "$sshd_config"
        sed -i -E "s/^#?PermitEmptyPasswords .*/PermitEmptyPasswords no/" "$sshd_config"
        sed -i -E "s/^#?MaxAuthTries .*/MaxAuthTries 3/" "$sshd_config"
        sed -i -E "s/^#?X11Forwarding .*/X11Forwarding no/" "$sshd_config"
        sed -i -E "s/^#?ClientAliveInterval .*/ClientAliveInterval 300/" "$sshd_config"
        sed -i -E "s/^#?ClientAliveCountMax .*/ClientAliveCountMax 2/" "$sshd_config"
        sed -i -E "s|^#?Banner .*|Banner /etc/issue.net|" "$sshd_config"

        if [[ "$disable_password_auth" == "true" ]]; then
            sed -i -E "s/^#?PasswordAuthentication .*/PasswordAuthentication no/" "$sshd_config"
        fi
    fi

    # Syntax test and restart
    if sshd -t 2>/dev/null; then
        service_start sshd || service_start ssh
        log_success "SSH Daemon hardened successfully (Port: $ssh_port, Root Password Login: DISABLED)."
    else
        log_error "SSH configuration syntax error detected! Restoring original backup..."
        cp "${sshd_config}.bak_bashwaf" "$sshd_config"
        return 1
    fi
}

is_ssh_hardened() {
    if grep -q -E "^PermitRootLogin (no|prohibit-password)" /etc/ssh/sshd_config 2>/dev/null || grep -q -E "PermitRootLogin (no|prohibit-password)" /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
        return 0
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
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/package_manager.sh"
    detect_system_os
    apply_user_hardening "$@"
fi
