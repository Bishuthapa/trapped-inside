# 𝕿𝖗𝖆𝖕𝖕𝖊𝖉 𝕴𝖓𝖘𝖎𝖉𝖊

<p align="center">
  <strong>A 2D action-adventure game built with Godot Engine 4.6 and GDScript.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Godot-4.6-blue?style=for-the-badge&logo=godot-engine" alt="Godot">
  <img src="https://img.shields.io/badge/Language-GDScript-478CBF?style=for-the-badge" alt="GDScript">
  <img src="https://img.shields.io/badge/Renderer-GL%20Compatibility-success?style=for-the-badge" alt="Renderer">
</p>

---

## Overview

**Trapped Inside** is a 2D game developed using **Godot Engine 4.6** and written entirely in **GDScript**.

The project uses Godot's **GL Compatibility Renderer**, allowing it to run efficiently across a wide range of hardware, including lower-end desktops and mobile devices.

---

## Project Structure

```text
trapped-inside/
│
├── assets/           # Sprites, textures, audio, fonts, and other assets
├── effects/          # Shaders, particles, and visual effects
├── scenes/           # Godot scene files (.tscn)
├── scripts/          # GDScript source files (.gd)
│
├── icon.svg
├── icon.svg.import
└── project.godot
```

---

## Technical Details

| Property | Value |
|-----------|---------|
| Engine | Godot 4.6 |
| Language | GDScript |
| Renderer | GL Compatibility |
| Physics Engine | Jolt Physics |
| Config Version | 5 |
| Windows Renderer | Direct3D 12 (d3d12) |

---

## Controls

| Action | Key |
|---------|-----|
| Move Up | `W` |
| Move Down | `S` |
| Move Left | `A` |
| Move Right | `D` |

### Combat

Aim using the mouse cursor and press the **Left Mouse Button** to attack in the desired direction.

---

## Getting Started

### Prerequisites

- Godot Engine 4.6

Download from: https://godotengine.org/download

### Clone the Repository

```bash
git clone https://github.com/Bishuthapa/trapped-inside.git
cd trapped-inside
```

### Open in Godot

1. Launch Godot Engine 4.6.
2. Click **Import**.
3. Select `project.godot`.
4. Click **Import & Edit**.

### Run the Game

Press **F5** or click **Run Project**.

---

## Running the Web Build

Navigate to the web build folder:

```bash
cd build/web
```

Start a local server:

```bash
python -m http.server 8000
```

Open:

```text
http://localhost:8000
```

---

## Development

### Folder Conventions

#### `scenes/`
Contains all game scenes (`.tscn` files), including levels, UI screens, and game objects.

#### `scripts/`
Contains all GDScript files (`.gd`) used for gameplay logic and systems.

#### `assets/`
Stores images, audio, fonts, and other resources used throughout the game.

#### `effects/`
Contains shaders, particle systems, and visual effect resources.

---

## Coding Style

- Language: **GDScript**
- Follow the official Godot style guide.
- Use `snake_case` for variables and functions.
- Use `PascalCase` for class names.

Reference:

https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html

---

## Contributing

1. Fork the repository.
2. Create a feature branch.

```bash
git checkout -b feature/your-feature-name
```

3. Commit your changes.

```bash
git commit -m "Add your feature"
```

4. Push your branch.

```bash
git push origin feature/your-feature-name
```

5. Open a Pull Request.

---

## License

This project currently does not specify a license.

Please contact the author before redistributing or using the project commercially.

---

## Author

**Bishu Thapa**

GitHub: https://github.com/Bishuthapa

---

<p align="center">
  Built with Godot Engine
</p>
