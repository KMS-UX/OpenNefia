# CLAUDE.md — Quantum Effect

**Read this file AND `PROGRESS.md` at the start of every session, then summarise your
understanding before writing any code.** This file tells you the rules. `PROGRESS.md`
tells you what already exists.

---

## 1. What this project is

Quantum Effect is a turn-based, systems-driven sci-fi RPG set in 2081 on First Earth,
built as a set of mods on a **pinned fork of the archived Lua/LÖVE OpenNefia**
(`Ruin0x11/OpenNefia`, `develop` branch).

The director is a non-coder. He makes scope and design decisions and verifies by
playing. You do architecture, drafting and implementation. This division is the whole
working model — respect it in both directions. Do not ask him to read code to answer a
question, and do not make a design or scope decision on his behalf.

**Desktop-first. Android is the eventual destination, not a deferral.** See §6.

---

## 2. The document set and canon order

When two documents disagree, the one higher in this list wins.

1. `Quantum_Effect.txt` — the story document. Canonical for all fiction. Not yet
   present in this repo.
2. **Faction Bible** — content canon for the 17 factions. Present in this repo as
   `docs/quantum-effect/Quantum Effect Faction Bible.txt` (Draft v0.2, a "living
   document, update as decisions change" — re-check it hasn't moved past v0.2
   before treating a specific line as settled). `Quantum_Effect_Companion_Bible.docx`
   is the same canon rank but still not present in this repo.
3. `Quantum_Effect_Technical_Architecture.docx` — engine, format, persisted state.
   Not yet present in this repo.
4. `Quantum_Effect_Game_Design_Bible_v0_3.docx` — systems, numbers, rules. Not yet
   present in this repo.
5. `Quantum_Effect_Amendment_A_Systems_Pivot.md` — turn-based combat, systems-driven
   paradigm. Not yet present in this repo.
6. `Quantum_Effect_Amendment_B_Engine_Pivot.md` — the move to OpenNefia. Present at
   `docs/Quantum_Effect_Amendment_B_Engine_Pivot.md`.

**Amendments override the documents beneath them only where they say so explicitly.**
Amendment B supersedes most of the Technical Architecture's engine-specific sections
(§0, §1.1, §2.1, §3.2, §6.1, §7.1, §8.1–8.3). Everything else in TA still stands, and
all of the Faction Bible, Companion Bible and story document stand untouched.

If you find a genuine contradiction that no amendment resolves, **stop and report it**.
Do not pick a winner yourself.

**The real Faction Bible roster (2026-08-03): 6 story-tier + 10 functional-tier + 1
deferred = 17.** Story-tier: Ironward, Eclipse Syndicate, **Nova Collective**
(renamed from Void Seekers — the only rename in effect), Emberpact, Aurelian Order,
Synthic Faith. Functional-tier: Quantum Revolution, Enlighteners, Corporates,
Technopunks, Vagabonds, Silent Veil, Merchant Guild, Horizon Coalition, The
Curators, Exile Front. Deferred: Quantum Babies (referenced in dialogue/lore from
launch, not joinable). The Faction Bible's own "Open items" section already has a
7×7 inter-faction attitude table (the 6 story-tier factions + Quantum Babies) with
6 named relationship tiers (Neutral/Skeptical/Alerted/Dislike/Curious/Mixed) —
this is almost certainly the "7×7 attitude matrix" §7's mod map and Amendment B
§6.2 refer to (the matrix's Ironward→Quantum Babies="Unknown" vs. Quantum
Babies→Ironward="Neutral" asymmetry matches Amendment B's explicit callout of "the
Ironward / Quantum Babies asymmetry" exactly). Build `qe_factions` from this table
when the time comes, not from a re-derivation.

**Open question, not resolved here — flag before building `qe_factions`:** the
Faction Bible's 6-tier vocabulary above is a *static baseline attitude* table
between factions. PROGRESS.md §4.2's carried-over acceptance tests instead
describe a *dynamic* reputation mechanic — numeric, "floors and locks," a
"Hostile" state, "Oathbreaker" — none of which appear anywhere in the Faction
Bible. These may be two complementary layers (static starting attitude +
dynamic player reputation that starts from it) or the acceptance tests may
predate this vocabulary and need updating — the missing Game Design Bible or
Companion Bible would likely settle it. Ask the director rather than guessing
when `qe_factions` is actually built; nothing depends on this yet.

**`docs/quantum-effect/` holds adjunct material that is not part of the numbered
chain above and outranks nothing in it.** Specifically:
- `AI_CONTEXT/QE_DESIGN_BIBLE.md.txt` — an early implementation-strategy sketch.
  Its "Scrap & Reskin Translation Matrix" (the clone-tweak approach) was elevated to
  canon on 2026-08-03 — see §3. Its "8 Gods → Factions" example named Quantum
  Revolution, Aurelian Order, Void Seekers and Synthic Faith — **correction,
  2026-08-03, now that the real Faction Bible is available: three of those four are
  genuine canonical faction names** (Quantum Revolution and Synthic Faith are real;
  Aurelian Order is real). Only **Void Seekers** is stale — renamed to **Nova
  Collective** per the Faction Bible's naming policy, before this doc was written.
  This doc is still not a canon source (it's not in the numbered list, and its
  "map 8 gods to factions" framing is illustrative, not a ruling), but don't repeat
  the earlier mistake of treating its faction names as invented — check the real
  roster above first. Its Mana/Compute-Power resource is still subordinate to D-22
  (§8), which defers a spendable resource until abilities exist.
- The design-system skill's companion portrait pointer files (`atom`, `echo`,
  `lumen`, `nia`, `rex` at the `VisualAssets/QuantumEffectDesignSystem/` root) name
  companions that **do not match** any name in the Faction Bible's companion
  cross-references (Drox/Ironward, Vayn/Nova Collective, Nix/Emberpact,
  Lyra/Aurelian Order, Elsi/Silent Veil, Grum/Merchant Guild, Quark/Synthic Faith —
  7 named, home-faction-confirmed companions, found 2026-08-03). Don't assume
  atom/echo/lumen/nia/rex art corresponds to any real companion without asking —
  treat it as unconfirmed until the Companion Bible surfaces or the director says
  otherwise. Relatedly: CLAUDE.md §9 defers "the other six companions," implying
  one of the 7 real companions above is in scope for launch — which one is not
  stated anywhere available to this repo. Ask, don't assume, before `qe_companions`
  is built.
- **RI-703, resolved 2026-08-03** (was an open placeholder in `qe_core`, see
  PROGRESS.md §1/§7): the Faction Bible's last "Open items" entry names it in full
  — "QuantumLab reflective instinct 703," a unique, evolvable prototype implant the
  player is told about by a bio-mechanical engineer at whichever faction they first
  contact after the prelude, gating the origin questline into the Lab Complex map.
  Narrative identity is now known; its stats/mechanical effect still aren't defined
  anywhere, so the `qe_core` slot stays data-only until that's designed.
- `Option A/B/C ... .txt` — pre-Amendment blueprints, superseded wherever Amendment A
  or B says so explicitly (e.g. Option A's four-resource model is cut to two by
  D-22). PROGRESS.md §6 records where their illustrative API calls turned out to
  differ from the real engine. Read them for structure, not for locked numbers.

---

## 3. Hard constraints

These are not preferences. Breaking one is a defect regardless of how well the code
works.

### L-1 — Mod isolation (AMENDED 2026-08-03 — director override)

~~Every `qe_*` mod depends on the `base` mod only. Never declare a dependency on the
`elona` mod.~~

**Overridden by the director on 2026-08-03.** The `quantum_effect` mod already
declares `dependencies = { elona = ">= 0" }` and clones `elona.*` chara templates
(`elona.warrior`, `elona.palmian_elite_soldier`, `elona.iron_maiden`, `elona.norland`,
`elona.tourist`). This was flagged as a hard-constraint violation and the director's
decision was to keep it — QE mods **may** depend on `elona` going forward.

The licensing rationale in Amendment B §2.2 (Elona's content derives from Elona's
original source, and shipping it inside a commercial product is exposure the project
cannot carry) still stands as written and was not rebutted — it just no longer blocks
day-to-day work. **Before any commercial release, this needs a real answer**: either
confirm the specific `elona.*` assets/data actually shipped are clear to distribute,
or strip the dependency before that build. Flag this again if a release is being
prepared and it hasn't been resolved.

You may still **read** `src/mod/elona/` freely as a reference — that half of the rule
is unaffected.

### Clone-tweak — the default content strategy (added 2026-08-03)

**Elona already implements almost every system this project needs. The default move
for new content is to clone an existing `elona.*` prototype and retarget it as data,
not to design a parallel system from scratch.** This is not a fallback for when
something's too hard to build fresh — it's the primary strategy, and it's what makes
"unlimited possibilities from limited resources" actually true here: the turn
scheduler, ether-disease pipeline, god-relation reputation math, dungeon generation
and item-affix system are already-solved problems. `quantum_effect`'s existing
character work (`elona.warrior` → `kira`, `elona.iron_maiden` → `colossus`, etc.,
`src/mod/quantum_effect/data/chara.lua`) is the proven pattern: clone, rename, reskin,
done — verified end-to-end, not theoretical.

This still obeys **data over code**: cloning means `table.deepcopy` on a data
prototype instance, then editing fields — never copying or re-deriving Elona's Lua
logic. Reference-read Elona's *code* to understand a mechanism (§5); clone Elona's
*data* to get content. Where no existing Elona data is close enough to clone, only
then design new data from scratch.

The table below is the standing translation matrix — which Elona mechanic backs
which QE concept — elevated from `docs/quantum-effect/AI_CONTEXT/QE_DESIGN_BIBLE.md.txt`
to canon here. Only the *mechanism-reuse* pairing is canon; specific names, numbers
and resource counts in that source document are not (see §2).

| Elona mechanic | QE reskin | Status |
| --- | --- | --- |
| Ether / Etherwind (`src/mod/elona/api/Weather.lua`, `data/weather.lua`) | Quantum Flux / Quantum Storms | Not built |
| Ether disease / mutation pipeline (`src/mod/elona/api/Effect.lua`) | Quantum Corruption — the mechanism behind `qe_core`'s contamination resource | Contamination exists in `qe_core` as a resource; not yet wired to this pipeline |
| Positive mutations, same pipeline | Quantumize / Overclocking — a buff that drains a resource like a curse | Not built. Which resource it drains is an open design question, not locked |
| Gods / god relations (`src/mod/elona/api/God.lua`, `data/god.lua`) | The reputation *mechanism* for faction standing — **not** Elona's 8 gods or new faction names. `qe_factions`' actual 17 factions and 7×7 matrix (Faction Bible, canon rank 2) are unaffected | Not yet wired to `qe_factions` |
| Magic / Mana | "Protocols" / Compute Power, a spendable resource | **Deferred by D-22 (§8) — do not build as an active resource before abilities exist** |
| Overworld map (`src/mod/elona/events/world_map.lua`) | The Quantum Limbo — tile-by-tile inter-hub travel, player sprite as vessel | Not built. Candidate substrate for `qe_world`'s warp travel |
| Towns / Dungeons | Hub Zones / Ruined Labs | Matches `qe_world`'s existing hub design (Amendment B §5.1) already |
| Item enchantment/affix generation | Loot affixes | Already in §5's reference-read table |

### No engine edits

**Do not modify any file outside `mod/qe_*/`.** If something appears to require an
engine change, stop and report what you found and why. An engine patch is a last
resort, taken deliberately by the director, and logged in `PROGRESS.md` when it
happens.

### Data over code

Every value a designer would tune lives in a data prototype field, never as a literal
inside a function. A faction is data. An implant is data. A warp route is data. A
dialogue condition is data.

The test: **can the director change this number without an AI in the room?** If not,
it is in the wrong place.

### No expression parser

Dialogue and gating conditions use `ConditionData`-shaped records only —
`{ source_type, key, operator, value }` — arrays ANDed together. This is a hard
constraint carried over from the Game Design Bible §13.2, and it is the single most
important "don't over-build it" note in the project. Roughly forty lines to evaluate.
Do not build an expression language.

### Don't guess the API

Where the OpenNefia API is uncertain, **find the answer by reading the engine source
or `src/mod/elona/`**, and cite the file and function you relied on in a comment. Do
not invent plausible-looking calls. The design documents were written before the
engine was inspected and their API examples are illustrative, not real.

---

## 4. Working discipline

- **One system at a time.** Never "combat and inventory and dialogue". Build it,
  verify it, commit it, then start the next.
- **Verify by playing, not by reading.** Every task ends with acceptance tests written
  in plain language that the director can run himself on desktop.
- **Commit before every session and again the moment something works.** This is what
  makes AI-assisted development recoverable rather than fragile.
- **Protect the golden path.** Once a system passes playtest it is frozen. Do not
  refactor working code because you found a tidier structure. Tidier is worth nothing;
  working is worth everything.
- **STOP HERE checkpoints.** Tasks with an investigative first half stop and report
  before the building half. Do not run past a STOP HERE.
- **Update `PROGRESS.md`** at the end of every session: what was built, what was
  verified, and — importantly — **which API calls turned out to differ from what the
  design documents assumed.**

---

## 5. Reference-read protocol

Before implementing a system that Elona already solves, read its implementation first.
You are reading for *approach*, not for code to copy (L-1).

| Building | Read first |
| --- | --- |
| Anything, first session on the fork | `docs/ARCHITECTURE.md` |
| Any mod at all | `src/mod/base/` — data prototype registration, event API, save events |
| Turn order, action costs, speed | Elona's turn scheduler and action-cost handling |
| Damage and combat resolution | `src/mod/elona/api/Combat.lua` |
| Contamination (D-15) | Elona's ether disease and mutation pipeline — `src/mod/elona/api/Effect.lua` and related |
| The Warp generator (D-17) | Elona's Nefia / dungeon generation |
| Loot affixes | Elona's item enchantment generation |
| NPC death consequences (D-12) | Elona's karma, guard response and town reaction handling |
| Message log (A §1.6) | `Gui.mes()` in `src/api/Gui.lua` — confirmed **`base`, not `elona`**. No `qe_ui` reimplementation needed (found 2026-08-03, see PROGRESS.md §6) |

See also §3's clone-tweak translation matrix for content-level mappings (gods →
faction-reputation mechanism, overworld map → Quantum Limbo, weather → Quantum Flux)
with file citations.

Record what you learned in `PROGRESS.md` so the next session doesn't re-read it.

---

## 6. Platform

Desktop-first. But **every UI screen authored from now on is designed to the D-16
ceiling** — roughly 13 columns, no dense multi-pane menus, nothing that requires a
keyboard to operate.

Elona's UI is keyboard-driven and menu-dense. That density is exactly what D-16 exists
to stop us inheriting. Building desktop-only UI now and paying for it later is the
most likely way this project fails.

An Android packaging spike runs at Stage 3 to find out what is actually possible. Until
it reports, assume mobile is coming and design accordingly.

---

## 7. Mod map

| Mod | Owns |
| --- | --- |
| `qe_core` | Quantum Baby state, humanity, contamination, implants and slots, the QE event bus, debug commands |
| `qe_world` | Hubs, warp routes, warp gates, the world graph, `universe_id` keying, the Warp generator |
| `qe_factions` | 17 factions, the 7×7 attitude matrix, reputation, joining, betrayal, Oathbreaker |
| `qe_companions` | Companion data, affinity, party rules, recruitment |
| `qe_art` | All Quantum Effect graphics, tilesets and chips |
| `qe_ui` | Every QE screen, authored under the §6 ceiling |

Naming: data IDs are `qe_core.resource.humanity`, `qe_world.hub.slums`,
`qe_factions.faction.ironward`. Production art keeps the Guidebook convention —
`CHR_QB_001`, `PROP_WARP_GATE_001`, `UI_WARP_MENU_001`.

---

## 8. Locked design, in brief

The full reasoning is in the documents. This is the digest so you don't have to load
all of them for a small task.

**Combat (D-10).** Turn-based on the logical grid. Energy/initiative scheduler — each
actor accumulates energy at a rate set by its speed and acts at threshold. One action
per turn. Diagonals cost the same as orthogonals. **The world only advances when the
player acts.** Animation is decorative and never gates resolution. Damage is resolved
by function call against a target actor, never by area overlap.

**Message log (A §1.6).** Not optional. Every resolution writes one line: actor,
action, target, result, number. If something happened and the log doesn't say so, the
player will not know it happened.

**Paradigm (D-11).** Playtime is generated, story is accreted. **Every system must
read the state of at least two others.** The Episode 1 loop is the whole design in one
sentence: Warp run → loot and contamination → humanity shifts → faction attitudes
shift → prices and access shift → what you can afford to install → what you survive on
the next run.

**Killability (D-12).** The player can kill anyone. The world reacts; it never
refuses. `persistence_class` on NPC data — GENERIC / ROLE / NAMED / STORY — governs
what happens after. **Death records are written from build one**, seven fields per
record, even though the Restructure feature that consumes them ships much later.

**Humanity (GDD §4, D-15, D-22).**
`humanity = 100 − Σ(implant invasiveness) − Σ(skill humanity_delta) − contamination
+ Σ(narrative overrides)`. Four bands. **Humanity is a key, not a meter** — each band
opens some doors and closes others. Low humanity must never be strictly worse than
high. Combat power is never gated on humanity. There are **no other player resources**
— Sync Rate and Original Sin were rejected as resources (Amendment B §4).

**Universes (D-14).** A universe is a seed plus a delta, never a copy of the world.
World state is keyed `world[universe_id][zone_id]` **from the first build**.

**Warp zones (D-17).** Seeded, three tiers, ephemeral — generated on entry, discarded
on exit, never a persistent entry in the world dict. **Prefab-room injection is
required**: an authored story dungeon is a Warp zone with the dial turned to
hand-placed. A run must complete in ≤ 15 minutes; this is law.

**Expansion rules that still bind.** Zone registry is data, not code. Transitions
reference `zone_id` + `spawn_point_id` strings, never direct paths. Faction presence
is data, not level content. The architecture kit is layered — structural art shared,
zone palette, faction decals — so a new zone is roughly 15% new art.

---

## 9. Scope guardrails — do not build unless asked

Romance · personal quests · the ending sequence and the nine endings · the ship and
starships · pets · base building beyond three tier-1 modules · the other thirteen
factions' questlines · the other six companions · Wasteland, Undercity, Lab Complex as
persistent zones · Quantum Restructure · vision-cone occlusion · any stealth system
beyond a backstab multiplier · encumbrance · a second currency.

Several of these have **schema hooks reserved but no implementation** — `is_pet`,
`restructured`, `universe_id`, the ending archive. Reserve the field; build nothing
else.

If a task seems to need something on this list, stop and say so rather than building
a small version of it.

---

## 10. Blocking open items

| ID | Item | Effect |
| --- | --- | --- |
| **A-1** | ~~Real tile and chip dimensions unconfirmed~~ — **CLOSED 2026-08-03: 48×48.** See PROGRESS.md §7 | Production art unblocked. D-16's column-count arithmetic (§6) still needs recomputing against the real 48×48 figure — not yet done |
| **D-21** | Whether the fork reaches Android at all | Answered by the Stage 3 spike — not yet run |

---

## 11. Git

- Pinned upstream commit. **Never chase upstream** — the base is archived and frozen,
  and that is a feature.
- Git LFS for PNG, Aseprite and `.blend`.
- Commit before every session, and again the moment something works.
- `git status` after a task should show changes only under `mod/qe_*/`. If it shows
  anything else, that is a defect to report, not to clean up silently.
