#!/usr/bin/env bash
# pages/images.sh — Image browser

page_images_enter() {
    PAGE_TITLE="Images"
    ACTION_BAR="Browse and manage Docker images | Enter:Inspect  D:Remove"
    CONTENT_LINES=()

    if ! load_images; then return; fi

    if ((${#IMAGE_REPOS[@]} == 0)); then
        CONTENT_LINES+=("")
        CONTENT_LINES+=("  No images found.")
        return
    fi

    local hdr
    hdr=$(printf "  ${C_CYAN}${C_BOLD}%-30s %-16s %-14s %-10s %-16s${C_RESET}" "REPOSITORY" "TAG" "ID" "SIZE" "CREATED")
    CONTENT_LINES+=("$hdr")

    local i
    for ((i = 0; i < ${#IMAGE_REPOS[@]}; i++)); do
        local line
        line=$(printf "  %-30s %-16s %-14s %-10s %-16s" \
            "${IMAGE_REPOS[$i]:0:28}" "${IMAGE_TAGS[$i]:0:14}" "${IMAGE_IDS[$i]}" \
            "${IMAGE_SIZES[$i]:0:8}" "${IMAGE_CREATED[$i]:0:14}")
        CONTENT_LINES+=("$line")
    done
    SELECTED_INDEX=1
}

page_images_key() {
    local key=$1
    local data_index=$((SELECTED_INDEX - 1))

    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        PGUP) page_up; return 0 ;;
        PGDN) page_down; return 0 ;;
        ENTER)
            if ((data_index >= 0 && data_index < ${#IMAGE_IDS[@]})); then
                local img_id="${IMAGE_IDS[$data_index]}"
                local inspect_out
                inspect_out=$(docker inspect "$img_id" 2>&1 | head -60) || true
                CONTENT_LINES=()
                CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}Image Inspect: %s${C_RESET}" "$img_id")")
                CONTENT_LINES+=("")
                while IFS= read -r line; do
                    CONTENT_LINES+=("  $line")
                done <<< "$inspect_out"
                reset_selection
                full_redraw
            fi
            return 0
            ;;
        d|D)
            if ((data_index >= 0 && data_index < ${#IMAGE_REPOS[@]})); then
                local img="${IMAGE_REPOS[$data_index]}:${IMAGE_TAGS[$data_index]}"
                if confirm_action "Remove image '$img'?"; then
                    exec_cmd "docker rmi '$img'"
                    show_flash "Removed: $img"
                    page_images_enter
                fi
                full_redraw
            fi
            return 0
            ;;
        *) return 1 ;;
    esac
}
