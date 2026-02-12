#!/usr/bin/env bash
# input.sh — Key reader, escape sequence parser
# Uses stty min/time for timeout (bash 3.2 compatible)
# Sets global KEY_RESULT to avoid subshell issues

read_key() {
    KEY_RESULT=""
    local key=""
    # No -t flag needed — stty min 0 time 2 handles the 0.2s timeout
    IFS= read -rsn1 -d '' key 2>/dev/null || true

    if [[ -z "$key" ]]; then
        KEY_RESULT="NONE"
        return
    fi

    # Escape sequences (bytes arrive near-instantly, stty time handles it)
    if [[ "$key" == $'\x1b' ]]; then
        local seq1="" seq2="" seq3=""
        IFS= read -rsn1 -d '' seq1 2>/dev/null || true
        if [[ -z "$seq1" ]]; then
            KEY_RESULT="ESC"
            return
        fi
        if [[ "$seq1" == "[" ]]; then
            IFS= read -rsn1 -d '' seq2 2>/dev/null || true
            case "$seq2" in
                A) KEY_RESULT="UP"; return ;;
                B) KEY_RESULT="DOWN"; return ;;
                C) KEY_RESULT="RIGHT"; return ;;
                D) KEY_RESULT="LEFT"; return ;;
                H) KEY_RESULT="HOME"; return ;;
                F) KEY_RESULT="END"; return ;;
                5) # PgUp
                    IFS= read -rsn1 -d '' seq3 2>/dev/null || true
                    KEY_RESULT="PGUP"; return ;;
                6) # PgDn
                    IFS= read -rsn1 -d '' seq3 2>/dev/null || true
                    KEY_RESULT="PGDN"; return ;;
                Z) KEY_RESULT="SHIFT_TAB"; return ;;
            esac
        fi
        KEY_RESULT="ESC"
        return
    fi

    # Special characters
    case "$key" in
        $'\n'|$'\r') KEY_RESULT="ENTER"; return ;;
        $'\t') KEY_RESULT="TAB"; return ;;
        $'\x7f'|$'\b') KEY_RESULT="BACKSPACE"; return ;;
    esac

    KEY_RESULT="$key"
}
