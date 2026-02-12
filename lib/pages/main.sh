#!/usr/bin/env bash
# pages/main.sh — Main menu grid

MENU_ITEMS=("Containers" "Images" "Volumes" "Docker Compose" "Cleanup" "Settings" "Kubernetes")
MENU_ICONS=("[C]" "[I]" "[V]" "[O]" "[P]" "[S]" "[K]")
MENU_DESCS=(
    "Manage running containers"
    "Browse and clean images"
    "Inspect and remove volumes"
    "Compose stack management"
    "Prune unused resources"
    "Engine, VM, preferences"
    "Kubernetes cluster"
)
MENU_PAGES=("containers" "images" "volumes" "compose" "system" "engine" "kubernetes")

page_main_enter() {
    PAGE_TITLE="Main Menu"
    ACTION_BAR="Use arrow keys to navigate, Enter to select"
    MENU_ROW=0
    MENU_COL=0
    CONTENT_LINES=()  # Main menu draws its own content
}

draw_menu_grid() {
    local idx row col item_row
    local h_gap=3
    local v_gap=1
    local cell_width=$(( (WIDTH - h_gap * (MENU_COLS - 1)) / MENU_COLS ))
    
    for ((idx = 0; idx < ${#MENU_ITEMS[@]}; idx++)); do
        row=$((idx / MENU_COLS))
        col=$((idx % MENU_COLS))
        item_row=$((CONTENT_START + row * (3 + v_gap)))
        local col_start=$((col * (cell_width + h_gap)))

        local is_selected=0
        if ((row == MENU_ROW && col == MENU_COL)); then
            is_selected=1
        fi

        # Draw cell
        if ((is_selected)); then
            tput cup "$item_row" "$col_start"
            printf "${C_MENU_SEL_BG}${C_MENU_SEL_FG} %-$((cell_width - 2))s ${C_RESET}" "${MENU_ICONS[$idx]} ${MENU_ITEMS[$idx]}"
            tput cup $((item_row + 1)) "$col_start"
            printf "${C_MENU_SEL_BG}${C_MENU_SEL_FG} %-$((cell_width - 2))s ${C_RESET}" "  ${MENU_DESCS[$idx]}"
            tput cup $((item_row + 2)) "$col_start"
            printf "${C_MENU_SEL_BG}%-${cell_width}s${C_RESET}" ""
        else
            tput cup "$item_row" "$col_start"
            printf "${C_MENU_ICON} %-$((cell_width - 2))s ${C_RESET}" "${MENU_ICONS[$idx]} ${MENU_ITEMS[$idx]}"
            tput cup $((item_row + 1)) "$col_start"
            printf "${C_GREY} %-$((cell_width - 2))s ${C_RESET}" "  ${MENU_DESCS[$idx]}"
            tput cup $((item_row + 2)) "$col_start"
            printf "%-${cell_width}s" ""
        fi
    done
}

page_main_key() {
    local key=$1
    case "$key" in
        UP)
            ((MENU_ROW > 0)) && ((MENU_ROW--))
            draw_menu_grid
            ;;
        DOWN)
            ((MENU_ROW < MENU_ROWS - 1)) && ((MENU_ROW++))
            draw_menu_grid
            ;;
        LEFT)
            ((MENU_COL > 0)) && ((MENU_COL--))
            draw_menu_grid
            ;;
        RIGHT)
            ((MENU_COL < MENU_COLS - 1)) && ((MENU_COL++))
            draw_menu_grid
            ;;
        ENTER)
            local idx=$((MENU_ROW * MENU_COLS + MENU_COL))
            if ((idx < ${#MENU_PAGES[@]})); then
                nav_push "${MENU_PAGES[$idx]}"
            fi
            ;;
        c|C) nav_push "containers" ;;
        i|I) nav_push "images" ;;
        v|V) nav_push "volumes" ;;
        o|O) nav_push "compose" ;;
        p|P) nav_push "system" ;;
        s|S) nav_push "engine" ;;
        k|K) nav_push "kubernetes" ;;
        *) return 1 ;;
    esac
    return 0
}
