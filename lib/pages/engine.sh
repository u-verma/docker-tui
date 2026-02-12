#!/usr/bin/env bash
# pages/engine.sh — Settings: Engine control, VM resources, preferences

show_usage_stats() {
    show_flash "Loading resource usage..." "${C_YELLOW}"
    
    local cpu_percent="0" mem_used_total="0" mem_percent="0" disk_used="0"
    
    # Get CPU and memory from all running containers (aggregate)
    local stats_output
    stats_output=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}" 2>/dev/null) || stats_output=""
    
    if [[ -n "$stats_output" ]]; then
        local cpu_sum=0 mem_perc_sum=0
        while IFS='|' read -r cpu mem_usage mem_perc; do
            local cpu_val=$(echo "$cpu" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
            local mem_val=$(echo "$mem_perc" | grep -oE '[0-9]+\.?[0-9]*' | head -1)
            
            [[ -n "$cpu_val" ]] && cpu_sum=$(echo "$cpu_sum + $cpu_val" | bc 2>/dev/null)
            [[ -n "$mem_val" ]] && mem_perc_sum=$(echo "$mem_perc_sum + $mem_val" | bc 2>/dev/null)
            
            # Parse memory value
            local mem_size=$(echo "$mem_usage" | awk '{print $1}')
            if [[ "$mem_size" =~ GiB ]]; then
                local mem_gb=$(echo "$mem_size" | sed 's/GiB//')
                mem_used_total=$(echo "$mem_used_total + $mem_gb" | bc 2>/dev/null)
            elif [[ "$mem_size" =~ MiB ]]; then
                local mem_mb=$(echo "$mem_size" | sed 's/MiB//')
                mem_used_total=$(echo "$mem_used_total + $mem_mb / 1024" | bc -l 2>/dev/null)
            fi
        done <<< "$stats_output"
        
        cpu_percent=$(printf "%.0f" "$cpu_sum" 2>/dev/null) || cpu_percent="0"
        mem_percent=$(printf "%.0f" "$mem_perc_sum" 2>/dev/null) || mem_percent="0"
        mem_used_total=$(printf "%.2f" "$mem_used_total" 2>/dev/null) || mem_used_total="0"
    fi
    
    # Get disk usage
    local df_output=$(docker system df 2>/dev/null)
    if [[ -n "$df_output" ]]; then
        disk_used=$(echo "$df_output" | tail -n +2 | awk '{sum+=$3} END {print int(sum)}' 2>/dev/null) || disk_used="0"
    fi
    
    # Get colima info for bar calculations
    local colima_list=$(colima list 2>&1 | tail -n +2)
    local cpu=$(echo "$colima_list" | awk '{print $4}' | head -1)
    local disk=$(echo "$colima_list" | awk '{print $6}' | sed 's/GiB//' | head -1)
    
    # Add usage section
    CONTENT_LINES+=("")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}Resource Usage:${C_RESET}")")
    
    # CPU bar
    local cpu_bar_width=40
    local cpu_max=$((cpu * 100))
    [[ "$cpu_max" -eq 0 ]] && cpu_max=100
    local cpu_display_percent=$((cpu_percent * 100 / cpu_max))
    [[ $cpu_display_percent -gt 100 ]] && cpu_display_percent=100
    local cpu_filled=$(( cpu_display_percent * cpu_bar_width / 100 ))
    [[ $cpu_filled -lt 0 ]] && cpu_filled=0
    local cpu_empty=$(( cpu_bar_width - cpu_filled ))
    local cpu_bar="" cpu_color="$C_GREEN"
    (( cpu_display_percent > 70 )) && cpu_color="$C_YELLOW"
    (( cpu_display_percent > 90 )) && cpu_color="$C_RED"
    for ((i=0; i<cpu_filled; i++)); do cpu_bar+="█"; done
    for ((i=0; i<cpu_empty; i++)); do cpu_bar+="░"; done
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} ${cpu_color}%s${C_RESET} %s%%" "CPU:" "$cpu_bar" "$cpu_percent")")
    
    # Memory bar
    [[ "$mem_percent" =~ ^[0-9]+$ ]] || mem_percent=0
    local mem_bar_width=40
    local mem_filled=$(( mem_percent * mem_bar_width / 100 ))
    [[ $mem_filled -gt $mem_bar_width ]] && mem_filled=$mem_bar_width
    [[ $mem_filled -lt 0 ]] && mem_filled=0
    local mem_empty=$(( mem_bar_width - mem_filled ))
    local mem_bar="" bar_color="$C_GREEN"
    (( mem_percent > 70 )) && bar_color="$C_YELLOW"
    (( mem_percent > 90 )) && bar_color="$C_RED"
    for ((i=0; i<mem_filled; i++)); do mem_bar+="█"; done
    for ((i=0; i<mem_empty; i++)); do mem_bar+="░"; done
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} ${bar_color}%s${C_RESET} %s%% (%sGB)" "Memory:" "$mem_bar" "$mem_percent" "$mem_used_total")")
    
    # Disk bar
    if [[ "$disk" =~ ^[0-9]+$ ]] && [[ "$disk" -gt 0 ]]; then
        [[ "$disk_used" == "?" ]] && disk_used=0
        local disk_percent=$(( disk_used * 100 / disk ))
        [[ $disk_percent -gt 100 ]] && disk_percent=100
        local disk_bar_width=40
        local disk_filled=$(( disk_percent * disk_bar_width / 100 ))
        [[ $disk_filled -lt 0 ]] && disk_filled=0
        local disk_empty=$(( disk_bar_width - disk_filled ))
        local disk_bar="" disk_bar_color="$C_GREEN"
        (( disk_percent > 70 )) && disk_bar_color="$C_YELLOW"
        (( disk_percent > 90 )) && disk_bar_color="$C_RED"
        for ((i=0; i<disk_filled; i++)); do disk_bar+="█"; done
        for ((i=0; i<disk_empty; i++)); do disk_bar+="░"; done
        CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} ${disk_bar_color}%s${C_RESET} %s%% (%s GB / %s GB)" "Disk:" "$disk_bar" "$disk_percent" "$disk_used" "$disk")")
    fi
    
    redraw_content
    show_flash "Usage stats loaded"
}

page_engine_enter() {
    PAGE_TITLE="Settings"
    ACTION_BAR="Configure engine and VM resources | S:Start  T:Stop  X:Restart  M:Resize-VM  U:Usage"
    CONTENT_LINES=()
    refresh_status_cache force

    local running="false"
    engine_running && running="true"

    local colima_ver colima_list cpu mem disk arch runtime
    colima_ver=$(colima version 2>&1 | head -1 || echo "unknown")
    colima_list=$(colima list 2>&1 | tail -n +2)

    cpu=$(echo "$colima_list" | awk '{print $4}' | head -1)
    mem=$(echo "$colima_list" | awk '{print $5}' | sed 's/GiB//' | head -1)
    disk=$(echo "$colima_list" | awk '{print $6}' | sed 's/GiB//' | head -1)
    arch=$(echo "$colima_list" | awk '{print $3}' | head -1)
    runtime=$(echo "$colima_list" | awk '{print $7}' | head -1)

    local status_color status_text
    if [[ "$running" == "true" ]]; then
        status_color="$C_GREEN"
        status_text="RUNNING"
    else
        status_color="$C_RED"
        status_text="STOPPED"
    fi
    
    CONTENT_LINES+=("")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}Engine Status:${C_RESET}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} ${status_color}${C_BOLD}%s${C_RESET}" "Status:" "$status_text")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Colima:" "$colima_ver")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Runtime:" "${runtime:-docker}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s" "Arch:" "${arch:-aarch64}")")
    CONTENT_LINES+=("")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}VM Resources (Allocated):${C_RESET}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s cores" "CPU:" "${cpu:-?}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s GB" "Memory:" "${mem:-?}")")
    CONTENT_LINES+=("$(printf "  ${C_CYAN}%-14s${C_RESET} %s GB" "Disk:" "${disk:-?}")")
    CONTENT_LINES+=("")
    
    if [[ "$running" == "true" ]]; then
        CONTENT_LINES+=("$(printf "  ${C_GREY}Press U to load live resource usage${C_RESET}")")
    fi
}

page_engine_key() {
    local key=$1
    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        u|U)
            show_usage_stats
            return 0
            ;;
        s|S)
            show_flash "Starting engine..." "${C_YELLOW}"
            exec_cmd "colima start"
            # Ensure docker context is set to colima after start
            exec_cmd "docker context use colima >/dev/null 2>&1 || true"
            # Force refresh status cache to update ENGINE status in header
            refresh_status_cache force
            show_flash "Engine started"
            page_engine_enter
            full_redraw
            return 0
            ;;
        t|T)
            if confirm_action "Stop Docker engine?"; then
                show_flash "Stopping engine..." "${C_YELLOW}"
                exec_cmd "colima stop"
                # Force refresh status cache to update ENGINE status in header
                refresh_status_cache force
                show_flash "Engine stopped"
                page_engine_enter
            fi
            full_redraw
            return 0
            ;;
        x|X)
            if confirm_action "Restart Docker engine?"; then
                show_flash "Restarting engine..." "${C_YELLOW}"
                exec_cmd "colima stop && colima start"
                # Ensure docker context is set to colima after restart
                exec_cmd "docker context use colima >/dev/null 2>&1 || true"
                # Force refresh status cache to update ENGINE status in header
                refresh_status_cache force
                show_flash "Engine restarted"
                page_engine_enter
            fi
            full_redraw
            return 0
            ;;
        m|M)
            nav_push "resize"
            return 0
            ;;
        *) return 1 ;;
    esac
}

# ── Resize VM ───────────────────────────────────────────────────

page_resize_enter() {
    PAGE_TITLE="Resize VM"
    ACTION_BAR="Adjust VM CPU and memory allocation | Tab:Next field  Enter:Apply"
    RESIZE_FIELD=0
    RESIZE_CPU=""
    RESIZE_MEM=""
    CONTENT_LINES=()
    CONTENT_LINES+=("")
    CONTENT_LINES+=("  Enter new VM resource allocation:")
    CONTENT_LINES+=("  (Engine will be restarted)")
    CONTENT_LINES+=("")
}

draw_resize_form() {
    local base_row=$((CONTENT_START + 4))
    draw_input_field "$base_row" "CPUs" "${RESIZE_CPU:-_}" $((RESIZE_FIELD == 0))
    draw_input_field $((base_row + 2)) "Memory (GB)" "${RESIZE_MEM:-_}" $((RESIZE_FIELD == 1))
    tput cup $((base_row + 4)) 4
    if ((RESIZE_FIELD == 2)); then
        printf "${C_REV}${C_GREEN}  [ Apply ]  ${C_RESET}"
    else
        printf "${C_GREEN}  [ Apply ]  ${C_RESET}"
    fi
}

page_resize_key() {
    local key=$1
    case "$key" in
        TAB)
            RESIZE_FIELD=$(( (RESIZE_FIELD + 1) % 3 ))
            draw_resize_form
            return 0
            ;;
        UP)
            ((RESIZE_FIELD > 0)) && ((RESIZE_FIELD--))
            draw_resize_form
            return 0
            ;;
        DOWN)
            ((RESIZE_FIELD < 2)) && ((RESIZE_FIELD++))
            draw_resize_form
            return 0
            ;;
        ENTER)
            if ((RESIZE_FIELD == 2)); then
                # Apply
                if [[ -z "$RESIZE_CPU" || -z "$RESIZE_MEM" ]]; then
                    show_flash "Please fill in both fields" "${C_ERROR_BG}${C_ERROR_FG}"
                    return 0
                fi
                if confirm_action "Resize VM to ${RESIZE_CPU}CPU/${RESIZE_MEM}GB?"; then
                    show_flash "Resizing VM..." "${C_YELLOW}"
                    exec_cmd "colima stop && colima start --cpu ${RESIZE_CPU} --memory ${RESIZE_MEM}"
                    # Ensure docker context is set to colima after resize
                    exec_cmd "docker context use colima >/dev/null 2>&1 || true"
                    # Force refresh status cache to update CPU/MEM in header
                    refresh_status_cache force
                    show_flash "VM resized"
                    nav_pop
                fi
                return 0
            fi
            # Move to next field on Enter
            RESIZE_FIELD=$(( (RESIZE_FIELD + 1) % 3 ))
            draw_resize_form
            return 0
            ;;
        BACKSPACE)
            if ((RESIZE_FIELD == 0)) && [[ -n "$RESIZE_CPU" ]]; then
                RESIZE_CPU="${RESIZE_CPU%?}"
            elif ((RESIZE_FIELD == 1)) && [[ -n "$RESIZE_MEM" ]]; then
                RESIZE_MEM="${RESIZE_MEM%?}"
            fi
            draw_resize_form
            return 0
            ;;
        [0-9])
            if ((RESIZE_FIELD == 0)); then
                RESIZE_CPU+="$key"
            elif ((RESIZE_FIELD == 1)); then
                RESIZE_MEM+="$key"
            fi
            draw_resize_form
            return 0
            ;;
        *) return 1 ;;
    esac
}
