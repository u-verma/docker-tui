#!/usr/bin/env bash
# pages/volumes.sh — Volume browser

page_volumes_enter() {
    PAGE_TITLE="Volumes"
    ACTION_BAR="Manage Docker volumes | D:Remove"
    CONTENT_LINES=()

    if ! load_volumes; then return; fi

    if ((${#VOLUME_NAMES[@]} == 0)); then
        CONTENT_LINES+=("")
        CONTENT_LINES+=("  No volumes found.")
        return
    fi

    local hdr
    hdr=$(printf "  ${C_CYAN}${C_BOLD}%-36s %-12s %-30s${C_RESET}" "NAME" "DRIVER" "MOUNTPOINT")
    CONTENT_LINES+=("$hdr")

    local i
    for ((i = 0; i < ${#VOLUME_NAMES[@]}; i++)); do
        local line
        line=$(printf "  %-36s %-12s %-30s" \
            "${VOLUME_NAMES[$i]:0:34}" "${VOLUME_DRIVERS[$i]:0:10}" "${VOLUME_MOUNTS[$i]:0:28}")
        CONTENT_LINES+=("$line")
    done
    SELECTED_INDEX=1
}

page_volumes_key() {
    local key=$1
    local data_index=$((SELECTED_INDEX - 1))

    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        PGUP) page_up; return 0 ;;
        PGDN) page_down; return 0 ;;
        d|D)
            if ((data_index >= 0 && data_index < ${#VOLUME_NAMES[@]})); then
                local vol="${VOLUME_NAMES[$data_index]}"
                if confirm_action "Remove volume '$vol'?"; then
                    exec_cmd "docker volume rm '$vol'"
                    show_flash "Removed: $vol"
                    page_volumes_enter
                fi
                full_redraw
            fi
            return 0
            ;;
        *) return 1 ;;
    esac
}
