---
name: samye-visual-models
description: >-
  Extracts, manages, and integrates visual reference sheets, turnaround sprites,
  isometric 3D-style building models, color palettes, and sacred lore modals for
  Padmasambhava (Guru Rinpoche), the Great Stupa, Samye Monastery, the
  Monastery Builder Monk, and all 4 Dual-Appearance Spirit Archetypes (Mountain
  Mist Demon, Fire Imp Demon, Shadow Cave Demon, and Stone Giant Demon — Before
  & After Cleansing). Activate this skill whenever updating character sprites,
  worker visuals, spirit visuals, building visuals, UI portraits, color themes,
  or inspection/lore modals in the Guru Rinpoche game.
---

# Samye Visual Models & Asset Pipeline Skill

This skill governs how visual concept and turnaround sheets for **Padmasambhava (Guru Rinpoche)**, **Stupa**, **Samye Monastery**, **Monastery Builder Monk**, and **All 4 Dual-Appearance Spirit Archetypes (Mountain Mist, Fire Imp, Shadow Cave, Stone Giant — Before & After Cleansing)** are stored, sliced into transparent Godot sprites, and presented inside the game.

## Directory Layout

* **Source Reference Sheets (`resources/` — 12 Sheets)**:
  * [padmasambhava_sheet.jpg](./resources/padmasambhava_sheet.jpg) — Character turnaround (Front, Left, Back, Right), Close-Up Face Portrait, Color Palette, and 6 Key Details (*Lotus Hat*, *Vajra*, *Lotus Flower*, *Khatvanga Staff*, *Robe Pattern*, *Boots*).
  * [stupa_sheet.jpg](./resources/stupa_sheet.jpg) — Perspective View, 4 Turnaround Views, Top View Layout, Isometric View (Game/3D Model Style), Color Palette, and 6 Key Elements (*Spire*, *Dome*, *Niche*, *Decorative Pattern*, *Prayer Wheels*, *Prayer Flags*).
  * [samye_monastery_sheet.jpg](./resources/samye_monastery_sheet.jpg) — Perspective View, 4 Turnaround Views, Top View Layout, Isometric View (Game/3D Model Style), and 6 Key Elements (*Golden Roof*, *Traditional Window*, *Main Entrance*, *Stupa*, *Prayer Flags*, *Wall Detail*).
  * [monk_sheet.jpg](./resources/monk_sheet.jpg) — Monastery Builder Monk turnaround (Front, Back, Left, Right), Portrait, Key Skills, Outfit Details, Construction Process, and 8 Craftsman Tools.
  * [mist_demon_corrupted_sheet.jpg](./resources/mist_demon_corrupted_sheet.jpg) & [mist_demon_cleansed_sheet.jpg](./resources/mist_demon_cleansed_sheet.jpg) — **Spirit 1: Mountain Mist Demon (Wrathful) -> Clear Sky Guardian (Cleansed)**.
  * [fire_imp_corrupted_sheet.jpg](./resources/fire_imp_corrupted_sheet.jpg) & [fire_imp_cleansed_sheet.jpg](./resources/fire_imp_cleansed_sheet.jpg) — **Spirit 2: Wrathful Fire Imp -> Fire Imp / Courage Flame Guardian (Cleansed)**.
  * [shadow_cave_corrupted_sheet.jpg](./resources/shadow_cave_corrupted_sheet.jpg) & [shadow_cave_cleansed_sheet.jpg](./resources/shadow_cave_cleansed_sheet.jpg) — **Spirit 3: Shadow Cave Demon (Wrathful) -> Cave Light Guardian (Cleansed)**.
  * [stone_giant_corrupted_sheet.jpg](./resources/stone_giant_corrupted_sheet.jpg) & [stone_giant_cleansed_sheet.jpg](./resources/stone_giant_cleansed_sheet.jpg) — **Spirit 4: Stone Giant Demon (Wrathful) -> Temple Guardian Giant (Cleansed)**.
* **Extraction Script (`scripts/`)**:
  * [extract_game_assets.ps1](./scripts/extract_game_assets.ps1) — Native Windows PowerShell + `System.Drawing` sprite slicer, flood-fill background cleaner, and largest-connected-component filter (`ExtractOutlinedMonk`, `ExtractMistSpirit`, `ExtractCardSpirit`).
* **Iconography, Coordinates & Palettes (`references/`)**:
  * [visual_lore_and_palettes.md](./references/visual_lore_and_palettes.md) — Exact hex color codes, pixel bounding boxes, and sacred lore text from all 12 model sheets.

---

## Workflow 1: Extracting & Refreshing Game Sprites

Whenever the source sheets in `resources/` are updated or crop regions are tuned:

1. Run the extraction script from the repository root:
   ```powershell
   powershell -ExecutionPolicy Bypass -File ".agents/skills/samye-visual-models/scripts/extract_game_assets.ps1"
   ```
2. Verify that `assets/sprites/` contains all 60 generated `.png` sprites with transparent backgrounds:
   * **Guru Rinpoche (`GuruPlayer`)**: `guru_front.png`, `guru_left.png`, `guru_back.png`, `guru_right.png`, `guru_portrait.png`
   * **Monastery Builder Monk (`SamyeWorker`)**: `monk_front.png`, `monk_back.png`, `monk_left.png`, `monk_right.png`, `monk_portrait.png`
   * **Spirit 1 — Mountain Mist (`MIST_DEMON`)**: `spirit_corrupted_{front,back,left,right,portrait}.png` & `spirit_cleansed_{front,back,left,right,portrait}.png`
   * **Spirit 2 — Fire Imp (`FIRE_IMP`)**: `fire_imp_corrupted_{front,back,left,right,portrait}.png` & `fire_imp_cleansed_{front,back,left,right,portrait}.png`
   * **Spirit 3 — Shadow Cave (`SHADOW_CAVE`)**: `shadow_cave_corrupted_{front,back,left,right,portrait}.png` & `shadow_cave_cleansed_{front,back,left,right,portrait}.png`
   * **Spirit 4 — Stone Giant (`STONE_GIANT`)**: `stone_giant_corrupted_{front,back,left,right,portrait}.png` & `stone_giant_cleansed_{front,back,left,right,portrait}.png`
   * **Great Stupa (`Stupa`)**: `stupa_isometric.png`, `stupa_front.png`, `stupa_top_layout.png`, `stupa_hero.png`
   * **Samye Monastery (`BuildingPlot`)**: `samye_isometric.png`, `samye_front.png`, `samye_side_left.png`, `samye_side_right.png`, `samye_top_layout.png`, `samye_hero.png`
3. Verify that `assets/sheets/` contains all 12 full reference sheets used by the in-game Sacred Lore Modal.

---

## Workflow 2: How Assets Map to Godot Nodes

1. **4-Directional Player (`node_2d.gd` / `GuruPlayer`)**:
   * Uses `ModelTextures.GURU_FRONT` (Down/Idle), `GURU_BACK` (Up), `GURU_LEFT` (Left), and `GURU_RIGHT` (Right).
2. **4-Directional Monastery Builder Monk (`scripts/worker.gd` / `SamyeWorker`)**:
   * Uses `ModelTextures.MONK_FRONT` (Down/Idle), `MONK_BACK` (Up), `MONK_LEFT` (Left), and `MONK_RIGHT` (Right).
   * Features individualized speed (`personal_speed_factor`), staggered wake-up timers (`think_delay_timer`), and personal spatial offsets (`shelter_offset`, `work_offset`, `harvest_offset`) so monks never synchronize into a single line on Day 2+.
3. **4-Archetype Dual-Appearance Spirit (`scripts/corrupted_spirit.gd` / `CorruptedSpirit`)**:
   * Randomly picks **any 2 of the 4 Spirit Archetypes at a time** (`CorruptedSpirit.roll_random_archetype_pair()`).
   * **Before Cleansing (`not is_subjugated`)**: Spawns in its Wrathful 4-directional turnaround sprites.
   * **After Cleansing (`is_subjugated == true`)**: Plays a luminous wisdom flash and transforms into its matching Cleansed Dharmapala 4-directional turnaround sprites, following Guru Rinpoche and ascending into the Great Stupa.
4. **Great Enlightenment Stupa (`scripts/stupa.gd`)**:
   * Renders `ModelTextures.STUPA_ISOMETRIC` centered over the golden floor mandala and ascension pulse rings.
5. **Samye Monastery Plots (`scripts/building_plot.gd`)**:
   * **Blueprint Stage**: Displays `ModelTextures.SAMYE_TOP_LAYOUT` inside the mandala boundary.
   * **Under Construction Stage**: Progressively clips and reveals the temple sprite (`SAMYE_ISOMETRIC` for Central Utse Temple; `SAMYE_SIDE_LEFT` / `SAMYE_SIDE_RIGHT` for West/East Pavilions) from bottom to top with timber scaffolding overlays.
   * **Completed Stage**: Renders the full consecrated temple model with a warm golden aura.
6. **HUD Portrait & Sacred Lore Modal (`scripts/hud.gd` & `scripts/lore_modal.gd`)**:
   * Displays `ModelTextures.GURU_PORTRAIT` in the top-left HUD frame and allows players to press `L` or `Tab` (or click the HUD button) to open the 12-tab **Sacred Lore & Model Sheet Modal**.
