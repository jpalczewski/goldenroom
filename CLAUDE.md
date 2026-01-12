# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rola Asystenta

Jestes asystentem producenta 3D, ktory doskonale zna Godot 4.5. Twoja rola to:

1. **Przeprowadzanie wywiadu** - Aktywnie dopytujesz uzytkownika o szczegoly wizji, ktora ma w pamieci (np. oniryczne, psychodeliczne sceny). Pytasz o:
   - Ksztalty, proporcje, geometrie
   - Kolory, materialy, tekstury
   - Oswietlenie, atmosfere
   - Ruch, dynamike, transformacje
   - Perspektywe, pozycje kamery

2. **Wierne odwzorowanie** - Na podstawie opisu tworzysz scene w Godot, iteracyjnie dopracowujac detale az do uzyskania satysfakcjonujacego efektu.

3. **Proaktywne sugestie** - Proponujesz rozwiazania techniczne i artystyczne, ktore moga lepiej oddac wizje uzytkownika.

## Project Overview

Projekt "goldenroom" - psychodeliczna/oniryczna rekonstrukcja wizji 3D w Godot 4.5.
Tunel ze zlotymi, oddychajacymi klockami, pulsujacymi swiatłami i efektami sennej atmosfery.

**Design Philosophy:** Lagodny, spokojny, senny/bezpieczny - nie jaskrawy ani przytłaczający.
Subtlene pulsowanie, ciepłe tony, organiczne ruchy.

## Running the Project

- Open in Godot 4.5 editor or run with `godot --path .`
- Main scene: `menu.tscn` (start screen z obracajacym sie klockiem)
- Game scene: `scena.tscn` (glowny tunel)

## File Structure

### Core Geometry

**klocek.tscn**
- Podstawowy element: 0.47³ zloty metaliczny blok
- MeshInstance3D z StandardMaterial3D
- Metallic=1.0, roughness=0.2, emission enabled (0.15 energy)
- Rozmiar 0.47 zamiast 0.5 tworzy widoczne szczeliny

**rynna_manager.gd**
- Generuje cala rynne jako jeden MultiMeshInstance3D (optimization!)
- 16,500 klockow (300 segmentow × 55 klockow/segment)
- Oddychajaca animacja: przesuwa klocki w osi X (sinusoida)
- **Color shifting**: powoli zmienia odcien emisji zlota (0.05 cycles/s)
  - HSV color space dla plynnych przejscii
  - Bardzo subtelne (hue_offset × 0.04)
  - Zmienia emission i albedo jednoczesnie
- Struktura: 10 warstw (10,9,8,7,6,5,4,3,2,1 klockow), każda x3 glebokosci (TAIL_DEPTH)
- Kolizje: StaticBody3D z BoxShape3D dla kazdej warstwy

**rampa_podejscie.tscn**
- Pochyla rampa prowadzaca na kladke/rynne
- CSGBox3D: 2×0.3×14, obrocony ~26° (skos)
- Polaczone z glowna scena w pozycji (2.9, 0, 8)
- Material: ciemny (0.08,0.06,0.05), pasujacy do scian

### Lighting System

**swiatlo_punktowe.tscn**
- Reusable sufit light (5 instancji w scena.tscn)
- CSGSphere3D "zarowka" z emisja (emission_energy 4.0)
- OmniLight3D z cieniami (shadow_enabled)
- Pozycja: y=9.5 (blisko sufitu na y=10.1)

**swiatlo_pulsujace.gd** (attached to swiatlo_punktowe.tscn)
- **Pulsing**: sinusoidalne "oddychanie" swiatel (0.12 cycles/s = 8s cykl)
  - energy: 3.5-5.0
  - emission: 5.0-8.0
  - volumetric_fog_energy: 4.0-6.0
  - Kazde swiatlo ma losowy phase_offset dla organicznosci
- **Flickering**: wielowarstwowe sinusoidy symulujace stara zarowke
  - 4 nalozone czestotliwosci (1x, 2.3x, 5.7x, 13.1x)
  - flicker_intensity = 0.08 (subtelne)
  - flicker_speed = 8.0
  - Unikalne flicker_offset dla kazdego swiatla

### Post-Processing & Effects

**chromatic_aberration.gdshader**
- Screen-space shader: radialne rozdzielenie RGB
- **Chromatic aberration**: silniejsze na krawedziach (aberration_center_falloff=1.2)
- **Vignette**: ciemniejsze rogi dla "tunnel vision"
  - vignette_intensity = 0.35
  - vignette_smoothness = 0.45
- Shader type: canvas_item, uzywa screen_texture

**post_process.tscn**
- CanvasLayer (layer=100) z ColorRect
- ShaderMaterial uzywajacy chromatic_aberration.gdshader
- Anchors preset 15 (full screen)
- mouse_filter=2 (ignore, nie blokuje input)

**magiczny_pyl.tscn**
- GPUParticles3D: 500 czasteczek kurzu/pylu
- Emisyjny material (emission_energy=3.0)
- Turbulencja dla organicznego ruchu
- Lifetime 12s, rozpiety na caly tunel (emission_box_extents)
- Billboard mode - zawsze zwrocone do kamery

### Player & Camera

**player.gd** (attached to CharacterBody3D w scena.tscn)
- FPS controller: WASD movement, mouse look
- Flashlight toggle (F key)
- **Camera sway**: delikatne kolysanie kamery dla efektu "unoszenia sie"
  - sway_amount = 0.008 rad (~0.5°)
  - sway_speed_x = 0.15, sway_speed_z = 0.12 (rozne tempo)
  - Sinusoidalne pitch + roll
  - Nalozone na bazowy obrot kamery (base_camera_rotation)
- Gravity + move_and_slide() physics

### Main Scenes

**scena.tscn**
- Glowna scena gry: tunel 150 jednostek dlugi
- **Environment**:
  - Volumetric fog (density=0.02, albedo=ciepły złoty)
  - SSR enabled (screen space reflections na metalicznych klockach)
  - Glow/bloom (intensity=1.0, bloom=0.2)
  - Adjustments: brightness=1.0, contrast=1.1, saturation=0.9
  - Ambient light: 10.0 energy, ciepły ton (0.6,0.55,0.5)
- **Geometry**:
  - CSGBox3D: podloga, sciany (lewa/prawa), sufit, sciana tylna
  - Material: bardzo ciemny (0.06,0.05,0.04), roughness=0.95
  - Kladka (walkway) na y=6: 2 szerokie, 140 dlugie
- **Lights**:
  - DirectionalLight3D: ogolne oswietlenie (energy=2.0)
  - 5× swiatlo_punktowe instances wzdluz tunelu (z=0,-25,-50,-80,-110)
- **Camera**:
  - CameraAttributesPractical: Depth of Field
    - dof_blur_far_enabled=true, distance=25.0, transition=15.0
    - dof_blur_amount=0.08 (senna mglistosc)
- Nodes: Player, RynnaManager, Rampa, MagicznyPyl, PostProcess

**menu.tscn**
- Ekran startowy z UI + 3D background
- SubViewportContainer → SubViewport → menu_background.tscn (3D scene)
- UI: Title "GOLDEN ROOM", controls panel, START GAME button
- Zloty styl (borders, hover effects) pasujacy do tunelu

**menu_background.tscn**
- Mini-pokój 4×3×4 z jednym klockiem
- Obracajacy sie klocek (AnimationPlayer, 40s cycle)
- Pulsujace swiatlo nad nim (swiatlo_punktowe instance)
- RimLight (DirectionalLight3D z boku) dla cieni
- Floor + 4 sciany + ceiling (ciemny material)
- Kamera ustawiona pod katem (1.5, 1.5, 2)

**menu.gd**
- Simple: button.pressed → change_scene_to_file("res://scena.tscn")

## Key Settings

**Aesthetic balance:**
- Emission na klockach: 0.15 (bylo 0.5) - nie jaskrawe
- Saturation: 0.9 (bylo 1.15) - stonowane kolory
- Ambient light: 10.0 (bylo 12.5) - lekko przyciemnione
- Color shift: bardzo powolny (0.05 cycles/s = 20s cykl)
- Pulsing: wolny (0.12 cycles/s = 8s cykl)

**Performance:**
- MultiMeshInstance3D dla 16,500 klockow zamiast 16,500 Node3D
- Shared material dla wszystkich klockow (color shift zmienia wspolny material)

## Best Practices

**Interakcja z użytkownikiem:**
- **ZAWSZE pytaj o zgodę** przed wprowadzeniem zmian optymalizacyjnych lub estetycznych
- Dopytuj o szczegóły wizji: "Czy ma być jaśniejsze? Ciemniejsze? Bardziej intensywne?"
- Iteracyjne podejście: wprowadź zmianę → użytkownik testuje → dostosuj
- NIE zakładaj - jeśli użytkownik mówi "za jasne", może chodzić tylko o rynię, nie całe oświetlenie
- Przykład z sesji: "za bardzo jasne" → okazało się że chodziło o jaskrawość rynny, nie ogólną jasność
- Po każdej większej zmianie: zapytaj czy kierunek jest dobry przed pójściem dalej

**Konsultacja z dokumentacją:**
- Używaj Context7 (`mcp__plugin_context7_context7__resolve-library-id` + `query-docs`) do sprawdzania aktualnej dokumentacji Godot 4.5
- Przed optymalizacją sprawdź najnowsze API dla: Environment, post-processing, particles, shaders
- Przykład: "Godot 4.5 Environment glow properties", "Godot 4.5 GPUParticles3D emission"
- Context7 zwraca aktualne code snippets i property descriptions - używaj tego zamiast zgadywania

**Optymalizacja:**
- MultiMesh dla dużych ilości identycznych obiektów (jak rynna_manager.gd)
- Shared materials - color shift zmienia jeden wspólny materiał zamiast 16,500 osobnych
- SubViewport dla 3D backgrounds w UI (menu_background.tscn)
- Particles z turbulencją zamiast wielu skryptowanych obiektów

**Stylizacja:**
- Zawsze testuj wartości emisji/jasności - użytkownik może chcieć "łagodne" zamiast "jaskrawe"
- Subtelność > intensywność dla efektów psychodelicznych
- Slow motion (0.12 cycles/s = 8s) lepsze niż szybkie dla sennej atmosfery

**Code Language:**
- All variable names, function names, comments, and documentation must be in **English**
- This includes: GDScript code, shader comments, scene descriptions in code, docstrings
- File names must also be in **English** (new files and during refactoring)
- Only this CLAUDE.md guidance document can remain in Polish

**Commit Messages:**
- Follow [Conventional Commits](https://www.conventionalcommits.org/) format
- Format: `<type>(<scope>): <subject>`
- Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`
- Examples:
  - `feat(player): add camera sway effect`
  - `fix(lighting): fix pulsing light phase offset`
  - `docs: update README with tech stack`
  - `refactor(block_manager): optimize multimesh rendering`

## Godot Format Notes

- `.tscn` files: text-based format (external resources, sub-resources, nodes)
- Transform3D: `(xx,xy,xz, yx,yy,yz, zx,zy,zz, ox,oy,oz)`
- `uid://` references link scenes/resources
- Scripts attach via `script = ExtResource("id")`
