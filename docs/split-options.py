import json
import sys
from collections import defaultdict
from pathlib import Path

nixos_json_path = sys.argv[1]
hm_json_path = sys.argv[2]
out_dir = Path(sys.argv[3])

with open(nixos_json_path) as f:
    nixos_options = json.load(f)

with open(hm_json_path) as f:
    hm_options = json.load(f)

# Categories and their prefix patterns
categories = {
    "nixos": {
        "title": "NixOS Options",
        "description": "System-level options available under `omanix.*` in your NixOS configuration.",
        "options": {},
    },
    "apps": {
        "title": "Apps",
        "description": "Optional application modules. Enable with `omanix.apps.<name>.enable = true`.",
        "options": {},
    },
    "hyprland": {
        "title": "Hyprland",
        "description": "Window manager configuration: visuals, keybindings, gaps, borders, blur, and rules.",
        "options": {},
    },
    "idle": {
        "title": "Idle & Power",
        "description": "Screensaver, screen dimming, locking, DPMS, and suspend timeouts.",
        "options": {},
    },
    "monitors": {
        "title": "Monitors",
        "description": "Multi-monitor configuration: resolution, refresh rate, scale, and workspace assignment.",
        "options": {},
    },
    "languages": {
        "title": "Languages",
        "description": "Opt-in development toolchains with LSPs. Enable with `omanix.languages.<name>.enable = true`.",
        "options": {},
    },
    "terminal": {
        "title": "Terminal",
        "description": "Terminal emulator selection and configuration.",
        "options": {},
    },
    "browser": {
        "title": "Browser",
        "description": "Browser package and keybinding integration.",
        "options": {},
    },
    "theme": {
        "title": "Theme & UI",
        "description": "Theme selection, wallpaper, Waybar, Walker menu, and fonts.",
        "options": {},
    },
    "quickshell": {
        "title": "Quickshell",
        "description": "The Quickshell desktop shell. Enable with `omanix.quickshell.enable = true`.",
        "options": {},
    },
    "user": {
        "title": "User",
        "description": "User identity (git name/email).",
        "options": {},
    },
    "tailscale": {
        "title": "Tailscale",
        "description": "Taildrop file sharing over Tailscale. Tailscale itself is host-provided (`services.tailscale.enable`); see also `omanix.tailscale.operator` under NixOS Options.",
        "options": {},
    },
    "gaming": {
        "title": "Gaming",
        "description": "Optional gaming helpers: Battle.net (umu + GE-Proton) and RetroArch with a declarative core set. Steam is separate — see `omanix.steam.enable` under NixOS Options.",
        "options": {},
    },
}


def categorize_option(name):
    if name.startswith("omanix.apps."):
        return "apps"
    if name.startswith("omanix.hyprland."):
        return "hyprland"
    if name.startswith("omanix.idle."):
        return "idle"
    if name.startswith("omanix.monitors") or name.startswith("omanix.monitor."):
        return "monitors"
    if name.startswith("omanix.languages."):
        return "languages"
    if name.startswith("omanix.terminal."):
        return "terminal"
    if name.startswith("omanix.browser."):
        return "browser"
    if name.startswith("omanix.quickshell."):
        return "quickshell"
    if name.startswith("omanix.user."):
        return "user"
    if name.startswith("omanix.tailscale."):
        return "tailscale"
    if name.startswith("omanix.gaming."):
        return "gaming"
    if name.startswith("omanix.theme") or name.startswith("omanix.wallpaper") or name.startswith("omanix.font") or name.startswith("omanix.waybar.") or name.startswith("omanix.walker.") or name.startswith("omanix.menu."):
        return "theme"
    return None


def format_option(name, opt):
    lines = []
    lines.append(f"### `{name}`\n")

    desc = opt.get("description", "")
    if desc:
        lines.append(f"{desc}\n")

    typ = opt.get("type", "")
    if typ:
        lines.append(f"**Type:** `{typ}`\n")

    default = opt.get("default")
    if default is not None:
        if isinstance(default, dict) and "_type" in default:
            default_str = default.get("text", str(default))
        elif isinstance(default, str):
            default_str = f'`"{default}"`'
        elif isinstance(default, bool):
            default_str = f"`{'true' if default else 'false'}`"
        elif isinstance(default, (int, float)):
            default_str = f"`{default}`"
        elif isinstance(default, list):
            default_str = f"`{json.dumps(default)}`"
        else:
            default_str = f"`{json.dumps(default)}`"
        lines.append(f"**Default:** {default_str}\n")

    example = opt.get("example")
    if example is not None:
        if isinstance(example, dict) and "_type" in example:
            example_str = example.get("text", str(example))
            lines.append(f"**Example:**\n```nix\n{example_str}\n```\n")
        elif isinstance(example, str):
            lines.append(f"**Example:** `\"{example}\"`\n")
        else:
            lines.append(f"**Example:** `{json.dumps(example)}`\n")

    lines.append("")
    return "\n".join(lines)


# Process NixOS options
for name, opt in sorted(nixos_options.items()):
    if not opt.get("visible", True):
        continue
    categories["nixos"]["options"][name] = opt

# Process HM options into categories
for name, opt in sorted(hm_options.items()):
    if not opt.get("visible", True):
        continue
    cat = categorize_option(name)
    if cat:
        categories[cat]["options"][name] = opt

# Write markdown files
for cat_id, cat in categories.items():
    if not cat["options"]:
        continue
    filepath = out_dir / f"{cat_id}.md"
    with open(filepath, "w") as f:
        f.write(f"# {cat['title']}\n\n")
        f.write(f"{cat['description']}\n\n")
        for name in sorted(cat["options"].keys()):
            f.write(format_option(name, cat["options"][name]))

# Write SUMMARY.md for mdbook
summary_path = out_dir / "SUMMARY.md"
with open(summary_path, "w") as f:
    f.write("# Summary\n\n")
    f.write("- [Introduction](index.md)\n")
    f.write("- [Getting Started](getting-started.md)\n")
    f.write("- [Configuration Guide](configuration.md)\n")
    f.write("- [Options Reference]()\n")
    for cat_id, cat in categories.items():
        if not cat["options"]:
            continue
        f.write(f"  - [{cat['title']}]({cat_id}.md)\n")
