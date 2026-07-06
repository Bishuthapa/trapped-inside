Fresh angles, not covered before:

**Audio system needs a rethink (given how much we've patched it)**
- We've hand-wired sound consts three separate times now (`sword_slice`, `normal_enemy_hit`, `large_enemy_hit`, per-enemy `attack_sfx`). Worth consolidating into one `SfxLibrary` autoload with named play calls (`Sfx.play("hit_fatal")`) — next sound request becomes a one-line addition instead of another player.gd surgery.
- No footstep sound, no ambient level audio, no UI click feedback beyond menu buttons. Combat sounds are dialed in; the rest of the soundscape is silent.

**Save system — biggest missing piece**
- Zero persistence beyond volume settings. Close the game mid-level 2, you restart from level 1 every time. Even a simple "furthest level unlocked" flag in a save file changes replayability a lot. This is probably the single highest-value addition left.

**Difficulty/pacing data isn't tuned, it's guessed**
- All damage/HP/speed numbers were typed once and never playtested against each other (attack_damage 180 vs enemy hitpoints 180 = 1-shot kills everything, which may or may not be intended). Worth an actual balance pass with real numbers logged (time-to-kill per enemy type, hits-to-kill player) rather than eyeballed exports.

**No accessibility/options beyond volume**
- No key rebinding, no colorblind-safe indicators (red flash for both hurt and telegraph — same color, different meaning, could confuse), no way to reduce screen shake/hitstop for sensitive players. Small, cheap, meaningfully broadens who can play it.

**Testing gap**
- Every fix this session (goblin animation corruption, spawn_point bug, hitbox monitoring default) was a silent authoring mistake nobody caught until manual play. No automated scene-validation pass exists (e.g., "every enemy scene's blend space has exactly N points, no duplicates" or "every exported PackedScene resolves"). A short GDScript editor tool script that sanity-checks scene files before you play would've caught 2 of the 4 bugs we hit today automatically.

**Project hygiene**
- `assets/effects/Dead.png` + `effects/Dead.png` — duplicate binary assets still sitting in two folders (found earlier, never resolved since it's not code). Worth a cleanup pass on `assets/` vs root-level folders — the split naming convention (`assets/sprites` vs `scripts/`, `effects/`, `scenes/` at root) is inconsistent and will keep causing "which death.gd is real" confusion as content grows.
- No `.gitignore` check on `.godot/` cache or `user://` save data once that exists — worth confirming before the save system lands.

**Where I'd spend the next session, ranked:** save/progress persistence → SfxLibrary consolidation → a real damage-number balance pass → scene-validation script.