# AGENTS.md — Deepglow

Guide for AI agents (Claude, Codex, Cursor, etc.) and humans working on this repository.
Read it fully before changing anything.

## 0. Language rules (mandatory)

| What | Language |
|---|---|
| **Everything technical**: code, identifiers, comments, doc comments (`##`), commit messages, file and directory names, asset names, node names, translation keys, log/error messages, tool output | **English** |
| **Documentation files** (`docs/`, READMEs, this AGENTS.md) | **Portuguese (pt-BR) or English** — Portuguese is welcome; file names stay in English. Identifiers, keys and paths quoted inside docs keep their original English form |
| **Player-facing text** (UI, piece names, descriptions, dialogs) | **Localized** — English (`en`) and Brazilian Portuguese (`pt_BR`) from day one |
| Conversation with the project owner | Portuguese |

Never hardcode player-facing strings in scripts or scenes: use translation keys (section 4).

## 1. The project

- **Game:** Deepglow — a pixel art **incremental game** on an 8x8 board, night-time bioluminescent
  setting. Timed phases: resource sources (trees, fruit, water, later rocks, fish, game, crystals)
  appear on the board, the player clicks to harvest them, then spends resources on an upgrade tree.
  Visual reference: `00_references/concept-art.png` in the art directory.
- **Engine:** Godot **4.7.x**, GDScript, **GL Compatibility** renderer.
- **Game design:** `docs/game-design.md` (source of truth for rules, balance targets and roadmap).
  Done: **M1** prototype loop (wood/fruit/water, phase generator, contextual cursor, hunger/thirst,
  upgrade list, programmer art), **M2** balance simulator, **M2.5** drawn upgrade tree, **M3**
  tiers 1–2 (stone, fish, meat) and **M3.5** tiers 3–4 (ores, crystals, final node; full game
  ≈ 2h10 for the simulated average player since the D10 rebalance), **M4** final art + pixel-art UI, **M5** save/load + title menu and **M6** juice (synthesized
  audio, particles, dusk-to-night cycle). **M7** publishing: technical part done (exports,
  controller play, optional Steam layer, achievements). Store publishing (Steam/Apple), macOS
  signing, store art and Steam Deck testing are deferred future improvements (`docs/publishing.md` §6).

### Directories

| Path | Role |
|---|---|
| `/Users/thiago/Projects/godot/deepglow-ai` | **This repository** (Godot project). Only what the game ships goes here. |
| `/Users/thiago/Documents/gamedev/deepglow/pixelart` | **Art support directory**: references, source files (.aseprite), raw Pixellab outputs, progress screenshots and videos. Never imported by Godot. |

Art support directory layout:

```
pixelart/
  00_references/        concept art, moodboards, reference captures
  01_palette/           deepglow.gpl + swatch PNGs (for Aseprite / Pixellab)
  02_source/            editable sources (.aseprite): pieces/, board/, ui/, fonts/
  03_pixellab/          raw Pixellab outputs: YYYY-MM-DD/<slug>/ + request.json
  04_drafts/            experiments and throwaway variations
  05_progress/          screenshots/ and videos/  (YYYY-MM-DD_description.ext)
```

## 2. Pixel art specification (mandatory)

- **Base resolution:** 640x360. The game renders into a fixed 640x360 `SubViewport` inside
  `App` (`src/main/app.tscn`, the main scene), which shows it integer-scaled and centred (3x at
  1080p) with black letterbox. Project stretch mode is `disabled` on purpose: the optional CRT
  shader (`src/main/crt.gdshader`) runs at the window resolution on top of the scaled image.
  (Changed from 320x180 in M4: 16 px sprites could not hold
  the concept art's level of detail.)
- **Filtering:** Nearest (project default). 2D transform and vertex snapping enabled.
  Never place nodes at fractional coordinates on purpose; use `.floor()`.
  Default font antialiasing is off.
- **Grid:** **40x40 px** cells; **32x32 px** piece sprites centered in the cell.
  The board is 320x320 px, centered (origin at (160, 20)).
- **UI scale:** layout values, line widths and fonts are 2x the old 320x180 values (default font
  16 px, titles 32 px, 2 px frame lines). Keep new UI on even numbers.
- **Palette:** 24 colors in `assets/palettes/deepglow.gpl` (mirrored in `src/core/palette.gd`
  as `Palette.*`). **Every final asset must use only these colors**, no semi-transparency.
  Check with `python3 tools/art/palette.py check <png>`; fix with `... apply <png>`.
- **Style:** readable objects over a dark night board (reference: `concept-art.png` in the
  Claude project; palette inspired by Animal Well). Objects are *not* neon: the palette has no
  neutral grey/brown/red, so materials are translated into fixed **material ramps** (shadow →
  light), always lit from the **top-left**:

  | Material | Ramp (`Palette.*`) |
  |---|---|
  | Stone | STRUCTURE_DEEP_BLUE → STRUCTURE_INDIGO → STRUCTURE_MID_BLUE → STRUCTURE_HIGHLIGHT |
  | Wood | CHARACTER_OUTLINE → STRUCTURE_VIOLET → CHARACTER_MIDTONE |
  | Leaves | VEGETATION_SHADOW → VEGETATION_MOSS → VEGETATION_GLOW_GREEN |
  | Water | WATER_ABYSS → WATER_MIDTONE → WATER_ELECTRIC_BLUE → WATER_CYAN |
  | Accents (fruit, metal, glow) | LIGHT_PINK, LIGHT_AMBER, LIGHT_SULFUR_YELLOW, VEGETATION_NEON_TEAL |

  Outline: CHARACTER_OUTLINE / SHADOW_*. (Style is being validated in M4; see docs/game-design.md.)

## 3. Godot architecture

### Folder structure

```
src/                  # code + scenes, organized by FEATURE (.tscn next to its .gd)
  autoload/           # singletons: Settings (prefs), Events (signal bus), Sound (audio), Platform (Steam, optional)
  core/               # generic utilities (StateMachine, Palette, GameDatabase)
  main/               # entry scene and screen flow
  game/               # run orchestration (Game) + states/ (rules per state)
  board/              # Board (view/input, generic items), BoardModel (pure state), BoardConfig
  economy/            # ResourceType, ResourceAmount (data) + Inventory (state)
  sources/            # Rarity, ToolType, SourceType (data) + SourceCard (scene)
  progression/        # UpgradeNode, Achievement (data) + ProgressionState (state, derived stats)
  biomes/             # Biome (data: background, ambience, ambient particles, color, gate points, first tree row)
  survival/           # Needs (hunger/thirst state; empty hunger = weak hits, empty thirst = half materials)
  save/               # SaveGame (run snapshot <-> JSON dict) + SaveSystem (user://save.json I/O)
  phases/             # PhaseRules (data) + PhaseGenerator/PhasePlan (pure logic)
  fx/                 # visual effects (FloatingText, PixelBurst, AmbientParticles + AmbientEffect, NightCycle + night_shift shader,
                      # PaletteShift = palette "darker" table shared with the intro)
  intro/              # Intro screen + IntroShot/IntroSequence (data: motion, background(s), text key, duration)
  ui/                 # one subfolder per screen/component (hud, phase_summary,
                      # upgrade_tree, tool_cursor, language_select, title_menu) + theme/
localization/         # translations.csv (source of all player-facing text)
data/                 # .tres instances: game_database.tres (root), resources/, rarities/,
                      # tools/, sources/, upgrades/, achievements/, phases/, board/, audio/, biomes/, intro/
assets/               # FINAL game-ready art/audio (sprites/, tilesets/, fonts/, audio/, palettes/)
tests/                # headless tests (test_*.gd)
tools/                # outside the game: pixellab/, art/ + audio/ (Python), balance/ (GDScript simulator),
                      # build/ (export_all.sh)
addons/               # third-party plugins (do not edit)
docs/                 # design and pipeline docs
```

### Current scene flow

```
App (Control)                        src/main/app.tscn — window root: integer scaling + CRT shader
└── Screen (SubViewportContainer) %  — material = crt.gdshader (Settings.crt_enabled, F2)
    └── GameViewport (SubViewport 640x360)
        └── Main (Node)              src/main/main.tscn — swaps screens (one at a time)
            ├── LanguageSelect (Control)         src/ui/language_select/  — first launch only
            ├── TitleMenu (Control)              src/ui/title_menu/ — Continue, New game, Watch intro, Settings, Quit
            ├── Intro (Control)                  src/intro/ — animated intro (IntroSequence data, data/intro/intro.tres):
            │                                     plays before a new game and from "Watch intro"; tap advances,
            │                                     hold (0.6 s) skips; every picture change is a pixel dissolve
            │                                     (src/fx/pixel_dissolve.gdshader, ordered dither, no alpha)
            ├── SettingsScreen (Control)         src/ui/settings/ — SettingRow per setting (language, CRT,
            │                                     fullscreen; volume later), applied + saved immediately
            │
            └── Game (Node2D)                    src/game/game.tscn — run state: inventory, progression, needs
                ├── Background (Sprite2D) %      — current biome's background (Game.apply_biome());
                │                                  night_shift.gdshader (darkened by NightCycle)
                ├── AmbientParticles (Node2D) %  — the biome's ambient particles (Biome.ambient_effects: fireflies,
                │                                  spores, glints/drips, embers/ash, snow, bubbles/plankton)
                ├── Board (Node2D) %             src/board/board.tscn
                │   ├── GridView (Node2D) %      — frame + cells drawn with PixelStyleBox (_draw)
                │   └── Items (Node2D, y_sort) % — SourceCard instances (no hovered-cell highlight)
                ├── Effects (Node2D) %           — FloatingText popups
                ├── PhaseTimer (Timer) %
                ├── StateMachine (Node) %
                │   ├── Setup          → PhaseBuild (new run) / Upgrade (loaded run)
                │   ├── PhaseBuild     — PhaseGenerator fills the board → Phase
                │   ├── Phase          — timer, clicks, needs, collection → PhaseSummary
                │   ├── PhaseSummary   — results overlay → Upgrade
                │   └── Upgrade        — autosave + drawn upgrade tree (GDD §7.1) → PhaseBuild / Menu → title
                ├── Hud (CanvasLayer) %          src/ui/hud/ — ClockTimer (round clock) + seconds, needs bars, inventory,
                │                                  "New biome" banner
                ├── Overlays (CanvasLayer 10)
                │   ├── PhaseSummary (Control) %
                │   ├── UpgradeTreeScreen (Control) % — UpgradeTreeView (biome bands, lines)
                │   │                                     + UpgradeNodeView per node + details popup
                │   │                                     + SaveIndicator badge (src/ui/save_indicator/)
                │   └── PauseMenu (Control) %    src/ui/pause_menu/ — pauses the tree (timer, needs, board stop);
                │                                  Resume / Main menu (phase progress is lost, confirmed)
                ├── ToolCursor (CanvasLayer 100) % — software cursor showing the contextual tool
                ├── GameAudio (Node) %           — music/SFX from Events (phase track + rush layer, hits, ticks)
                ├── GameFx (Node)                — PixelBurst chips on hits, sparkles on collect
                ├── GameRumble (Node)            — gamepad vibration on hits/collects (only when playing with a pad)
                └── NightCycle (Node)            — dusk -> deep night in palette steps during a phase
```

**Biomes:** six `Biome` resources (`GameDatabase.biomes`, in order) split the upgrade tree into
stages: a biome's `required_points` gates every node from its `tree_row` down
(`ProgressionState.get_required_points()`), the tree draws one column per biome (header text in `Biome.color`), and the
current biome (`ProgressionState.get_biome()`, from levels bought — not saved; a biome also needs
a level bought in the previous biome's rows, so points alone never skip one) sets the phase
background, its ambient particles (`AmbientEffect` layers in `data/ambient/`, drawn by
`AmbientParticles`) and its ambience loop (`Sound.play_ambience` crossfades; menus use the night
loop); `PhaseBuild` shows a banner on the first phase of a new biome. Each biome's content
matches its theme (GDD §7.2): keep new tools/sources in the biome they belong to.

Data flow: `GameDatabase` (all data) → `ProgressionState` computes derived stats (effective clicks,
yields, phase duration, drains, rarity weights) from upgrade levels → `PhaseGenerator` builds a
`PhasePlan` from progression + seed → states apply it. Game relays `Inventory.changed` and
`Needs.changed` to `Events` for the HUD.

**Save (M5):** one slot, `user://save.json` (versioned JSON, written to a `.tmp` file and renamed).
Saved only **between phases**: when the `Upgrade` state starts and after every purchase
(`ProgressionState.upgrade_purchased`). Contents: run seed, completed phases, inventory amounts +
discovered, upgrade levels, `phases_played`, `measured_cps` — nothing from inside a phase, so a
loaded run resumes at the upgrade screen (quitting mid-phase loses only that phase). `Main` reads
the save for the title menu and passes it to `Game.resume_from()` before the Game enters the tree.
`SaveGame.apply_to()` drops ids missing from the database and clamps levels to `max_level`, so data
changes do not break old saves; bump `SaveGame.VERSION` (and migrate in `from_dict`) when the format
changes. Player settings stay in `user://settings.cfg` (Settings autoload), separate from the run.
Every save shows the `SaveIndicator` badge ("Saving" for 1.2 s, then "Game saved" for 1.8 s —
saving is instant, the hold times only make it noticeable).
`user://` is a custom user dir named `Deepglow` (`application/config/use_custom_user_dir`): macOS
`~/Library/Application Support/Deepglow/`, Windows `%APPDATA%\Deepglow\`, Linux `~/.local/share/Deepglow/`.

### Principles

1. **Separate data, state and view.**
   - *Data* → `Resource` with `class_name` (`SourceType`, `UpgradeNode`, `PhaseRules`…), instances
     in `data/` and registered in `data/game_database.tres`. New source/upgrade = new `.tres` +
     translation keys + database entry, no new code. Balance numbers never live in code.
   - *State/logic* → pure `RefCounted` classes (`BoardModel`, `Inventory`, `ProgressionState`,
     `Needs`, `PhaseGenerator`), testable headless and reusable by the balance simulator.
   - *View* → nodes/scenes that reflect the state (`Board`, `SourceCard`, HUD).
2. **One scene = one responsibility**, with a same-named script next to it
   (`board.tscn` + `board.gd`). Compose scenes by instancing; avoid giant scenes.
3. **Communication:** "call down, signal up".
   - Parent → child: method call.
   - Child → parent: the node's own signal.
   - Unrelated systems (e.g. Board → HUD): the `Events` autoload.
     `Events` only declares signals — **it never stores state**.
4. **Game rules live in states** (`src/game/states/*`, extending `GameState`).
   Each phase/turn is a child node of `StateMachine`; transition with `request_transition(&"Name")`.
   Connect signals in `enter()` and disconnect them in `exit()`.
5. **Screen flow lives in `Main`**: screens are `PackedScene` exports that emit a signal when done;
   `Main` swaps them. Screens never load other screens directly.
6. **Node references:** use *Unique Names* (`%Name`) with typed `@onready`.
   No `get_node("../../X")`. External dependencies via `@export`.
7. **Prefer built-in nodes before writing code:**
   `TileMapLayer` (board/scenery), `AnimationPlayer` (property animations),
   `AnimatedSprite2D` + `SpriteFrames` (Pixellab spritesheets), `Tween` (short code-driven motion),
   `CanvasLayer` + `Control`/containers + `Theme` (UI), `CPUParticles2D`/`GPUParticles2D`
   (fireflies, glow), `PointLight2D` + `CanvasModulate` (bioluminescent lighting),
   `AudioStreamPlayer` (audio), `Timer`, `Marker2D`. `Autoload` only when truly global.
8. **No magic layout numbers in scenes/code**: they come from `BoardConfig`/exports.
9. **Effects stay pixel art:** particles, ambient particles and the night cycle use whole pixels and
   palette colors only — they change color in palette steps (or ordered dither) instead of fading
   with alpha. No `PointLight2D`/`CanvasModulate` gradients.
10. **Boxes are pixel art:** every rectangle (panels, buttons, board cells, tree nodes, bars) uses
   `PixelStyleBox` (`src/ui/pixel_style_box.gd`): flat fill, 2 px border, stepped corners, whole
   pixels only. Theme styles are `PixelStyleBox` resources; custom `_draw` code calls
   `PixelStyleBox.create(...).draw(get_canvas_item(), rect)`. Never use antialiased shapes or
   diagonal `draw_line` (upgrade tree links are 1 px octilinear paths stamped pixel by pixel; tree node frames use 1 px borders).
11. **UI styling comes from the project theme** (`src/ui/theme/main_theme.tres`, set as
   `gui/theme/custom`). Use `theme_type_variation` (`TitleLabel`, `MutedLabel`, …) instead of
   per-node overrides; add new variations to the theme.

### GDScript conventions

- Follow the [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html):
  `snake_case` files/folders, `PascalCase` `class_name`, past-tense signals
  (`piece_placed`), `_` prefix for private members, `UPPER_SNAKE` constants.
- **Static typing everywhere** (variables, parameters, returns, `for x: T in` loops,
  typed arrays/dictionaries). The project warns on untyped declarations and unsafe
  access — treat warnings as errors.
- File order: `@tool`, `class_name`, `extends`, `##` doc, signals, enums, constants,
  `@export`, public vars, private vars, `@onready`, virtual methods (`_ready`…),
  public methods, private methods, `_on_*` callbacks.
- Use `StringName` (`&"select"`) for input actions, states and ids.
- Document classes and public methods with `##` (shown in the editor).
- Scripts used in the editor (`_draw` previews, Resources they read) need `@tool`.
- Tabs for indentation (see `.editorconfig`).
- Numbers shown to the player go through `NumberFormat.compact()` (1234 → "1.2k").
- **Avoid script self-references in Resources** (e.g. `Array[UpgradeNode]` inside
  `upgrade_node.gd`): they create a reference cycle that leaks at exit. Type such fields as
  `Array[Resource]` and document the expected type.
- Don't name methods after `Object` virtuals (`_set`, `_get`, `_notification`…).
- Don't name inner enums/classes after global `class_name`s (e.g. an enum `State` clashes with the
  `State` class of the state machine) — prefix them (`NodeState`).

### Input

Actions defined in `project.godot`: `select` (left mouse / space / gamepad A),
`cancel` (right mouse / Esc / gamepad B), `board_left|right|up|down` (arrows / WASD / d-pad /
left stick: move the hovered cell, only while `Board.navigation_enabled`, i.e. during a phase;
the software cursor jumps to that cell; `Board` polls them in `_process` — one step per press, then a timed repeat (`repeat_delay`/`repeat_interval`), and the stick uses press/release thresholds — because a tilted stick sends a stream of motion events), `pause` (Esc / P / gamepad Start: pause menu during a
phase), `toggle_crt` (F2, CRT filter on/off), `toggle_fullscreen` (F11);
both are also on the Settings screen. New player options = a `SettingRow` on the Settings
screen + a value/setter/signal in the `Settings` autoload. Menus use Godot's built-in `ui_*` actions (keyboard/gamepad
focus navigation must always work); `ui_accept`/`ui_cancel` are overridden in `project.godot` to add
gamepad A (PS Cross) / B (PS Circle) — Godot's defaults have no gamepad button to press a UI button.
Test gamepad flows with real `InputEventJoypadButton` events, not `InputEventAction`.
Upgrade tree with keys/gamepad: moving the focus only highlights a node; confirm opens its details
popup and moves the focus to Buy (confirm again buys); cancel (Esc / B / right click) closes the
popup and returns to the node; with the mouse, clicking a node only opens the popup. Always use actions, never raw keys.
Pausing uses `get_tree().paused`: `App` is `PROCESS_MODE_ALWAYS` (so input still reaches the
SubViewport) and `Main` is set back to `PAUSABLE`; `PauseMenu` and `ToolCursor` are `ALWAYS`.
Gameplay input goes in `_unhandled_input` (UI consumes first). HUD Controls that must not
block the board use `mouse_filter = IGNORE`.

## 4. Localization (en + pt_BR)

- **Source of truth:** `localization/translations.csv` (columns `keys,en,pt_BR`). Godot imports
  it into `translations.<locale>.translation` files (generated, git-ignored) registered in
  Project Settings → Localization. Fallback locale: `en`.
- **Keys:** `UPPER_SNAKE_CASE`, prefixed by area: `GAME_`, `UI_`, `HUD_`, `PIECE_<ID>_NAME`,
  `PIECE_<ID>_DESC`, … Every key must have **all** locales filled (enforced by
  `tests/test_localization.gd`).
- **Usage:**
  - Static text in scenes: set the key as the Control's `text` (auto-translated, updates live on
    locale change).
  - Dynamic text in code: `tr(&"HUD_TURN") % value`; in Resources use
    `TranslationServer.translate(key)`.
  - Data items derive keys from their `id`: `RESOURCE_<ID>_NAME`, `SOURCE_<ID>_NAME`,
    `UPGRADE_<ID>_NAME` / `_DESC`, `TOOL_<ID>_NAME`, `RARITY_<ID>_NAME` (checked by
    `tests/test_localization.gd` against `data/game_database.tres`).
  - Language names are always written in their own language and never translated.
- **Active locale:** owned by the `Settings` autoload (`Settings.set_locale()`), persisted to
  `user://settings.cfg`. On first launch it defaults to the OS locale when supported.
  The **LanguageSelect** screen (first launch only) lets the player choose; focusing an option
  previews the screen in that language. Later changes: the Language row of the Settings screen.
- **Adding a language:** add a CSV column, register the new `.translation` in Project
  Settings → Localization, add the entry to `Settings.SUPPORTED_LOCALES`.
- Keep strings short: the UI is 640x360 with a 16 px font. Check that Portuguese (usually
  longer) fits.

## 5. Art pipeline with Pixellab

Two ways to use [Pixellab](https://www.pixellab.ai) (same token for both; keep it in `.env`,
never in git):

1. **MCP** (`https://api.pixellab.ai/mcp`) — configured in `.mcp.json`
   (Pixellab + [godot-mcp](https://github.com/Coding-Solo/godot-mcp)), read by Claude Code.
   It only references `${PIXELLAB_API_KEY}` / `${GODOT_PATH}` env vars — never put a literal
   token in it.
   Main tools: `create_image_pixflux`, `create_image_pixen` (accepts < 32 px),
   `create_1_direction_object`, `create_topdown_tileset`, `create_character`/`animate_character`,
   `animate_image`, `reduce_colors` (force palette), `correct_pixelart`, `create_ui_asset`,
   `create_font`. Generation is async: create → poll with `get_*` → download.
2. **REST CLI** (`tools/pixellab/pixellab.py`, stdlib only) — for batches and reproducibility:
   ```bash
   python3 tools/pixellab/pixellab.py balance
   python3 tools/pixellab/pixellab.py image "glowing violet crystal, board game icon, dark outline" --size 32 --name gem_violet
   python3 tools/pixellab/pixellab.py call create-tileset --body @req.json --name board_tiles
   ```
   Outputs go to `$DEEPGLOW_ART_DIR/03_pixellab/YYYY-MM-DD/<slug>/` with `request.json`
   (prompt + parameters) and `response.json`.

**Credits are limited:** only generate what the task needs, start with the cheapest
tool/size, and never batch-generate without the owner's approval.

### Placeholder art

Until M4, sprites are **programmer art** generated by `tools/art/placeholder_sprites.py`
(ASCII maps → palette-only PNGs in `assets/sprites/{sources,cursors,icons}/`). Edit the maps and
re-run the script; final art replaces the PNGs with the same file names and must be added to
`FINAL` in the script so it is never overwritten.

Sizes: sources 32x32, cursors 24x24 (hotspot in `ToolType.cursor_hotspot`), HUD icons 16x16,
upgrade tree icons 20x20 (maps are drawn at half size and upscaled 2x by the script;
final art is authored at full size) (`assets/sprites/upgrades/<upgrade_id>.png`, set in `UpgradeNode.icon`).

### Upgrade tree layout

The tree is horizontal: each `UpgradeNode` sets `grid_position` (x = lane 0–5, top to bottom;
y = depth, drawn as a column left to right). Lines go from every prerequisite to the node (0°/45°/90°
segments), so place children at a greater depth than their parents. `choice_group` renders an
octagon (mutually exclusive nodes). Each biome is a band of columns (from its `tree_row`) with a
text header (name + "Unlocks at N points", `Biome.color`) and a dotted separator; links whose
parent is owned take the child's biome color, and a link's diagonal moves to either end of the gap
when the middle route would pass behind another node. Cell spacing is `UpgradeTreeView.CELL`; the
screen scrolls horizontally and shows the details as a popup (opened only by click/confirm). Tool unlocks use
`Effect.UNLOCK_TOOL` + a `ToolType` with `unlocked_by_default = false`; the generator only places
sources whose tool is unlocked.

### Asset workflow

1. **Create the art** (current M4 pipeline — the owner's rules: hand-drawn look, no blur/halo,
   palette only, light from the top-left, simple shapes at small sizes):
   - **Board sources (32x32):** crop the item from the concept art (Claude project files
     `concept-art*.png`) without its background, 4x the target size → Pixellab
     `/image-to-pixelart` (default "reinterpret" mode, seed 11; raw outputs in
     `pixelart/03_pixellab/...`) → `python3 tools/art/pixellab_palette_map.py <id> <pixellab.png> <out.png>`
     (removes the grey background, maps each distinct color onto the material ramps, black outline).
   - **HUD icons, cursors, upgrade icons:** hand-drawn pixel by pixel as ASCII maps in
     `tools/art/hand_drawn/{icons,cursors,upgrades,pointer,hand}.py` (run them to rewrite the PNGs).
     Pixellab is too muddy at 16–24 px. Cursor hotspots are set by hand in `data/tools/*.tres`
     and `tool_cursor.tscn`.
   - **Backgrounds:** `python3 tools/art/concept_background.py <painting.png> <out.png> [--lab]
     [--warm-boost K]` (palette first, majority-vote downscale, lonely-pixel cleanup; drawn at
     320x180 and upscaled 2x). Biome paintings (1672x941) live in
     `pixelart/deepglow-biomes-v2/`; they are painterly (no pixel grid), so downscaling them gives
     noise: they were redrawn with Pixellab `/image-to-pixelart` (painting resized to 1280x720,
     output 320x180, seed 11 or 23; raw results in `pixelart/03_pixellab/2026-09-28/bg_i2p_*`) and
     converted with `--native` (+ `--warm-boost 2.2` for the ash forest). Outputs in
     `assets/sprites/board/biomes/<biome_id>.png`; the night forest is `board/background.png`
     (its painting was already real pixel art).
   - `concept_to_sprite.py` / `concept_panel_items.py` are the earlier script-only conversions,
     kept as helpers (they produced halos; not used for final art).
   - HUD text sits on opaque `HudPanel` panels (no transparency). Font: `assets/fonts/m5x7.ttf`
     (Daniel Linssen), 16 px body / 32 px titles, no antialiasing.
2. **Clean up/edit** in Aseprite → `pixelart/02_source/<category>/<id>.aseprite`.
3. **Force and validate the palette:** `python3 tools/art/palette.py apply|check`.
4. **Export** the final PNG to `assets/sprites/<category>/<id>.png` (32x32 for sources;
   spritesheets as `assets/sprites/.../<id>_sheet.png`).
5. **Hook it up:** set `texture` in `data/sources/<id>.tres` (or `icon` / `cursor_texture` for
   resources/tools; create a `SpriteFrames` for animations).
6. **Record progress:** screenshots/videos in `pixelart/05_progress/`.

Art file names: `snake_case`, no spaces, English, id equal to the data `id`
(e.g. `tree_oak.png` ↔ `data/sources/tree_oak.tres` ↔ `SOURCE_TREE_OAK_NAME`).

## 5.1 Audio

- **Everything is synthesized** by Python scripts in `tools/audio/` (numpy/scipy + ffmpeg for Ogg
  Vorbis): no samples, no licenses to track. Edit the recipe, re-run, commit the `.ogg`:
  `python3 tools/audio/sfx.py` (effects), `music.py` (loops), `ambience.py` (night ambience).
  Outputs: `assets/audio/{sfx,music,ambience}/`.
- **Buses** (`default_bus_layout.tres`): Master (hard limiter, -1 dB) ← Music, SFX, Ambience, Voice.
  Volumes are `Settings` values in steps 0–10 (Settings screen rows).
- **`Sound` autoload** (`src/autoload/sound.gd`): `play(stream, pitch_jitter)` (pooled one-shots),
  `play_music(stream)` (crossfade), `set_rush(bool)` (fades layer 1 of an `AudioStreamSynchronized`),
  `play_ambience(stream)`. Every `BaseButton` gets `ui_click`/`ui_move` automatically.
  Call `Sound.stop_all()` and wait a few frames before quitting (`Main._quit()`), or the audio
  server reports leaked playbacks.
- **Music:** `data/audio/phase_music.tres` = `phase_base.ogg` + `phase_rush.ogg` (132 BPM acid
  techno, 32 bars / ~58 s in four 8-bar sections that change key: Am → Cm → Dm → Am; same length,
  the rush layer fades in during the last 10 s); `camp.ogg` (112 BPM, 16 bars, second half one
  tone up) for menus and between phases. `play_music` crossfades in linear amplitude (out 2 s,
  in 2.5 s, new track starts 0.6 s later). Loops are imported with `loop=true` (edit the `.ogg.import`).
- **Voice (narration):** recorded outside (ElevenLabs, paid plan = commercial license), exported as
  `intro_NN_<locale>.mp3` into `pixelart/06_voice/`, then `python3 tools/audio/voice.py <dir>` trims
  silence, normalizes to -16 LUFS and writes `assets/audio/voice/<locale>/intro_NN.ogg`. The intro
  plays the file for the current locale (`IntroSequence.get_voice`). **Rule (owner):** a language
  without its own recording is narrated in English, with the captions in its own language
  (`IntroSequence.fallback_voice_locale`). Recorded: pt_BR, en.
  ElevenLabs voices (reuse them for any new narration so every line sounds the same):

  | Locale | Voice | Voice ID |
  |---|---|---|
  | en | Connery - Dramatic Mythology Storyteller | `onwK4e9ZLuTAKqWW03F9` |
  | pt_BR | Lucas - Deep & Profound Narrator | `GIuLCSVfgJaUuh7hYOY8` |

  Each shot lasts its line + 0.8 s; the music bus is lowered 8 dB while the intro runs.
- **Ambience:** one loop per biome (`Biome.ambience`, 48 s, sparse events in bouts with long
  rests, loudness matched to the night loop in `ambience.py`): `night` crickets, `swamp` bubbles
  surfacing, `caves` echoing drips + rare crystal chime, `ash`
  ember crackles + a soft thump, `frozen` ice tinkles + a rare distant howl, `ruins` a drowned temple bell
  (muffled, inharmonic) + bubble trains; pure sub-bass pulses were inaudible on small speakers. Rejected by the owner (don't bring back): a continuous stream/wind noise bed
  (sounded like hiss), occasional water swells and synthetic frogs (didn't sound like frogs).
- **Material sounds/particles are data:** `ToolType.hit_sound` + `ToolType.particle_colors`
  (palette, bright → dark).
  A source can override them: `SourceType.hit_sound` and `SourceType.collect_sound` (played on
  the final, collecting hit instead of the hit sound) — the boar grunts on each spear hit and
  squeals when collected (`boar_grunt`/`boar_squeal`, formant "voice" synthesis in `sfx.py`).
- New gameplay moments emit an `Events` signal (e.g. `source_hit`); `GameAudio`/`GameFx`/`GameRumble` react.

## 5.2 Publishing

- Versions: bump `application/config/version` (shown on the title screen) for every store build.
- `Platform` autoload: uses GodotSteam only if its `Steam` singleton exists (all calls via
  `call()`), so builds without the extension still run. Steam App ID: project setting
  `deepglow/steam/app_id`. Achievements are data (`data/achievements/*.tres`, `Achievement`
  resource, ids = Steamworks API names) and are reported by `Game.report_achievements()`.
- Full guide (Steamworks, Steam Cloud, Deck checklist, macOS notarization, store page):
  `docs/publishing.md`.

## 6. Useful commands

```bash
# Godot (macOS)
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --path . --editor                               # open the editor
$GODOT --path .                                        # run the game
$GODOT --headless --path . --import                    # (re)import / check parse errors
$GODOT --headless --path . -s res://tests/run_tests.gd # tests (exit 1 on failure)

# Balance simulator (uses the real game code + data; exit 1 if a check fails)
$GODOT --headless --path . -s res://tools/balance/simulate.gd -- --runs 12   # default target 120 min
#   (~1–2 min for the full game; use --profiles average:3.0 --runs 4 for quick iterations)
#   report: tools/balance/reports/latest.md (git-ignored); options in simulate.gd header

# Release builds (needs the export templates; output in build/, git-ignored)
GODOT=$GODOT tools/build/export_all.sh            # Windows, macOS, Linux (or pass one preset name)

# Audio (regenerate)
python3 tools/audio/sfx.py && python3 tools/audio/music.py && python3 tools/audio/ambience.py

# Art
python3 tools/art/palette.py check assets/sprites/**/*.png
python3 tools/art/palette.py png --swatch 8 --out /tmp/palette.png
```

Tests: `tests/test_*.gd` files extending `RefCounted`, with `test_*()` methods returning
`""` (pass) or a failure message. Scripts run with `-s` are compiled before autoloads exist:
tests must cover pure logic (`BoardModel`, `Inventory`, `ProgressionState`, `Needs`,
`PhaseGenerator`, `SaveGame`/`SaveSystem`, Resources) using the real `data/game_database.tres`, and must not statically
reference classes that depend on `Events`/`Settings` (Board, Game, UI).

## 7. Git workflow

- **Remote:** https://github.com/thiagoalgo/deepglow-ai (default branch `main`).
- **Never commit without the owner's explicit approval.** Before every commit, ask the owner,
  showing a short summary of the changes and the proposed message. Approval for one commit does
  not carry over to the next.
- **Pushing is done manually by the owner** (the agent environment has no GitHub credentials).
  After every commit, the agent must **remind the owner to run `git push`** and say how many
  commits are waiting. Never force-push or rewrite published history.
- **Messages:** English, [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `art:`), imperative mood,
  subject ≤ 72 characters, body explaining the *why* when useful.
- **Scope:** small, focused commits — one logical change each. Run the checklist below first.
- **What to commit:** sources, scenes, resources, `*.uid` and `*.import` files, final assets,
  `localization/translations.csv`, `.mcp.json`, `export_presets.cfg` (no credentials in it: those
  live in `.godot/export_credentials.cfg`). **Never:** `.env`, `.godot/`, generated
  `*.translation`, `.idea/`, raw/source art (that lives in the art support directory).

## 8. Checklist before finishing a task

- [ ] `--headless --import` with no new GDScript errors/warnings.
- [ ] `tests/run_tests.gd` passing; new rule logic has a test.
- [ ] Everything technical (code, names, keys) is in English; player-facing text uses translation keys filled for
      `en` and `pt_BR`.
- [ ] Changed anything in `data/` (costs, yields, rules) or the generator/progression code? Run the
      balance simulator and keep all acceptance checks green (targets in GDD §8).
- [ ] New assets pass `palette.py check` and respect 32x32 / 40 px grid.
- [ ] `--headless --import` shows no "leaked"/"still in use" messages (see self-reference rule).
- [ ] No secrets (`.env`, tokens) committed.
- [ ] No raw/source art (`.aseprite`, discarded generations) inside this repository.
- [ ] If architecture, folders, pipeline or conventions changed: **update this AGENTS.md**.
- [ ] Changes committed **only** after the owner approved; owner reminded to push (see section 7).
