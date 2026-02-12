#!/usr/bin/env bash
# Centralized configuration - update these to rename the project

COMMAND_NAME="docker-tui"
PROJECT_DISPLAY_NAME="Docker TUI"
PROJECT_DESCRIPTION="Docker Operations Console"
PROJECT_VERSION="1.0.0"

INSTALL_BASE="/usr/local/bin"
INSTALL_DIR="${INSTALL_BASE}/${COMMAND_NAME}"
EXECUTABLE_PATH="${INSTALL_BASE}/${COMMAND_NAME}"
CONFIG_DIR="${HOME}/.${COMMAND_NAME}"
CONFIG_FILE="${CONFIG_DIR}/config.conf"
LOG_DIR="${CONFIG_DIR}/logs"

REQUIRED_DEPS=(docker colima kubectl docker-compose)
DEFAULT_CACHE_TTL=30
AUTO_START_ENGINE=true
