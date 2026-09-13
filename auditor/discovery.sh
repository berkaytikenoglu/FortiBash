#!/usr/bin/env bash
# ==============================================================================
# BashWAF Auditor: Subnet & Live Host Discovery
# ==============================================================================

# Detect Local Network Subnet & IP
get_local_subnet_info() {
    local ip_addr=""
    local cidr=""

    if command -v ip >/dev/null 2>&1; then
        local default_iface
        default_iface="$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)"
        if [[ -n "$default_iface" ]]; then
            cidr="$(ip -o -f inet addr show "$default_iface" 2>/dev/null | awk '{print $4}' | head -n1)"
            ip_addr="$(echo "$cidr" | cut -d/ -f1)"
        fi
    fi

    if [[ -z "$cidr" ]] && command -v ifconfig >/dev/null 2>&1; then
        local iface
        iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || echo "en0")"
        ip_addr="$(ifconfig "$iface" 2>/dev/null | awk '/inet / {print $2}')"
        if [[ -n "$ip_addr" ]]; then
            cidr="$(echo "$ip_addr" | cut -d. -f1-3).0/24"
        fi
    fi

    if [[ -z "$cidr" ]]; then
        cidr="192.168.1.0/24"
        ip_addr="127.0.0.1"
    fi

    echo "$cidr|$ip_addr"
}

# Resolve Device Hostname
resolve_hostname() {
    local ip="$1"
    local local_ip="$2"
    local hostname=""

    if [[ "$ip" == "$local_ip" || "$ip" == "127.0.0.1" ]]; then
        echo "Localhost ($(hostname 2>/dev/null || echo "Current Machine"))"
        return
    fi

    if [[ "$ip" == *".1" ]]; then
        hostname="Gateway / Router"
    fi

    if command -v host >/dev/null 2>&1; then
        local h_out
        h_out="$(host -W 1 "$ip" 2>/dev/null | head -n1 | awk '{print $NF}' | sed 's/\.$//' || true)"
        if [[ -n "$h_out" && "$h_out" != *"NXDOMAIN"* && "$h_out" != *"not found"* && "$h_out" != *"timed out"* ]]; then
            hostname="$h_out"
        fi
    fi

    if [[ -z "$hostname" ]] && command -v dscacheutil >/dev/null 2>&1; then
        local ds_out
        ds_out="$(dscacheutil -q host -a ip_address "$ip" 2>/dev/null | awk '/name:/ {print $2}' | head -n1 || true)"
        if [[ -n "$ds_out" ]]; then
            hostname="$ds_out"
        fi
    fi

    if [[ -z "$hostname" ]]; then
        hostname="Active Network Device"
    fi

    echo "$hostname"
}

# Fast Asynchronous Live Host Discovery
scan_live_hosts() {
    local subnet="$1"
    local base_ip
    base_ip="$(echo "$subnet" | cut -d. -f1-3)"
    local temp_file
    temp_file="$(mktemp -t live_hosts-XXXXXX)"

    printf " %b[SCAN]%b Discovering active hosts on subnet %s...\n" "\033[36m" "\033[0m" "$subnet" >&2

    # 1. ARP Cache Inspection (Excluding Incomplete/Failed)
    if command -v arp >/dev/null 2>&1; then
        arp -an 2>/dev/null | grep -v -i "incomplete" | grep -v "(incomplete)" | grep -E -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep "^${base_ip}\." >> "$temp_file" || true
    elif command -v ip >/dev/null 2>&1; then
        ip neigh show 2>/dev/null | grep -v -i "FAILED" | grep -v -i "INCOMPLETE" | awk '{print $1}' | grep "^${base_ip}\." >> "$temp_file" || true
    fi

    # 2. Fast Parallel Ping Sweep
    if command -v nmap >/dev/null 2>&1; then
        nmap -sn -n --max-retries 1 --host-timeout 400ms "$subnet" -oG - 2>/dev/null | awk '/Status: Up/{print $2}' >> "$temp_file" || true
    else
        local ping_cmd="ping -c 1 -W 250"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            ping_cmd="ping -c 1 -t 1"
        fi

        for i in $(seq 1 254); do
            (
                local target_ip="${base_ip}.${i}"
                if $ping_cmd "$target_ip" 2>&1 | grep -q -E "(64 bytes from|1 packets received|1 received)"; then
                    echo "$target_ip" >> "$temp_file"
                fi
            ) &
        done

        local wait_cycles=0
        while [ $(jobs -r | wc -l) -gt 0 ] && [ $wait_cycles -lt 25 ]; do
            sleep 0.1
            ((wait_cycles++))
        done
        kill $(jobs -p) 2>/dev/null || true
    fi

    sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n "$temp_file" 2>/dev/null | grep -v "\.255$" | grep -v "\.0$" || true
    rm -f "$temp_file"
}
