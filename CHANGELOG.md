# Changelog

All notable changes to Docker Operations Console will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### V2.0 - Planning Phase
See [docs/ROADMAP_V2.md](docs/ROADMAP_V2.md) for complete V2 feature list.

#### Planned - High Priority
- Async data loading system
- Command timeout wrapper
- Enhanced error messages with recovery suggestions
- Interactive container shell (`docker exec -it`)
- Advanced log viewer (search, filter, export)
- Network management page
- Linux platform support
- Unit test framework (BATS)
- Configuration file support
- Debug logging system

#### Planned - Medium Priority
- Docker Compose support
- Search and filter system
- Enhanced image management (pull, push, build, scan)
- Volume file browser
- Help system (? key overlay)
- Dashboard overview page
- Theme system
- Bulk operations (multi-select)

#### Planned - Low Priority
- Container templates
- Statistics with ASCII graphs
- Plugin system
- Mouse support
- Read-only mode

---

## [1.0.0] - 2026-02-11

### Initial Release 🎉

#### Added
- **Container Management**
  - List all containers (running and stopped)
  - View detailed container information
  - Start/stop/restart containers
  - Remove containers with confirmation
  - Toggle K8s container visibility
  
- **Image Management**
  - Browse all Docker images
  - View image details (repository, tag, ID, size, age)
  - Inspect image metadata
  - Remove images with confirmation

- **Volume Management**
  - List all Docker volumes
  - View volume details (name, driver, mountpoint)
  - Remove volumes with confirmation

- **Log Viewer**
  - View container logs (last 200 lines)
  - Follow mode for live log streaming
  - Auto-scroll to bottom
  - Refresh on demand

- **Live Statistics**
  - Real-time container stats (CPU, memory, network, disk I/O)
  - Auto-refresh every 2 seconds
  - Process count monitoring

- **Engine Control**
  - View Colima VM status
  - Start/stop/restart Docker engine
  - View VM resource allocation (CPU, memory, disk)
  - Resize VM resources dynamically
  - View runtime and architecture info

- **Kubernetes Support**
  - Enable/disable Kubernetes cluster
  - View cluster information
  - List cluster nodes
  - Integration with kubectl

- **System Maintenance**
  - Prune entire system (containers, images, networks, cache)
  - Prune networks separately
  - Prune volumes separately
  - Prune build cache separately

- **UI/UX Features**
  - Color-coded status indicators (green=running, red=stopped)
  - 256-color ANSI terminal support
  - Grid-based main menu
  - Stack-based page navigation (ESC to go back)
  - Modal confirmation dialogs
  - Flash messages for actions
  - Keyboard-driven interface
  - Responsive to terminal resize (SIGWINCH)
  - Alternate screen buffer (clean terminal on exit)

- **Installation**
  - Interactive installer with menu
  - Automatic dependency installation via Homebrew
  - Modular file installation to `/usr/local/bin/docker-tui/`
  - Two entry points: `docker-tui` and `docker-tui`
  - Uninstall option
  - Clean install option (wipes Docker data)

#### Technical Details
- **Platform:** macOS (Darwin)
- **Shell:** Bash 3.2+ compatible
- **Dependencies:** docker, colima, kubectl
- **Architecture:** Modular, page-based design
- **Code:** ~2,000 lines of Bash
- **Modules:** 17 files (8 core, 10 pages)

#### Performance
- Startup time: < 1 second
- Smart caching (30s TTL) for expensive calls
- Non-blocking input with timeout
- Efficient screen rendering (only changed regions)

#### Known Limitations
- macOS only (Colima-specific)
- No search/filter functionality
- No Docker Compose support
- No network management
- Synchronous data loading (can block UI)
- No configuration file
- No logging/debugging output
- No unit tests

---

## Development History

### Pre-1.0 Development

#### Phase 1: Foundation (Weeks 1-2)
- Initial project structure
- Basic terminal control (alternate screen, raw mode)
- Input handling (keyboard, escape sequences)
- Navigation system (page stack)

#### Phase 2: Core Pages (Weeks 3-4)
- Main menu with grid layout
- Container list page
- Container detail page
- Image browser page
- Volume browser page

#### Phase 3: Live Features (Weeks 5-6)
- Log viewer with follow mode
- Live statistics page with auto-refresh
- Engine control page
- VM resize form

#### Phase 4: Advanced Features (Weeks 7-8)
- System prune operations
- Kubernetes integration
- Modal dialogs
- Flash messages

#### Phase 5: Polish & Release (Weeks 9-10)
- Bug fixes
- Performance optimization
- Status caching
- Installer improvements
- Documentation

---

## Version History

| Version | Date       | Highlights |
|---------|------------|------------|
| 1.0.0   | 2026-02-11 | Initial release with core features |
| 2.0.0   | TBD        | Async loading, search, Compose support |

---

## Migration Guides

### Upgrading to V2.0 (Future)

When V2.0 is released, follow these steps:

1. **Backup current installation:**
   ```bash
   cp /usr/local/bin/docker-tui ~/docker-tui-v1-backup
   ```

2. **Review breaking changes:**
   - Configuration file replaces some environment variables
   - Some keybindings may change
   - Bash 4.0+ may be required

3. **Install V2:**
   ```bash
   bash install-dev-docker.sh
   ```

4. **Review new configuration file:**
   ```bash
   cat ~/.docker-tui/config.conf
   # Adjust settings as needed
   ```

5. **Test new features:**
   ```bash
   docker-tui
   # Press ? for help
   ```

---

## Release Process

### For Maintainers

1. **Update version:**
   ```bash
   # Edit version in install script
   VERSION="2.0.0"
   ```

2. **Update CHANGELOG.md:**
   - Move items from Unreleased to new version section
   - Add release date
   - Summarize changes

3. **Tag release:**
   ```bash
   git tag -a v2.0.0 -m "Release version 2.0.0"
   git push origin v2.0.0
   ```

4. **Create GitHub release:**
   - Use tag
   - Copy changelog content
   - Attach installer script

5. **Update Homebrew formula** (if applicable)

---

## Support

- **Bug Reports:** [GitHub Issues]
- **Feature Requests:** [GitHub Discussions]
- **Documentation:** [README.md](README.md), [docs/ROADMAP_V2.md](docs/ROADMAP_V2.md)

---

**Note:** This is a living document. As development progresses, changes will be documented here.

[Unreleased]: https://github.com/your-org/docker-tui/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-org/docker-tui/releases/tag/v1.0.0
