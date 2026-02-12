#!/usr/bin/env bash
# pages/system.sh — System prune actions

page_system_enter() {
    PAGE_TITLE="Cleanup"
    ACTION_BAR="Remove unused Docker resources | Enter:Run selected action"
    CONTENT_LINES=()
    CONTENT_LINES+=("")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}%-4s %-30s${C_RESET}" "#" "ACTION")")
    CONTENT_LINES+=("$(printf "  %-4s %-30s" "[1]" "Prune System (containers, images, networks, build cache)")")
    CONTENT_LINES+=("$(printf "  %-4s %-30s" "[2]" "Prune Networks")")
    CONTENT_LINES+=("$(printf "  %-4s %-30s" "[3]" "Prune Volumes")")
    CONTENT_LINES+=("$(printf "  %-4s %-30s" "[4]" "Prune Build Cache")")
    SELECTED_INDEX=2
}

page_system_key() {
    local key=$1
    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        1|ENTER)
            local action_index=$((SELECTED_INDEX - 2))
            if [[ "$key" == "1" ]]; then action_index=0; fi
            case "$action_index" in
                0)
                    if confirm_action "Prune entire system?"; then
                        exec_cmd "docker system prune -a -f"
                        CONTENT_LINES=()
                        CONTENT_LINES+=("")
                        CONTENT_LINES+=("  ${C_GREEN}System pruned successfully.${C_RESET}")
                        CONTENT_LINES+=("")
                        while IFS= read -r line; do
                            CONTENT_LINES+=("  $line")
                        done <<< "$CMD_OUTPUT"
                        reset_selection
                    fi
                    full_redraw
                    ;;
                1)
                    if confirm_action "Prune all unused networks?"; then
                        exec_cmd "docker network prune -f"
                        show_flash "Networks pruned"
                        page_system_enter
                    fi
                    full_redraw
                    ;;
                2)
                    if confirm_action "Prune all unused volumes?"; then
                        exec_cmd "docker volume prune -f"
                        show_flash "Volumes pruned"
                        page_system_enter
                    fi
                    full_redraw
                    ;;
                3)
                    if confirm_action "Prune build cache?"; then
                        exec_cmd "docker builder prune -f"
                        show_flash "Build cache pruned"
                        page_system_enter
                    fi
                    full_redraw
                    ;;
            esac
            return 0
            ;;
        2)
            if confirm_action "Prune all unused networks?"; then
                exec_cmd "docker network prune -f"
                show_flash "Networks pruned"
                page_system_enter
            fi
            full_redraw
            return 0
            ;;
        3)
            if confirm_action "Prune all unused volumes?"; then
                exec_cmd "docker volume prune -f"
                show_flash "Volumes pruned"
                page_system_enter
            fi
            full_redraw
            return 0
            ;;
        4)
            if confirm_action "Prune build cache?"; then
                exec_cmd "docker builder prune -f"
                show_flash "Build cache pruned"
                page_system_enter
            fi
            full_redraw
            return 0
            ;;
        *) return 1 ;;
    esac
}
