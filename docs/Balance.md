# Combat Balance

Reference numbers for tuning. Update this file whenever a stat changes so the
numbers stay checked against each other instead of guessed.

## Player

| Stat | Value | Where |
|---|---|---|
| HP | 200 (3 lives) | `global/playerdata.gd` |
| Light hit (combo 1, 2) | 60 | `player.gd` `attack_damage` |
| Finisher (combo 3) | 120 (2×), 2.2× knockback | `FINISHER_MULT` |
| Empowered hit (after perfect dodge) | ×1.5 → 90 / 180 | `EMPOWER_MULT` |
| Swing time light / finisher | 0.33 s / 0.48 s | `COMBO_TIME_SCALES` |
| Recovery after finisher | 0.35 s | `attack_cooldown` |
| Full combo | 240 dmg in ~1.15 s (+0.35 s recovery) ≈ 160 DPS | |
| Dash | 0.18 s, 1.2 s cooldown, i-frames | |
| Perfect dodge window | first 0.12 s of a dash | `PERFECT_DODGE_WINDOW` |

Old values for comparison: 180 dmg per swing, 0.85 s cooldown; warrior/goblin had
360 HP (2 hits), lizardman 140 HP (1 hit). Fights ended before enemies could act.

## Enemies — hits to kill

Level scaling: HP × (1 + 0.15 per level after 1), damage × (1 + 0.10 per level).
Level 3 waves use × (1 + 0.12 per wave).

| Enemy | Role | HP L1 | HP L2 | Hits to kill (L1 / L2) | Damage to player | Player hits to die |
|---|---|---|---|---|---|---|
| Warrior | melee bruiser | 240 | 276 | 3 / 4 (one combo) | 30 | 7 |
| Goblin | ranged, retreats | 150 | 173 | 3 / 3 | 20 (thrown) | 10 |
| Lizardman | charger, stunned after | 200 | 230 | 3 / 3 | 25 swipe, 35 charge | 6–8 |
| L2 boss (warrior) | | — | 736 | ~10 (3 combos) | 33 | 6 |
| L3 boss (warrior) | | 1340 | — | ~17 (6 combos) | 75 | 3 |
| Spear turret | hazard | | | | 40 | 5 |

Targets this table is checked against:
- Normal enemies die to one full combo, or a bit more on later levels.
- Bosses take 10–20 hits, so the player must dodge between combos.
- No single normal enemy can kill a full-HP player in under 6 hits.

## Tuning log
- Playtest 1: combo felt too slow. Swing speed 1.4/1.4/0.95 → 1.8/1.8/1.25, finisher recovery 0.45 → 0.35 s, buffer opens after 25% of a swing instead of 35%.

## Next tuning to do after playtesting
- If the combo feels slow, raise `COMBO_TIME_SCALES` before touching damage.
- If the L3 boss is too punishing at 75 per hit, lower `BOSS_EXTRA_DAMAGE` first.
- Record real time-to-clear per level from playtests here.
