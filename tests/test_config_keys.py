#!/usr/bin/env python3
"""Regression checks that every config key reaches its code path."""

import importlib.machinery
import importlib.util
import random
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PATH = str(ROOT)
loader = importlib.machinery.SourceFileLoader("pf", PATH + "/piperfetch")
spec = importlib.util.spec_from_loader("pf", loader)
pf = importlib.util.module_from_spec(spec)
loader.exec_module(pf)

failures = []
checks = 0


def check(name, condition, detail=""):
    global checks
    checks += 1
    if not condition:
        failures.append(f"{name}: {detail}")


def cfg(**kwargs):
    c = pf.copy.deepcopy(pf.CONFIG_DEFAULTS)
    c.update(kwargs)
    return c


# --- layout ---------------------------------------------------------------
base = cfg(specs=False, autosize=False, width=54, height=22, max_width=0, max_height=0, align="left", shell_rows=8)
check("width", pf.compute_layout(cfg(**{**base, "width": 40}), 0, 0, 120, 40, 1200, 800)[0] == 40)
check("height", pf.compute_layout(cfg(**{**base, "height": 15}), 0, 0, 120, 40, 1200, 800)[1] == 15)
wide = pf.compute_layout(cfg(**{**base, "width": 100, "max_width": 600}), 0, 0, 120, 40, 1200, 800)
check("max_width", wide[0] == 60, wide)
tall = pf.compute_layout(cfg(**{**base, "height": 30, "max_height": 400}), 0, 0, 120, 40, 1200, 800)
check("max_height", tall[1] == 20, tall)

left = pf.compute_layout(cfg(**{**base, "width": 40}), 0, 0, 120, 40, 1200, 800)
center = pf.compute_layout(cfg(**{**base, "width": 40, "align": "center"}), 0, 0, 120, 40, 1200, 800)
right = pf.compute_layout(cfg(**{**base, "width": 40, "align": "right"}), 0, 0, 120, 40, 1200, 800)
check("align", left[2] == 1 and center[2] > left[2] and right[2] > center[2], (left, center, right))

shell = pf.compute_layout(cfg(**{**base, "autosize": True, "shell_rows": 8}), 0, 0, 120, 40, 1200, 800)
shell2 = pf.compute_layout(cfg(**{**base, "autosize": True, "shell_rows": 20}), 0, 0, 120, 40, 1200, 800)
check("shell_rows", shell[1] == 32 and shell2[1] == 20, (shell, shell2))

without = pf.compute_layout(cfg(specs=False, autosize=True), 0, 0, 120, 40, 1200, 800)
with_info = pf.compute_layout(cfg(specs=True, autosize=True), 30, 15, 120, 40, 1200, 800)
check("specs", without[0] == 120 and with_info[0] == 88 and with_info[1] == 15, (without, with_info))

auto = pf.compute_layout(cfg(specs=False, autosize=True), 0, 0, 120, 40, 1200, 800)
fixed = pf.compute_layout(cfg(specs=False, autosize=False, width=54, height=22), 0, 0, 120, 40, 1200, 800)
check("autosize", auto[0] == 120 and fixed[0] == 54, (auto, fixed))

# --- styles ---------------------------------------------------------------
style_keys = ("title_color", "separator_color", "key_color", "value_color", "border_color", "clock_color")
for key in style_keys:
    c = cfg(**{key: "#123456", "title_bold": False, "key_bold": False, "value_bold": False})
    pf.apply_style(c)
    code = pf.color_code(c[key], False)
    check("style " + key, "38;2;18;52;86" in code, code)

for key, glob in (("title_bold", "TITLE"), ("key_bold", "KEY"), ("value_bold", "VALUE")):
    c = cfg(**{key: True, "title_color": "green", "key_color": "cyan", "value_color": "white"})
    pf.apply_style(c)
    check("bold " + key, getattr(pf, glob).startswith("\x1b[1;"), getattr(pf, glob))
    c[key] = False
    pf.apply_style(c)
    check("nobold " + key, not getattr(pf, glob).startswith("\x1b[1;"), getattr(pf, glob))

# --- labels ---------------------------------------------------------------
labels = {key: f"X_{key}" for key in pf.LABEL_DEFAULTS}
info = "\n".join(pf.demo_info(labels))
for key in ("os", "kernel", "uptime", "packages", "shell", "display", "wm", "theme", "font", "terminal", "cpu", "gpu", "memory", "swap", "disk", "locale"):
    check("label " + key, f"X_{key}" in info)

# --- effects --------------------------------------------------------------
random.seed(1)
p0 = pf.PipesEffect(cfg(pipe_type=0, pipe_colors=(1, 2)), 40, 20)
p4 = pf.PipesEffect(cfg(pipe_type=4, pipe_colors=(1, 2)), 40, 20)
check("pipe_type", p0.glyphs != p4.glyphs)
pp = pf.PipesEffect(cfg(pipe_type=1, pipe_colors=(2,)), 40, 20)
draw = pp.step()[0]
check("pipe_colors", "3" in draw[3] and draw[3].endswith("2m"), draw)

random.seed(2)
m_low = pf.ColumnRainEffect(20, 10, pf.MATRIX_CHARS, "H", "T", 1, 0.0, 5)
m_high = pf.ColumnRainEffect(20, 10, pf.MATRIX_CHARS, "H", "T", 4, 1.0, 30)
check("matrix_speed", m_low.columns[0]["speed"] == 1 and m_high.columns[0]["speed"] == 4)
check("matrix_density", not any(c["active"] for c in m_low.columns) and all(c["active"] for c in m_high.columns))
check("matrix_trail", m_low.columns[0]["trail"] != 30 and m_high.columns[0]["trail"] > 20)
m_col = pf.ColumnRainEffect(20, 10, pf.MATRIX_CHARS, "\x1b[31m", "\x1b[32m", 1, 1.0, 5)
check("matrix_color", any(d[3] == "\x1b[31m" for d in m_col.step() if d[2] != " "))
rain = pf.ColumnRainEffect(20, 10, pf.RAIN_CHARS, "\x1b[1;91m", "\x1b[31m", 3, 1.0, 20)
check("rain_speed", rain.columns[0]["speed"] == 3)
check("rain_density", all(c["active"] for c in rain.columns))
check("rain_trail", rain.columns[0]["trail"] > 15)
rain_draws = []
for _ in range(3):
    rain_draws.extend(rain.step())
check("rain_color", any(d[3] == "\x1b[1;91m" for d in rain_draws if d[2] != " "))

random.seed(3)
s0 = pf.StarsEffect(40, 20, 0, 2, "multi")
s1 = pf.StarsEffect(40, 20, 50, 4, "green")
check("stars_density", len(s0.stars) == 0 and len(s1.stars) == 400)
check("stars_speed", s1.speed == 4)
check("stars_color", len(s1.palette) == 2 and len(pf.StarsEffect(40, 20, 5, 2, "multi").palette) == 4)

f0 = pf.FireEffect(20, 10, 0, 1)
f1 = pf.FireEffect(20, 10, 100, 4)
f0.step(); f1.step()
check("fire_intensity", max(max(r) for r in f1.heat) > max(max(r) for r in f0.heat))
check("fire_speed", f1.speed == 4)

random.seed(4)
b0 = pf.BubblesEffect(40, 20, 0, 6, "cyan")
b1 = pf.BubblesEffect(40, 20, 50, 12, "red")
check("bubble_density", len(b0.bubbles) == 0 and len(b1.bubbles) == 400)
check("bubble_speed", b1.speed == 12)
bubble_draws = []
for _ in range(12):
    bubble_draws.extend(b1.step())
check("bubble_color", any("\x1b[31m" in d[3] or "\x1b[91m" in d[3] for d in bubble_draws))

random.seed(5)
o2 = pf.OrbsEffect(cfg(orb_count=2, orb_speed=1, orb_min_size=2, orb_max_size=8, orb_color="purple"), 60, 30)
o4 = pf.OrbsEffect(cfg(orb_count=4, orb_speed=4, orb_min_size=4, orb_max_size=9, orb_color="multi"), 60, 30)
check("orb_count", len(o2.orbs) == 2 and len(o4.orbs) == 4)
check("orb_speed", o2.speed == 1 and o4.speed == 4)
check("orb_size", (o2.min_size, o2.max_size) != (o4.min_size, o4.max_size), (o2.min_size, o2.max_size, o4.min_size, o4.max_size))
o_min = pf.OrbsEffect(cfg(orb_min_size=2, orb_max_size=20, orb_color="purple"), 60, 30)
check("orb_min_size", o_min.min_size == 2.0, o_min.min_size)
check("orb_max_size", 2.0 < o_min.max_size <= 20.0, o_min.max_size)
check("orb_color", o4.orbs[0]["head"] in {p[0] for p in pf.COLOR_SCHEMES.values()})

pl1 = pf.PlasmaEffect(20, 10, 1, 1.0)
pl2 = pf.PlasmaEffect(20, 10, 4, 3.0)
check("plasma_speed", pl1.speed == 1 and pl2.speed == 4)
check("plasma_scale", pl1.scale == 1.0 and pl2.scale == 3.0)
check("plasma_step", pl1.step() != pl2.step())

for name in pf.EFFECTS:
    c = cfg(effect=name)
    effect = pf.make_effect(c, 20, 10)
    check("effect " + name, (effect is None) if name == "none" else effect is not None)

# --- clock ----------------------------------------------------------------
check("clock_off", pf.clock_position(cfg(clock=False), 40, 20) is None)
for size, rows in ((1, 1), (2, 3), (3, 5)):
    pos = pf.clock_position(cfg(clock=True, clock_size=size, clock_format="%H:%M:%S"), 60, 30)
    check(f"clock_size {size}", pos is not None and pos[3] == rows, pos)
clock_short = pf.clock_position(cfg(clock=True, clock_size=1, clock_format="%H"), 60, 30)
clock_long = pf.clock_position(cfg(clock=True, clock_size=1, clock_format="%H:%M:%S"), 60, 30)
check("clock_format", clock_short[5] != clock_long[5], (clock_short, clock_long))

# --- static sanity --------------------------------------------------------
source = (Path(PATH) / "piperfetch").read_text()
check("fps used", 'frame_time = 1.0 / max(1, cfg["fps"])' in source)
check("labels wired", all(re.search(rf'labels\[\s*["\']{re.escape(k)}["\']\s*\]', source) for k in pf.LABEL_DEFAULTS))

print(f"{checks} checks, {len(failures)} failures")
for failure in failures:
    print("FAIL", failure)
sys.exit(1 if failures else 0)
