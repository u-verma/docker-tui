#!/usr/bin/env bash
set -eo pipefail

# ── Load Centralized Configuration ─────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source config file
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo "ERROR: config.sh not found in $SCRIPT_DIR"
    echo "Please ensure config.sh exists before running installer."
    exit 1
fi

# ── Colors & helpers ────────────────────────────────────────────

BLUE="\033[1;34m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"; BOLD="\033[1m"
info()  { echo -e "${BLUE}$1${NC}"; }
ok()    { echo -e "${GREEN}$1${NC}"; }
warn()  { echo -e "${YELLOW}$1${NC}"; }
fail()  { echo -e "${RED}$1${NC}"; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ── Helper Functions ───────────────────────────────────────────

check_deps() {
    local pkg ver
    echo ""
    for pkg in "${REQUIRED_DEPS[@]}"; do
        if command_exists "$pkg"; then
            ver=$("$pkg" version 2>/dev/null | head -1 || echo "installed")
            ok "  $pkg: $ver"
        else
            warn "  $pkg: NOT INSTALLED"
        fi
    done
    echo ""
}

get_missing_deps() {
    command_exists brew || return 0
    local MISSING=()
    for pkg in "${REQUIRED_DEPS[@]}"; do
        if ! brew list "$pkg" &>/dev/null; then
            MISSING+=("$pkg")
        fi
    done
    # Return one per line for proper array handling
    printf '%s\n' "${MISSING[@]}"
}

install_missing_deps() {
    local missing=("$@")
    
    # Filter out empty strings
    local filtered=()
    for item in "${missing[@]}"; do
        [[ -n "$item" ]] && filtered+=("$item")
    done
    
    if [ ${#filtered[@]} -eq 0 ]; then
        ok "All dependencies installed."
        return 0
    fi
    
    command_exists brew || fail "Homebrew required — https://brew.sh"
    
    warn "Missing: ${filtered[*]}"
    for pkg in "${filtered[@]}"; do
        info "Installing $pkg..."
        brew install "$pkg" || fail "Failed to install $pkg"
    done
    docker context use colima >/dev/null 2>&1 || true
}

upgrade_all_deps() {
    command_exists brew || fail "Homebrew required — https://brew.sh"
    info "Updating Homebrew..."
    brew update || warn "Homebrew update failed, continuing..."
    
    for pkg in "${REQUIRED_DEPS[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            info "Upgrading $pkg..."
            brew upgrade "$pkg" 2>/dev/null || info "  $pkg already latest version"
        else
            warn "  $pkg not installed, skipping"
        fi
    done
    docker context use colima >/dev/null 2>&1 || true
}

deep_clean() {
    if docker info >/dev/null 2>&1; then
        info "Stopping all containers..."
        local containers=$(docker ps -q 2>/dev/null)
        if [[ -n "$containers" ]]; then
            docker stop $containers 2>/dev/null || true
        fi
        
        info "Removing all Docker data..."
        docker system prune -a -f --volumes 2>/dev/null || true
        docker network prune -f 2>/dev/null || true
    else
        info "Docker engine not running, skipping container cleanup..."
    fi
    
    info "Removing ${COMMAND_NAME}..."
    rm -f "$EXECUTABLE_PATH"
    rm -rf "$INSTALL_DIR"
}

# ── Tool installation ───────────────────────────────────────────

install_docker_tui() {
    info "Installing ${COMMAND_NAME} modules..."

    # Clean existing installation first (always fresh install)
    if [[ -d "$INSTALL_DIR" ]] || [[ -f "$EXECUTABLE_PATH" ]]; then
        info "Removing existing ${COMMAND_NAME} installation..."
        rm -f "$EXECUTABLE_PATH"
        rm -rf "$INSTALL_DIR"
    fi

    # Validate source directory
    [[ -d "$SCRIPT_DIR/lib" ]] || fail "Source directory not found: $SCRIPT_DIR/lib"

    # Create install directory
    mkdir -p "$INSTALL_DIR/pages" || fail "Failed to create $INSTALL_DIR"

    # Copy lib modules
    local modules=(core.sh renderer.sh input.sh navigation.sh data.sh scroll.sh dialog.sh main_loop.sh)
    for mod in "${modules[@]}"; do
        [[ -f "$SCRIPT_DIR/lib/$mod" ]] || fail "Missing source file: $SCRIPT_DIR/lib/$mod"
        cp "$SCRIPT_DIR/lib/$mod" "$INSTALL_DIR/$mod" || fail "Failed to copy $mod"
    done

    # Copy page modules
    local pages=(main.sh containers.sh detail.sh logs.sh stats.sh images.sh volumes.sh compose.sh system.sh engine.sh kubernetes.sh)
    for page in "${pages[@]}"; do
        [[ -f "$SCRIPT_DIR/lib/pages/$page" ]] || fail "Missing page: $SCRIPT_DIR/lib/pages/$page"
        cp "$SCRIPT_DIR/lib/pages/$page" "$INSTALL_DIR/pages/$page" || fail "Failed to copy $page"
    done

    # Write tool entry point with auto-start logic
    cat > "$EXECUTABLE_PATH" <<ENTRY_EOF
#!/usr/bin/env bash
set -o pipefail

# Load configuration
SCRIPT_NAME="\$(basename "\$0")"
CFG="\$(dirname "\$0")/\${SCRIPT_NAME}/config.sh"
if [[ -f "\$CFG" ]]; then
    source "\$CFG"
else
    # Fallback for standalone installation
    COMMAND_NAME="\${SCRIPT_NAME}"
    INSTALL_DIR="\$(dirname "\$0")/\${SCRIPT_NAME}"
fi

# Check dependencies
command -v colima >/dev/null || { echo "colima not found. Install with: brew install colima"; exit 1; }
command -v docker >/dev/null || { echo "docker not found. Install with: brew install docker"; exit 1; }

docker context use colima >/dev/null 2>&1 || true

# Auto-start engine if not running (unless --no-start flag)
engine_running() { docker info >/dev/null 2>&1; }

if [[ "\$1" != "--no-start" ]] && ! engine_running; then
    echo "Docker engine is not running."
    read -p "Start engine now? (y/n): " ans
    if [[ "\$ans" == "y" || "\$ans" == "Y" ]]; then
        echo "Starting Colima..."
        colima start
    else
        echo "Launching \${COMMAND_NAME} anyway (engine controls available inside)."
    fi
fi

# Load TUI modules
source "\$INSTALL_DIR/core.sh"
source "\$INSTALL_DIR/renderer.sh"
source "\$INSTALL_DIR/input.sh"
source "\$INSTALL_DIR/navigation.sh"
source "\$INSTALL_DIR/data.sh"
source "\$INSTALL_DIR/scroll.sh"
source "\$INSTALL_DIR/dialog.sh"
source "\$INSTALL_DIR/pages/main.sh"
source "\$INSTALL_DIR/pages/containers.sh"
source "\$INSTALL_DIR/pages/detail.sh"
source "\$INSTALL_DIR/pages/logs.sh"
source "\$INSTALL_DIR/pages/stats.sh"
source "\$INSTALL_DIR/pages/images.sh"
source "\$INSTALL_DIR/pages/volumes.sh"
source "\$INSTALL_DIR/pages/compose.sh"
source "\$INSTALL_DIR/pages/system.sh"
source "\$INSTALL_DIR/pages/engine.sh"
source "\$INSTALL_DIR/pages/kubernetes.sh"
source "\$INSTALL_DIR/main_loop.sh"

main "\$@"
ENTRY_EOF
    chmod +x "$EXECUTABLE_PATH"

    # Copy config.sh to installation directory
    if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
        cp "$SCRIPT_DIR/config.sh" "$INSTALL_DIR/config.sh"
    fi

    # chmod all module files
    chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/pages/*.sh 2>/dev/null || true

    ok "${COMMAND_NAME} installed successfully."
    echo "  Run: ${COMMAND_NAME}"
}

# ── Uninstall ──────────────────────────────────────────────────

do_uninstall() {
    echo ""
    echo "  Uninstall options:"
    echo ""
    echo "    [1] Remove ${COMMAND_NAME} only (keep Docker, containers, images)"
    echo "    [2] Deep clean (remove ${COMMAND_NAME} + wipe all Docker data)"
    echo "    [Q] Cancel"
    echo ""
    read -p "  Select option: " ans || { info "Cancelled."; return; }
    
    case "$ans" in
        1)
            info "Removing ${COMMAND_NAME}..."
            rm -f "$EXECUTABLE_PATH"
            rm -rf "$INSTALL_DIR"
            ok "${COMMAND_NAME} removed."
            info "Note: docker, colima, kubectl, docker-compose were NOT removed."
            info "Note: Containers, images, and volumes are intact."
            ;;
        2)
            echo ""
            echo -e "${RED}${BOLD}WARNING: This will DELETE EVERYTHING:${NC}"
            echo "  - All Docker containers, images, volumes, networks"
            echo "  - ${COMMAND_NAME} tool"
            echo "  - docker, colima, kubectl, docker-compose (via Homebrew)"
            echo ""
            read -p "Type 'DELETE ALL' to confirm: " confirm || { info "Cancelled."; return; }
            if [[ "$confirm" != "DELETE ALL" ]]; then
                info "Cancelled."
                return
            fi
            
            deep_clean
            
            if command_exists brew; then
                info "Uninstalling Homebrew packages..."
                for pkg in "${REQUIRED_DEPS[@]}"; do
                    if brew list "$pkg" &>/dev/null; then
                        info "Removing $pkg..."
                        brew uninstall "$pkg" --force 2>/dev/null || warn "  Failed to remove $pkg"
                    fi
                done
            fi
            
            ok "Complete uninstall finished."
            ;;
        q|Q)
            info "Cancelled."
            return
            ;;
        *)
            warn "Invalid option."
            return
            ;;
    esac
}


# ── Interactive Menu ───────────────────────────────────────────

# ── Main Operations ────────────────────────────────────────────

do_install() {
    if [[ -f "$EXECUTABLE_PATH" ]]; then
        echo ""
        warn "${COMMAND_NAME} is already installed."
        read -p "Remove old setup and install fresh? (y/n): " ans || return
        if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
            info "Cancelled. Use 'Upgrade' or 'Repair' instead."
            return
        fi
        
        echo ""
        echo -e "${RED}${BOLD}This will wipe all Docker containers, images, and volumes.${NC}"
        read -p "Type 'yes' to confirm: " confirm || return
        if [[ "$confirm" != "yes" ]]; then
            info "Cancelled."
            return
        fi
        
        deep_clean
    fi
    
    info "Installing fresh setup..."
    local -a missing_array=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && missing_array+=("$line")
    done < <(get_missing_deps)
    install_missing_deps "${missing_array[@]}"
    install_docker_tui
    ok "Installation complete!"
}

do_upgrade() {
    info "Checking for missing dependencies..."
    local -a missing_array=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && missing_array+=("$line")
    done < <(get_missing_deps)
    
    if [ ${#missing_array[@]} -gt 0 ] && [[ -n "${missing_array[0]}" ]]; then
        warn "Found missing dependencies: ${missing_array[*]}"
        read -p "Repair (install missing) first? (y/n): " ans || return
        if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
            install_missing_deps "${missing_array[@]}"
        else
            info "Skipping repair."
        fi
    fi
    
    info "Upgrading all dependencies..."
    upgrade_all_deps
    
    info "Updating ${COMMAND_NAME}..."
    install_docker_tui
    
    ok "Upgrade complete!"
}

do_repair() {
    info "Checking installation..."
    local -a missing_array=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && missing_array+=("$line")
    done < <(get_missing_deps)
    
    if [ ${#missing_array[@]} -gt 0 ] && [[ -n "${missing_array[0]}" ]]; then
        install_missing_deps "${missing_array[@]}"
    else
        ok "All dependencies installed."
    fi
    
    if [[ ! -f "$EXECUTABLE_PATH" ]] || [[ ! -d "$INSTALL_DIR" ]]; then
        warn "${COMMAND_NAME} is broken or missing."
        info "Reinstalling ${COMMAND_NAME}..."
        install_docker_tui
    else
        ok "${COMMAND_NAME} is intact."
    fi
    
    ok "Repair complete!"
}

show_menu() {
    echo ""
    echo -e "${BLUE}${BOLD}${PROJECT_DISPLAY_NAME} Installer${NC}"
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 ${#PROJECT_DISPLAY_NAME}))============${NC}"
    echo ""
    echo "  Current status:"
    check_deps

    if [[ -f "$EXECUTABLE_PATH" ]]; then
        ok "  ${COMMAND_NAME}: INSTALLED"
    else
        warn "  ${COMMAND_NAME}: NOT INSTALLED"
    fi
    echo ""
    echo "  What would you like to do?"
    echo ""
    echo "    [1] Install     - Fresh installation (checks for conflicts)"
    echo "    [2] Upgrade     - Upgrade dependencies and ${COMMAND_NAME} to latest"
    echo "    [3] Repair      - Fix missing dependencies or broken installation"
    echo "    [4] Install UI  - Install/update ${COMMAND_NAME} tool only (quick)"
    echo "    [5] Uninstall   - Remove ${COMMAND_NAME} and optionally wipe Docker data"
    echo "    [Q] Quit"
    echo ""
    read -p "  Select option: " choice || { echo ""; info "Cancelled."; exit 0; }

    case "$choice" in
        1)
            do_install
            ;;
        2)
            do_upgrade
            ;;
        3)
            do_repair
            ;;
        4)
            install_docker_tui
            ;;
        5)
            do_uninstall
            ;;
        q|Q)
            info "Bye."
            exit 0
            ;;
        *)
            warn "Invalid option."
            exit 1
            ;;
    esac
}

# ── CLI flag handling ──────────────────────────────────────────

case "${1:-}" in
    --install)
        do_install
        ;;
    --upgrade)
        do_upgrade
        ;;
    --repair)
        do_repair
        ;;
        --ui)
            install_docker_tui
        ;;
    --uninstall)
        do_uninstall
        ;;
    *)
        show_menu
        ;;
esac
