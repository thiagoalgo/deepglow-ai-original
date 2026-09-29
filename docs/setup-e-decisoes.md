# Deepglow — setup and decisions

## Setup
- Godot 4.7.x, GL Compatibility, statically typed GDScript. **640x360** (changed from 320x180 in M4), integer scale inside a SubViewport (App root, optional CRT shader, F2); **40x40 cells, 32x32 source sprites**, cursors 24, HUD icons 16, upgrade icons 20; UI values/fonts 2x (m5x7 font 16, titles 32). 24-color palette (paleta.gpl) — KEEP IT (inspired by Animal Well; owner decision).
- Godot repo: /Users/thiago/Projects/godot/deepglow-ai (guide: AGENTS.md; CLAUDE.md points to it). Art support dir: /Users/thiago/Documents/gamedev/deepglow/pixelart (also connected to Cowork sessions; biome paintings in pixelart/deepglow-biomes-v2/, 1672x941 + 3x).
- user:// = custom dir "Deepglow" (macOS ~/Library/Application Support/Deepglow/): save.json (run) + settings.cfg (prefs). That folder is protected from Claude: the owner deletes/copies saves himself (or uses "Novo jogo"). Test saves: src/dev/saves/NN_<biome>.json (dev console: load_save NN; 01 = empty run).
- Pixellab: REST CLI tools/pixellab/pixellab.py (token in .env on the owner's machine; run API calls via the device shell — works). Ask before batches (credits: ~1875 left on Sep 28 2026).
- Running the game embedded in the editor's Game tab ignores fullscreen (normal); disable "Embed Game on Next Play" to test it.
- Builds (>20 MB) reach the owner's folder by splitting into <20 MB parts, committing them to build/.parts and joining with cat (verify md5). Build from a clean clone of the device repo (git bundle) to be sure it matches HEAD.
- Don't leave `.git/index.lock` behind (a `git status` from the device shell once did; deleting needs the owner's delete permission).

## Language rules
- Code, comments, identifiers, file/dir/asset names, translation keys, commit messages: English.
- Documentation files (docs/, READMEs, AGENTS.md): Portuguese allowed.
- Player-facing text: en + pt_BR via localization/translations.csv.

## Git
- Remote https://github.com/thiagoalgo/deepglow-ai (main). Author Thiago <thiagoalgo@gmail.com>.
- ALWAYS ask before each commit.
- PUSH IS MANUAL BY THE OWNER. ALWAYS remind him after every commit with the pending count: `git rev-list --count origin/main..HEAD`.
- `Claude outputs/` in the repo is untracked; never `git add -A` blindly. export_presets.cfg is versioned.

## Communication with the owner
- LAUNCH NOTES: all Steam/itch/launch notes live ONLY in `docs/steam-launch.md` (repo, versioned in git; also mirrored in the Project files). Claude maintains it: every launch-related note or change goes there, edited DIRECTLY in the repo when the session has repo access (Claude Code/Cowork), uncommitted, then ask before committing as usual. In claude.ai chats (Project files are read-only there), deliver the full updated file for the owner to replace in the repo and in the Project. No Claude Docs for this. If copies diverge, the repo wins.
- When showing variants, ALWAYS label them by row and column of the image, never by seed/variant names.
- Be honest; don't oversell weak results. Remember prior feedback before proposing.
- NEVER show flat placeholder cards/empty screens as a result: the owner judges visually ("ficou péssimo"). Use real art or say it is a skeleton before showing.
- The owner wants to check changes in the game BEFORE committing: apply to the repo uncommitted first, then ask to commit.
- ONLY GENERATE BUILDS (exports/zips) WHEN THE OWNER EXPLICITLY ASKS.
- BUILD TYPE: when the owner asks for a build without saying which, ASK: dev (preset "<platform> (dev)", has the dev console + test saves), demo or production (release presets, no src/dev/) — and the platform (Windows/macOS/Linux). A demo preset does not exist yet: create it when first asked.
- "Menos é mais" — he prefers removing an effect over keeping a mediocre one.
- After changes that alter the tree/balance, remind him to delete the save.
- For visual A/B tests he likes before/after screenshots saved in pixelart/05_progress/screenshots/.
- For new effects/sounds: send in-game GIFs + mp3 previews first, then apply after approval. Claude cannot listen to audio: say so, and check loudness with ffmpeg ebur128 (also with a 150 Hz highpass to simulate laptop speakers).

## Art direction — lessons (DO NOT FORGET)
- "excesso de detalhes para uma pequena resolução": simple clean shapes; light ALWAYS from the top-left.
- Must look HAND-DRAWN pixel art (no blur/halo). NO TRANSPARENCY.
- Items: concept crop → Pixellab /image-to-pixelart (seed 11) → tools/art/pixellab_palette_map.py. Icons/cursors/upgrade icons: hand-drawn ASCII maps (tools/art/hand_drawn/).
- BACKGROUNDS: a painting only converts well by downscaling if it is already real pixel art with a grid (the Bosque Noturno is). Painterly images (the other 5 biomes) turn into noise; mean-shift "simplifying" made paint blobs (rejected). What works: Pixellab /image-to-pixelart (painting resized to 1280x720 → output 320x180, default reinterpret mode, init_image_strength 0) then `concept_background.py --native` (8-bit Lab palette mapping, + `--warm-boost 2.2` for the ash forest). Owner picked (Sep 28): caves seed 11 (bg_i2p_caves_a), swamp seed 11, ash seed 11, vale seed 23, ruins seed 23 (raw in pixelart/03_pixellab/2026-09-28/).
- UI boxes: PixelStyleBox (stepped corners).
- REJECTED: dotted glow halos around board items; an "OR/OU" badge between exclusive-choice nodes; biome background images behind the upgrade tree; boxes around the tree's biome headers.
- Known small art issues: copper HUD icon fragmented, fruit vs meat icons too similar.

## Story & narration
- Owner's canonical text is the Project doc "História de Deepglow" (pt_BR). Read it before any story/narrative work; don't rewrite it without asking.
- Intro: see Project doc claude/introducao-roteiro.md. Intro (animatic with pixel dissolves + narration en/pt_BR) is committed.
- ElevenLabs voices (paid plan) — reuse for ANY new narration:
  - en: **Connery - Dramatic Mythology Storyteller**, voice ID `onwK4e9ZLuTAKqWW03F9`
  - pt_BR: **Lucas - Deep & Profound Narrator**, voice ID `GIuLCSVfgJaUuh7hYOY8`
- Rule: a language without its own recording is narrated in English with captions in its own language.

## Biomes (implemented Sep 27 2026, D11)
- Six `Biome` resources (data/biomes/, GameDatabase.biomes): each tree gate = a biome; reaching its points (+ one level bought in the previous biome's rows) swaps the phase background and shows a "Novo bioma" banner.
- Content: Bosque Noturno (0) wood/fruit/water · Pântano (10) fishing · Cavernas de Cristal (18) stone + crystals · Bosque de Cinzas (31) ores · Vale Lunar (41) spear/boar · Ruínas Submersas (53) Heart.
- Sim: average 132 min; "fast ≤ 40% faster" sits at the edge (40–42%).
- Optional idea not done: generator weighting sources by biome. Future: one music track per biome.
- Per-biome atmosphere (commit 3baa583): Biome.ambient_effects (AmbientEffect layers in data/ambient/, drawn by AmbientParticles behind the board) + Biome.ambience (loop, crossfade 3 s; menus = night). Night: fireflies + crickets · Swamp: teal spores + bubbles · Caves: crystal glints + drips, echoing drips + rare chime · Ash: embers up + ash flakes down, ember crackles + thump · Vale: 2-layer snow, ice tinkles + distant howl · Ruins: ring bubbles + plankton, muffled sunken-temple bell + bubbles.

## Upgrade tree (redesigned Sep 28 2026, commit e6e1360)
- Horizontal (left→right), one band per biome with a text-only header in Biome.color + "Libera com N pontos"; dotted separators.
- 1 px octilinear links (owner chose 1 px over 2 px) in the child's biome color when the parent is owned; routes avoid passing behind nodes. 28 px nodes, 1 px frames, 20x20 icons unscaled, level pips.
- Details = popup opened only by click/confirm (focus alone never opens it); stays put after buying; closes with Esc/B/right click/empty click. Column gap 36 px.

## Audio (M6) — decisions
- Frenetic 90s/2000s techno for phases (32 bars, Am → Cm → Dm → Am, rush layer at 10 s); camp track for menus; smooth crossfade.
- All music/SFX/ambience SYNTHESIZED by tools/audio/*.py. Ambiences = sparse events in bouts, loudness matched to the night loop.
- REJECTED: continuous noise bed/wind, water swells, synthetic frogs (two attempts, "não parece sapo"), pure sub-bass pulses (inaudible on small speakers).

## Game design (docs/game-design.md) — decided
- Incremental, no defeat, full tree (29 nodes). D5 ≈ 2h10 simulated average player; changes gradual.
- D10 demand-aware generator. D6: empty hunger = weak hits (×0.5); empty thirst = materials half (food/drink not reduced), always visible.
- Pause menu (Esc/P/Start). Gamepad: stick one cell per tilt; vibration on hits.

## M7 publishing — what exists
- export_presets.cfg + tools/build/export_all.sh → build/. Version 0.7.0. Platform autoload (GodotSteam optional), 10 achievements.
- OWNER DECISION (Sep 2026): NOT publishing on Steam or Apple for now; no macOS signing; no Steam Deck.

## Status (Sep 28 2026)
- M1–M7 done; biomes, new backgrounds, intro (animatic + narration), tree redesign and per-biome atmosphere all committed.
