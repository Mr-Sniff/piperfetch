# piperfetch bash integration
#
# Source this from ~/.bashrc after the usual prompt setup:
#
#     source /path/to/shell/bash-piperfetch.sh
#
# The animation pauses while a command runs, resumes when the dashboard is
# still on screen, and is retired once the output has scrolled it away.
# Bash has no native preexec hook, so this uses a DEBUG trap; if you already
# use a DEBUG trap, merge the two carefully.

__piperfetch_file() {
    printf '%s\n' "${XDG_RUNTIME_DIR:-/tmp}/piperfetch-$$.pid"
}

__piperfetch_state() {
    local f
    f=$(__piperfetch_file)
    printf '%s\n' "${f%.pid}.state"
}

__piperfetch_stop() {
    local f pid
    f=$(__piperfetch_file)
    if [[ -r $f ]]; then
        pid=$(cat "$f")
        kill -TERM "$pid" 2>/dev/null
        kill -CONT "$pid" 2>/dev/null
    fi
    rm -f "$f" "$(__piperfetch_state)"
}

__piperfetch_pause() {
    local f pid
    f=$(__piperfetch_file)
    [[ -r $f ]] || return
    pid=$(cat "$f")
    kill -STOP "$pid" 2>/dev/null
}

__piperfetch_prompt() {
    local f state script verdict
    f=$(__piperfetch_file)
    [[ -r $f ]] || return

    state=$(__piperfetch_state)
    if [[ ! -r $state ]]; then
        __piperfetch_stop
        return
    fi

    script=$(sed -n '2p' "$state")
    verdict=$(command python3 "$script" --prompt-check "$state" 2>/dev/null)
    if [[ $verdict == resume ]]; then
        kill -CONT "$(cat "$f")" 2>/dev/null
    else
        __piperfetch_stop
    fi
}

__piperfetch_at_prompt=1
__piperfetch_debug() {
    if [[ ${__piperfetch_at_prompt:-0} == 1 ]]; then
        __piperfetch_at_prompt=0
        __piperfetch_pause
    fi
}
__piperfetch_prompt_command() {
    __piperfetch_at_prompt=0
    __piperfetch_prompt
    __piperfetch_at_prompt=1
}

__piperfetch_clear_screen() {
    __piperfetch_stop
    printf '\e[r\e[2J\e[H'
}

trap '__piperfetch_debug' DEBUG
trap '__piperfetch_stop' EXIT
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }__piperfetch_prompt_command"
bind -x '"\C-l": __piperfetch_clear_screen' 2>/dev/null

clear() {
    __piperfetch_stop
    printf '\e[r'
    command clear "$@"
}
