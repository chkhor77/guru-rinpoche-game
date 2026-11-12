# Guru Rinpoche Game — Testing & Verification Guide

This directory contains the automated test suites and execution proofs for the **Guru Rinpoche Game** and the **`samye-visual-models`** workspace skill.

---

## Directory Organization

```text
c:\GitHub\guru-rinpoche-game\testing\
├── README.md                                     # This guide: architecture, test categories, and CLI commands
├── suites\                                       # Executable test suites
│   ├── run_all_tests.ps1                         # Automated Asset, Architecture & Behavioral Test Runner (29 tests)
│   └── godot_test_suite.gd                       # Headless Godot 4 GDScript Unit & Integration Test Runner
└── proof\                                        # Verifiable proof artifacts from test executions
    ├── test_execution_report.md                  # Human-readable test matrix (Happy, Unhappy, Edge, Boundary)
    ├── test_results.json                         # Machine-readable JSON test report with timestamps
    └── visual_verification_contact_sheet.png     # Visual checkerboard proof of all extracted sprites & alpha channels
```

---

## How to Run the Tests

### 1. Run the Full Automated Verification Suite (PowerShell + .NET)
From the repository root, run:
```powershell
powershell -ExecutionPolicy Bypass -File "testing/suites/run_all_tests.ps1"
```
This script validates **29 tests** across 4 engineering categories:
- **Happy Path (`HP-01` – `HP-10`)**: Skill frontmatter, all 60 extracted `.png` sprites and 12 `.jpg` reference sheets, `ModelTextures` registry resolution (72 constants), 4-directional `GuruPlayer`, `SamyeWorker` (Monastery Builder Monk), and `CorruptedSpirit` (4 Spirit Archetypes: Mountain Mist, Fire Imp, Shadow Cave, Stone Giant) state machines, random 2-model spirit pair selection per wave (`roll_random_archetype_pair()` / `pick_from_active_pair()`), `BuildingPlot` `ArchitectureStyle` scene assignments, and event-driven signal wiring.
- **Unhappy Path (`UP-01` – `UP-05`)**: Empty/missing texture paths, rejecting construction work before materials are delivered, rejecting resource deposits after completion, null `clearZones` / zero tolerance inputs, and ignoring mouse input when `SacredLoreModal` is closed.
- **Edge Cases (`EC-01` – `EC-08`)**: Dismantling a 100% completed building back to `UNDER_CONSTRUCTION`, clamping material drain at `0.0`, disabling collision on subjugated Dharmapalas so they never block Guru Rinpoche, single-trigger idempotency on `EndingCelebration`, preserving Guru Rinpoche's opaque cream silk sleeves, preserving the Builder Monk's work glove and architectural scroll, preserving opaque eyes and face cores on the Spirit turnarounds, and preventing Day 2+ Monastery Builder Monk unified walking synchronization (`EC-08`).
- **Boundary Values (`BV-01` – `BV-06`)**: Clamping out-of-bounds crop rectangles, verifying corner `Alpha == 0` vs. center `Alpha == 255` across all 42 keyed character, spirit & building sprites, clamping resource deposits to exact required capacity, capping construction progress at `100.0%`, guarding `SacredLoreModal` tab indices `[0..11]`, and verifying `.godot/global_script_class_cache.cfg`.

### 2. Run the Headless Godot 4 GDScript Test Suite
When running with the Godot 4.7 executable:
```powershell
& "C:\Users\CheeHaw\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64.exe" --headless --path . -s res://testing/suites/godot_test_suite.gd
```

---

## Proof Artifacts Reference
- **Test Matrix Report**: [test_execution_report.md](./proof/test_execution_report.md)
- **JSON Test Output**: [test_results.json](./proof/test_results.json)
- **Visual Alpha & Dimension Proof**: [visual_verification_contact_sheet.png](./proof/visual_verification_contact_sheet.png)
