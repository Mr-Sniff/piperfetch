# piperfetch bash integration
#
# Source this from ~/.bashrc after the usual prompt setup:
#
#     source /path/to/shell/bash-piperfetch.sh
#
# It stops the animation when a command starts.  Bash has no native preexec
# hook, so this uses a DEBUG trap; if you already use a DEBUG trap, merge the
# two carefully.

__piperfetch_file() {
    printf '%s\n' "${XDG_RUNTIME_DIR:-/tmp}/piperfetch-$$.pid"
}

__piperfetch_stop() {
    local f
    f=$(__piperfetch_file)
    if [[ -r $f ]]; then
        kill "$(cat "$f")" 2>/dev/null
    fi
    rm -f "$f"
}

__piperfetch_at_prompt=1
__piperfetch_debug() {
    if [[ ${__piperfetch_at_prompt:-0} == 1 ]]; then
        __piperfetch_at_prompt=0
        __piperfetch_stop
    fi
}
__piperfetch_prompt() {
    __piperfetch_at_prompt=1
}

__piperfetch_clear_screen() {
    __piperfetch_stop
    printf '\e[r\e[2J\e[H'
}

trap '__piperfetch_debug' DEBUG
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }__piperfetch_prompt"
bind -x '"\C-l": __piperfetch_clear_screen' 2>/dev/null

clear() {
    __piperfetch_stop
    printf '\e[r'
    command clear "$@"
}
