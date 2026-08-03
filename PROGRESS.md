# PROGRESS.md — Quantum Effect (OpenNefia build)

Living status log. Read this AND `CLAUDE.md` at the start of every session — this file
tells you what already exists; `CLAUDE.md` tells you the rules for building more.
Update the "Last updated" line and append to the session log after each session.

**Last updated:** 2026-08-03. `qe_core` (Stage 2) built and verified. Art pipeline
started on `assets/tiles/` (director-chosen priority): first real `base.map_tile`
entries wired (3 tiles), a new label-contamination failure mode found and
documented, ~275 more tiles files packed but not yet wired. The real Faction Bible
surfaced mid-session and is reconciled into `CLAUDE.md` §2 — real 17-faction
roster, the 7×7 matrix, RI-703's identity resolved, two open questions flagged
(reputation-vocabulary mismatch, which companion isn't deferred). See §1 and §9.

**Engine:** pinned fork of `Ruin0x11/OpenNefia` (Lua / LÖVE, archived upstream).
**Previous build:** Godot 4 + Summer Engine, frozen read-only as a data donor. See §4.

---

## 1. What's built and verified on this engine

**The fork runs on desktop.** Launches and plays.

**`src/mod/quantum_effect/` exists as a real, separate mod** (not edits to
`src/mod/elona/`) — the L-1 audit that was PENDING is resolved: it's the correct
pattern, one mod, not scattered edits. It currently declares an `elona` dependency
and clones `elona.*` chara templates; this was flagged as an L-1 violation and the
director overrode L-1 to permit it on 2026-08-03 — see `CLAUDE.md` §3, L-1. Revisit
before any commercial release.

Verified end-to-end (`verify --load-all-mods`, full desktop test suite — 316 tests,
and a clean boot on the Android emulator with correct on-map rendering):

- Player + 3 clone character sprites (`kira`, `trooper`, `colossus`) wired as real
  `base.chip` / `base.chara` entries, cloned from `elona.warrior`,
  `elona.palmian_elite_soldier`, `elona.iron_maiden` respectively. Quickstart
  defaults to the QE player sprite.
- 83 bestiary creatures wired into `base.chara` / `base.chip` data
  (`chara_creatures.lua`, `chip_creatures.lua`).
- Two icon atlases wired into real item data: a 184-chip icon library and a 40-item
  set (weapons/containers) (`chip_icon_library.lua`, `item_icon_library.lua`,
  `chip_icons.lua`, `item_icons.lua`).
- An art-extraction pipeline (`tools/quantum-effect/`: `pack_sprites.ps1`,
  `dekey_alpha.ps1`, `slice_contact_sheet.ps1`, `strip_bands.ps1`,
  `strip_caption.ps1`) that turns `VisualAssets/QuantumEffectDesignSystem/` raw
  reference art into game-ready sprite sheets. Validated against the full
  `bestiary/creatures/` set (83/84 clean) and `icons/` set (32/35 clean); failures
  are genuine low-contrast/no-gap source-art problems, documented in
  `tools/quantum-effect/README.md`, not tooling bugs.
- **3 real `base.map_tile` entries** (`quantum_effect.terrain_cracked_ground`,
  `_dirt`, `_cracked_stone`) — the first QE map tiles, not just chip/chara/item
  sprites, wired 2026-08-03 (`data/map_tile_terrain.lua`). 48×48, not the 48×96
  cell used elsewhere in this mod — `tile_layer.lua` draws every tile into one
  fixed cell size, confirmed before wiring rather than guessed. Verified with a
  real `map:clear()` + `map:tile()` round trip
  (`test/data/map_tile_terrain.lua`), not just data inspection. See §7 for the
  ~275 more `tiles/` files packed but not yet wired, and the label-contamination
  issue found along the way.

**`src/mod/qe_core/` exists** — Quantum Baby systems, built 2026-08-03, depends on
`base` only (no `elona`). Verified via `verify --load-all-mods` (loads cleanly
alongside all 43 other mods) and the full desktop test suite (327 tests, up from 316
— 11 new, 0 failed). Covers Stage 2's Definition of Done:

- **Contamination** — a `qe_core.resource` data instance (min 0 / max 100 / default
  0), directly mutable via `api/Resources.lua`'s `add_contamination(delta)`, clamped
  and firing `qe_core.on_contamination_changed`.
- **Humanity — deliberately never stored.** `Resources.get_humanity()` recomputes it
  every call from the CLAUDE.md §8 formula (100 − installed-augment invasiveness −
  contamination + narrative overrides; the "skill humanity_delta" term is wired in
  but always 0 today — no skill system exists yet to sum over). This is what
  "humanity is a key, not a meter" means in code: it can't drift from what produced
  it because it's never independently written.
- **Five augment slots** (`qe_core.augment_slot`): `neuro`, `limbs`, `spinal`
  unlocked by default; `torso_core`, `ri_703` locked. **`ri_703`'s narrative identity
  is now known (found 2026-08-03, see `CLAUDE.md` §2):** "QuantumLab reflective
  instinct 703," a unique evolvable prototype implant revealed by a bio-mechanical
  engineer right after the prelude, gating the origin questline into the Lab
  Complex map — from the Faction Bible's "Open items" section, not GDD §3.1 (still
  not in this repo). Its stats/mechanical effect are still undefined, so no augment
  targets the slot yet.
- **Three test augments** (`qe_core.augment`): `neuro_basic` (5 invasiveness),
  `limb_servo` (8), `spinal_reflex_booster` (6) — one per unlocked slot, proving
  install/uninstall/humanity-impact, not balance (Option A §1's own stated purpose).
- **Save persistence** — `save.qe_core`, mod-level (not player-keyed — this resolves
  the open question from §6 below), version field, populated on `base.on_init_save`.
  Round-trip covered by an actual `TestUtil.save_cycle()` test, not just inspection.
- **Debug command** — `F11` prints version/contamination/humanity/installed-slots via
  `Log.info` (visible in the `tools` mod's log widget, `ctrl+-` to show it, or the
  terminal). No dedicated "debug command" registry exists in the engine (confirmed by
  search); this uses the same `base.keybind` + `Gui.bind_keys` pattern
  `mod/tools/init.lua` uses for its own F12 menu.

**Deliberately not done, per Option A Milestone 9's own stated fallback**: augments
don't hook any real OpenNefia stat/turn system yet — no combat or stat system exists
in any `qe_*` mod for them to hook into. Their effect is currently limited to the
humanity formula. "Augment modifiers exist in QE state and are exposed through
API... acceptable, as long as it is documented" — documented here.

**This is still separate from the art-pipeline work above** — `qe_core` is systems,
`quantum_effect` is art, and they don't depend on each other. The Stage 0 `qe_test`
gate below was never built; `qe_core` proceeded past it by explicit director decision
(2026-08-03) rather than silently.

**Naming note:** everything above lives in one mod, `quantum_effect`, not the
`qe_core` / `qe_art` / etc. split in §7 below. The mod's own description calls this a
spike. Confirm before more content lands here whether it stays one mod, gets renamed
`qe_art` outright, or gets split now.

---

## 2. Stage 0 — validation gate

**SKIPPED by director decision, 2026-08-03.** A dedicated throwaway `qe_test` mod
was never built; `qe_core` (Stage 2, see §1) proves the same four things directly, as
real QE systems rather than a disposable exercise:

- [x] A mod loads with no errors and **no engine files modified** — `qe_core`
- [x] It registers custom data prototype types and instances — `qe_core.resource`,
      `qe_core.augment_slot`, `qe_core.augment`, `qe_core.event`
- [x] It initialises namespaced mod save data with a version field, and that data
      survives save → quit → reload — `save.qe_core`, covered by an actual
      `TestUtil.save_cycle()` test (`test/api/Core.lua`), not just inspection
- [x] It registers event callbacks that fire and write an observable line —
      `base.on_init_save` (event/save.lua) and the qe_core event bus
      (`on_contamination_changed`, `on_augment_installed`, `on_augment_uninstalled`);
      the F11 debug command writes an observable line via `Log.info`

Plus:

- [x] The L-1 audit of the existing reskin is complete — resolved 2026-08-03,
      `quantum_effect` is a real separate mod (correct pattern); its `elona`
      dependency is a separate, now-permitted issue (see §1, §9)
- [x] The real API calls used are recorded in §6 below, especially anywhere they
      differ from what the design documents assumed

---

## 3. Build path

| Stage | Work | Status |
| --- | --- | --- |
| 0 | Validation gate | **SKIPPED by director decision, 2026-08-03.** `qe_test`'s custom-prototype/save-roundtrip/event-callback proof was never built as its own mod — `qe_core` (Stage 2) exercises the same ground directly and is verified instead. Reskin audit is complete |
| 1 | Fork, freeze, harness — pin commit, Git LFS, this file and `CLAUDE.md` in place, Godot repo archived read-only | IN PROGRESS |
| 1.5 | **Close A-1** — read the real chip and tile dimensions, revise the asset spec | **DONE, 2026-08-03 — 48×48.** D-16 column arithmetic still needs recomputing against it |
| 2 | `qe_core` — Quantum Baby state, humanity, contamination, five implant slots, three test implants, save persistence, debug commands | **DONE, 2026-08-03.** See §1. Milestone 9 (real stat/turn hook) explicitly deferred — no stat system exists yet to hook |
| 3 | Android packaging spike — one session, answer written here whatever it is | NOT STARTED |
| 4 | `qe_world` — hubs, warp routes, warp gate, warp menu, map transition, `world[universe_id][zone_id]` from day one | NOT STARTED |
| 5 | `qe_factions` + `qe_companions` — ported data, propagation, join/betray, Oathbreaker, affinity | NOT STARTED |
| 6 | The interlock loop — Warp generator with prefab injection, contamination accrual, humanity gating prices and access | NOT STARTED |

Stage 6 is the point at which this is a game rather than a set of mods.

---

## 4. Carried over from the Godot build

The Godot project is **frozen read-only**. Its GDScript is gone; its data and its
acceptance tests are assets.

### 4.1 Data available for port

| Asset | Ports as | Effort |
| --- | --- | --- |
| 17 `FactionData` rows | Lua data prototypes | Mechanical — **the real roster + tiering is now readable in this repo**, `docs/quantum-effect/Quantum Effect Faction Bible.txt` (found 2026-08-03, reconciled in `CLAUDE.md` §2). Use it, not a re-derivation from the old Godot data |
| The 7×7 attitude matrix, including the Ironward / Quantum Babies asymmetry | Lua table | Mechanical — the Faction Bible's own "Open items" section has this table verbatim (6 story-tier factions + Quantum Babies), confirmed matching the asymmetry Amendment B calls out. **Write a conversion script, do not transcribe by hand** |
| Propagation deltas, five standing bands, Oathbreaker rule | ~20-line Lua functions | Small — **terminology mismatch found 2026-08-03, not yet resolved**: this row's language ("standing bands," "Oathbreaker," and elsewhere "Hostile" — see §4.2 below) doesn't appear anywhere in the Faction Bible, which instead defines a 6-tier static attitude vocabulary (Neutral/Skeptical/Alerted/Dislike/Curious/Mixed) for inter-faction relationships. Unclear whether these are two layers (static baseline + dynamic player reputation) or the acceptance tests predate the Bible's current terms. Ask the director when `qe_factions` is actually started — flagged in `CLAUDE.md` §2, not resolved by guessing |
| `DialogueTreeData` / `DialogueLineData` / `DialogueChoiceData` / `ConditionData` | Lua prototypes; the `{source_type, key, operator, value}` shape is unchanged | Mechanical |
| Zone registry rows | `qe_world.hub` prototypes | Mechanical |
| Embassy Row and Slums layouts | Reference only — maps are rebuilt in OpenNefia's map format | Level authoring |
| Art produced so far | Unknown until A-1 closes | — |

### 4.2 Acceptance-test library

These all passed on the Godot build. They are the regression suite for the port —
re-run each one against the new engine as the corresponding system lands. They are
written in plain language deliberately; the director runs them himself.

**Movement and actors**
- The player moves and the world reads correctly at every step.
- One shared actor template serves player, companion and enemy alike; a fix to one
  fixes all three.

**Enemy behaviour**
- An enemy notices the player at range and pursues.
- The enemy gives up after a grace period out of range, and resumes if the player
  returns in time.

**Combat and death**
- Damage flows one direction: the attacker builds a damage record and hands it to the
  target, who decides what happens. The attacker never touches the target's HP.
- Current HP lives on the actor instance, never on a shared data resource. *(This bug
  bit us once already on Godot — shared-resource HP corrupts across instances.)*
- Enemy death is terminal. Player death respawns at the last legitimate spawn point
  with systems restored.

**Zones**
- The zone registry is the single source of truth; transitions are string-keyed by
  `zone_id` + `spawn_point_id` and never by direct path.
- The same enemy template behaves identically in two different zones with zero rework.

**Dialogue**
- Condition-gated lines and choices appear and disappear correctly as state changes.
- Talking to an NPC suspends the actor properly through a real state transition, not
  an ad-hoc freeze flag.

**Factions**
- All 17 factions load; the 7×7 matrix matches the Faction Bible verbatim, asymmetries
  included.
- Unlisted or "Unknown" matrix pairs default to Neutral.
- Joining Ironward propagates deltas through the matrix to the other six story-tier
  factions, pushing Eclipse Syndicate to Hostile.
- Betraying Ironward floors and locks reputation, sets Oathbreaker, caps unjoined
  factions' attainable reputation, and blocks re-joining.
- Dialogue can gate on faction reputation and on whether a faction has been joined.

### 4.3 New tests this engine adds

- **L-1:** `git status` after any task shows changes only under `mod/qe_*/`.
- **Save round-trip:** every new persisted field survives save → quit → reload.
- **Message log:** every resolution writes one line — actor, action, target, result,
  number. If it happened and the log is silent, that is a defect.

---

## 5. Explicitly deferred — don't build unless asked

Everything in `CLAUDE.md` §9, plus, from this phase specifically: quest system
(Ironward's join/betray rode on dialogue-choice effects as a stand-in on the old
build and may do so again), reputation HUD, traitor-hook scene content, skill tree,
abilities, crafting, and the companion-departure check on betrayal (a stub on the old
build).

---

## 6. Engine findings

*Record here every place the real OpenNefia API differs from what the design documents
assumed. The Option A/B/C blueprints were written before the engine was inspected and
their code examples are illustrative, not real. This section is how the next session
avoids rediscovering the same things.*

Findings so far, from `src/mod/quantum_effect/` (art-pipeline spike, not the
`qe_test` mod — that gate is still unbuilt, see below):

- **Chip cell size is 48×48**, not the Godot-era 16×16 assumption. Confirmed by
  testing against real source art; see `tools/quantum-effect/README.md` "Cell size:
  settled at 48×48". This closes A-1 — see §7.
- **`config` and `data` are mod-context globals inside a mod's `init.lua`** — no
  `require` needed. `require("internal.config")` fails from mod code with "cannot
  load path"; internal engine modules aren't reachable that way. See
  `mod/cheat/init.lua`'s `config.base.themes` for the same pattern.
- **A runtime `config.base.x = y` assignment in `init.lua` does not survive to
  actual gameplay.** Every real boot runs `game/startup.lua`, which unconditionally
  calls `config_store.clear()` then `config_store.load()` before anything reads
  config — `clear()` wipes whatever a mod set earlier, and `load()` only restores a
  save file, which doesn't exist on a fresh install. To change an effective default,
  edit the `base.config_option` entry's `default` field instead, via
  `data["base.config_option"]:edit(name, func)` — see
  `src/mod/quantum_effect/init.lua` and the pattern it copied from
  `mod/base/init.lua`'s `data["base.effect"]:edit(...)`.
- OpenNefia sends any non-`.bmp` image straight to `love.graphics.newImage` (see
  `src/internal/bmp_convert.lua`), so PNG sprite sheets with real alpha work directly
  — no Elona-style key-colour BMP needed.

Findings from `src/mod/qe_core/` (2026-08-03), answering every question this section
used to list as outstanding — the `qe_test` mod that was meant to answer them was
skipped (§2), `qe_core` answered them directly instead:

- **Custom data prototype types**: `data:add_type{name=..., fields={...}}`
  (`src/internal/data_table.lua:180`). The type id is auto-namespaced from the
  calling mod (`data_table.lua:194-195`) — a mod can't choose its own prefix, it's
  always `<mod_id>.<name>`. Field types come from the `types` global (`types.int`,
  `types.string`, `types.boolean`, `types.uint`, `types.optional(...)`,
  `types.data_id("other.type")`, etc.) — see `data/qe_core/*.lua` for real usage.
- **Save/load event names**: only one exists — `base.on_init_save`, triggered once
  per **new game** by `src/game/field_layer.lua:84-90`
  (`field_layer:init_global_data`). There is **no separate "on save loaded" event**
  and **no version-migration mechanism anywhere in the engine** (confirmed by
  search) — `qe_core`'s `version` field is written but nothing reads it yet; a real
  migration path is `qe_core`'s own problem to build if/when the schema changes
  after a save exists in the wild.
- **Mod save data namespacing**: the global `save` table, e.g. `save.qe_core.foo =
  ...` — auto-namespaced per mod (`src/internal/save_store.lua`), populated inside a
  `base.on_init_save` handler under `event/save.lua`. This IS mod-level, not
  player-keyed, and there's no built-in alternative for "keyed to the player" — the
  blueprint's suggestion to confirm this turned out to be moot, mod-level is simply
  what the engine gives you. `qe_core` uses it as-is (one Quantum Baby protagonist,
  so this was never actually a design choice with a real alternative).
- **Message log**: `Gui.mes()` lives in `src/api/Gui.lua` — **`base`/core engine, not
  `elona`.** The open question in prior sessions ("`base` or `elona`?") is answered:
  `base`. No `qe_ui` reimplementation is needed for this.
- **Debug commands**: no dedicated registry exists anywhere in the engine (confirmed
  by search). The established pattern is a `base.keybind` entry wired through
  `Gui.bind_keys{...}` — same mechanism `mod/tools/init.lua` uses for its F12 debug
  menu. Separately, the in-game Lua REPL (`src/api/Repl.lua`) auto-exposes every
  public `api/`/`mod.*.api` function by name with zero registration needed, so any
  API function is already a de-facto debug command from the console.
- **Custom mod-owned events** (for the "QE event bus" `qe_core` owns per CLAUDE.md
  §7): `Event.register`/`Event.trigger` refuse an `event_id` that isn't already a
  `base.event` data entry (`src/api/EventHolder.lua`, `check_event`, line 34-40) —
  so a mod must `data:add{_type="base.event", _id=...}` before it can register or
  fire its own event. (`Event.create(id, types, desc)` in `src/api/Event.lua:77-89`
  wraps exactly this, but it's unused anywhere in the codebase, so `qe_core` used the
  explicit `data:add` form instead — see `data/qe_core/event.lua`.)
- **Test harness has a real save-cycle helper**: `TestUtil.save_cycle()`
  (`src/api/test/TestUtil.lua:39-42`) does an actual `Save.save_game` /
  `Save.load_game` round trip against a throwaway test save — used to verify
  `qe_core`'s persistence for real rather than by inspection (`test/api/Core.lua`).
- `math.clamp(value, min, max)` (`src/ext/math.lua:9`) is a global extension,
  useful for exactly the kind of resource clamping `qe_core.resource` needs.

---

## 7. Open decisions

- **A-1 — tile and chip dimensions. CLOSED, 2026-08-03: 48×48.** Tested against real
  QE source art (authored at roughly 25×40); 48×48 lands near 1:1 with no
  magnification artifacts. See `tools/quantum-effect/README.md`. Production art is
  now unblocked. D-16's UI column arithmetic still needs recomputing against the real
  48×48 figure (it was derived assuming 16×16 in a 640×360 viewport) — not yet done.
- **D-21 — does the fork reach Android at all?** Answered by the Stage 3 spike, not
  by argument. Three outcomes, all useful; write whichever one happens here.
- **Warp run reward curve** — what makes run #20 worth doing. The genuine design risk
  of a systems game. Answer before the generator is tuned, not before it is built.
- **Contamination upper bound** — is a fully-Quantum player a valid end state? Story
  question, thematically loaded.
- **`ri_703` — RESOLVED 2026-08-03.** No longer an undefined placeholder; its
  narrative identity is now known from the Faction Bible's "Open items" section
  ("QuantumLab reflective instinct 703"). See §1. Its stats/mechanical effect are
  still undefined — that part is still open, just not the "what is it" part.
- **Artwork still awaiting extraction — corrected scope, 2026-08-03.** The previous
  entry here mis-described the layout: `atom`, `commerce`, `culture`, `echo`,
  `engineering`, `entertainment`, `food`, `government`, `lumen`, `medical`, `nia`,
  `nomad`, `outlaw`, `religion`, `rex`, `science`, `security` are **not folders** —
  they're one-line pointer files (e.g. `atom` contains the text
  `assets/characters/companions/atom.png`). `atom`/`echo`/`lumen`/`nia`/`rex` point
  at **companion** portraits; the rest point at **profession** portraits. **Correction,
  2026-08-03:** these five names do NOT match any of the 7 real companions now known
  from the Faction Bible (Drox, Vayn, Nix, Lyra, Elsi, Grum, Quark — see `CLAUDE.md`
  §2) — don't assume this art is usable for `qe_companions` without confirming the
  correspondence first. Also worth knowing:
  `VisualAssets/QuantumEffectDesignSystem/` is structured as an actual Claude Skill
  (`SKILL.md`, `name: quantum-effect-design`, `user-invocable: true`) — inert as a
  skill since it lives outside `.claude/skills/`, but that's what it is.

  The real content root is `assets/`: `bestiary` (83, `creatures/` done 83/84,
  `bosses/bossclass/featured/highthreat/` untouched), `characters` (643,
  `sprites/` done for 4 actors, rest untouched), `icon-library` (763, 184 chips + 40
  items done), `icons` (70, 32/35 clean), `tiles` (557 — **partially started this
  session, see below**), `environments`/`worldmap` (111/53, sampled files are
  single "key art" illustrations like `bestiary/bosses/`, not pipeline-ready — no
  slicer exists for that shape yet), `fx`/`dungeon`/`data` (81/18/16, untouched).
  None of it blocks `qe_core` systems work. `components/`, `tokens/`, `templates/`,
  `ui_kits/`, `guidelines/`, `exports/`, `scraps/`, `uploads/` are the skill's own
  scaffolding (React components, CSS tokens, HTML templates, the 61 original
  uploaded reference sheets) — not pixel art for this pipeline.

  **`tiles/` — director-chosen priority, started 2026-08-03.** All 6 subfolders
  (terrain/building/objects/decor/interior/vehicles, ~278 files) packed via
  `pack_sprites.ps1` with no new tooling needed (same shape as `icons/` — already
  individually cropped, real alpha). Found a new failure mode along the way: every
  subfolder has 2-4 files that are pure category-header text ("WALLS", "DOORS /
  GATES", "MISC", "ROCKS / STONES"...) mixed in among the real art — not a caption
  *on* real content (that's `strip_caption.ps1`'s job), a whole separate file
  that's *only* text. No reliable automated filter found; confirmed by eye using
  annotated, zoomed copies of each sheet — full account in
  `tools/quantum-effect/README.md`. Only 3 files are actually wired into game data
  so far (`quantum_effect.terrain_cracked_ground/dirt/cracked_stone`, real
  `base.map_tile` entries, verified via a real `map:clear()` test — see
  `src/mod/quantum_effect/test/data/map_tile_terrain.lua`). The other ~275 packed
  tiles files, and all of building/objects/decor/interior/vehicles, are sitting in
  `tools/quantum-effect/out/` (gitignored) untriaged — real remaining work, not
  something this session's pass quietly finished.

  Bring the rest of this up with the director when it's actually needed — before
  `qe_art` is built for real, or whenever a task needs a specific category (UI
  chrome for `qe_ui`, faction iconography for `qe_factions`, the rest of `tiles/`
  once `qe_world` needs more than 3 floor textures) — rather than defaulting to
  "do more art now."

---

## 8. Suggested next step

`qe_core` (Stage 2) is done and verified — see §1, §9. Candidates for what's next:

- **Stage 3 — Android spike.** Amendment B's own build order puts this right after
  `qe_core`, before `qe_world`.
- **`qe_world`** (Stage 4) — hubs, warp routes, warp gate, `world[universe_id][zone_id]`
  keying.
- **Hook `qe_core` into a real stat/turn system** — the deferred half of Option A's
  Milestone 9 (see §1), once there's a stat system in a `qe_*` mod worth hooking.
- **Resume the art pipeline** — see the "Artwork still awaiting extraction" item in
  §7. Only worth picking up when a specific category is actually needed by whatever's
  built next, not as a default.

Don't silently pick one — ask the director, per how this session's earlier decisions
went.

---

## 9. Session log

- **Engine pivot decided.** OpenNefia (Lua/LÖVE) fork replaces Godot 4 + Summer.
  Amendment B issued. Rule L-1 established. Resource model confirmed as humanity +
  contamination only; Sync Rate and Original Sin rejected as resources. Prototype
  content ordered: Slums → warp gate → Quantum Lab Ruins as the first prefab-injected
  Warp zone → Embassy Row. A-1 raised as blocking all art.
- **Stage 1 harness written** — this file and `CLAUDE.md`.
- **Reskin audit resolved, A-1 closed, L-1 overridden (2026-08-03).** The
  `quantum_effect` mod is confirmed to be a real separate mod (not edits to
  `src/mod/elona/`), resolving the PENDING AUDIT from Stage 0's Task 1. It declares
  an `elona` dependency and clones `elona.*` chara templates; flagged as an L-1
  violation, and the director's decision was to override L-1 and allow the
  dependency going forward (`CLAUDE.md` §3, L-1 — revisit before any commercial
  release). A-1 closed at 48×48, unblocking production art. This session also found
  that substantial art-pipeline work (4 character sprites, 83 bestiary creatures, 2
  icon atlases, a 5-script extraction pipeline) had already been built and verified
  across 5 commits without this file being updated to reflect it — brought current
  now.
- **`qe_core` built, Stage 0's `qe_test` explicitly skipped (2026-08-03).** Director
  decision: skip the throwaway `qe_test` mod and build `qe_core` directly. Delivered:
  `qe_core.resource` (contamination, data-driven min/max/default),
  `qe_core.augment_slot` (5 slots — neuro/limbs/spinal unlocked, torso_core/ri_703
  locked), `qe_core.augment` (3 test implants), a computed (never-stored)
  `Resources.get_humanity()`, install/uninstall via `api/Augments.lua`, a
  `qe_core.on_*` event bus, save persistence via `save.qe_core` verified with a real
  `TestUtil.save_cycle()` round trip, and an F11 debug command. 11 new tests, all
  passing; `verify --load-all-mods` and the full suite (327 tests, was 316) both
  clean. Depends on `base` only. Answered every question §6 had previously listed as
  outstanding (data-type registration, save event names, mod-vs-player-keyed save
  data, message-log location, debug-command pattern) — see §6 for the answers.
  `ri_703` slot created but left an undefined placeholder (flagged, not invented —
  see §7). Artwork extraction is far from complete and was explicitly logged, not
  worked on this session (see §7) — most of `VisualAssets/QuantumEffectDesignSystem/`
  hasn't been through the pipeline yet.
- *(next: see §8 — Stage 3 Android spike, `qe_world`, the deferred Milestone 9 stat
  hook, or resuming the art pipeline are all live options. Ask the director rather
  than picking.)*
- **Clone-tweak elevated to canon; CLAUDE.md staleness pass (2026-08-03).**
  Director asked for useful content from `docs/quantum-effect/` to be integrated
  into `CLAUDE.md` to settle what's actually canonical, citing "clone-tweaking"
  existing Elona assets as key architecture. `CLAUDE.md` §3 now has a dedicated
  "Clone-tweak" subsection with a standing Elona-mechanic → QE-reskin translation
  matrix (gods → faction-reputation mechanism, weather → Quantum Flux, overworld map
  → Quantum Limbo, mutation pipeline → Quantum Corruption/Quantumize), sourced from
  `AI_CONTEXT/QE_DESIGN_BIBLE.md.txt`. That source's specific content proposals were
  explicitly **not** elevated — its "8 Gods → 4 named Factions" example conflicts
  with the real 17-faction Faction Bible content and is marked illustrative-only in
  `CLAUDE.md` §2, and its Mana/Compute-Power resource stays subordinate to D-22's
  deferral. While in there, fixed two things `CLAUDE.md` still had stale from before
  this session: §10 said A-1 was still open (it closed at 48×48 last session) and §5
  told readers to go locate the message log (already found — `base`, not `elona`).
- **Art pipeline started on `tiles/`, director's chosen priority (2026-08-03).**
  Corrected a mistake from two sessions ago first: the 17 "categories" logged as
  untouched (`atom`, `commerce`, ...) were never folders, just one-line pointer
  files to companion/profession portraits — see §7. Also found
  `VisualAssets/QuantumEffectDesignSystem/` is an actual (inert) Claude Skill
  package, not a plain asset dump.
  Packed all 6 `assets/tiles/` subfolders (~278 files, ~557 counting `.import`
  siblings) with the existing `pack_sprites.ps1` — no new tooling needed, same
  shape as `icons/`. Found a new problem doing it: every subfolder has a handful
  of files that are pure section-header text ("WALLS", "MISC", "ROCKS / STONES")
  mixed in with the real art, distinct from the already-known baked-caption
  problem. No reliable automated filter — triaged by eye instead using annotated,
  zoomed sheet copies. Full account in `tools/quantum-effect/README.md`.
  Also learned map tiles need `-Cell 48` square, not the `-CellHeight 96` this
  mod's chip work uses for tall subjects — `tile_layer.lua` draws every tile into
  one fixed cell size, checked before wiring rather than found by trial and error.
  Shipped: 3 real `base.map_tile` entries (unambiguous clean ground textures),
  verified with an actual `map:clear()` test, not just data inspection. `verify
  --load-all-mods` and the full suite (329 tests, was 327) both clean.
  **Not done**: the other ~275 packed tiles files (labels not triaged for most of
  them) and all of building/objects/decor/interior/vehicles sit in
  `tools/quantum-effect/out/` (gitignored), packed but not copied into the mod or
  wired into data. This was a deliberate stop, not a time-boxed cutoff — wiring
  untriaged label-contaminated art as if it were real game content would ship
  "WALLS"/"MISC" text as game objects, which is worse than wiring less.
- **Real Faction Bible found and reconciled (2026-08-03).**
  `docs/quantum-effect/Quantum Effect Faction Bible.txt` (Draft v0.2) appeared in
  the repo mid-session, unannounced. Read in full and reconciled into `CLAUDE.md`
  §2, which is now the source of truth for this — summary here, not a duplicate:
  - The real 17-faction roster (6 story-tier / 10 functional-tier / 1 deferred) and
    the 7×7 inter-faction attitude matrix are now readable in-repo, not just
    referenced abstractly. Confirmed this is the matrix Amendment B §6.2 and
    `CLAUDE.md` §7 have been citing all along — the Ironward/Quantum Babies
    asymmetry it calls out matches exactly (Unknown vs. Neutral).
  - **Corrected a mistake from last session's `CLAUDE.md` edit**: I had flagged
    AI_CONTEXT's "8 Gods → Quantum Revolution, Aurelian Order, Void Seekers,
    Synthic Faith" example as entirely illustrative/non-canonical, contradicting
    the real Faction Bible. Wrong — 3 of those 4 are genuine canonical faction
    names (Quantum Revolution, Aurelian Order, Synthic Faith); only Void Seekers is
    stale, renamed to Nova Collective before that doc was written. I made this
    claim without having the real document to check against; now corrected in
    `CLAUDE.md` §2 rather than left standing.
  - **RI-703 resolved**: "QuantumLab reflective instinct 703," a unique implant
    revealed after the prelude that gates the origin questline — closes the
    placeholder flagged in `qe_core` two sessions ago. See §1.
  - **Two things flagged, not resolved, because nothing depends on them yet**:
    (1) the Bible's static 6-tier attitude vocabulary doesn't match the dynamic
    "Hostile"/"Oathbreaker"/"standing bands" language in this file's own §4.1-4.2 —
    unclear if these are two layers or the acceptance tests are stale; (2) the
    design-system's companion portrait pointers (atom/echo/lumen/nia/rex) don't
    match any of the 7 real companion names the Bible cross-references
    (Drox/Vayn/Nix/Lyra/Elsi/Grum/Quark) — don't treat that art as usable
    companion art without confirming first. Both need the director or the still-
    missing Companion Bible/GDD to settle, not a guess. Ask before `qe_factions` or
    `qe_companions` is actually built — neither is started, so nothing is at risk
    from leaving these open right now.
