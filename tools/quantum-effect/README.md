# Quantum Effect asset tooling

Tooling for turning Quantum Effect artwork into game-usable sprite sheets.

## Why this exists

QE art under `VisualAssets/` is authored as individually-cropped images at
arbitrary dimensions (25x40, 226x132, 520x100, ...). OpenNefia's chip system
needs the opposite: a rigid grid of fixed-size cells in a fixed column count,
addressed by index — `x = (id % 33) * 48`, `y = floor(id / 33) * 48`
(see `src/mod/elona/data/chip.lua`, `make_chip_group`).

`pack_sprites.ps1` bridges the two.

## Usage

```powershell
.\pack_sprites.ps1 -InputDir <art folder> -OutSheet out\sheet.png [-Cell 48]
```

Per source image it trims transparent margins, scales to fit the cell
preserving aspect ratio, anchors it in the cell (bottom for things that stand
on the ground, centre for items/icons), and composites it into the sheet. It
writes a PNG with real alpha plus a JSON manifest recording which source file
landed at which index.

PNG rather than Elona's key-colour BMP is deliberate: OpenNefia sends any
non-`.bmp` source straight to `love.graphics.newImage` (see
`src/internal/bmp_convert.lua`), so real alpha works and no key colour is needed.

Useful switches: `-Cell` / `-CellHeight` (cell size), `-Columns`,
`-Anchor bottom|center`, `-Interpolation nearest|bicubic|auto`, `-NoUpscale`,
`-NoTrim`.

## Cell size: settled at 48x48

`-Cell` is a parameter because it was an open question — whether QE art reads
better at Elona's native 48x48 or something larger. It was tested and the
answer is **48x48**.

QE's character sprites are authored at roughly 25x40. Rendering them into a
96x96 or 128x128 cell just magnifies the same pixels: it cannot add detail that
was never drawn, and it costs sheet memory and crispness. 48x48 lands near 1:1
for this art. Use a larger cell only if higher-resolution source art is
authored later, or for genuinely tall props (Elona's own `is_tall` chips are
48x96).

## Known issue with the current source art

`VisualAssets/QuantumEffectDesignSystem/` is a **design-system reference
library**, not a game-ready sprite library. Much of it needs extraction work
before it can be packed:

- **Contact sheets.** e.g. `bestiary/creatures/arctic.png` (520x100) holds
  about seven creatures side by side with captions — one file, many subjects.
- **Baked-in label text.** Several sprite frames and tiles have reference
  labels burned into the pixels (`RUN (8 FRAMES)`, `WALLS`).
- **Key art, not sprites.** e.g. `bestiary/bosses/bio-leviathan.png` (226x132)
  is a painterly illustration with a caption and letterbox bars.
- **Missing alpha.** Some icons (`icons/coin-gold.png`) carry a baked
  background rather than transparency.

The exception is `characters/sprites/` (254 files across `player`, `kira`,
`trooper`, `colossus`) — genuine per-frame pixel art, named `<name>_rNN_fNN`,
which packs cleanly today apart from a handful of label-contaminated frames
(the first frame of several animation rows has a caption like `RUN (8
FRAMES)` baked into the top of the image - pick a different frame from the
same row rather than trying to crop it out).

Slicing, de-labelling and curating the rest is the next piece of work.

## Phase 1 spike: confirmed working on-device (2026-08-03)

`src/mod/quantum_effect/` takes one clean frame per character (`player`,
`kira`, `trooper`, `colossus`) through this pipeline and wires the result into
OpenNefia as real `base.chip`/`base.chara` data, with Quickstart pointed at
the QE player sprite. Verified end-to-end: `verify --load-all-mods` and the
full desktop test suite (316 tests) both pass, and a clean install boots
straight into gameplay on the Android emulator with the QE player sprite
rendering correctly on a real map, HP/MP bars and all.

Two non-obvious things learned building that mod, worth knowing before
writing more `quantum_effect` data:

- **`config` and `data` are mod-context globals** - no `require` needed in a
  mod's `init.lua` (see `mod/cheat/init.lua`'s `config.base.themes` for the
  same pattern). `require("internal.config")` fails from mod code with
  "cannot load path" - internal engine modules aren't reachable that way.
- **A runtime `config.base.x = y` assignment in `init.lua` does not survive
  to actual gameplay.** Every real boot runs `game/startup.lua`, which
  unconditionally calls `config_store.clear()` then `config_store.load()`
  before anything reads config - `clear()` wipes whatever a mod set earlier,
  and `load()` only restores a save file, which doesn't exist on a fresh
  install. To change an effective default, edit the `base.config_option`
  entry's `default` field instead, via
  `data["base.config_option"]:edit(name, func)` (pattern copied from
  `mod/base/init.lua`'s `data["base.effect"]:edit(...)`) - that runs before
  the clear/load cycle, so the freshly-computed default picks it up.
