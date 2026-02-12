#!/usr/bin/env bash
# data.sh — Docker/Colima queries, exec_cmd, guard_engine

exec_cmd() {
    CMD_OUTPUT=$(eval "$1" 2>&1) || true
    CMD_EXIT=$?
}

engine_running() {
    docker info >/dev/null 2>&1
}

guard_engine() {
    if ! engine_running; then
        CONTENT_LINES=()
        CONTENT_LINES+=("")
        CONTENT_LINES+=("  Docker engine is not running.")
        CONTENT_LINES+=("")
        CONTENT_LINES+=("  Start the engine from the Engine page,")
        CONTENT_LINES+=("  or run: colima start")
        return 1
    fi
    return 0
}

load_containers() {
    CONTAINER_NAMES=()
    CONTAINER_STATUS=()
    CONTAINER_IMAGES=()
    CONTAINER_PORTS=()

    guard_engine || return 1

    local line
    while IFS='|' read -r name status image ports; do
        [[ -z "$name" ]] && continue
        if [[ "$SHOW_K8S_CONTAINERS" == false && "$name" == k8s_* ]]; then
            continue
        fi
        CONTAINER_NAMES+=("$name")
        CONTAINER_STATUS+=("$status")
        CONTAINER_IMAGES+=("$image")
        CONTAINER_PORTS+=("$ports")
    done < <(docker ps -a --format '{{.Names}}|{{.Status}}|{{.Image}}|{{.Ports}}' 2>/dev/null || true)
    return 0
}

load_images() {
    IMAGE_REPOS=()
    IMAGE_TAGS=()
    IMAGE_IDS=()
    IMAGE_SIZES=()
    IMAGE_CREATED=()

    guard_engine || return 1

    while IFS='|' read -r repo tag id size created; do
        [[ -z "$repo" ]] && continue
        IMAGE_REPOS+=("$repo")
        IMAGE_TAGS+=("$tag")
        IMAGE_IDS+=("${id:0:12}")
        IMAGE_SIZES+=("$size")
        IMAGE_CREATED+=("$created")
    done < <(docker images --format '{{.Repository}}|{{.Tag}}|{{.ID}}|{{.Size}}|{{.CreatedSince}}' 2>/dev/null || true)
    return 0
}

load_volumes() {
    VOLUME_NAMES=()
    VOLUME_DRIVERS=()
    VOLUME_MOUNTS=()

    guard_engine || return 1

    while IFS='|' read -r name driver mount; do
        [[ -z "$name" ]] && continue
        VOLUME_NAMES+=("$name")
        VOLUME_DRIVERS+=("$driver")
        VOLUME_MOUNTS+=("$mount")
    done < <(docker volume ls --format '{{.Name}}|{{.Driver}}|{{.Mountpoint}}' 2>/dev/null || true)
    return 0
}
