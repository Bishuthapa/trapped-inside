<h1 align="center">⚔️ Trapped Inside</h1>

<p align="center">
  <em>You wake up in a cage, deep under the earth.<br>
  The halls are full of goblins, warriors and lizardmen.<br>
  There is one way out: through all of them.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Godot-4.6-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white" alt="Godot 4.6">
  <img src="https://img.shields.io/badge/GDScript-100%25-355570?style=for-the-badge" alt="GDScript">
  <img src="https://img.shields.io/badge/Platforms-Windows%20%7C%20Web-2ea44f?style=for-the-badge" alt="Windows and Web">
  <img src="https://img.shields.io/badge/Gamepad-supported-orange?style=for-the-badge" alt="Gamepad supported">
</p>

<!-- TODO: drop a gameplay GIF here, e.g. docs/media/gameplay.gif -->

---

## 🗡️ What is it?

**Trapped Inside** is a fast top-down action game. Fight through three dungeon levels,
read your enemies, dodge at the last second and land the heavy hit.

It started as a college project and is now being rebuilt into a **roguelite**:
random rooms, upgrades after every fight, and a reason to run it one more time.

## ✨ Features

- **3-hit sword combo.** Two quick slashes and a heavy finisher that sends enemies flying.
- **Perfect dodge.** Dash through an attack at the last moment: time slows, your
  cooldown resets and your next hit lands for 1.5× damage.
- **Enemies that play differently.**

  | Enemy | How it fights | How to beat it |
  |---|---|---|
  | 🛡️ **Warrior** | Walks up and swings hard | Hit first, dash out, finish the combo |
  | 🏹 **Goblin** | Keeps its distance and throws | Sidestep the throw, then close in |
  | 🦎 **Lizardman** | Marks a red line, then charges | Dodge the charge and punish the stun |
  | 🗿 **Spear turrets** | Fire spears from the pillars | Keep moving |

- **Bosses** at the end of level 2 and level 3.
- **Feedback:** damage numbers, hit sparks, screen shake and a short freeze on kills.
- **Keyboard + mouse or gamepad**, with full menu navigation on a controller.
- **Saves your stats:** best time, wins, total kills and deepest level reached.
- **Accessibility options:** turn off screen shake and the slow-motion effects.

## 🎮 Controls

| Action | Keyboard / Mouse | Gamepad |
|---|---|---|
| Move | `W` `A` `S` `D` | Left stick / D-pad |
| Attack (press 3× for a combo) | Left mouse button | `X` / `RT` |
| Aim | Mouse cursor | Right stick (or the way you're moving) |
| Dash / dodge | `Space` | `A` / `RB` |
| Pause | `Esc` | `Start` |

> 💡 **Tip:** dash *into* an attack, not away from it. The perfect dodge only
> counts when you get hit during the start of the dash.

## 🏰 The dungeon

1. **The Cells:** clear the room, take the key, find the door.
2. **The Deep Halls:** deeper inside, the air gets colder, and a champion guards the exit.
3. **The Final Chamber:** survive the waves, then face the last champion. Win and you're free.

## 🚀 Play it

### From source
1. Install **[Godot 4.6](https://godotengine.org/download)**.
2. Clone the repo:
   ```bash
   git clone https://github.com/Bishuthapa/trapped-inside.git
   ```
3. Open Godot → **Import** → select `project.godot` → **Import & Edit**.
4. Press **F5**.

### Web build
```bash
cd build/web
python -m http.server 8000
```
Then open <http://localhost:8000>.

## 🗺️ Roadmap

The full plan is in [`docs/Roguelite-Plan.md`](docs/Roguelite-Plan.md).

- [x] **M0: Foundation.** Save system, sound manager, gamepad, accessibility options
- [x] **M1: Combat feel.** Combo, perfect dodge, enemy roles, balance pass
- [ ] **M1+:** shield enemy, bosses with several phases
- [ ] **M2: Roguelite runs.** Random rooms, pick 1 of 3 upgrades after each fight
- [ ] **M3: Meta progression.** A hub cell, bones currency, unlocks, story intro and ending
- [ ] **M4: Release.** Public playtests, itch.io launch

## 🛠️ Under the hood

| | |
|---|---|
| Engine | Godot 4.6, GL Compatibility renderer (runs on low-end PCs and in the browser) |
| Language | GDScript |
| Global systems | `PlayerData` (run state) · `SaveData` (progress + settings) · `Sfx` (sound) · `Juice` (hitstop, damage numbers, particles) · `AudioSettings` (volume) |

```text
trapped-inside/
├── assets/      sprites, tilesets, audio, fonts
├── docs/        design plan, balance numbers
├── effects/     projectiles, pickups, VFX scenes
├── global/      autoload singletons
├── scenes/      player, enemies, hazards, levels
├── scripts/     gameplay logic
└── UI/          menus, HUD, pause and end screens
```

**Balance numbers** for damage, HP and hits needed to kill each enemy are in
[`docs/Balance.md`](docs/Balance.md). Change them there first, then in code.

## 🤝 Contributing

Ideas, bug reports and pull requests are welcome.

1. Fork the repo and create a branch: `git checkout -b feature/my-idea`
2. Follow the [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) (`snake_case` functions and variables, `PascalCase` classes).
3. Open a pull request that explains what changed and why.

## 📜 License

No license has been chosen yet. Please contact the author before redistributing
or using this project commercially.

---

<p align="center">
  Made by <a href="https://github.com/Bishuthapa"><strong>Bishu Thapa</strong></a> with Godot 🖤<br>
  <sub>Find a way out.</sub>
</p>
