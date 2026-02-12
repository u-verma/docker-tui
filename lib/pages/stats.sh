#!/usr/bin/env bash
# pages/stats.sh — Live stats

page_stats_enter() {
    PAGE_TITLE="Stats: $STATS_CONTAINER"
    ACTION_BAR="Live resource monitoring (auto-refreshes) | R:Refresh"
    CONTENT_LINES=()

    if ! guard_engine; then return; fi

    local stats_output
    stats_output=$(docker stats --no-stream --format \
        'CPU:{{.CPUPerc}}|MEM:{{.MemUsage}}|MEM%:{{.MemPerc}}|NET:{{.NetIO}}|BLOCK:{{.BlockIO}}|PIDS:{{.PIDs}}' \
        "$STATS_CONTAINER" 2>&1) || true

    CONTENT_LINES+=("")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}%-14s${C_RESET} %s" "Container:" "$STATS_CONTAINER")")
    CONTENT_LINES+=("")

    if [[ -z "$stats_output" || "$stats_output" == *"Error"* ]]; then
        CONTENT_LINES+=("  Container is not running or stats unavailable.")
        return
    fi

    # Parse using sed (BSD-compatible, no Perl regex needed)
    local cpu mem memp net block pids
    cpu=$(echo "$stats_output" | sed -n 's/.*CPU:\([^|]*\).*/\1/p')
    mem=$(echo "$stats_output" | sed -n 's/.*MEM:\([^|]*\).*/\1/p')
    memp=$(echo "$stats_output" | sed -n 's/.*MEM%:\([^|]*\).*/\1/p')
    net=$(echo "$stats_output" | sed -n 's/.*NET:\([^|]*\).*/\1/p')
    block=$(echo "$stats_output" | sed -n 's/.*BLOCK:\([^|]*\).*/\1/p')
    pids=$(echo "$stats_output" | sed -n 's/.*PIDS:\([^|]*\).*/\1/p')

    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "CPU Usage:" "${cpu:-N/A}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Memory:" "${mem:-N/A}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Memory %:" "${memp:-N/A}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Net I/O:" "${net:-N/A}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Block I/O:" "${block:-N/A}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "PIDs:" "${pids:-N/A}")")
}

page_stats_key() {
    local key=$1
    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        *) return 1 ;;
    esac
}
