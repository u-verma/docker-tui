#!/usr/bin/env bash
# pages/kubernetes.sh — K8s enable/disable

page_kubernetes_enter() {
    local k8s_enabled=false
    if colima status 2>&1 | grep -qi "kubernetes.*enabled"; then
        k8s_enabled=true
    fi

    local status_color status_text
    if [[ "$k8s_enabled" == true ]]; then
        status_color="$C_GREEN"
        status_text="ENABLED"
    else
        status_color="$C_GREY"
        status_text="DISABLED"
    fi

    # Put status in the title bar
    PAGE_TITLE="Kubernetes - Status: ${status_color}${status_text}${C_RESET}"
    ACTION_BAR="Manage Kubernetes cluster | E:Enable  D:Disable"
    CONTENT_LINES=()

    if [[ "$k8s_enabled" == true ]]; then
        CONTENT_LINES+=("")
        
        # ALWAYS use colima context - never use user's current context
        # This prevents accidental production cluster access
        local cluster_info
        cluster_info=$(kubectl --context=colima cluster-info 2>&1 | head -5)
        
        if [[ $? -ne 0 ]] || [[ "$cluster_info" == *"context \"colima\" does not exist"* ]]; then
            CONTENT_LINES+=("")
            CONTENT_LINES+=("")
            
            local err_msg="Unable to reach Colima Kubernetes cluster"
            local hint1="Kubernetes is enabled but cluster is not responding."
            local hint2="Try restarting: colima stop && colima start --kubernetes"
            local indent_err=$(( (WIDTH - ${#err_msg}) / 2 ))
            local indent_h1=$(( (WIDTH - ${#hint1}) / 2 ))
            local indent_h2=$(( (WIDTH - ${#hint2}) / 2 ))
            
            CONTENT_LINES+=("$(printf "%${indent_err}s${C_RED}%s${C_RESET}" "" "$err_msg")")
            CONTENT_LINES+=("")
            CONTENT_LINES+=("$(printf "%${indent_h1}s${C_GREY}%s${C_RESET}" "" "$hint1")")
            CONTENT_LINES+=("$(printf "%${indent_h2}s${C_GREY}%s${C_RESET}" "" "$hint2")")
            CONTENT_LINES+=("")
            return
        fi
        
        CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}Cluster Info (Colima Local):${C_RESET}")")
        CONTENT_LINES+=("")
        while IFS= read -r line; do
            CONTENT_LINES+=("  $line")
        done <<< "$cluster_info"

        local nodes
        nodes=$(kubectl --context=colima get nodes 2>/dev/null) || nodes="Unable to list nodes"
        CONTENT_LINES+=("")
        CONTENT_LINES+=("$(printf "  ${C_CYAN}${C_BOLD}Nodes:${C_RESET}")")
        CONTENT_LINES+=("")
        while IFS= read -r line; do
            CONTENT_LINES+=("  $line")
        done <<< "$nodes"
        CONTENT_LINES+=("")
        CONTENT_LINES+=("")
        local hint="Press D to disable Kubernetes"
        local hint_indent=$(( (WIDTH - ${#hint}) / 2 ))
        CONTENT_LINES+=("$(printf "%${hint_indent}s${C_GREY}%s${C_RESET}" "" "$hint")")
    else
        CONTENT_LINES+=("")
        
        # Center the message
        local msg="Press E to enable (will restart engine)"
        local indent=$(( (WIDTH - ${#msg}) / 2 ))
        
        CONTENT_LINES+=("$(printf "%${indent}s${C_GREY}%s${C_RESET}" "" "$msg")")
        CONTENT_LINES+=("")
    fi
}

page_kubernetes_key() {
    local key=$1
    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        e|E)
            if confirm_action "Enable K8s? (engine restarts)"; then
                show_flash "Enabling Kubernetes..." "${C_YELLOW}"
                # Ensure we're using colima docker context
                exec_cmd "docker context use colima >/dev/null 2>&1 || true"
                exec_cmd "colima stop && colima start --kubernetes"
                # Switch kubectl context to colima
                exec_cmd "kubectl config use-context colima >/dev/null 2>&1 || true"
                # Force refresh status cache to update K8S status in header
                refresh_status_cache force
                show_flash "Kubernetes enabled"
                page_kubernetes_enter
            fi
            full_redraw
            return 0
            ;;
        d|D)
            if confirm_action "Disable K8s? (engine restarts)"; then
                show_flash "Disabling Kubernetes..." "${C_YELLOW}"
                # Ensure we're using colima docker context
                exec_cmd "docker context use colima >/dev/null 2>&1 || true"
                exec_cmd "colima stop && colima start --kubernetes=false"
                # Force refresh status cache to update K8S status in header
                refresh_status_cache force
                show_flash "Kubernetes disabled"
                page_kubernetes_enter
            fi
            full_redraw
            return 0
            ;;
        *) return 1 ;;
    esac
}
