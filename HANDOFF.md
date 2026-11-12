# Handoff — Guru Rinpoche Game

**Date:** 2026-11-12
**Repo:** `c:\GitHub\guru-rinpoche-game`
**Engine:** Godot 4.7 (`gl_compatibility` / D3D12 on Windows, Mobile-ready)

---

## 1. Project Overview

A **Godot 4.7** 2D top-down Y-sorted game inspired by the authentic history and sacred cosmology of **Samye Monastery** (Tibet/Bhutan), blending:
- **Daytime Worker Economy (Warcraft/Settlers-lite)**: **Monastery Builder Monks** ([`SamyeWorker`](file:///c:/GitHub/guru-rinpoche-game/scripts/worker.gd)) harvest Cedar Timber and Carved Sandstone from natural nodes ([`ResourceNode`](file:///c:/GitHub/guru-rinpoche-game/scripts/resource_node.gd)), haul materials to sacred foundations ([`BuildingPlot`](file:///c:/GitHub/guru-rinpoche-game/scripts/building_plot.gd)), and construct the Samye Mandala with independent per-monk pacing, staggered wake-ups, randomized task dispersion, and individual work/shelter offsets.
- **Guru Rinpoche (Padmasambhava) Blessings & Defense ([`GuruPlayer`](file:///c:/GitHub/guru-rinpoche-game/node_2d.gd))**:
  - **Day Phase**: Hold `[SPACE]` / `[SHIFT]` / `[E]` to chant the Vajra Guru Mantra (`OM AH HUM VAJRA GURU PADMA SIDDHI HUM`), granting nearby Builder Monks a **2x speed & construction blessing** with procedural singing bowl chimes ([`AudioManager`](file:///c:/GitHub/guru-rinpoche-game/scripts/audio_manager.gd)).
  - **Night Phase**: Corrupted spirits ([`CorruptedSpirit`](file:///c:/GitHub/guru-rinpoche-game/scripts/corrupted_spirit.gd)) raid from the perimeter ([`NightWaveSpawner`](file:///c:/GitHub/guru-rinpoche-game/scripts/night_wave_spawner.gd)) to dismantle unguarded temples. At the start of the game and each night wave, gameplay **randomly selects any 2 of the 4 Dual-Appearance Spirit Archetypes** (**Mountain Mist Demon**, **Fire Imp Demon**, **Shadow Cave Demon**, **Stone Giant Demon**). Spirits spawn in their **Wrathful (Before Cleansing)** 4-directional appearance and transform into their matching **Cleansed (After Cleansing)** 4-directional appearance when purified by Guru Rinpoche's [`PurificationAura`](file:///c:/GitHub/guru-rinpoche-game/scripts/purification_aura.gd) or Vajra Purification Pulse (`[SPACE]`), orbiting him and ascending into the **Great Stupa** ([`Stupa`](file:///c:/GitHub/guru-rinpoche-game/scripts/stupa.gd)).
- **Sacred Lore & Model Sheet Modal ([`SacredLoreModal`](file:///c:/GitHub/guru-rinpoche-game/scripts/lore_modal.gd))**: Press `[L]` or `[TAB]` (or click the HUD button) to inspect all **12 Master Reference Sheets** (**Padmasambhava**, **Great Stupa**, **Samye Monastery**, **Builder Monk**, plus Wrathful & Cleansed sheets for **Mountain Mist**, **Fire Imp**, **Shadow Cave**, and **Stone Giant**) across a 2-row tab header.
- **Level 1 Victory Ending Movie ([`EndingCelebration`](file:///c:/GitHub/guru-rinpoche-game/scripts/ending_celebration.gd))**: Automatically triggers when all 3 Samye temples reach `100%` and at least `3` Dharmapalas are consecrated at the Great Stupa.

---

## 2. Project Structure

```text
c:\GitHub\guru-rinpoche-game\
├── .agents\
│   └── skills\
│       └── samye-visual-models\               # Workspace Agent Skill: reference sheets, palettes & sprite slicer
│           ├── SKILL.md                       # Skill instructions & asset mapping reference
│           ├── resources\                     # 12 Master Reference Sheets (Guru, Stupa, Samye, Monk + 4 Spirit Pairs)
│           ├── scripts\
│           │   └── extract_game_assets.ps1    # Automated C#/.NET background keyer & sprite cropper (60 sprites)
│           └── references\
│               └── visual_lore_and_palettes.md # Color palettes, symbolic meanings & crop coordinates
├── assets\
│   ├── sheets\                                # 12 reference sheets displayed in SacredLoreModal
│   └── sprites\                               # 60 extracted transparent PNG sprites (Guru, Monk, 4 Spirit Pairs, Stupa, Samye)
├── testing\
│   ├── README.md                              # Testing guide & CLI instructions
│   ├── suites\
│   │   ├── run_all_tests.ps1                  # Automated PowerShell + .NET test runner (29 tests)
│   │   └── godot_test_suite.gd                # Headless Godot 4 GDScript unit/integration test runner
│   └── proof\
│       ├── test_execution_report.md           # Full 29/29 test matrix (Happy, Unhappy, Edge, Boundary)
│       ├── test_results.json                  # Machine-readable JSON test report
│       └── visual_verification_contact_sheet.png # Checkerboard alpha & sprite verification sheet
├── project.godot                              # Godot 4.7 config; main scene: res://node_2d.tscn
├── icon.svg                                   # Custom Guru Rinpoche project icon
├── node_2d.tscn                               # Main scene: Samye Mandala, Stupa, Temples, Workers & Player
├── node_2d.gd                                 # GuruPlayer controller (4-dir turnaround, Mantra Chant, Night pulse)
├── scripts\
│   ├── model_textures.gd                      # Centralized asset registry (72 constants) & export-safe runtime cache
│   ├── lore_modal.gd                          # 12-tab Sacred Lore & Model Sheet Modal ([L] / [TAB], [1-9, 0])
│   ├── audio_manager.gd                       # Procedural audio: Tibetan temple drone & singing bowl chimes
│   ├── day_night_cycle.gd                     # Day/Night cycle timer & state machine
│   ├── day_night_lighting.gd                  # CanvasModulate ambient lighting controller
│   ├── monastery_phase_manager.gd             # Phase manager (Day building vs Night defense & sanctity)
│   ├── stupa.gd                               # Stupa sanctuary: isometric model, collects Dharmapalas
│   ├── ending_celebration.gd                  # Event-driven Level 1 Victory Ending Movie with hero illustrations
│   ├── building_plot.gd                       # Mandala building site with ArchitectureStyle enum & progressive reveal
│   ├── resource_node.gd                       # Natural resource deposits (Forest Trees for Wood, Quarry for Stone)
│   ├── worker.gd                              # SamyeWorker: 4-dir Builder Monk with anti-synchronization dispersal
│   ├── purification_aura.gd                   # 2D collision sphere aura (active during Night phase)
│   ├── corruption_component.gd                # Non-violent "Karmic Debt" / Corruption gauge
│   ├── corrupted_spirit.gd                    # 4-Archetype Spirit: random 2-model pair, Wrathful -> Cleansed transformation
│   ├── night_wave_spawner.gd                  # Spawns perimeter spirit waves at dusk using active random 2-spirit pair
│   └── hud.gd                                 # Event-driven HUD with Guru portrait frame & Lore Modal button
└── .clinerules                                # Game design rules (combat loop, art direction, Phase 1 & 2)
```

---

## 3. Architecture & Senior Game Developer Standards

1. **Single Source of Truth for Assets ([`ModelTextures`](file:///c:/GitHub/guru-rinpoche-game/scripts/model_textures.gd))**:
   - All 72 sprite and sheet paths (`GURU_*`, `MONK_*`, `SPIRIT_*`, `FIRE_IMP_*`, `SHADOW_CAVE_*`, `STONE_GIANT_*`, `STUPA_*`, `SAMYE_*`, `SHEET_*`) are strongly-typed `const` declarations in [`ModelTextures`](file:///c:/GitHub/guru-rinpoche-game/scripts/model_textures.gd).
   - Uses `ResourceLoader.exists()` first so exported `.pck` / Mobile / Web builds work natively, with an automatic `OS.has_feature("editor")` fallback to `Image.load_from_file()` when new sprites are sliced before Godot's editor import runs.
2. **4-Directional Character & Dual-Appearance Spirit State Machines ([`GuruPlayer`](file:///c:/GitHub/guru-rinpoche-game/node_2d.gd), [`SamyeWorker`](file:///c:/GitHub/guru-rinpoche-game/scripts/worker.gd), [`CorruptedSpirit`](file:///c:/GitHub/guru-rinpoche-game/scripts/corrupted_spirit.gd))**:
   - **Guru Rinpoche**, **Monastery Builder Monks**, and all **4 Spirit Archetypes** use `enum FacingDirection { DOWN, UP, LEFT, RIGHT }` to switch turnaround sprites cleanly based on velocity or target orientation (`_face_towards()`).
   - [`CorruptedSpirit`](file:///c:/GitHub/guru-rinpoche-game/scripts/corrupted_spirit.gd) defines `enum SpiritArchetype { MIST_DEMON = 0, FIRE_IMP = 1, SHADOW_CAVE = 2, STONE_GIANT = 3 }`, rolls any 2 distinct archetypes per wave (`roll_random_archetype_pair()`), and switches from `corrupted_dir_textures` to `cleansed_dir_textures` upon purification.
3. **Day 2+ Monk Anti-Synchronization ([`SamyeWorker`](file:///c:/GitHub/guru-rinpoche-game/scripts/worker.gd))**:
   - Prevents monks from walking in a single unified clone line after sheltering together on Night 1 via per-monk `personal_speed_factor`, staggered dawn `think_delay_timer`, individual `shelter_offset` / `work_offset` / `harvest_offset`, randomized resource priority, `.pick_random()` across eligible targets, and independent courtyard strolling (`_process_idle_stroll`).
4. **Inspector-Driven Building Styles ([`BuildingPlot`](file:///c:/GitHub/guru-rinpoche-game/scripts/building_plot.gd))**:
   - Uses `@export var architecture_style: ArchitectureStyle` (`CENTRAL_UTSE`, `WEST_PAVILION`, `EAST_PAVILION`, `FRONT_SHRINE`) and optional `@export var custom_completed_texture: Texture2D` override.
5. **Event-Driven UI & Cutscenes ([`MonasteryHUD`](file:///c:/GitHub/guru-rinpoche-game/scripts/hud.gd), [`EndingCelebration`](file:///c:/GitHub/guru-rinpoche-game/scripts/ending_celebration.gd))**:
   - Subscribes to `building_completed`, `building_dismantled`, `dharmapala_joined`, and `monastery_sanctity_changed` signals instead of polling `get_tree().get_nodes_in_group(...)` every frame.

---

## 4. Verification & Testing Commands

### Run the Automated 29-Test Suite (Happy, Unhappy, Edge, Boundary)
```powershell
powershell -ExecutionPolicy Bypass -File "c:\GitHub\guru-rinpoche-game\testing\suites\run_all_tests.ps1"
```
- **Current Status**: **29 / 29 PASSED (100%)**
- **Proof Artifacts**:
  - [testing/proof/test_execution_report.md](file:///c:/GitHub/guru-rinpoche-game/testing/proof/test_execution_report.md)
  - [testing/proof/test_results.json](file:///c:/GitHub/guru-rinpoche-game/testing/proof/test_results.json)
  - [testing/proof/visual_verification_contact_sheet.png](file:///c:/GitHub/guru-rinpoche-game/testing/proof/visual_verification_contact_sheet.png)

### Re-Extract All 60 Game Sprites from the 12 Master Reference Sheets
```powershell
powershell -ExecutionPolicy Bypass -File "c:\GitHub\guru-rinpoche-game\.agents\skills\samye-visual-models\scripts\extract_game_assets.ps1"
```
