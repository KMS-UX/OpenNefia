# Quantum Effect — Amendment B: The Engine Pivot

*Cross-document amendment · Amends Technical Architecture v0.2, Game Design Bible v0.3 and Amendment A · Issued from the engine-pivot session*

*Canon order is unchanged: story document → Faction Bible / Companion Bible → Technical Architecture → Game Design Bible, with Amendment A and now Amendment B layered on top. This amendment overrides those documents only where it says so explicitly, and nothing else.*

---

## Why this amendment exists

Amendment A moved Quantum Effect from real-time action to turn-based grid combat, and from authored content to generated systems. Having made both changes, the game it describes is structurally an Elona-family roguelike — an energy-scheduled turn loop, a contamination system that behaves like ether disease, universal killability, seeded dungeons, affix loot, and faction standing that gates the world.

OpenNefia is a working implementation of most of that machinery in Lua. The director has ruled that the project moves onto it rather than rebuilding it in Godot.

**Nothing in the fiction changes.** No faction, companion, zone, theme or story beat is cut by this amendment.

**Nothing in Amendment A's design changes.** D-10 through D-18 all stand. What changes is the runtime that executes them.

**What is lost is code, not design.** The Godot build's verified systems — the scaffold, five autoloads, zone registry and `SceneRouter`, dialogue with `ConditionData`, the 17-faction reputation model with the 7×7 matrix, the Ironward join/betray pipeline, Embassy Row and the Slums — do not port as code. Their **data** ports directly, and their **acceptance tests** port unchanged.

---

## Changelog

| ID | Decision | Status | Effect on existing documents |
| --- | --- | --- | --- |
| **D-19** | Engine: Godot 4 + Summer → **OpenNefia (Lua / LÖVE) fork** | **LOCKED** | Supersedes TA §0, §1.1, §2.1, §3.2 (Godot column), §6.1, §7.1, §8.1–8.3 |
| **D-20** | **Mod isolation rule L-1** — `qe_*` mods depend on `base` only, never `elona` | **LOCKED** | New. Licensing and design constraint |
| **D-21** | Platform order: **desktop-first, Android gated by an early spike** | **LOCKED** | Amends D-18 and TA §1.2 |
| **D-22** | Resource model: **humanity + contamination hold.** Original Sin and Sync Rate rejected as resources | **LOCKED** | Confirms GDD §4 and A/D-15. New cut-register entries |
| **D-23** | Prototype content set and build order | **LOCKED** | Amends TA §4.4 build order, not its scope |
| **D-24** | Godot project **frozen as a data donor**, not deleted | **LOCKED** | New |
| **D-01** | Landscape orientation | **HOLDS** | Trivially true on desktop; still governs the mobile retrofit |
| **D-16** | UI at 3×, 13-column ceiling | **HOLDS as a design law**, implementation deferred | The ceiling still governs every UI authored from now on |
| **A-1** | **Tile and chip dimensions** — 16×16 / 64×64 asset spec is now unverified against the fork | **OPEN — BLOCKING ART** | Amends TA §3.2 and the Guidebook's file specs |

D-02 through D-09 and D-11 through D-15, D-17 stand as written or as amended by Amendment A.

---

## 1. D-19 — Engine

### 1.1 Ruling

**Quantum Effect is built as a set of mods on a pinned fork of the archived Lua/LÖVE OpenNefia (Ruin0x11/OpenNefia, `develop`).**

### 1.2 Why

- The turn scheduler, actor AI, inventory, item affixes, ether-disease pipeline, dungeon generation and save serialisation already exist and are the exact systems Amendment A specified building.
- Lua data prototypes plus event callbacks are a better authoring surface for AI agents than Godot's scene and resource formats: text files, no binary diffs, no editor dependency.
- Code hotloading and an in-game Lua REPL mean an agent can inspect live state and a non-coder can verify by reading a value rather than by feeling a frame.
- Validated in practice: the fork runs on desktop and has already accepted a small reskin batch.

### 1.3 What this replaces

| Document section | Status |
| --- | --- |
| TA §0 Stack ruling (Summer / Godot) | **Superseded.** Replaced by §1.4 below |
| TA §1.1 Compatibility renderer, §1.3–1.4 frame budgets | **Superseded on desktop.** Recomputed if and when D-21's spike passes |
| TA §2.1 viewport, stretch mode, integer scaling | **Superseded.** OpenNefia owns presentation |
| TA §3.2 atlas rules, §6.1 node structure, §6.6 modular characters | **Superseded in form, retained in intent.** See A-1 |
| TA §7.1 JSON save to `user://` | **Superseded.** Mod save data via OpenNefia's save events. The *schema* (TA §7.2, A §10) survives as table shape |
| TA §8.1 Godot folder layout, §8.2 data-over-code, §8.3 Summer workflow | **Superseded by §1.4.** The data-over-code principle survives and is strengthened |
| TA Risk T-01 (Summer cannot press play on a handset) | **Retired.** Replaced by T-02 and T-03 below |
| Everything in the Faction Bible, Companion Bible, story document | **Untouched** |
| Amendment A §1–§9 design rulings | **Untouched** |

### 1.4 Project structure

| Mod | Owns |
| --- | --- |
| `qe_core` | Quantum Baby state, humanity, contamination, implants and slots, QE event bus, debug commands |
| `qe_world` | Hubs, warp routes, warp gates, the world graph, `universe_id` keying, the Warp generator |
| `qe_factions` | 17 factions, the 7×7 attitude matrix, reputation, joining, betrayal, Oathbreaker |
| `qe_companions` | Companion data, affinity, party rules, recruitment |
| `qe_art` | All Quantum Effect graphics, tilesets and chips |
| `qe_ui` | Every QE screen, authored under the D-16 column ceiling |

Rules that survive the pivot intact and are restated here as binding:

- **Data over code.** Every tunable value is a data prototype field, never a literal in a function.
- **No engine files are edited.** Anything that cannot be done from a mod is a design problem first and an engine patch only as a last resort, recorded when it happens.
- **One system at a time. Verify by playing. Commit before and after every session.**
- **Protect the golden path.** Once a system passes playtest it is frozen; agents do not refactor working code for tidiness.

### 1.5 New risks

| ID | Risk | Mitigation |
| --- | --- | --- |
| T-02 | The base is unmaintained and alpha-quality, with open defects and no upstream fixes | Pin one commit. Never chase upstream. Every bug found is logged in `PROGRESS.md` as owned, not reported |
| T-03 | Mobile retrofit debt — Elona's UI is keyboard-driven and menu-dense, which is exactly what D-16 exists to prevent inheriting | D-21's early spike; D-16 enforced as a design law on every screen authored from now, even on desktop |
| T-04 | Agents reach for `elona` mod code because it is the nearest working example | L-1, restated in `CLAUDE.md` as a hard constraint with an explicit "read for reference, never depend" instruction |

---

## 2. D-20 — Rule L-1, mod isolation

### 2.1 Ruling

**Every `qe_*` mod depends on `base` only. No `qe_*` mod may declare a dependency on the `elona` mod, and no Elona data, graphics, sound or names may ship inside Quantum Effect.**

### 2.2 Why this is not a style preference

OpenNefia's own engine code is MIT-licensed and free to fork and ship commercially. The `elona` mod is a different matter: its content derives from Elona's original source and assets, and shipping it inside a commercial product is a licensing exposure the project cannot carry.

It is also the correct design rule independently. Quantum Effect is not an Elona variant. Inheriting `elona`'s content pulls in a fantasy economy, fantasy creatures and Elona's own balance assumptions, none of which belong in 2081 First Earth.

### 2.3 What "reference, never depend" means in practice

Agents **read** `src/mod/elona/` freely — it is the best available worked example of the engine's APIs, and Amendment A already identified the specific reads worth doing (turn scheduler, combat math, ether disease, dungeon generation, item affixes, NPC death consequences). Agents **write** the equivalent into `qe_*` mods as new Quantum Effect content.

### 2.4 Immediate consequence — the existing reskin

The reskin already performed must be audited. If it was done by replacing files under `src/mod/elona/`, it violates L-1 and must be redone as a `qe_art` mod before anything is built on top of it. If it was done as a separate mod, it is the correct pattern and becomes the seed of `qe_art`.

---

## 3. D-21 — Platform order

### 3.1 Ruling

**Desktop-first. Android remains the destination, not the deferral.**

Amendment A's D-18 is amended: itch.io ships a **desktop** build for Episode 1's early releases; the Play Store target moves behind the mobile spike.

### 3.2 The spike — non-negotiable and early

After `qe_core` exists and before `qe_world` is built, spend one session packaging the fork as a `.love`, building the LÖVE Android embed APK, and installing it on the Fold 6. The purpose is not a mobile build. The purpose is to learn, while the codebase is still small, whether the fork's native dependencies and launcher assumptions survive the trip at all.

Three outcomes, all useful:

- **It runs.** Mobile stays a retrofit, and the retrofit is scoped.
- **It runs badly** — unreadable UI, unusable input. Expected, and confirms that D-16's ceiling must govern every screen authored from now on.
- **It does not launch.** Then the project is a desktop game, and that is a decision made in month one rather than month twelve.

### 3.3 The standing rule this creates

**Every UI screen authored from today is designed to the D-16 ceiling** — roughly 13 columns, no dense multi-pane menus, no screen that requires a keyboard to operate. Building desktop-only UI now and paying for it later is the single most likely way this pivot fails.

---

## 4. D-22 — Resource model

### 4.1 Ruling

**Humanity and contamination hold, exactly as written in GDD §4 and Amendment A §6. No new player resources are added.**

```
humanity = 100 − Σ(implant invasiveness) − Σ(skill humanity_delta) − contamination + Σ(narrative overrides)
```

### 4.2 What is rejected, and why

| Proposed | Ruling | Reason |
| --- | --- | --- |
| **Sync Rate** | **CUT** | Duplicates the work humanity already does as a gate on implant installation. A second axis measuring "how much machine can you take" makes both axes weaker and doubles the balance surface |
| **Original Sin** | **CUT as a resource. RETAINED as fiction** | The story document's "growing tree of Original Sins" is the game's moral vocabulary and should appear throughout dialogue and the message log. Mechanically it is already expressed by the three ending axes plus death records. A fourth meter tracking sin would compete with humanity for the same design job |
| **Quantum Energy** | **DEFERRED, not cut** | If abilities need a spendable pool, that is an ability-system question for when abilities are built, not a protagonist resource to lock now |

### 4.3 Consequence for `qe_core`

Option A's Milestone list stands, with its four resources reduced to the locked model. The augment slot, install, uninstall, modifier-recalculation and save-persistence work is unaffected and remains the correct first build.

Implant slots follow GDD §3.1 — neuro, limbs, torso/core, spinal, plus the unique RI-703 — not the four-slot variant in the uploads.

---

## 5. D-23 — Prototype content and build order

### 5.1 Ruling

Both content proposals are accepted, sequenced so that each map earns its place by proving a system. The director's "as many as feasible" is honoured by ordering them so that cutting from the bottom costs the least.

| # | Map | Proves | Cut cost if dropped |
| --- | --- | --- | --- |
| 1 | **Slums** — hub, with the safehouse and its three tier-1 modules | The hub loop; ADAPT has somewhere to happen | Fatal. Not cuttable |
| 2 | **Warp gate + one route** | The world graph is data, not level content | Fatal. Not cuttable |
| 3 | **Quantum Lab Ruins** — authored as a **prefab-injected Warp zone**, not a hand-built hub | The Warp generator *and* Option B's route destination *and* D-17's prefab injection, in one map | High. This is the content engine |
| 4 | **Embassy Row** — four factions physically co-present | Communal-versus-open space; faction standing visible in how the world greets you | Moderate. Cut last, restore first |

**The important merge:** the uploads proposed Quantum Lab Ruins as a second hand-built hub. It is worth more as the first prefab-injected Warp zone. Amendment A §8.3 argues that a story dungeon and a random Nefia must be the same object, and this is the cheapest possible place to prove it. Same code path, same tileset, same generator, dial turned to hand-placed.

Everything else in Amendment A §12's Episode 1 list is unchanged.

### 5.2 What does not port

Embassy Row and the Slums exist as Godot scenes. Their **layouts** and **art** are reference material; the maps are rebuilt in OpenNefia's map format. This is level authoring, not engineering, and it is the one genuinely repeated piece of work in the pivot.

---

## 6. D-24 — The Godot project

### 6.1 Ruling

**Freeze it read-only. Do not delete it.** It is the project's data donor and its acceptance-test library.

### 6.2 What ports, and how

| Asset | Ports as | Effort |
| --- | --- | --- |
| 17 `FactionData` rows | Lua data prototypes | Mechanical conversion |
| The 7×7 attitude matrix, including the Ironward / Quantum Babies asymmetry | Lua table | Mechanical |
| Propagation deltas, standing bands, Oathbreaker rule | Lua functions, ~20 lines each as GDD §13.2 predicted | Small |
| `DialogueTreeData` / `DialogueLineData` / `ConditionData` | Lua prototypes; `ConditionData`'s `{source_type, key, operator, value}` shape is unchanged | Mechanical |
| Zone registry rows | `qe.world.hub` prototypes | Mechanical |
| Every acceptance test in `PROGRESS.md` | Unchanged, re-run against the new build | Free |
| Art produced so far | Pending A-1 | Unknown until A-1 closes |
| GDScript | Nothing. Rewritten | — |

Write the conversion as a one-off script rather than by hand where the row count justifies it — 17 factions and a 49-cell matrix is exactly the case where a transcription error is both likely and invisible.

---

## 7. A-1 — Tile and chip dimensions, OPEN and BLOCKING

The asset specification in the Guidebook and TA §3.2 — 16×16 tiles, 64×64 characters, 2048×2048 atlases, bottom-centre pivot — was derived from Godot's TileMap and atlas handling. OpenNefia inherits Elona's chip dimensions, which are **not** 16×16.

**This must be confirmed against the fork before any production art is made.** Getting it wrong means redrawing everything, and it is the cheapest question in this document to answer: read the base mod's tile and chip definitions and the map renderer's assumptions, and write the real numbers into a revised asset spec.

Until A-1 closes:

- No production art. Placeholder and reskin work only.
- D-16's UI figures are recomputed once the real chip size is known — the 13-column ceiling is a design law, but the arithmetic behind it assumed a 16×16 icon in a 640×360 viewport.
- Amendment A's closure of D-02 and D-09 stands regardless. Direction count and proportions remain cheap under turn-based combat whatever the chip size turns out to be.

---

## 8. Revised build path

| Stage | Work | Exit condition |
| --- | --- | --- |
| **0** | **Validation gate.** Partially passed — the fork runs and accepts a reskin. Remaining: a `qe_test` mod that touches no engine files, registers a custom data type, initialises and reloads mod save data, and registers an event callback | All four demonstrated, plus the L-1 audit in §2.4 complete |
| **1** | **Fork, freeze, harness.** Pin the commit, Git LFS, rewrite `CLAUDE.md` for Lua and L-1, add the reference-read stage (`docs/ARCHITECTURE.md`, `base` APIs, the Nefia generator), archive the Godot repo read-only | A new agent session can bootstrap from `CLAUDE.md` + `PROGRESS.md` alone |
| **1.5** | **Close A-1.** Read the real chip and tile dimensions; revise the asset spec | A written asset spec matching the engine |
| **2** | **`qe_core`.** Quantum Baby state, humanity, contamination, five implant slots, three test implants, save persistence, debug commands | Option A's Definition of Done, with D-22's resource model |
| **3** | **Android spike.** One session, per §3.2 | An answer, whatever it is, written into `PROGRESS.md` |
| **4** | **`qe_world`.** Hub prototypes, warp routes, warp gate, warp menu, map transition, `world[universe_id][zone_id]` keying from day one | Option B's acceptance criteria, plus: adding a hub is data entry |
| **5** | **`qe_factions` + `qe_companions`.** Ported data, propagation, join/betray, Oathbreaker, affinity, party cap 2 | The Godot build's faction acceptance tests pass on the new engine |
| **6** | **The interlock loop.** Warp generator with prefab injection; contamination accrual; humanity bands gating dialogue, prices and access | Amendment A §2.2's five-system circle closes without authored content |

Stage 6 is the point at which the project has a game rather than a set of mods.

---

## 9. Cut register additions

| Cut | Replaced by | Saved |
| --- | --- | --- |
| Sync Rate as a resource | Humanity as the single implant gate | A second meter and its whole balance surface |
| Original Sin as a resource | Ending axes, death records, and narrative vocabulary | A fourth persisted axis competing with humanity |
| Godot 4 + Summer Engine | OpenNefia fork | Rebuilding the turn scheduler, actor AI, inventory, affixes, dungeon generation and save serialisation |
| Dependency on the `elona` mod | Reference reads plus original `qe_*` content | A licensing exposure and an inherited fantasy economy |
| Second hand-built hub (Quantum Lab Ruins) | The same map as the first prefab-injected Warp zone | One authored map, and it proves more |

---

## 10. Still open

| ID | Question | Note |
| --- | --- | --- |
| **A-1** | Real tile and chip dimensions | **Blocking all art.** Cheapest question here; answer it in Stage 1.5 |
| **D-21** | Does the fork reach Android at all? | Answered by the Stage 3 spike, not by argument |
| **NEW** | How is the message log (A §1.6) implemented on this engine? | Elona has one; confirm whether it is `base` or `elona` and, if the latter, budget writing a `qe_ui` equivalent |
| **NEW** | Warp run reward curve — what makes run #20 worth doing | Carried forward from Amendment A. Still the genuine design risk |
| **NEW** | Does contamination have an upper bound? | Carried forward. Story agent |
| D-03 | Minimum device | Now dependent on D-21. Defer until the spike answers |
| GD-05, GD-07 | Level cap, party cap | Default to confirm |

---

## Appendix — Stage 0 completion brief for Claude Code

```
Read CLAUDE.md and PROGRESS.md first and summarise your understanding before writing
any code.

Context: this is a pinned fork of the archived Lua/LÖVE OpenNefia. We are building
Quantum Effect as a set of qe_* mods on top of it.

HARD CONSTRAINT (rule L-1): qe_* mods depend on the `base` mod only. Never declare a
dependency on the `elona` mod. You may READ src/mod/elona/ freely as a reference for
how the engine's APIs are used. You may not depend on it, copy its data, or ship its
assets.

Second hard constraint: do not edit any file outside mod/qe_*. If something appears to
require an engine change, stop and report it rather than doing it.

TASK 1 — Audit
Report whether the existing reskin work modified files under src/mod/elona/ or created
a separate mod. Do not change anything yet; just report what you find and where.

STOP HERE. Wait for confirmation before continuing.

TASK 2 — qe_test mod
Create mod/qe_test/ demonstrating, in the smallest possible form, four things:

  1. The mod loads with no errors and no engine files modified.
  2. It registers one custom data prototype type and one instance of it.
  3. It initialises namespaced mod save data with a version field, and that data
     survives a save and reload.
  4. It registers one event callback that fires and writes an observable line.

Add a debug command that prints the mod's save state.

Where the exact OpenNefia API is uncertain, find the answer by reading the engine
source or src/mod/elona/ rather than guessing, and cite the file and function you
relied on in a comment.

ACCEPTANCE TESTS — I will run these myself on desktop:
  - The game launches with qe_test enabled and no error output.
  - The debug command prints the save state.
  - Saving, quitting, reloading and re-running the debug command prints the same
    state including the version field.
  - `git status` shows changes only under mod/qe_test/.

Update PROGRESS.md with what was built, what was verified, and the exact API calls
that turned out to be different from what the design documents assumed.
```
