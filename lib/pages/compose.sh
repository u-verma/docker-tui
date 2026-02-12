#!/usr/bin/env bash
# pages/compose.sh — Docker Compose management

declare -a COMPOSE_PROJECTS=()
declare -a COMPOSE_PATHS=()
declare -a COMPOSE_CONTAINER_COUNTS=()

page_compose_enter() {
    PAGE_TITLE="Docker Compose"
    ACTION_BAR="Browse and manage compose projects | Enter:Services  D:Down  R:Restart  L:Logs"
    CONTENT_LINES=()
    
    if ! guard_engine; then return; fi
    
    # Get all compose projects from running containers
    COMPOSE_PROJECTS=()
    COMPOSE_PATHS=()
    COMPOSE_CONTAINER_COUNTS=()
    
    # Get unique project names from container labels
    local projects
    projects=$(docker ps -a --filter "label=com.docker.compose.project" --format "{{.Label \"com.docker.compose.project\"}}" 2>/dev/null | sort -u)
    
    if [[ -z "$projects" ]]; then
        CONTENT_LINES+=("")
        CONTENT_LINES+=("  No compose projects found.")
        CONTENT_LINES+=("")
        CONTENT_LINES+=("  Start a compose project to see it here:")
        CONTENT_LINES+=("  $ cd your-project && docker-compose up -d")
        CONTENT_LINES+=("")
        return
    fi
    
    # Header
    local hdr
    hdr=$(printf "  ${C_CYAN}${C_BOLD}%-30s %-15s %-12s %-30s${C_RESET}" "PROJECT" "CONTAINERS" "STATUS" "WORKING DIR")
    CONTENT_LINES+=("$hdr")
    
    # List each project
    while IFS= read -r project; do
        [[ -z "$project" ]] && continue
        
        # Count total and running containers for this project
        local total_count running_count
        total_count=$(docker ps -a --filter "label=com.docker.compose.project=$project" --format "{{.ID}}" 2>/dev/null | wc -l | tr -d ' ')
        running_count=$(docker ps --filter "label=com.docker.compose.project=$project" --format "{{.ID}}" 2>/dev/null | wc -l | tr -d ' ')
        
        # Get working directory from first container
        local working_dir
        working_dir=$(docker ps -a --filter "label=com.docker.compose.project=$project" --format "{{.Label \"com.docker.compose.project.working_dir\"}}" 2>/dev/null | head -1)
        [[ -z "$working_dir" ]] && working_dir="unknown"
        
        # Determine status
        local status_color status_text
        if [[ "$running_count" -eq "$total_count" ]] && [[ "$running_count" -gt 0 ]]; then
            status_color="$C_GREEN"
            status_text="running"
        elif [[ "$running_count" -gt 0 ]]; then
            status_color="$C_YELLOW"
            status_text="partial"
        else
            status_color="$C_GREY"
            status_text="stopped"
        fi
        
        COMPOSE_PROJECTS+=("$project")
        COMPOSE_PATHS+=("$working_dir")
        COMPOSE_CONTAINER_COUNTS+=("$total_count")
        
        local container_info="$running_count/$total_count"
        local line
        line=$(printf "  %-30s %-15s ${status_color}%-12s${C_RESET} %-30s" "${project:0:28}" "$container_info" "$status_text" "${working_dir:0:28}")
        CONTENT_LINES+=("$line")
    done <<< "$projects"
    
    # Skip header for selection
    SELECTED_INDEX=1
}

page_compose_key() {
    local key=$1
    local data_index=$((SELECTED_INDEX - 1))
    
    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        PGUP) page_up; return 0 ;;
        PGDN) page_down; return 0 ;;
        d|D)
            if ((data_index >= 0 && data_index < ${#COMPOSE_PROJECTS[@]})); then
                local project="${COMPOSE_PROJECTS[$data_index]}"
                local working_dir="${COMPOSE_PATHS[$data_index]}"
                if confirm_action "Stop compose project '$project'?"; then
                    show_flash "Stopping compose project..." "${C_YELLOW}"
                    if [[ "$working_dir" != "unknown" && -d "$working_dir" ]]; then
                        cd "$working_dir"
                        if command -v docker-compose &>/dev/null; then
                            exec_cmd "docker-compose down"
                        else
                            exec_cmd "docker compose down"
                        fi
                    else
                        # Stop containers directly by label
                        exec_cmd "docker stop \$(docker ps -q --filter \"label=com.docker.compose.project=$project\")"
                    fi
                    show_flash "Stopped: $project"
                    page_compose_enter
                fi
                full_redraw
            fi
            return 0
            ;;
        r|R)
            if ((data_index >= 0 && data_index < ${#COMPOSE_PROJECTS[@]})); then
                local project="${COMPOSE_PROJECTS[$data_index]}"
                show_flash "Restarting compose project..." "${C_YELLOW}"
                # Restart all containers in this project
                exec_cmd "docker restart \$(docker ps -aq --filter \"label=com.docker.compose.project=$project\")"
                show_flash "Restarted: $project"
                page_compose_enter
                full_redraw
            fi
            return 0
            ;;
        l|L)
            if ((data_index >= 0 && data_index < ${#COMPOSE_PROJECTS[@]})); then
                local project="${COMPOSE_PROJECTS[$data_index]}"
                CONTENT_LINES=()
                CONTENT_LINES+=("")
                CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}Logs: %s${C_RESET}" "$project")")
                CONTENT_LINES+=("")
                
                # Get logs from all containers in this project
                local containers
                containers=$(docker ps -q --filter "label=com.docker.compose.project=$project" 2>/dev/null)
                
                if [[ -z "$containers" ]]; then
                    CONTENT_LINES+=("  No running containers in this project.")
                else
                    for container in $containers; do
                        local container_name
                        container_name=$(docker inspect --format '{{.Name}}' "$container" | sed 's/^\///')
                        CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}=== %s ===${C_RESET}" "$container_name")")
                        local logs
                        logs=$(docker logs --tail 20 "$container" 2>&1)
                        while IFS= read -r line; do
                            CONTENT_LINES+=("  $line")
                        done <<< "$logs"
                        CONTENT_LINES+=("")
                    done
                fi
                
                reset_selection
                full_redraw
            fi
            return 0
            ;;
        ENTER)
            if ((data_index >= 0 && data_index < ${#COMPOSE_PROJECTS[@]})); then
                local project="${COMPOSE_PROJECTS[$data_index]}"
                CONTENT_LINES=()
                CONTENT_LINES+=("")
                CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}Project: %s${C_RESET}" "$project")")
                CONTENT_LINES+=("")
                
                # List all containers in this project
                local hdr
                hdr=$(printf "  ${C_CYAN}%-30s %-15s %-30s${C_RESET}" "CONTAINER" "STATUS" "IMAGE")
                CONTENT_LINES+=("$hdr")
                
                local containers
                containers=$(docker ps -a --filter "label=com.docker.compose.project=$project" --format "{{.Names}}|{{.Status}}|{{.Image}}" 2>/dev/null)
                
                while IFS='|' read -r name status image; do
                    [[ -z "$name" ]] && continue
                    
                    local status_color="$C_GREY"
                    if [[ "$status" == *"Up"* ]]; then
                        status_color="$C_GREEN"
                    fi
                    
                    local line
                    line=$(printf "  %-30s ${status_color}%-15s${C_RESET} %-30s" "${name:0:28}" "${status:0:13}" "${image:0:28}")
                    CONTENT_LINES+=("$line")
                done <<< "$containers"
                
                reset_selection
                full_redraw
            fi
            return 0
            ;;
        *) return 1 ;;
    esac
}
