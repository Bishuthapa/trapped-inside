#  Trapped Inside

> A 2D game built with **Godot Engine 4.6** and written entirely in **GDScript**.

---

##  About

**Trapped Inside** is a Godot 4.6 game project developed by [Bishuthapa](https://github.com/Bishuthapa). The project uses Godot's GL Compatibility renderer, making it suitable for a wide range of hardware including mobile and lower-end desktops.

---

##  Project Structure

```
trapped-inside/
├── assets/          # Game assets (sprites, textures, audio, fonts, etc.)
├── effects/         # Visual effects (shaders, particles, post-processing, etc.)
├── scenes/          # Godot scene files (.tscn) for levels, UI, and game objects
├── scripts/         # GDScript source files (.gd) for game logic
├── icon.svg         # Project icon
├── icon.svg.import  # Godot import metadata for the icon
└── project.godot    # Godot project configuration file
```

---

##  Technical Details

| Property            | Value                          |
|---------------------|-------------------------------|
| **Engine**          | Godot 4.6                     |
| **Language**        | GDScript (100%)               |
| **Renderer**        | GL Compatibility               |
| **Physics Engine**  | Jolt Physics (3D)             |
| **Config Version**  | 5                              |
| **Windows Renderer**| Direct3D 12 (d3d12)           |

##  Controls

| Action | Key |
|--------|-----|
| Move Up    | `W` |
| Move Down  | `S` |
| Move Right | `D` |
| Move Left  | `A` |


---
**To attack in the direction you want, move the mouse toward the desired direction and press the left mouse button.**
---

## Getting Started

### Prerequisites

- [Godot Engine 4.6](https://godotengine.org/download) — make sure to download the correct version.

### Running the Project

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Bishuthapa/trapped-inside.git
   cd trapped-inside
   ```

2. **Open in Godot:**
   - Launch Godot Engine 4.6.
   - Click **Import** and navigate to the cloned folder.
   - Select `project.godot` and click **Import & Edit**.

3. **Run the game:**
   - Press **F5** or click the  Play button to run the main scene.


   ----------------OR----------------<br/>
   <br/>
   ##Run the server
   Just go to the folder `build -> web`
   and open the terminal in `trapped-inside\build\web` dir
   then run the server <br/>
   ```bash
    python -m server.http 8000
   ```
   then open the web browser and paste  `localhost:8000` to the url.
   
---

## Development

### Folder Conventions

- **`scenes/`** — All `.tscn` scene files. Each major game object, level, or UI screen should have its own scene.
- **`scripts/`** — All `.gd` GDScript files. Scripts are typically attached to scene nodes or used as autoloads.
- **`assets/`** — Raw and imported assets (images, audio, fonts). Godot generates `.import` files here automatically.
- **`effects/`** — Visual effect resources such as shaders (`.gdshader`), particle materials, and environment resources.

### Coding Style

- Language: **GDScript**
- Follow [Godot's GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- Use `snake_case` for variables and functions, `PascalCase` for class names and nodes.

---

##  Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push to your branch: `git push origin feature/your-feature-name`
5. Open a Pull Request.

---

##  License

This project does not currently specify a license. Please contact me before using or distributing this project.

---

##  Author

**Bishuthapa** — [@Bishuthapa](https://github.com/Bishuthapa)

---

*Made with using [Godot Engine](https://godotengine.org/)*
