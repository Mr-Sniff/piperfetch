# piperfetch fish integration
#
# Copy this file to ~/.config/fish/conf.d/piperfetch.fish, or source it from
# your fish config.  It pauses the piperfetch animation while a command runs,
# then resumes it if the dashboard is still visible.  Once the output has
# scrolled the dashboard off the screen, the animation is retired.
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

function __piperfetch_state
    set -l file (__piperfetch_file)
    string replace -r '\.pid$' '.state' -- $file
end

function __piperfetch_stop
    set -l f (__piperfetch_file)
    if test -r "$f"
        set -l pid (cat "$f")
        kill -TERM $pid 2>/dev/null
        kill -CONT $pid 2>/dev/null
    end
    rm -f "$f" (__piperfetch_state)
end

function __piperfetch_pause --on-event fish_preexec
    set -l f (__piperfetch_file)
    test -r "$f"; or return
    set -l pid (cat "$f")
    kill -STOP $pid 2>/dev/null
end

function __piperfetch_prompt --on-event fish_prompt
    set -l f (__piperfetch_file)
    test -r "$f"; or return

    set -l state (__piperfetch_state)
    if not test -r "$state"
        __piperfetch_stop
        return
    end

    set -l lines (string split \n < "$state")
    set -l script $lines[2]
    set -l verdict (command python3 "$script" --prompt-check "$state" 2>/dev/null)

    if test "$verdict" = resume
        kill -CONT (cat "$f") 2>/dev/null
    else
        __piperfetch_stop
    end
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
