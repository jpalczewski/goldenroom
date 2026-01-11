# Golden Room

A vibe coding experiment exploring psychedelic/oneiric 3D reconstruction in Godot 4.5.

## About

This project is an experiment in collaborative development between a human and [Claude Code](https://claude.com/claude-code), translating abstract oneiric and psychedelic visions into an interactive 3D experience. The focus is on atmosphere, subtle movement, and a dreamlike aesthetic rather than traditional gameplay.

## Features

- GPU-accelerated breathing animation for 16,500+ golden blocks
- Proximity-based glow effects (player presence influences the environment)
- Zone-based color shifting deeper into the tunnel
- Gentle camera sway for floating sensation
- Volumetric fog and pulsing lights
- Optimized for web export (WebGL 2.0)

## Tech Stack

- **Engine**: Godot 4.5 (Compatibility renderer for web)
- **Language**: GDScript
- **Graphics**: Custom spatial shaders with MultiMesh instancing
- **Platform**: Desktop + Web (HTML5)

## Running

```bash
# Open in Godot 4.5 editor
godot --path .

# Or run directly
godot --path . res://menu.tscn
```

## Design Philosophy

*Lagodny, spokojny, senny/bezpieczny* - gentle, calm, dreamy/safe. Not harsh or overwhelming. Subtle pulsation, warm tones, organic movement.

## Credits

Collaborative experiment between human vision and AI implementation via Claude Code.
