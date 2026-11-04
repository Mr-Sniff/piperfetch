# Changelog

## 1.1.0 — 2026-11-04

- Added the `orbs` effect: 2–4 evenly spaced, slowly breathing lava-lamp
  blobs with selectable colour.
- Reworked `stars` into a calm, mostly static night sky with sparse
  twinkling instead of fast movement.
- Made bubbles much slower and documented `bubble_speed` as a frame divisor.
- Tuned defaults for every effect to calmer, more usable speeds.
- Documented how `fps` and per-effect speed settings combine.
- Added a preview GIF for every effect under `demos/`, plus clock-size
  showcases.

## 1.0.0 — 2026-11-04

- First stable release.
- Live dashboard with system information, a configurable clock, and a
  white pipe border.
- Effects: `pipes`, `matrix`, `rain`, `stars`, `fire`, `bubbles`, `plasma`,
  and `none`.
- Per-effect density, speed, trail, colour, and intensity settings.
- Configurable FPS, layout size, pixel caps, horizontal alignment, and
  optional system-information block.
- Resize-aware dashboard and clock.
- Output scrolls the dashboard away naturally when commands run.
- Fish, zsh, and bash integration files.
- Terminal detection for Kitty, Alacritty, foot, WezTerm, Konsole,
  GNOME Terminal, xterm, tmux, and screen.
- Display and window-manager detection for niri, Hyprland, Sway/i3, KDE
  Plasma, GNOME Shell, Xfce, `wlr-randr`, and `xrandr`.
- `--demo`, `--info`, `--list-effects`, `--check-config`, and `--config`
  command-line options.
- MIT license.
