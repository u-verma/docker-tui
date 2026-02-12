#!/usr/bin/env bash
# dialog.sh — Confirmation dialog, input form helpers

confirm_action() {
    local msg=$1
    OVERLAY_ACTIVE=true

    local box_width=40
    local box_height=5
    local start_col=$(( (WIDTH - box_width) / 2 ))
    local start_row=$(( (HEIGHT - box_height) / 2 ))

    # Top border
    tput cup "$start_row" "$start_col"
    printf "${C_BORDER}+%*s+${C_RESET}" $((box_width - 2)) "" | tr ' ' '-'

    # Message line
    tput cup $((start_row + 1)) "$start_col"
    printf "${C_BORDER}|${C_RESET}${C_WHITE}${C_BOLD} %-$((box_width - 4))s ${C_BORDER}|${C_RESET}" "$msg"

    # Blank line
    tput cup $((start_row + 2)) "$start_col"
    printf "${C_BORDER}|${C_RESET} %-$((box_width - 4))s ${C_BORDER}|${C_RESET}" ""

    # Options line
    tput cup $((start_row + 3)) "$start_col"
    printf "${C_BORDER}|${C_RESET}   ${C_GREEN}[Y]${C_TEXT} Yes    ${C_RED}[N]${C_TEXT} No %-$((box_width - 26))s${C_BORDER}|${C_RESET}" ""

    # Bottom border
    tput cup $((start_row + 4)) "$start_col"
    printf "${C_BORDER}+%*s+${C_RESET}" $((box_width - 2)) "" | tr ' ' '-'

    while true; do
        local k
        read -rsn1 k
        case "$k" in
            y|Y)
                OVERLAY_ACTIVE=false
                return 0
                ;;
            n|N|$'\x1b')
                OVERLAY_ACTIVE=false
                full_redraw
                return 1
                ;;
        esac
    done
}

draw_input_field() {
    local row=$1 label=$2 value=$3 active=$4
    tput cup "$row" 4
    if ((active)); then
        printf "${C_CYAN}%-12s${C_RESET}: ${C_REV} %-20s ${C_RESET}" "$label" "$value"
    else
        printf "${C_GREY}%-12s${C_RESET}: ${C_TEXT} %-20s ${C_RESET}" "$label" "$value"
    fi
}
