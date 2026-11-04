# piperfetch zsh integration
#
# Add this to ~/.zshrc:
#
#     source /path/to/shell/zsh-piperfetch.zsh
#
# The animation pauses while a command runs, resumes when the dashboard is
# still on screen, and is retired once the output has scrolled it away.

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

autoload -Uz add-zsh-hook
add-zsh-hook preexec __piperfetch_pause
add-zsh-hook precmd __piperfetch_prompt
add-zsh-hook zshexit __piperfetch_stop

__piperfetch_clear_screen() {
    __piperfetch_stop
    printf '\e[r\e[2J\e[H'
    zle -R
}
zle -N __piperfetch_clear_screen
bindkey '^L' __piperfetch_clear_screen

clear() {
    __piperfetch_stop
    printf '\e[r'
    command clear "$@"
}
