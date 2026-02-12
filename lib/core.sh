#!/usr/bin/env bash
# core.sh — Colors, constants, terminal setup, cleanup

# Colors
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_REV=$'\033[7m'
C_HEADER_BG=$'\033[48;5;24m'
C_HEADER_FG=$'\033[38;5;15m'
C_STATUS_BG=$'\033[48;5;236m'
C_STATUS_FG=$'\033[38;5;252m'
C_ACTION_BG=$'\033[48;5;235m'
C_ACTION_FG=$'\033[38;5;228m'
C_TITLE_FG=$'\033[38;5;75m'
C_BORDER=$'\033[38;5;240m'
C_TEXT=$'\033[38;5;252m'
C_HIGHLIGHT_BG=$'\033[48;5;25m'
C_HIGHLIGHT_FG=$'\033[38;5;15m'
C_GREEN=$'\033[38;5;82m'
C_RED=$'\033[38;5;196m'
C_YELLOW=$'\033[38;5;220m'
C_CYAN=$'\033[38;5;81m'
C_WHITE=$'\033[38;5;15m'
C_GREY=$'\033[38;5;245m'
C_ERROR_BG=$'\033[48;5;52m'
C_ERROR_FG=$'\033[38;5;210m'
C_SUCCESS_BG=$'\033[48;5;22m'
C_SUCCESS_FG=$'\033[38;5;120m'
C_MENU_ICON=$'\033[38;5;75m'
C_MENU_SEL_BG=$'\033[48;5;25m'
C_MENU_SEL_FG=$'\033[38;5;15m'
C_FOOTER_BG=$'\033[48;5;234m'
C_FOOTER_FG=$'\033[38;5;245m'
C_FOOTER_KEY=$'\033[38;5;75m'

# Dimensions (updated by SIGWINCH)
WIDTH=80
HEIGHT=24
HEADER_ROW=0
STATUS_ROW=2
ACTION_ROW=4
TITLE_ROW=9
CONTENT_START=11
FOOTER_ROW=23

# Navigation
declare -a NAV_STACK=()
INITIALIZED=false

# Content & selection
declare -a CONTENT_LINES=()
SCROLL_OFFSET=0
SELECTED_INDEX=0
CONTENT_HEIGHT=18

# Page state
PAGE_TITLE=""
ACTION_BAR=""

# Data
CMD_OUTPUT=""
CMD_EXIT=0
SHOW_K8S_CONTAINERS=false

# Menu grid state
MENU_ROW=0
MENU_COL=0
MENU_COLS=3
MENU_ROWS=3

# Container data cache
declare -a CONTAINER_NAMES=()
declare -a CONTAINER_STATUS=()
declare -a CONTAINER_IMAGES=()
declare -a CONTAINER_PORTS=()

# Image data cache
declare -a IMAGE_REPOS=()
declare -a IMAGE_TAGS=()
declare -a IMAGE_IDS=()
declare -a IMAGE_SIZES=()
declare -a IMAGE_CREATED=()

# Volume data cache
declare -a VOLUME_NAMES=()
declare -a VOLUME_DRIVERS=()
declare -a VOLUME_MOUNTS=()

# Logs state
declare -a LOG_LINES=()
LOG_CONTAINER=""
LOG_FOLLOW=false

# Stats state
STATS_CONTAINER=""

# Overlay state
OVERLAY_ACTIVE=false
OVERLAY_MSG=""
OVERLAY_CALLBACK=""

# Resize VM input state
RESIZE_FIELD=0
RESIZE_CPU=""
RESIZE_MEM=""

# Flash message
FLASH_MSG=""
FLASH_COLOR=""
FLASH_UNTIL=0

# Container detail
DETAIL_CONTAINER=""

# Input
KEY_RESULT=""

# Status cache (avoids slow docker/colima calls on every redraw)
CACHED_ENGINE_UP=false
CACHED_COLIMA_STATUS=""
CACHED_CPU="?"
CACHED_MEM="?"
CACHED_K8S=false
STATUS_CACHE_TIME=0
STATUS_CACHE_TTL=30

# Save original stty to restore later
ORIG_STTY=""

# ── Terminal Setup ──────────────────────────────────────────────

update_dimensions() {
    WIDTH=$(tput cols)
    HEIGHT=$(tput lines)
    FOOTER_ROW=$((HEIGHT - 1))
    CONTENT_HEIGHT=$((FOOTER_ROW - CONTENT_START))
    # Only redraw if the app is fully initialized
    if [[ "$INITIALIZED" == true ]]; then
        full_redraw
    fi
}

setup_terminal() {
    ORIG_STTY=$(stty -g 2>/dev/null) || true
    tput smcup      # alt screen buffer
    tput civis      # hide cursor
    # min 0 time 2 = return after 0.2s if no input (time unit = 1/10th sec)
    # This avoids bash 3.2 issues with fractional read -t values
    stty -echo -icanon min 0 time 2 2>/dev/null || true
    printf '\033[?25l'  # hide cursor (belt & suspenders)
}

cleanup_terminal() {
    printf '\033[?25h' 2>/dev/null || true
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    if [[ -n "$ORIG_STTY" ]]; then
        stty "$ORIG_STTY" 2>/dev/null || true
    else
        stty sane 2>/dev/null || true
    fi
}

trap cleanup_terminal EXIT INT TERM HUP
trap update_dimensions WINCH
