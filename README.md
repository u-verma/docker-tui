# Docker Operations Console

A powerful terminal-based UI for managing Docker containers, images, volumes, and Colima engine on macOS.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Shell](https://img.shields.io/badge/shell-bash-green)

---

## ✨ Features

### Current (V1.0)

- 🐳 **Container Management** - Start, stop, restart, remove containers
- 🖼️ **Image Browser** - View, inspect, and remove images
- 💾 **Volume Management** - Inspect and clean up volumes
- 📊 **Live Statistics** - Real-time CPU, memory, and I/O monitoring
- 📜 **Log Viewer** - View container logs with follow mode
- 🔧 **Engine Control** - Start/stop/restart Colima VM
- ⚙️ **VM Resize** - Adjust CPU and memory allocation
- ☸️ **Kubernetes** - Enable/disable K8s cluster
- 🧹 **System Cleanup** - Prune unused resources
- 🎨 **Rich UI** - Color-coded status, keyboard navigation, modal dialogs

### Navigation

```
Main Menu (Grid Layout)
  ├─ Containers → List → Detail → Logs/Stats
  ├─ Images     → List → Inspect
  ├─ Volumes    → List
  ├─ System     → Prune operations
  ├─ Engine     → Control VM → Resize
  └─ Kubernetes → Enable/Disable → Cluster info
```

### Keybindings

**Global:**
- `Q` - Quit
- `ESC` - Go back
- `R` - Refresh current page
- `↑/↓` - Navigate items
- `Enter` - Select/Execute

**Page-Specific:**
- Containers: `S`-Start, `T`-Stop, `X`-Restart, `D`-Remove, `K`-Toggle K8s containers
- Images: `D`-Remove, `Enter`-Inspect
- Volumes: `D`-Remove
- Engine: `S`-Start, `T`-Stop, `X`-Restart, `M`-Resize VM
- Detail: `L`-Logs, `M`-Stats

---

## 🚀 Installation

### Quick Install

```bash
# Run the installer
bash install-dev-docker.sh

# Or use make
make install
```

The installer will:
1. Check for dependencies (docker, colima, kubectl)
2. Install missing tools via Homebrew
3. Install docker-tui to `/usr/local/bin/`
4. Create command: `docker-tui`

### Usage

```bash
# Launch (with automatic engine check)
docker-tui

# Launch without auto-start
docker-tui --no-start

# Uninstall
make uninstall
# or
bash install-dev-docker.sh --uninstall

# Clean install (removes all Docker data)
bash install-dev-docker.sh --clean
```

---

## 📋 Requirements

- **macOS** (Darwin) - Tested on macOS 12+
- **Homebrew** - For dependency installation
- **Bash 3.2+** - Built-in on macOS
- **Terminal** - 80x24 minimum, 120x40+ recommended

### Dependencies (Auto-installed)

- `docker` - Docker CLI
- `colima` - Container runtime for macOS
- `kubectl` - Kubernetes CLI (optional)

---

## 🏗️ Architecture

Built with pure Bash, following a modular, page-based architecture:

```
docker-tui/
├── install-dev-docker.sh    # Installer
├── Makefile                 # Build commands
└── lib/
    ├── core.sh              # State management, terminal control
    ├── main_loop.sh         # Event loop
    ├── renderer.sh          # Screen rendering
    ├── input.sh             # Keyboard input parser
    ├── navigation.sh        # Page stack navigation
    ├── data.sh              # Docker API wrappers
    ├── scroll.sh            # List scrolling logic
    ├── dialog.sh            # Modal dialogs
    └── pages/               # Page modules
        ├── main.sh          # Main menu
        ├── containers.sh    # Container list
        ├── detail.sh        # Container details
        ├── logs.sh          # Log viewer
        ├── stats.sh         # Live statistics
        ├── images.sh        # Image browser
        ├── volumes.sh       # Volume browser
        ├── system.sh        # System prune
        ├── engine.sh        # Engine control
        └── kubernetes.sh    # K8s management
```

### Key Design Patterns

- **Event-Driven:** Main event loop with keyboard input handling
- **Page-Based Navigation:** Stack-based page history (like a SPA)
- **Modular Design:** Each page is self-contained with enter/key handlers
- **Stateful Caching:** Smart caching to minimize expensive Docker calls
- **Terminal Control:** Raw mode, alternate screen buffer, ANSI colors

---

## 📚 Documentation

### For Users

- **README.md** - This file (installation, usage, features)

### For Developers

- **[docs/ROADMAP_V2.md](docs/ROADMAP_V2.md)** - Complete V2 feature roadmap
  - Planned features, priorities, timeline
  - Performance improvements
  - New capabilities (Compose, Networks, Search, etc.)

- **[docs/FEATURES_V2_SUMMARY.md](docs/FEATURES_V2_SUMMARY.md)** - Quick reference
  - Prioritized feature list
  - Implementation checklist
  - Success metrics

## 🛠️ Development

### Project Structure

```bash
# Install development version
make install

# Lint code
shellcheck lib/*.sh lib/pages/*.sh

# Test manually
docker-tui

# Uninstall
make uninstall

# Clean install (wipes Docker data)
make clean
```

### Adding a New Page

1. Create `lib/pages/mypage.sh`
2. Implement `page_mypage_enter()` and `page_mypage_key()`
3. Add to installer modules list
4. Source in docker-tui entry point
5. Add navigation from another page

Example:
```bash
# lib/pages/mypage.sh
page_mypage_enter() {
    PAGE_TITLE="My Page"
    ACTION_BAR="Enter:Action  Esc:Back"
    CONTENT_LINES=("Line 1" "Line 2")
}

page_mypage_key() {
    local key=$1
    case "$key" in
        UP) scroll_up; return 0 ;;
        DOWN) scroll_down; return 0 ;;
        *) return 1 ;;
    esac
}
```

---

## 🔮 V2 Roadmap Highlights

Version 2.0 is in planning with major enhancements:

### Performance
- ⚡ Async data loading (no UI blocking)
- ⏱️ Command timeouts (prevent hangs)
- 🗄️ Smart caching and lazy loading

### New Features
- 🔍 Search and filter system
- 🐙 Docker Compose support
- 🌐 Network management page
- 📦 Enhanced image management (pull, push, build)
- 📂 Volume file browser
- 📊 Dashboard with overview
- 💻 Interactive container shell

### Improvements
- 🎨 Theme system (customizable colors)
- ❓ Built-in help system
- ⚙️ Configuration file support
- 📝 Debug logging framework
- 🧪 Unit test coverage
- 🐧 Linux compatibility

See **[docs/ROADMAP_V2.md](docs/ROADMAP_V2.md)** for complete details.

---

## 🤝 Contributing

Contributions welcome! See **[docs/CONTRIBUTING_V2.md](docs/CONTRIBUTING_V2.md)** for:

- Development setup
- Code style guidelines
- Testing procedures
- PR workflow

### Quick Start for Contributors

```bash
# 1. Fork and clone
git clone <your-fork>
cd docker-tui

# 2. Create feature branch
git checkout -b feature/my-feature

# 3. Make changes
vim lib/mymodule.sh

# 4. Test
make install
docker-tui

# 5. Lint
shellcheck lib/mymodule.sh

# 6. Commit and push
git commit -am "feat: add my feature"
git push origin feature/my-feature

# 7. Open PR on GitHub
```

---

## 📝 License

[Add your license here]

---

## 🙏 Acknowledgments

Built with:
- Pure Bash shell scripting
- Docker and Colima
- ANSI terminal control sequences
- Love for the command line ❤️

Inspired by:
- `lazydocker` - Docker TUI
- `k9s` - Kubernetes TUI
- `htop` - System monitor
- `tig` - Git TUI

---

## 📞 Support

- **Issues:** https://github.com/u-verma/docker-tui/issues
- **Discussions:** https://github.com/u-verma/docker-tui/discussions
- **Documentation:** See `/docs` folder

---

## 🎯 Status

- **Current Version:** 1.0.0
- **Status:** Production Ready ✅
- **Platform:** macOS (Darwin)
- **Next Release:** V2.0 (Q2 2026)

---

**Happy Docker Managing! 🐳**
