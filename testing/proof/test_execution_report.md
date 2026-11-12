# Guru Rinpoche Game — Automated Test Execution Report

- **Execution Timestamp**: 2026-11-12 11:58:00 +08:00
- **Models Verified**: Padmasambhava, Monastery Builder Monk, 4 Dual-Appearance Spirits (Mountain Mist, Fire Imp, Shadow Cave, Stone Giant), Great Stupa, Samye Monastery, Cedar Grove & Sandstone Quarry
- **Total Tests Executed**: 32
- **Passed**: **32 / 32 (100%)**
- **Failed**: **0**
- **Visual Proof Contact Sheet**: `testing/proof/visual_verification_contact_sheet.png`
- **Machine-Readable Proof**: `testing/proof/test_results.json`

---

## Test Matrix Results

| ID | Category | Test Case Name | Expected Behavior | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **HP-01** | Happy Path | Workspace Skill Structure & YAML Frontmatter | Valid SKILL.md YAML frontmatter + references/visual_lore_and_palettes.md | SKILL.md frontmatter valid=True | **PASS** |
| **HP-02** | Happy Path | All 66 Extracted Game Sprites Exist & Match Dimensions | 66/66 PNG sprites present with exact dimensions | 66/66 verified | **PASS** |
| **HP-03** | Happy Path | All 14 Sacred Lore Reference Sheets Present in assets/sheets/ | 14/14 JPG sheets verified in assets/sheets/ | 14/14 verified (Guru, Stupa, Samye, Monk, 4 Spirit Pairs, Cedar Grove, Stone Quarry) | **PASS** |
| **HP-04** | Happy Path | ModelTextures Constants Resolve 100% of Disk Paths | 80/80 const res:// paths exist on disk | 80/80 resolved | **PASS** |
| **HP-05** | Happy Path | GuruPlayer 4-Directional Turnaround Wiring | GuruPlayer maps DOWN/UP/LEFT/RIGHT to ModelTextures.GURU_* | Verified class_name GuruPlayer & all 4 FacingDirection mappings | **PASS** |
| **HP-06** | Happy Path | SamyeWorker 4-Directional Monastery Builder Monk Wiring | SamyeWorker maps DOWN/UP/LEFT/RIGHT to ModelTextures.MONK_* | Verified 4-directional Builder Monk sprites & _face_towards() | **PASS** |
| **HP-07** | Happy Path | BuildingPlot ArchitectureStyle Enum & Scene Assignment | CentralUtse=1, WestTemple=2, EastTemple=3 in node_2d.tscn | All 3 Samye temples explicitly typed in node_2d.tscn | **PASS** |
| **HP-08** | Happy Path | Event-Driven Signal Architecture (Zero Per-Frame Polling) | HUD & EndingCelebration use signal connections instead of _process polling | Verified signal-driven HUD & deferred _process on EndingCelebration | **PASS** |
| **HP-09** | Happy Path | CorruptedSpirit 4-Archetype Dual-Appearance Turnaround Wiring | Supports Mist Demon, Fire Imp, Shadow Cave & Stone Giant (Wrathful -> Cleansed) | Verified all 4 SpiritArchetypes (32 directional textures) & state switch | **PASS** |
| **HP-10** | Happy Path | Random 2-Model Spirit Pair Selection Per Wave | roll_random_archetype_pair() selects 2 random spirit models at a time | Verified 2-archetype pool shuffle & NightWaveSpawner integration | **PASS** |
| **HP-11** | Happy Path | Spirit Attack & Building Destruction Effects Based on Modal Abilities | Mist fog, Fire Imp sparks, Shadow Cave crystal lightning, and Stone Giant seismic rubble FX | Verified _draw_archetype_attack_effect() & BuildingPlot._draw_spirit_affliction_effect() | **PASS** |
| **HP-12** | Happy Path | ResourceNode 3-Stage Visual Models (Cedar Forest & Sandstone Quarry) | ResourceNode renders Full/Mid/Low stage sprites from Cedar Grove & Stone Quarry modals | Verified 6 stage textures & get_active_stage_texture() in ResourceNode | **PASS** |
| **HP-13** | Happy Path | Realistic Day & Night Ambience (Birds, Rabbits/Squirrels & Night Fog) | Daytime birds/rabbits/squirrels + Nighttime rolling fog banks & wisps in AmbientEcosystem | Verified AmbientEcosystem script and node_2d.tscn scene integration | **PASS** |
| **UP-01** | Unhappy Path | ModelTextures Null/Empty/Missing Path Guard | Returns null and logs warning on empty or non-existent texture path | Verified empty string guard + ResourceLoader/FileAccess checks | **PASS** |
| **UP-02** | Unhappy Path | BuildingPlot Blocks Construction Before Materials Delivered | add_construction_work() gated by has_all_materials() | Verified has_all_materials() guard before progress increment | **PASS** |
| **UP-03** | Unhappy Path | BuildingPlot Rejects Resource Deposit After Completion | deposit_resource() returns 0.0 when State.COMPLETED | Verified early return 0.0 on completed plots | **PASS** |
| **UP-04** | Unhappy Path | SpriteCleaner Handles Null ClearZones & Zero Tolerance | Returns valid 20x20 Bitmap without NullReferenceException | Returned True 20x20 Bitmap cleanly | **PASS** |
| **UP-05** | Unhappy Path | SacredLoreModal Ignores Mouse Clicks When Closed | MOUSE_FILTER_IGNORE + early return in _gui_input when not is_open | Verified mouse_filter toggle and _gui_input guard | **PASS** |
| **EC-01** | Edge Case | Dismantling a 100% Completed Building Reverts to UNDER_CONSTRUCTION | State transitions COMPLETED -> UNDER_CONSTRUCTION when progress drops < 100 | Verified state downgrade and building_dismantled signal | **PASS** |
| **EC-02** | Edge Case | Dismantling 0% Progress Plot Clamps Material Drain at 0.0 | maxf(0.0, ...) prevents negative wood_delivered / stone_delivered | Verified maxf(0.0, ...) floor clamps | **PASS** |
| **EC-03** | Edge Case | Subjugated Dharmapala Disables Collision to Never Block Player | collision_layer=0, collision_mask=0, CollisionShape2D disabled on cleanse | Verified collision layer/mask zeroing and deferred shape disable | **PASS** |
| **EC-04** | Edge Case | EndingCelebration Single-Trigger Idempotency Guard | Repeated building_completed signals do not restart cutscene once celebrating | Verified if is_celebrating: return guard | **PASS** |
| **EC-05** | Edge Case | Guru Right Sprite Preserves Opaque Cream Silk Sleeve | Sleeve interior pixel (96,235) Alpha == 255 (not eaten by flood fill) | Sleeve pixel RGBA=(227,199,177,255) | **PASS** |
| **EC-06** | Edge Case | Builder Monk Preserves Work Glove & Architectural Scroll | Glove (84,162) A=255 and Scroll (24,162) A=255 | Glove A=255, Scroll A=255 | **PASS** |
| **EC-07** | Edge Case | Mist Demon & Clear Sky Guardian Preserve Opaque Eyes & Face Core | Corrupted face (80,90) A=255 and Cleansed face (76,86) A=255 | Corrupted Face A=255, Cleansed Face A=255 | **PASS** |
| **EC-08** | Edge Case | Day 2+ Builder Monk Anti-Synchronization & Dispersal Fix | Randomized personal speed, staggered wake-up delay, spatial offsets & pick_random() tasking | Verified personal_speed_factor, think_delay_timer, offsets & pick_random() | **PASS** |
| **BV-01** | Boundary | SpriteCleaner Clamps Out-of-Bounds Crop Rectangles | Crop (-25,-15,250,200) on 100x80 image clamps to 100x80 | Result bitmap size=True (100x80) | **PASS** |
| **BV-02** | Boundary | Alpha Channel Boundary (48/48 Keyed Sprites: Corner A=0, Center A=255) | All 48 keyed sprites (Guru, Monk, 4 Spirits x 8, Stupa, Samye, 6 Resource Stages) have Corner A=0 & Center A=255 | 48/48 sprites verified (Corner A=0, Center A=255) | **PASS** |
| **BV-03** | Boundary | BuildingPlot Resource Deposit Upper Boundary Clamp | clampf(amount, 0.0, needed) prevents resource overflow beyond required | Verified clampf(amount, 0.0, needed) on both Timber and Sandstone | **PASS** |
| **BV-04** | Boundary | BuildingPlot Construction Progress 100.0% Upper Boundary | minf(100.0, ...) caps construction_progress at 100.0% | Verified minf(100.0, ...) and >= 100.0 completion trigger | **PASS** |
| **BV-05** | Boundary | SacredLoreModal Tab Index Boundary Check (0..13) | Supports all 14 sheets (tabs 0..13) and guards out-of-range indices | Verified bounds check [0, sheets.size()) across all 14 sheets | **PASS** |
| **BV-06** | Boundary | Godot Global Script Class Cache Registration | AmbientEcosystem, GuruPlayer, SamyeWorker, ModelTextures, and SacredLoreModal registered | All 19 project classes registered and sorted | **PASS** |
