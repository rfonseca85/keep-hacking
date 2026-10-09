# Keep Hacking

Arcade hacking game built with **Godot 4.7** (GL Compatibility, 1280×720).

## Run

```bash
godot --path .                 # play (main scene: network select)
godot --path . --editor        # open editor
```

Press **`` ` ``** in a debug build to toggle **DevMode** (autoload).

## Project layout

```
scenes/           Game screens and UI prefabs
  ui/             Reusable Control scenes (HUD, tier cards, dev panel, …)
scripts/
  autoload/       GameState, Audio
  game/           Main gameplay screens (Main, NetworkSelect, SkillTree, ServerNode)
  dev/            DevMode overlay logic
  ui/             UI components (TierCard, SkillNodeCard, …)
  skills/         Skill purchase effects
  visual/         KHArt loader, VisualFX
assets/game/      Runtime art (icons, props, tiles, ui, fx, backgrounds)
addons/kh_holographic/  Optional holographic presentation layer
themes/           Project theme resource
docs/             Addon notes and asset coverage reference
```

## Scenes (edit in Godot)

| Scene | Purpose |
|-------|---------|
| `scenes/NetworkSelect.tscn` | Title / tier selection |
| `scenes/Main.tscn` | Grid gameplay |
| `scenes/SkillTree.tscn` | Meta upgrades |
| `scenes/ui/DevMode.tscn` | Debug tools (autoload) |

## CLI smoke tests (debug build)

```bash
godot --path . --headless --quit-after 2 res://scenes/Main.tscn -- autotest_audio
godot --path . --headless --quit-after 2 -- autotest_devmode
```

## Holographic addon

See [docs/holographic-addon.md](docs/holographic-addon.md). Hooks live in `scripts/game/Main.gd`, `NetworkSelect.gd`, and `SkillTree.gd` between `KH_HOLOGRAPHIC_BEGIN/END`.
