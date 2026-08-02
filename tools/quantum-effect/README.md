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
which packs cleanly today apart from a handful of label-contaminated frames.

Slicing, de-labelling and curating the rest is the next piece of work.
