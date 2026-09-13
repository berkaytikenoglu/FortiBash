#!/usr/bin/env bash
# ==============================================================================
# Linux Utility: Local CIS & System Baseline Security Auditor
# ==============================================================================

run_baseline_audit() {
    log_step "Running Local Linux Configuration & Baseline Security Audit..."

    render_matrix_header

    # 1. Root Account UID Check
    local root_uids
    root_uids="$(awk -F: '($3 == 0) {print $1}' /etc/passwd 2>/dev/null | tr '\n' ' ')"
    if [[ "$root_uids" == "root " ]]; then
        render_matrix_row "Single Root Account (UID 0)" "COMPLIANT" "PASS (Secure)" "success"
    else
        render_matrix_row "Single Root Account (UID 0)" "NON-COMPLIANT" "FAIL (${root_uids})" "danger"
    fi

    # 2. Empty Password Accounts Check
    if [[ -f /etc/shadow && $EUID -eq 0 ]]; then
        local empty_pw
        empty_pw="$(awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow 2>/dev/null | wc -l)"
        if [[ "$empty_pw" -eq 0 ]]; then
            render_matrix_row "Empty Password Accounts" "COMPLIANT" "PASS (None)" "success"
        else
            render_matrix_row "Empty Password Accounts" "NON-COMPLIANT" "WARN (Found)" "warn"
        fi
    else
        render_matrix_row "Empty Password Accounts" "SHADOW PROTECTED" "INFO" "info"
    fi

    # 3. World Writable Files in /etc
    local ww_files
    ww_files="$(find /etc -maxdepth 3 -type f -perm -0002 2>/dev/null | wc -l)"
    if [[ "$ww_files" -eq 0 ]]; then
        render_matrix_row "World-Writable /etc Files" "COMPLIANT" "PASS (0 Files)" "success"
    else
        render_matrix_row "World-Writable /etc Files" "NON-COMPLIANT" "FAIL (${ww_files} Files)" "danger"
    fi

    # 4. SUID Binaries Audit
    local suid_count
    suid_count="$(find /bin /usr/bin /sbin /usr/sbin -perm -4000 -type f 2>/dev/null | wc -l)"
    render_matrix_row "System SUID Executables" "AUDITED" "INFO (${suid_count} Binaries)" "info"

    render_matrix_footer
}

# Standalone execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/ui.sh"
    # shellcheck disable=SC1091
    source "$SCRIPT_ROOT/core/os_detector.sh"
    detect_system_os
    run_baseline_audit "$@"
fi
