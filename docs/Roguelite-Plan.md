# Trapped Inside — Roguelite Upgrade Plan

Direction chosen: **roguelite runs**. Each run is a climb out of the dungeon through
randomized rooms. Clear a room, pick 1 of 3 upgrades, keep going. Death ends the run,
but some currency carries over for permanent unlocks.

## Core loop

```
Hub (the cage cell) ──► Floor 1 ──► Floor 2 ──► Floor 3 ──► Escape (win)
                         │
                         └─ 4 combat rooms → 1 elite/treasure room → mini-boss
                            after every room: choose 1 of 3 upgrades
```

- **Run length target:** 15–25 minutes for a win. One death = back to hub.
- **Floors** reuse the three existing level themes (stone halls, deep halls, final chamber).
- **Rooms** are small hand-made scenes (`RoomTemplate`) with spawn markers and exit doors.
  The game picks rooms at random per floor from a pool, so no two runs look the same.
- The current kill-all → key → door loop stays: it becomes "clear room → reward → door".

## Upgrades (in-run, lost on death)

Data-driven: each upgrade is an `UpgradeData` resource (`.tres`) with id, name, icon,
rarity, description and stat modifiers. Starting pool (~20):

| Type | Examples |
|---|---|
| Stats | +20% damage, +15% attack speed, +25 max HP, −20% dash cooldown |
| Sword | Wider swing, 3rd combo hit stuns, crits (10% for 2×), kills heal 5 HP |
| Dash | Dash damages enemies, dash leaves fire trail, 2 dash charges |
| Defense | Thorns (reflect 20%), one free revive, longer i-frames |
| Weapon | Spear throw as secondary attack (reuses `spear_projectile`) |

Rarity: common 70%, rare 25%, legendary 5%. One reroll per pick (more via unlocks).

## Meta progression (kept between runs, saved to disk)

- **Bones** currency dropped by enemies; banked on death or win.
- Spend in the hub on: new upgrades added to the pool, starting weapon choice (sword/spear),
  +1 reroll, +1 heart at start. Keep it light so player skill still matters most.
- Track best time, wins, total kills, deepest floor reached.

## Combat fixes that must land before content

1. **Balance pass.** Player 180 dmg vs enemy 180 HP = everything one-shots. Target 2–4 hits
   for normal enemies, 15–25 for bosses. Upgrades need room to feel meaningful.
2. **3-hit combo** with a heavier finisher.
3. **Dash i-frames already exist** — add a "perfect dodge" reward (brief slow-mo + bonus hit).
4. **Enemy roles:** Goblin = ranged thrower, Lizardman = charger, Base = melee bruiser,
   new Shield enemy = must hit from behind or after a dash.
5. **Real bosses:** 2–3 phases with readable telegraphs, one per floor.
6. Damage numbers + hit particles.

## Technical architecture

| Piece | Job |
|---|---|
| `SaveData` autoload | Meta progress, stats, accessibility settings → `user://save.cfg` |
| `Sfx` autoload | One place to play any sound: `Sfx.play("hit")` |
| `RunState` autoload | Seed, floor, room index, picked upgrades, bones this run |
| `PlayerStats` | Base stats + upgrade modifiers → final numbers the player reads |
| `RoomDirector` | Picks next room from pool, spawns enemies, opens doors on clear |
| `UpgradePicker` UI | Shows 3 cards, handles reroll, applies choice |
| `RoomTemplate.tscn` | Base room: tilemap, `SpawnPoints`, `PlayerStart`, `Exit` |

Seeded RNG (`RandomNumberGenerator` with stored seed) so runs can be shared and a
daily-seed mode is possible later.

## Milestones

### M0 — Foundation (in progress)
- [x] Design doc (this file)
- [x] Ignore export folders in git
- [x] `SaveData` autoload: run stats, best time, settings
- [x] `Sfx` autoload, gameplay sounds routed through it, slight pitch variation
- [x] Gamepad: move (left stick/d-pad), aim (right stick), attack (X/RT), dash (A/RB), pause (Start)
- [x] Screen shake / hitstop toggle (accessibility)
- [ ] Commit current work-in-progress (needs owner OK)

### M1 — Combat feel
- [x] Balance pass with numbers written down (see docs/Balance.md)
- [x] 3-hit combo + finisher, dash-cancel after the hit window
- [x] Perfect dodge (slow-mo, attack reset, next hit x1.5)
- [x] Damage numbers, hit particles
- [x] Distinct enemy behaviors (ranged goblin, charging lizard)
- [ ] Playtest and tune numbers in docs/Balance.md
- [ ] Shield enemy, multi-phase bosses

### M2 — Run structure (the roguelite itself)
- [x] `RunState` autoload: seed, picked upgrades, stat modifiers (player reads them directly, no separate `PlayerStats`)
- [x] `UpgradeData` + `UpgradeCatalog` (13 upgrades, defined in code in `global/upgrade_catalog.gd`)
- [x] Upgrade picker after each cleared room/wave: 3 cards, 1 reroll, mouse/keys/gamepad
- [x] Seeded runs; seed and upgrades shown on the end screens
- [ ] `RoomTemplate` + split existing maps into 8–10 rooms (needs room scenes built in the editor)
- [ ] `RoomDirector` with seeded room order
- [ ] Floor transitions + mini-boss per floor
- [ ] HUD list of current upgrades

### M3 — Meta + identity
- [ ] Hub cell scene, bones currency, unlock shop
- [ ] Short intro story (knight in a cage) + escape ending
- [ ] Lighting (torches with `PointLight2D`), ambient audio, footsteps
- [ ] Title screen polish

### M4 — Ship
- [ ] Playtest with 5–10 people, note where they quit or get confused
- [ ] itch.io web release + 30s trailer/GIF
- [ ] Post on r/godot, r/roguelites, itch devlog
- [ ] Decide on Steam based on feedback
