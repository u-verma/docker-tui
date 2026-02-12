#!/usr/bin/env bash
# pages/detail.sh — Container detail view

page_detail_enter() {
    PAGE_TITLE="Container: $DETAIL_CONTAINER"
    
    # Check if container is running to show exec option
    local status
    status=$(docker inspect --format '{{.State.Status}}' "$DETAIL_CONTAINER" 2>/dev/null || echo "unknown")
    
    if [[ "$status" == "running" ]]; then
        ACTION_BAR="Container operations and monitoring | E:Shell  C:Exec  L:Logs  M:Stats  S:Start  T:Stop  X:Restart"
    else
        ACTION_BAR="Container operations and monitoring | L:Logs  M:Stats  S:Start  T:Stop  X:Restart"
    fi
    
    CONTENT_LINES=()

    if ! guard_engine; then return; fi

    local inspect
    inspect=$(docker inspect "$DETAIL_CONTAINER" 2>/dev/null) || {
        CONTENT_LINES+=("  Container not found: $DETAIL_CONTAINER")
        return
    }

    local id status image created ports networks mounts
    id=$(echo "$inspect" | grep -m1 '"Id"' | cut -d'"' -f4 | head -c 12)
    status=$(docker inspect --format '{{.State.Status}}' "$DETAIL_CONTAINER" 2>/dev/null || echo "unknown")
    image=$(docker inspect --format '{{.Config.Image}}' "$DETAIL_CONTAINER" 2>/dev/null || echo "unknown")
    created=$(docker inspect --format '{{.Created}}' "$DETAIL_CONTAINER" 2>/dev/null || echo "unknown")
    ports=$(docker inspect --format '{{range $p, $conf := .NetworkSettings.Ports}}{{$p}}->{{range $conf}}{{.HostPort}}{{end}} {{end}}' "$DETAIL_CONTAINER" 2>/dev/null || echo "none")
    networks=$(docker inspect --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$DETAIL_CONTAINER" 2>/dev/null || echo "none")
    mounts=$(docker inspect --format '{{range .Mounts}}{{.Type}}:{{.Source}}->{{.Destination}} {{end}}' "$DETAIL_CONTAINER" 2>/dev/null || echo "none")

    local status_color="$C_GREY"
    [[ "$status" == "running" ]] && status_color="$C_GREEN"
    [[ "$status" == "exited" ]] && status_color="$C_RED"

    CONTENT_LINES+=("")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Name:" "$DETAIL_CONTAINER")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "ID:" "$id")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} ${status_color}%s${C_RESET}" "Status:" "$status")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Image:" "$image")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Created:" "${created:0:19}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Ports:" "${ports:-none}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Networks:" "${networks:-none}")")
    CONTENT_LINES+=("")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}Mounts:${C_RESET}")")
    if [[ -n "$mounts" && "$mounts" != "none" ]]; then
        local m
        for m in $mounts; do
            CONTENT_LINES+=("    $m")
        done
    else
        CONTENT_LINES+=("    none")
    fi
}

detect_shell() {
    local container=$1
    local shells=("bash" "sh" "/bin/bash" "/bin/sh")
    
    for shell in "${shells[@]}"; do
        if docker exec "$container" command -v "$shell" >/dev/null 2>&1; then
            echo "$shell"
            return 0
        fi
    done
    
    echo "sh"  # fallback
    return 1
}

exec_interactive_shell() {
    local container=$1
    local status
    status=$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null)
    
    if [[ "$status" != "running" ]]; then
        show_flash "Error: Container is not running"
        return 1
    fi
    
    local shell
    shell=$(detect_shell "$container")
    
    # Exit TUI mode
    cleanup_terminal
    
    clear
    echo -e "${C_CYAN}${C_BOLD}Entering container: $container${C_RESET}"
    echo -e "${C_GREY}Shell: $shell${C_RESET}"
    echo -e "${C_GREY}Type 'exit' to return to docker-tui${C_RESET}"
    echo ""
    
    # Execute interactive shell
    docker exec -it "$container" "$shell"
    
    # Return to TUI mode
    echo ""
    echo -e "${C_GREEN}Returned from container${C_RESET}"
    echo -e "${C_GREY}Press any key to continue...${C_RESET}"
    read -rsn1
    
    setup_terminal
    full_redraw
}

exec_command() {
    local container=$1
    local status
    status=$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null)
    
    if [[ "$status" != "running" ]]; then
        show_flash "Error: Container is not running"
        return 1
    fi
    
    # Exit TUI mode temporarily for input
    cleanup_terminal
    
    clear
    echo -e "${C_CYAN}${C_BOLD}Execute command in: $container${C_RESET}"
    echo ""
    echo -e "${C_GREY}Examples:${C_RESET}"
    echo -e "  ${C_GREY}ls -la${C_RESET}"
    echo -e "  ${C_GREY}ps aux${C_RESET}"
    echo -e "  ${C_GREY}cat /etc/os-release${C_RESET}"
    echo ""
    echo -n -e "${C_YELLOW}Command: ${C_RESET}"
    
    read -r cmd
    
    if [[ -z "$cmd" ]]; then
        echo -e "${C_RED}Cancelled${C_RESET}"
        sleep 1
        setup_terminal
        full_redraw
        return 1
    fi
    
    echo ""
    echo -e "${C_CYAN}Executing...${C_RESET}"
    echo ""
    
    # Execute command
    docker exec "$container" sh -c "$cmd"
    local exit_code=$?
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${C_GREEN}✓ Command completed successfully${C_RESET}"
    else
        echo -e "${C_RED}✗ Command failed with exit code: $exit_code${C_RESET}"
    fi
    echo -e "${C_GREY}Press any key to continue...${C_RESET}"
    read -rsn1
    
    setup_terminal
    full_redraw
}

page_detail_key() {
    local key=$1
    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        e|E)
            exec_interactive_shell "$DETAIL_CONTAINER"
            return 0
            ;;
        c|C)
            exec_command "$DETAIL_CONTAINER"
            return 0
            ;;
        l|L)
            LOG_CONTAINER="$DETAIL_CONTAINER"
            nav_push "logs"
            return 0
            ;;
        m|M)
            STATS_CONTAINER="$DETAIL_CONTAINER"
            nav_push "stats"
            return 0
            ;;
        s|S)
            exec_cmd "docker start '$DETAIL_CONTAINER'"
            show_flash "Started: $DETAIL_CONTAINER"
            page_detail_enter
            full_redraw
            return 0
            ;;
        t|T)
            exec_cmd "docker stop '$DETAIL_CONTAINER'"
            show_flash "Stopped: $DETAIL_CONTAINER"
            page_detail_enter
            full_redraw
            return 0
            ;;
        x|X)
            exec_cmd "docker restart '$DETAIL_CONTAINER'"
            show_flash "Restarted: $DETAIL_CONTAINER"
            page_detail_enter
            full_redraw
            return 0
            ;;
        *) return 1 ;;
    esac
}
