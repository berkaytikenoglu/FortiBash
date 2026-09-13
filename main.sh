#!/usr/bin/env bash
# ==============================================================================
# BashWAF: Master Multi-Platform Launcher
# ==============================================================================
set -e

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$APP_ROOT/core/engine.sh"
start_engine "$@"
