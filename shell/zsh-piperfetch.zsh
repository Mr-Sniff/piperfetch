# piperfetch zsh integration
#
# Add this to ~/.zshrc:
#
#     source /path/to/shell/zsh-piperfetch.zsh

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

__piperfetch_preexec() {
    __piperfetch_stop
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __piperfetch_preexec
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
