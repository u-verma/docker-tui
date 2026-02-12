#!/usr/bin/env bash
# pages/logs.sh — Log viewer

# Search state
LOG_SEARCH_TERM=""
declare -a LOG_SEARCH_MATCHES=()
LOG_SEARCH_CURRENT=0

page_logs_enter() {
    PAGE_TITLE="Logs: $LOG_CONTAINER"
    local follow_status=""
    [[ "$LOG_FOLLOW" == true ]] && follow_status=" (Following)" || follow_status=""
    local search_status=""
    if [[ -n "$LOG_SEARCH_TERM" ]]; then
        search_status=" | Searching: \"$LOG_SEARCH_TERM\" (${#LOG_SEARCH_MATCHES[@]} matches)"
    fi
    ACTION_BAR="View container logs${follow_status}${search_status} | /:Search  n:Next  N:Prev  Esc:Clear  ↑↓:Scroll  F:Follow  R:Refresh"
    CONTENT_LINES=()

    if ! guard_engine; then return; fi

    local logs
    logs=$(docker logs --tail 200 "$LOG_CONTAINER" 2>&1) || true

    if [[ -z "$logs" ]]; then
        CONTENT_LINES+=("  (no log output)")
        return
    fi

    # Wrap long lines to terminal width
    local max_width=$((WIDTH - 4))  # Leave margin for indentation
    while IFS= read -r line; do
        # If line is empty, add it as-is
        if [[ -z "$line" ]]; then
            CONTENT_LINES+=("  ")
            continue
        fi
        
        # Highlight search term if searching (case-insensitive)
        local display_line="$line"
        if [[ -n "$LOG_SEARCH_TERM" ]]; then
            # Use sed for case-insensitive highlighting
            display_line=$(echo "$line" | sed -E "s/($LOG_SEARCH_TERM)/${C_SUCCESS_BG}${C_WHITE}\1${C_RESET}/gi")
        fi
        
        # Wrap long lines
        local wrapped_line="  $display_line"
        if ((${#wrapped_line} <= WIDTH + 50)); then  # Account for ANSI codes
            CONTENT_LINES+=("$wrapped_line")
        else
            # For now, just add the line as-is for simplicity with highlights
            # TODO: Improve wrapping with ANSI codes
            CONTENT_LINES+=("$wrapped_line")
        fi
    done <<< "$logs"

    # Auto-scroll to bottom (unless searching)
    if [[ -z "$LOG_SEARCH_TERM" ]]; then
        local total=${#CONTENT_LINES[@]}
        if ((total > CONTENT_HEIGHT)); then
            SCROLL_OFFSET=$((total - CONTENT_HEIGHT))
            SELECTED_INDEX=$((total - 1))
        fi
    fi
}

search_logs() {
    # Prompt for search term
    cleanup_terminal
    clear
    echo -e "${C_CYAN}${C_BOLD}Search Logs: $LOG_CONTAINER${C_RESET}"
    echo ""
    echo -e "${C_GREY}Enter search term (case-insensitive):${C_RESET}"
    echo -n -e "${C_YELLOW}Search: ${C_RESET}"
    
    read -r search_term
    
    if [[ -z "$search_term" ]]; then
        setup_terminal
        full_redraw
        return
    fi
    
    # Store search term and refresh content with highlights
    LOG_SEARCH_TERM="$search_term"
    LOG_SEARCH_MATCHES=()
    LOG_SEARCH_CURRENT=0
    
    setup_terminal
    page_logs_enter  # This will rebuild CONTENT_LINES with highlights
    
    # Find all matching line indices (case-insensitive)
    local i
    for ((i = 0; i < ${#CONTENT_LINES[@]}; i++)); do
        # Remove ANSI codes for matching
        local clean_line=$(echo "${CONTENT_LINES[$i]}" | sed 's/\x1b\[[0-9;]*m//g')
        if echo "$clean_line" | grep -qi "$search_term"; then
            LOG_SEARCH_MATCHES+=("$i")
        fi
    done
    
    # Jump to first match
    if ((${#LOG_SEARCH_MATCHES[@]} > 0)); then
        local first_match=${LOG_SEARCH_MATCHES[0]}
        SELECTED_INDEX=$first_match
        
        # Center the match on screen if possible
        if ((first_match > CONTENT_HEIGHT / 2)); then
            SCROLL_OFFSET=$((first_match - CONTENT_HEIGHT / 2))
        else
            SCROLL_OFFSET=0
        fi
    else
        show_flash "No matches found"
    fi
    
    full_redraw
}

next_match() {
    if ((${#LOG_SEARCH_MATCHES[@]} == 0)); then
        show_flash "No search results"
        return
    fi
    
    LOG_SEARCH_CURRENT=$(( (LOG_SEARCH_CURRENT + 1) % ${#LOG_SEARCH_MATCHES[@]} ))
    local match=${LOG_SEARCH_MATCHES[$LOG_SEARCH_CURRENT]}
    SELECTED_INDEX=$match
    
    # Center the match on screen
    if ((match > CONTENT_HEIGHT / 2)); then
        SCROLL_OFFSET=$((match - CONTENT_HEIGHT / 2))
    else
        SCROLL_OFFSET=0
    fi
    
    page_logs_enter
    full_redraw
}

prev_match() {
    if ((${#LOG_SEARCH_MATCHES[@]} == 0)); then
        show_flash "No search results"
        return
    fi
    
    LOG_SEARCH_CURRENT=$(( (LOG_SEARCH_CURRENT - 1 + ${#LOG_SEARCH_MATCHES[@]}) % ${#LOG_SEARCH_MATCHES[@]} ))
    local match=${LOG_SEARCH_MATCHES[$LOG_SEARCH_CURRENT]}
    SELECTED_INDEX=$match
    
    # Center the match on screen
    if ((match > CONTENT_HEIGHT / 2)); then
        SCROLL_OFFSET=$((match - CONTENT_HEIGHT / 2))
    else
        SCROLL_OFFSET=0
    fi
    
    page_logs_enter
    full_redraw
}

clear_search() {
    LOG_SEARCH_TERM=""
    LOG_SEARCH_MATCHES=()
    LOG_SEARCH_CURRENT=0
    page_logs_enter
    full_redraw
}

page_logs_key() {
    local key=$1
    case "$key" in
        '/')
            search_logs
            return 0
            ;;
        n)
            next_match
            return 0
            ;;
        N)
            prev_match
            return 0
            ;;
        ESC)
            clear_search
            return 0
            ;;
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        PGUP) page_up; return 0 ;;
        PGDN) page_down; return 0 ;;
        HOME)
            SCROLL_OFFSET=0
            SELECTED_INDEX=0
            full_redraw
            return 0
            ;;
        END)
            local total=${#CONTENT_LINES[@]}
            if ((total > CONTENT_HEIGHT)); then
                SCROLL_OFFSET=$((total - CONTENT_HEIGHT))
                SELECTED_INDEX=$((total - 1))
            else
                SELECTED_INDEX=$((total > 0 ? total - 1 : 0))
            fi
            full_redraw
            return 0
            ;;
        f|F)
            if [[ "$LOG_FOLLOW" == true ]]; then
                LOG_FOLLOW=false
            else
                LOG_FOLLOW=true
            fi
            page_logs_enter
            full_redraw
            return 0
            ;;
        r|R)
            page_logs_enter
            full_redraw
            return 0
            ;;
        *) return 1 ;;
    esac
}
