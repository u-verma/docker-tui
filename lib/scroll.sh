#!/usr/bin/env bash
# scroll.sh — Scrollable content & selection

reset_selection() {
    SCROLL_OFFSET=0
    SELECTED_INDEX=0
}

scroll_down() {
    local total=${#CONTENT_LINES[@]}
    if ((SELECTED_INDEX < total - 1)); then
        ((SELECTED_INDEX++))
        local bottom=$((SCROLL_OFFSET + CONTENT_HEIGHT - 1))
        if ((SELECTED_INDEX > bottom)); then
            ((SCROLL_OFFSET++))
        fi
        redraw_content
    fi
}

scroll_up() {
    if ((SELECTED_INDEX > 0)); then
        ((SELECTED_INDEX--))
        if ((SELECTED_INDEX < SCROLL_OFFSET)); then
            SCROLL_OFFSET=$SELECTED_INDEX
        fi
        redraw_content
    fi
}

page_down() {
    local total=${#CONTENT_LINES[@]}
    SELECTED_INDEX=$((SELECTED_INDEX + CONTENT_HEIGHT))
    if ((SELECTED_INDEX >= total)); then
        SELECTED_INDEX=$((total - 1))
    fi
    SCROLL_OFFSET=$((SELECTED_INDEX - CONTENT_HEIGHT + 1))
    if ((SCROLL_OFFSET < 0)); then
        SCROLL_OFFSET=0
    fi
    redraw_content
}

page_up() {
    SELECTED_INDEX=$((SELECTED_INDEX - CONTENT_HEIGHT))
    if ((SELECTED_INDEX < 0)); then
        SELECTED_INDEX=0
    fi
    SCROLL_OFFSET=$SELECTED_INDEX
    redraw_content
}
