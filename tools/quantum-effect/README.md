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

## Phase 0.5: extraction tooling (2026-08-03)

Three scripts turn the raw design-system art into `pack_sprites.ps1`-ready
per-subject files. Each is a standalone pre-processing step - none of them
replace `pack_sprites.ps1`, they just clean its input.

### `dekey_alpha.ps1` - restore real alpha to opaque art

Some source images (`icons/coin-gold.png`, `bestiary/creatures/arctic.png`)
carry a baked-in background instead of transparency - every pixel has
alpha=255. This flood-fills the background out from the image border. Unlike
a flat colour-distance test against one sampled background colour, each step
compares a candidate pixel only to the neighbour that reached it, so the
fill follows QE's vignette/gradient backgrounds instead of stopping the
instant the gradient drifts past a fixed tolerance.

Known limit: a handful of icons (`potion-stamina.png`) have almost no
contrast between subject and background to begin with - no keying strategy
recovers those; the tool prints a warning when it clears >90% of an image
(a sign it likely ate the subject) so they're easy to spot and triage by
hand rather than shipped silently broken.

### `slice_contact_sheet.ps1` - split multi-subject sheets

Splits a sheet (e.g. `arctic.png`, 7 creatures side by side) into one file
per subject by finding columns that are fully transparent - i.e. it needs
real alpha, so run `dekey_alpha.ps1` first if the source is still opaque.
Segments narrower than `-MinWidth` are dropped as edge antialiasing noise,
not real subjects.

This is column-only: it does not remove the caption/badge bands still baked
into each sliced tile. That's `strip_bands.ps1`'s job.

### `strip_bands.ps1` - drop caption/badge bands from sliced tiles

For contact-sheet tiles (bestiary-style: one connected creature silhouette
per tile, with a text caption above and a level-badge icon below), this
finds row-runs of content separated by real transparent gaps. Only the
TOPMOST and BOTTOMMOST runs are ever candidates for removal, each dropped
if it's under `-MinHeightRatio` of the tallest of the *other* runs; any run
in between is always kept regardless of size.

That edge-only restriction isn't incidental - an earlier version judged
every run purely by "is it tall enough vs. the tallest run" and left the
badge behind on several sprawling creatures (spread wings, many legs),
because their own anatomy fragments into several runs and a mid-body leg
run can land in the same height range as the badge. A label/badge is
structurally always outermost, so restricting candidacy to first/last and
always keeping the middle fixes it without needing to guess a threshold
that works for every silhouette shape.

Validated against the full `bestiary/creatures/` set (12 sheets, 84
creatures) through the whole `dekey_alpha -> slice_contact_sheet ->
strip_bands -> pack_sprites` pipeline with no per-file tuning: 83/84 tiles
came out clean (spiders and scorpions with fully-spread legs included -
verified those legs survive, since they're always "middle" runs). One
outlier, `forest_07`, still has its badge baked in because the creature's
own art touches the badge with no transparent gap between them at all -
there's no row-gap for any gap-based tool to find; it needs a manual crop
or a different (non-gap) signal.

**Scope warning, confirmed the hard way: this is only safe for
single-connected-silhouette tiles, not general character-sprite frames.**
A dynamic pose (a jump, an attack) can legitimately have parts - a raised
head, a trailing foot - separated from the rest of the silhouette by a real
transparent gap, and even the edge-only version can't tell a disconnected
head from a caption by geometry alone if the head happens to be first/last.
Tested against `characters/sprites/player`: an earlier version of this tool
silently deleted a head from a frame that had no caption at all. Use
`strip_caption.ps1` for character-sprite frames instead.

### `strip_caption.ps1` - remove baked-in captions from character-sprite frames

Purpose-built for the `characters/sprites/` caption problem (`RUN (8
FRAMES)` etc., see below), after `strip_bands.ps1` proved unsafe there.
Requires **both** signals to agree before dropping anything:

1. **Geometric**: the topmost run of content rows, separated from
   everything below by a real transparent gap.
2. **Colour**: that run must be majority caption-coloured - a saturated
   cyan (G and B channels well above R) - measured off the actual "RUN (8
   FRAMES)" pixels, not assumed.
3. **Size cap**: that run must be a small fraction of the frame's total
   height, so an effect that fills nearly the whole canvas and simply runs
   out of pixels near the bottom edge (an ordinary trim margin, not a
   caption boundary) doesn't qualify no matter how cyan it is.

All three were necessary - each single-signal version was tried and each
had a confirmed false positive: geometry-only deleted a disconnected head;
colour-only shaved the tip off a legitimately blue dash-effect frame that
tapers into the character with no gap; geometry+colour without the size cap
wiped out most of an attack-effect sprite because the "gap" it found was
just bottom margin. Validated clean across all four actors (`player`,
`kira`, `trooper`, `colossus`) - flags 2-7 frames per actor, matching the
"first frame of an animation row, occasionally" pattern the sprites
`README.md` describes, including the specifically-documented `colossus`
row-1 case.

### Suggested pipeline for a new contact-sheet category (e.g. bestiary)

```powershell
.\dekey_alpha.ps1 -InputDir <raw category dir> -OutDir out\<category>_keyed
foreach ($sheet in Get-ChildItem out\<category>_keyed -Filter *.png) {
    .\slice_contact_sheet.ps1 -InputFile $sheet.FullName -OutDir out\<category>_sliced
}
.\strip_bands.ps1 -InputDir out\<category>_sliced -OutDir out\<category>_clean
.\pack_sprites.ps1 -InputDir out\<category>_clean -OutSheet out\<category>_48.png
```

For `characters/sprites/`, skip slicing (already one subject per file) and
use `strip_caption.ps1` instead of `strip_bands.ps1`:

```powershell
.\strip_caption.ps1 -InputDir <sprites dir>\player -OutDir out\player_clean
.\pack_sprites.ps1 -InputDir out\player_clean -OutSheet out\player_48.png
```

Not yet built: a slicer/cropper for "key art, not sprites" files (e.g.
`bestiary/bosses/bio-leviathan.png`, a painterly illustration with a
caption and letterbox bars) - different shape of problem, deferred.
