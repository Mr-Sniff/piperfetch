# piperfetch fish integration
#
# Copy this file to ~/.config/fish/conf.d/piperfetch.fish, or source it from
# your fish config.  It stops the piperfetch animation when a command starts
# so command output can scroll the dashboard away.
#
# Add this line to your existing fish_user_key_bindings function to make
# Ctrl-L clear the dashboard:
#
#     bind \cl __piperfetch_clear_screen

function __piperfetch_file
    set -l dir $XDG_RUNTIME_DIR
    test -n "$dir"; or set dir /tmp
    echo "$dir/piperfetch-$fish_pid.pid"
end

function __piperfetch_stop
    set -l f (__piperfetch_file)
    if test -r "$f"
        kill (cat "$f") 2>/dev/null
    end
    rm -f "$f"
end

function __piperfetch_preexec --on-event fish_preexec
    __piperfetch_stop
end

function __piperfetch_exit --on-event fish_exit
    __piperfetch_stop
end

# clear also drops the dashboard and returns to a normal terminal.
function clear
    __piperfetch_stop
    printf '\e[r'
    command clear $argv
end

function __piperfetch_clear_screen
    __piperfetch_stop
    printf '\e[r\e[2J\e[H'
    commandline -f repaint
end

# If your shell greeting runs another fetch, disable it when using piperfetch
# as the Kitty shell program:
#
# function fish_greeting
# end
