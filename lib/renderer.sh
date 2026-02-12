#!/usr/bin/env bash
# renderer.sh — draw_header, draw_content, draw_footer, etc.

clear_line() {
    local row=$1
    tput cup "$row" 0
    printf "%${WIDTH}s" ""
}

refresh_status_cache() {
    local now=0
    now=$(date +%s)
    # Only refresh if cache is stale (older than TTL) or forced
    if [[ "${1:-}" == "force" ]] || ((now - STATUS_CACHE_TIME >= STATUS_CACHE_TTL)); then
        CACHED_ENGINE_UP=false
        docker info >/dev/null 2>&1 && CACHED_ENGINE_UP=true

        local colima_list=$(colima list 2>&1 | tail -n +2)
        CACHED_CPU=$(echo "$colima_list" | awk '{print $4}' | head -1)
        CACHED_MEM=$(echo "$colima_list" | awk '{print $5}' | sed 's/GiB//' | head -1)
        CACHED_K8S=false
        local runtime=$(echo "$colima_list" | awk '{print $7}' | head -1)
        [[ "$runtime" == *"kubernetes"* ]] && CACHED_K8S=true
        STATUS_CACHE_TIME=$now
    fi
}

draw_header() {
    tput cup "$HEADER_ROW" 0
    printf "${C_HEADER_BG}${C_HEADER_FG}%-${WIDTH}s${C_RESET}" ""
    local title=" DOCKER OPERATIONS CONSOLE "
    local title_pos=$(( (WIDTH - ${#title}) / 2 ))
    tput cup "$HEADER_ROW" "$title_pos"
    printf "${C_HEADER_BG}${C_HEADER_FG}${C_BOLD}%s${C_RESET}" "$title"

    local engine_str="" k8s_str="" resources=""
    if [[ "$CACHED_ENGINE_UP" == true ]]; then
        engine_str="${C_GREEN}ENGINE:UP${C_RESET}"
    else
        engine_str="${C_RED}ENGINE:DOWN${C_RESET}"
    fi

    if [[ "$CACHED_K8S" == true ]]; then
        k8s_str="${C_GREEN}K8S:ON${C_RESET}"
    else
        k8s_str="${C_GREY}K8S:OFF${C_RESET}"
    fi

    resources="CPU:${CACHED_CPU:-?} MEM:${CACHED_MEM:-?}G"

    tput cup "$STATUS_ROW" 0
    printf "${C_STATUS_BG}${C_STATUS_FG}%-${WIDTH}s${C_RESET}" ""
    tput cup "$STATUS_ROW" 0
    printf "${C_STATUS_BG}${C_STATUS_FG}${engine_str}${C_STATUS_BG}${C_STATUS_FG} | ${k8s_str}${C_STATUS_BG}${C_STATUS_FG} | ${resources}${C_RESET}"
}

draw_action_bar() {
    # Split by | separator: description | actions
    local description="" actions_part=""
    if [[ "$ACTION_BAR" == *"|"* ]]; then
        description="${ACTION_BAR%%|*}"
        actions_part="${ACTION_BAR#*|}"
    else
        # No separator - treat as description only
        description="$ACTION_BAR"
        actions_part=""
    fi
    
    # Trim whitespace from description and actions
    description=$(echo "$description" | xargs)
    actions_part=$(echo "$actions_part" | xargs)
    
    # Draw description on first line
    tput cup "$ACTION_ROW" 0
    printf "${C_ACTION_BG}${C_ACTION_FG}%-${WIDTH}s${C_RESET}" ""
    tput cup "$ACTION_ROW" 0
    printf "${C_ACTION_BG}${C_ACTION_FG}%s${C_RESET}" "$description"
    
    # If no actions, done
    if [[ -z "$actions_part" ]]; then
        tput cup $((ACTION_ROW + 1)) 0
        printf "%-${WIDTH}s" ""
        return
    fi
    
    # Split actions by double space for grid
    local actions=()
    local IFS='  '
    read -ra actions <<< "$actions_part"
    
    local cols=3
    local col_width=$((WIDTH / cols))
    local col=0
    local grid_row=0
    
    # Draw actions in grid
    for action in "${actions[@]}"; do
        [[ -z "$action" ]] && continue
        
        local x=$((col * col_width))
        local y=$((ACTION_ROW + 1 + grid_row))
        
        # Prepare row if starting new one
        if ((col == 0)); then
            tput cup "$y" 0
            printf "${C_ACTION_BG}${C_ACTION_FG}%-${WIDTH}s${C_RESET}" ""
        fi
        
        tput cup "$y" "$x"
        printf "${C_ACTION_BG}${C_ACTION_FG}%-${col_width}s${C_RESET}" "$action"
        
        ((col++))
        if ((col >= cols)); then
            col=0
            ((grid_row += 2))  # Next row + 1 blank line gap
        fi
    done
    
    # blank line separator after all actions
    tput cup $((ACTION_ROW + 1 + grid_row + 1)) 0
    printf "%-${WIDTH}s" ""
}

draw_page_title() {
    tput cup "$TITLE_ROW" 0
    printf "%-${WIDTH}s" ""
    tput cup "$TITLE_ROW" 0
    printf "${C_TITLE_FG}${C_BOLD}%s${C_RESET}" "$PAGE_TITLE"
}

draw_content() {
    local total=${#CONTENT_LINES[@]}
    local visible=$CONTENT_HEIGHT
    local i row

    for ((i = 0; i < visible; i++)); do
        row=$((CONTENT_START + i))
        tput cup "$row" 0
        local idx=$((SCROLL_OFFSET + i))
        if ((idx < total)); then
            local line="${CONTENT_LINES[$idx]}"
            if ((idx == SELECTED_INDEX)); then
                printf "${C_HIGHLIGHT_BG}${C_HIGHLIGHT_FG}%-${WIDTH}.${WIDTH}s${C_RESET}" "$line"
            else
                printf "${C_TEXT}%-${WIDTH}.${WIDTH}s${C_RESET}" "$line"
            fi
        else
            printf "%-${WIDTH}s" ""
        fi
    done
}

draw_footer() {
    tput cup "$FOOTER_ROW" 0
    printf "${C_FOOTER_BG}%-${WIDTH}s${C_RESET}" ""
    tput cup "$FOOTER_ROW" 1

    local current
    current=$(nav_current)

    if [[ "$current" == "main" ]]; then
        printf "${C_FOOTER_BG} ${C_FOOTER_KEY}Enter${C_FOOTER_FG}:Select  ${C_FOOTER_KEY}Arrows${C_FOOTER_FG}:Navigate  ${C_FOOTER_KEY}R${C_FOOTER_FG}:Refresh  ${C_FOOTER_KEY}Q${C_FOOTER_FG}:Quit ${C_RESET}"
    else
        printf "${C_FOOTER_BG} ${C_FOOTER_KEY}Esc${C_FOOTER_FG}:Back  ${C_FOOTER_KEY}Arrows${C_FOOTER_FG}:Navigate  ${C_FOOTER_KEY}R${C_FOOTER_FG}:Refresh  ${C_FOOTER_KEY}Q${C_FOOTER_FG}:Quit ${C_RESET}"
    fi
}

draw_flash() {
    if [[ -n "$FLASH_MSG" ]]; then
        local now
        now=$(date +%s)
        if ((now < FLASH_UNTIL)); then
            tput cup $((TITLE_ROW)) $((WIDTH - ${#FLASH_MSG} - 4))
            printf "${FLASH_COLOR} %s ${C_RESET}" "$FLASH_MSG"
        else
            FLASH_MSG=""
        fi
    fi
}

full_redraw() {
    refresh_status_cache
    tput clear
    draw_header
    draw_action_bar
    draw_page_title
    draw_content
    draw_footer
    draw_flash
}

redraw_content() {
    draw_content
    draw_flash
}

show_flash() {
    local msg=$1 color=${2:-$C_SUCCESS_BG$C_SUCCESS_FG}
    FLASH_MSG="$msg"
    FLASH_COLOR="$color"
    FLASH_UNTIL=$(( $(date +%s) + 3 ))
    draw_flash
}
