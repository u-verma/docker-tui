#!/usr/bin/env bash
# pages/containers.sh — Container list table

page_containers_enter() {
    PAGE_TITLE="Containers"
    local k8s_action=""
    [[ "$SHOW_K8S_CONTAINERS" == true ]] && k8s_action="K:Hide K8s containers" || k8s_action="K:Show K8s containers"
    ACTION_BAR="Manage containers and view details | Enter:Detail  E:Shell  S:Start  T:Stop  X:Restart  D:Remove  ${k8s_action}"
    CONTENT_LINES=()

    if ! load_containers; then
        return
    fi

    if ((${#CONTAINER_NAMES[@]} == 0)); then
        CONTENT_LINES+=("")
        CONTENT_LINES+=("  No containers found.")
        return
    fi

    # Table header
    local hdr
    hdr=$(printf "  ${C_CYAN}${C_BOLD}%-28s %-14s %-30s %-20s${C_RESET}" "NAME" "STATUS" "IMAGE" "PORTS")
    CONTENT_LINES+=("$hdr")

    local i
    for ((i = 0; i < ${#CONTAINER_NAMES[@]}; i++)); do
        local status_color="$C_GREY"
        if [[ "${CONTAINER_STATUS[$i]}" == *"Up"* ]]; then
            status_color="$C_GREEN"
        elif [[ "${CONTAINER_STATUS[$i]}" == *"Exited"* ]]; then
            status_color="$C_RED"
        fi
        # Truncate fields to fit
        local name="${CONTAINER_NAMES[$i]:0:26}"
        local status="${CONTAINER_STATUS[$i]:0:12}"
        local image="${CONTAINER_IMAGES[$i]:0:28}"
        local ports="${CONTAINER_PORTS[$i]:0:18}"
        local line
        line=$(printf "  %-28s ${status_color}%-14s${C_RESET} %-30s %-20s" "$name" "$status" "$image" "$ports")
        CONTENT_LINES+=("$line")
    done
    # Skip header for selection (start at index 1)
    SELECTED_INDEX=1
}

page_containers_key() {
    local key=$1
    local data_index=$((SELECTED_INDEX - 1))  # offset for header row

    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        PGUP) page_up; return 0 ;;
        PGDN) page_down; return 0 ;;
        ENTER)
            if ((data_index >= 0 && data_index < ${#CONTAINER_NAMES[@]})); then
                DETAIL_CONTAINER="${CONTAINER_NAMES[$data_index]}"
                nav_push "detail"
            fi
            return 0
            ;;
        e|E)
            if ((data_index >= 0 && data_index < ${#CONTAINER_NAMES[@]})); then
                local c="${CONTAINER_NAMES[$data_index]}"
                local status="${CONTAINER_STATUS[$data_index]}"
                if [[ "$status" == *"Up"* ]]; then
                    exec_interactive_shell "$c"
                else
                    show_flash "Error: Container is not running"
                fi
            fi
            return 0
            ;;
        s|S)
            if ((data_index >= 0 && data_index < ${#CONTAINER_NAMES[@]})); then
                local c="${CONTAINER_NAMES[$data_index]}"
                exec_cmd "docker start '$c'"
                show_flash "Started: $c"
                page_containers_enter
                full_redraw
            fi
            return 0
            ;;
        t|T)
            if ((data_index >= 0 && data_index < ${#CONTAINER_NAMES[@]})); then
                local c="${CONTAINER_NAMES[$data_index]}"
                exec_cmd "docker stop '$c'"
                show_flash "Stopped: $c"
                page_containers_enter
                full_redraw
            fi
            return 0
            ;;
        x|X)
            if ((data_index >= 0 && data_index < ${#CONTAINER_NAMES[@]})); then
                local c="${CONTAINER_NAMES[$data_index]}"
                exec_cmd "docker restart '$c'"
                show_flash "Restarted: $c"
                page_containers_enter
                full_redraw
            fi
            return 0
            ;;
        d|D)
            if ((data_index >= 0 && data_index < ${#CONTAINER_NAMES[@]})); then
                local c="${CONTAINER_NAMES[$data_index]}"
                if confirm_action "Remove container '$c'?"; then
                    exec_cmd "docker rm -f '$c'"
                    show_flash "Removed: $c"
                    page_containers_enter
                fi
                full_redraw
            fi
            return 0
            ;;
        k|K)
            if [[ "$SHOW_K8S_CONTAINERS" == true ]]; then
                SHOW_K8S_CONTAINERS=false
            else
                SHOW_K8S_CONTAINERS=true
            fi
            page_containers_enter
            full_redraw
            return 0
            ;;
        *) return 1 ;;
    esac
}
