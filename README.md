# piperfetch

A small, self-contained fastfetch-style terminal dashboard with a live
`pipes.sh`-inspired animation.

![piperfetch demo](demo.gif)

The dashboard sits at the top until you run a command. That means:

- the prompt is available immediately;
- typing works normally;
- the pipes keep animating while you are at the prompt;
- when a command starts, the animation stops so its output can scroll the
  dashboard up naturally; a long output pushes it out of sight;
- `clear` / Ctrl-L removes the dashboard and returns to a normal shell.

## Requirements

- **Python 3.11+** (uses the standard-library `tomllib`; no pip packages)
- a Linux/Unix terminal that supports `ESC 7` / `ESC 8` cursor save/restore;
  Kitty is recommended
- **fish** for the included shell integration (the animation stop/clear hooks)
- optional: `niri`, `lscpu`, `lspci`, `ip`, `gsettings`, `kitty`, `fish` for
  the corresponding information lines. Missing commands simply hide their
  module.

There are **no third-party Python dependencies** and no build step.

## Installation

```bash
git clone https://github.com/Mr-Sniff/piperfetch.git
cd piperfetch

# optional config
mkdir -p ~/.config/piperfetch
cp config.example.toml ~/.config/piperfetch/config.toml

# fish hooks (stops the animation when a command starts)
mkdir -p ~/.config/fish/conf.d
cp fish/piperfetch.fish ~/.config/fish/conf.d/piperfetch.fish
```

Add the Ctrl-L binding to your `fish_user_key_bindings` function:

```fish
bind \cl __piperfetch_clear_screen
```

If your fish greeting runs another fetch, disable it:

```fish
function fish_greeting
end
```

Then set Kitty to use piperfetch as its shell program:

```conf
shell /absolute/path/to/piperfetch
```

Restart Kitty or open a new window.

## Run it

```bash
./piperfetch          # dashboard + exec your $SHELL
./piperfetch --demo   # sanitized demo layout for screenshots
./piperfetch --info   # print the information block only
./piperfetch --version
```

## Configuration

`~/.config/piperfetch/config.toml`:

```toml
# Show the system information block on the right.
specs = false

# Let the pipe box grow with the terminal.
# When false, width/height are used (in character cells).
autosize = true
width = 54
height = 22

# Maximum pipe-box size in pixels (0 = no limit).
max_width = 700
max_height = 700

# Horizontal placement when the box is narrower than the terminal:
# "left", "center" or "right".
align = "center"

# Bold clock in the middle of the box; pipes are drawn behind it.
clock = true
# 1 = normal text, 2 = 3-row clock, 3 = 5-row large clock.
clock_size = 3
clock_format = "%H:%M:%S"

# Pipe animation speed in frames per second (1-240).
# Lower is slower; pipes.sh's default is 75, piperfetch's default is 38.
fps = 38

# Rows kept free below the box when specs are off and autosize is on.
shell_rows = 8
```

With `specs = false` and `autosize = true`, the pipe box uses the full terminal
width and `terminal_rows - shell_rows` rows. With `specs = true`, autosize uses
the information block's width and height instead. With `autosize = false`, the
box uses exactly `width` x `height`.

`clock_size = 1` is the one-line text clock, `2` is a 3-row clock, and `3` is a
5-row clock. `fps` controls the pipe speed (default 38; lower is slower). Big
clock sizes work with numeric formats such as `%H:%M:%S`; other formats fall
back to the one-line clock.

The box, clock and information block are redrawn when the terminal is resized.
Resizing clears the visible shell area so reflowed dashboard lines cannot leave
artifacts behind.

## Make it the Kitty default

`~/.config/kitty/kitty.conf`:

```conf
shell /home/teo/AAegna_grejer/programmering/piperfetch/piperfetch
```

Kitty then starts `piperfetch` as the shell program. `piperfetch` draws the
dashboard, starts the animation, and `exec`s fish.

The fish side needs the integration in `~/.config/fish/config.fish`:

- `fish_greeting` must be empty, since piperfetch already draws the header.
- `fish_preexec` stops the animation when a command starts, so the output can
  scroll the dashboard away.
- `fish_exit` stops the animation.
- a `clear` wrapper (and a Ctrl-L binding) kills the animation and clears the
  screen, so the dashboard disappears like a normal fetch logo.

The hooks are included in `fish/piperfetch.fish`; see Installation above.

## Layout

- with `specs = true`, the information block is measured first, the pipes box
  gets the same number of rows, and its width is
  `terminal_columns - information_width - 2`;
- with `specs = false`, the box uses the full width and `terminal_rows -
  shell_rows` rows;
- with `autosize = false`, `width` and `height` from the config are used;
- `max_width` and `max_height` cap the box in pixels, and `align` places the
  dashboard left, center or right when it is narrower than the terminal;
- the box has a white type-1 pipe border and the animation uses only colors
  1–7 (no black);
- the clock is centered in the box, bold, and pipe cells underneath it are
  skipped so the time stays readable.

## Files

- `piperfetch` — the whole program (stdlib only)
- `config.example.toml` — configuration example
- `fish/piperfetch.fish` — fish hooks
- `demo.gif` — animated demo
- `README.md` — this file

Runtime state (the animation PID) is kept in
`$XDG_RUNTIME_DIR/piperfetch-<fish-pid>.pid` and is cleaned up automatically.

## Uninstall

Remove the `shell` line from `kitty.conf`, restore a `fish_greeting` if desired,
and delete this directory.
