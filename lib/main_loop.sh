#!/usr/bin/env bash
# main_loop.sh — Main event loop, global key dispatch

main() {
    # Dependency check
    command -v docker >/dev/null || { echo "docker not found"; exit 1; }
    command -v colima >/dev/null || { echo "colima not found"; exit 1; }

    docker context use colima >/dev/null 2>&1 || true

    setup_terminal
    # Set dimensions without redrawing (not initialized yet)
    WIDTH=$(tput cols)
    HEIGHT=$(tput lines)
    FOOTER_ROW=$((HEIGHT - 1))
    CONTENT_HEIGHT=$((FOOTER_ROW - CONTENT_START))

    # Start at main menu
    NAV_STACK=()
    nav_push "main"
    INITIALIZED=true

    # For main menu, draw the grid after full_redraw
    draw_menu_grid

    local last_refresh=0
    last_refresh=$(date +%s)

    while true; do
        read_key 0.2
        local key="$KEY_RESULT"

        if [[ "$key" == "NONE" ]]; then
            # Auto-refresh for stats, logs follow-mode, and engine page
            local now=0
            now=$(date +%s)
            local current=""
            current=$(nav_current)
            if [[ "$current" == "stats" ]] && ((now - last_refresh >= 2)); then
                page_stats_enter
                full_redraw
                last_refresh=$now
            elif [[ "$current" == "logs" && "$LOG_FOLLOW" == true ]] && ((now - last_refresh >= 2)); then
                page_logs_enter
                full_redraw
                last_refresh=$now
            fi
            continue
        fi

        # Global keys (always processed first)
        local handled=false
        case "$key" in
            q|Q)
                if confirm_action "Quit Docker Console?"; then
                    exit 0
                fi
                full_redraw
                [[ "$(nav_current)" == "main" ]] && draw_menu_grid
                handled=true
                ;;
            ESC)
                if ((${#NAV_STACK[@]} > 1)); then
                    nav_pop
                    [[ "$(nav_current)" == "main" ]] && draw_menu_grid
                fi
                handled=true
                ;;
            r|R)
                local current=""
                current=$(nav_current)
                # Don't treat R as refresh on resize page (it's a data entry page)
                if [[ "$current" != "resize" ]]; then
                    refresh_status_cache force
                    "page_${current}_enter"
                    full_redraw
                    [[ "$current" == "main" ]] && draw_menu_grid
                    handled=true
                fi
                ;;
        esac

        if [[ "$handled" == true ]]; then
            continue
        fi

        # Page-specific key dispatch
        local current=""
        current=$(nav_current)
        "page_${current}_key" "$key" || true

        # After resize form interaction, redraw it
        if [[ "$current" == "resize" ]]; then
            draw_resize_form
        fi
    done
}
