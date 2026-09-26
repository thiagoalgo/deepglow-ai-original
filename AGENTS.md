# AGENTS.md — Deepglow

Guide for AI agents (Claude, Codex, Cursor, etc.) and humans working on this repository.
Read it fully before changing anything.

## 0. Language rules (mandatory)

| What | Language |
|---|---|
| **Everything technical**: code, identifiers, comments, doc comments (`##`), commit messages, file and directory names, asset names, node names, translation keys, log/error messages, tool output, technical docs (this file, `docs/`, READMEs) | **English** |
| **Player-facing text** (UI, piece names, descriptions, dialogs) | **Localized** — English (`en`) and Brazilian Portuguese (`pt_BR`) from day one |
| Conversation with the project owner | Portuguese is fine |

Never hardcode player-facing strings in scripts or scenes: use translation keys (section 4).

## 1. The project

- **Game:** Deepglow — a pixel art **board game** with a night-time, bioluminescent setting
  (forest, waterfall, crystals, glowing mushrooms). 8x8 board with icon-like pieces
  (trees, rocks, ores, gems, plants, structures). Visual reference:
  `00_references/concept-art.png` in the art directory.
- **Engine:** Godot **4.7.x**, GDScript, **GL Compatibility** renderer.
- **Game rules:** still being designed (`docs/game-design.md`). The current loop (click places
  a random piece, right click removes) is a **prototype** in `src/game/states/player_turn_state.gd`.

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

- **Base resolution:** 320x180, `stretch/mode=viewport`, `scale_mode=integer` (6x at 1080p).
  Development window 1280x720 (4x).
- **Filtering:** Nearest (project default). 2D transform and vertex snapping enabled.
  Never place nodes at fractional coordinates on purpose; use `.floor()`.
  Default font antialiasing is off.
- **Grid:** **20x20 px** cells; **16x16 px** piece sprites centered in the cell.
  The board is 160x160 px, centered (origin at (80, 10)).
- **Palette:** 24 colors in `assets/palettes/deepglow.gpl` (mirrored in `src/core/palette.gd`
  as `Palette.*`). **Every final asset must use only these colors**, no semi-transparency.
  Check with `python3 tools/art/palette.py check <png>`; fix with `... apply <png>`.
- **Style:** dark outline (`CHARACTER_OUTLINE`/`SHADOW_*`), simple shading,
  neon highlights (teal, cyan, sulfur yellow) over dark blue backgrounds.

## 3. Godot architecture

### Folder structure

```
src/                  # code + scenes, organized by FEATURE (.tscn next to its .gd)
  autoload/           # singletons: Settings (persisted prefs), Events (signal bus)
  core/               # generic utilities, no game rules (StateMachine, Palette)
  main/               # entry scene and screen flow
  game/               # match orchestration + states/ (rules per state)
  board/              # Board (view/input), BoardModel (pure state), BoardConfig
  pieces/             # Piece (scene), PieceData/PieceCatalog (Resources)
  ui/                 # one subfolder per screen/component + theme/
localization/         # translations.csv (source of all player-facing text)
data/                 # .tres instances (configs, catalog, piece definitions)
assets/               # FINAL game-ready art/audio (sprites/, tilesets/, fonts/, audio/, palettes/)
tests/                # headless tests (test_*.gd)
tools/                # Python scripts outside the game (pixellab/, art/)
addons/               # third-party plugins (do not edit)
docs/                 # design and pipeline docs
```

### Current scene flow

```
Main (Node)                          src/main/main.tscn — swaps screens
├── LanguageSelect (Control)         src/ui/language_select/  — start screen
│
└── (after a language is confirmed)
    ├── Game (Node2D)                src/game/game.tscn      — match context
    │   ├── Board (Node2D) %         src/board/board.tscn    — view + input
    │   │   ├── GridView (Node2D) %  — placeholder drawing (_draw) → future TileMapLayer
    │   │   ├── Pieces (Node2D, y_sort) %
    │   │   └── Cursor (Node2D) %
    │   └── StateMachine (Node) %
    │       ├── Setup (GameState)
    │       └── PlayerTurn (GameState)
    └── Hud (CanvasLayer)            src/ui/hud/hud.tscn
```

Autoloads (in order): `Settings`, `Events`.

### Principles

1. **Separate data, state and view.**
   - *Data* → `Resource` with `class_name` (`PieceData`, `BoardConfig`), instances in `data/`.
     New piece type = new `.tres` + translation keys, no new code.
   - *State* → pure `RefCounted` classes (`BoardModel`), testable headless.
   - *View* → nodes/scenes that reflect the state (`Board`, `Piece`).
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
9. **UI styling comes from the project theme** (`src/ui/theme/main_theme.tres`, set as
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

### Input

Actions defined in `project.godot`: `select` (left mouse / space),
`cancel` (right mouse / Esc). Menus use Godot's built-in `ui_*` actions (keyboard/gamepad
focus navigation must always work). Always use actions, never raw keys.
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
  - Pieces: the key is derived from `PieceData.id` (`gem_violet` → `PIECE_GEM_VIOLET_NAME`);
    use `PieceData.get_display_name()`.
  - Language names are always written in their own language and never translated.
- **Active locale:** owned by the `Settings` autoload (`Settings.set_locale()`), persisted to
  `user://settings.cfg`. On first launch it defaults to the OS locale when supported.
  The **LanguageSelect** start screen lets the player choose; focusing an option previews
  the screen in that language.
- **Adding a language:** add a CSV column, register the new `.translation` in Project
  Settings → Localization, add the entry to `Settings.SUPPORTED_LOCALES`.
- Keep strings short: the UI is 320x180 with an 8 px font. Check that Portuguese (usually
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

### Asset workflow

1. **Generate** with Pixellab (raw output → `pixelart/03_pixellab/...`). Always log the prompt.
   Recommended base prompt: *"<object>, pixel art game icon, top-down 3/4 view, dark
   single-color outline, simple shading, bioluminescent night palette, transparent background"*.
   Use `pixelart/01_palette/deepglow_palette.png` as the color/palette image when supported.
2. **Clean up/edit** in Aseprite → `pixelart/02_source/<category>/<id>.aseprite`.
3. **Force and validate the palette:** `python3 tools/art/palette.py apply|check`.
4. **Export** the final PNG to `assets/sprites/<category>/<id>.png` (16x16 for pieces;
   spritesheets as `assets/sprites/.../<id>_sheet.png`).
5. **Hook it up:** set `texture` in `data/pieces/<id>.tres` (or create a `SpriteFrames`).
6. **Record progress:** screenshots/videos in `pixelart/05_progress/`.

Art file names: `snake_case`, no spaces, English, id equal to `PieceData.id`
(e.g. `gem_violet.png` ↔ `data/pieces/gem_violet.tres` ↔ `PIECE_GEM_VIOLET_NAME`).

## 6. Useful commands

```bash
# Godot (macOS)
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
$GODOT --path . --editor                               # open the editor
$GODOT --path .                                        # run the game
$GODOT --headless --path . --import                    # (re)import / check parse errors
$GODOT --headless --path . -s res://tests/run_tests.gd # tests (exit 1 on failure)

# Art
python3 tools/art/palette.py check assets/sprites/**/*.png
python3 tools/art/palette.py png --swatch 8 --out /tmp/palette.png
```

Tests: `tests/test_*.gd` files extending `RefCounted`, with `test_*()` methods returning
`""` (pass) or a failure message. Scripts run with `-s` are compiled before autoloads exist:
tests must cover pure logic (`BoardModel`, Resources, static helpers) and load scenes/scripts
via `load()` without static typing of classes that depend on `Events`/`Settings`.

## 7. Git workflow

- **Remote:** https://github.com/thiagoalgo/deepglow-ai (default branch `main`).
- **Never commit or push without the owner's explicit approval.** Before every commit, ask the
  owner, showing a short summary of the changes and the proposed message. Pushing is a separate
  approval. Approval for one commit does not carry over to the next.
- **Messages:** English, [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `art:`), imperative mood,
  subject ≤ 72 characters, body explaining the *why* when useful.
- **Scope:** small, focused commits — one logical change each. Run the checklist below first.
- **What to commit:** sources, scenes, resources, `*.uid` and `*.import` files, final assets,
  `localization/translations.csv`, `.mcp.json`. **Never:** `.env`, `.godot/`, generated
  `*.translation`, `.idea/`, raw/source art (that lives in the art support directory).

## 8. Checklist before finishing a task

- [ ] `--headless --import` with no new GDScript errors/warnings.
- [ ] `tests/run_tests.gd` passing; new rule logic has a test.
- [ ] Everything technical is in English; player-facing text uses translation keys filled for
      `en` and `pt_BR`.
- [ ] New assets pass `palette.py check` and respect 16x16 / 20 px grid.
- [ ] No secrets (`.env`, tokens) committed.
- [ ] No raw/source art (`.aseprite`, discarded generations) inside this repository.
- [ ] If architecture, folders, pipeline or conventions changed: **update this AGENTS.md**.
- [ ] Changes committed **only** after the owner approved (see section 7).
