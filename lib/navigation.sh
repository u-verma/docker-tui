#!/usr/bin/env bash
# navigation.sh — Nav stack (push/pop), page lifecycle

nav_push() {
    local page=$1
    NAV_STACK+=("$page")
    reset_selection
    "page_${page}_enter"
    full_redraw
}

nav_pop() {
    local len=${#NAV_STACK[@]}
    if ((len <= 1)); then
        return
    fi
    unset 'NAV_STACK[len-1]'
    NAV_STACK=("${NAV_STACK[@]}")
    len=${#NAV_STACK[@]}
    local prev="${NAV_STACK[len-1]}"
    reset_selection
    "page_${prev}_enter"
    full_redraw
}

nav_current() {
    local len=${#NAV_STACK[@]}
    if ((len == 0)); then
        echo "main"
        return
    fi
    echo "${NAV_STACK[len-1]}"
}
