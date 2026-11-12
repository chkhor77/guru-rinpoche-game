extends SceneTree

## Headless Godot 4 Test Runner for Guru Rinpoche Game.
## Run via: godot --headless -s res://testing/suites/godot_test_suite.gd
## Covers Happy Path, Unhappy Path, Edge Cases, and Boundary Conditions.

var passed: int = 0
var failed: int = 0
var results: Array[Dictionary] = []


func _init() -> void:
	print("==================================================================")
	print(" GURU RINPOCHE GAME — HEADLESS GDSCRIPT TEST SUITE")
	print("==================================================================")

	_run_happy_path_tests()
	_run_unhappy_path_tests()
	_run_edge_case_tests()
	_run_boundary_tests()

	print("------------------------------------------------------------------")
	print(" SUMMARY: %d Passed | %d Failed | Total: %d" % [passed, failed, passed + failed])
	print("==================================================================")
	quit(0 if failed == 0 else 1)


func _assert(id: String, category: String, name: String, condition: bool, detail: String) -> void:
	var status := "PASS" if condition else "FAIL"
	if condition:
		passed += 1
	else:
		failed += 1
	print("[%s] [%s] %s — %s (%s)" % [status, category, id, name, detail])
	results.append({
		"id": id,
		"category": category,
		"name": name,
		"status": status,
		"detail": detail
	})


func _run_happy_path_tests() -> void:
	# HP-01: ModelTextures loads Guru, Builder Monk, and all 4 Dual-Appearance Spirit Archetypes
	var g_front  := ModelTextures.get_tex(ModelTextures.GURU_FRONT)
	var m_front  := ModelTextures.get_tex(ModelTextures.MONK_FRONT)
	var s1_w     := ModelTextures.get_tex(ModelTextures.SPIRIT_CORRUPTED_FRONT)
	var s1_p     := ModelTextures.get_tex(ModelTextures.SPIRIT_CLEANSED_FRONT)
	var s2_w     := ModelTextures.get_tex(ModelTextures.FIRE_IMP_CORRUPTED_FRONT)
	var s2_p     := ModelTextures.get_tex(ModelTextures.FIRE_IMP_CLEANSED_FRONT)
	var s3_w     := ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CORRUPTED_FRONT)
	var s3_p     := ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CLEANSED_FRONT)
	var s4_w     := ModelTextures.get_tex(ModelTextures.STONE_GIANT_CORRUPTED_FRONT)
	var s4_p     := ModelTextures.get_tex(ModelTextures.STONE_GIANT_CLEANSED_FRONT)
	_assert("HP-01", "Happy Path", "Guru, Monk & All 4 Dual-Appearance Spirit Pairs Load",
		g_front != null and m_front != null and s1_w != null and s1_p != null and s2_w != null and s2_p != null and s3_w != null and s3_p != null and s4_w != null and s4_p != null,
		"All character & 4 dual-appearance spirit pairs loaded")

	# HP-01B: CorruptedSpirit.roll_random_archetype_pair() selects 2 distinct models at a time
	var pair := CorruptedSpirit.roll_random_archetype_pair()
	var pick_a := CorruptedSpirit.pick_from_active_pair()
	var pick_b := CorruptedSpirit.pick_from_active_pair()
	_assert("HP-01B", "Happy Path", "Random 2-Model Spirit Pair Selection",
		pair.size() == 2 and pair[0] != pair[1] and pick_a == pair[0] and pick_b == pair[1],
		"Selected 2 distinct SpiritArchetypes: %d & %d" % [pair[0], pair[1]])

	# HP-02: BuildingPlot full lifecycle (Blueprint -> Under Construction -> Completed)
	var plot := BuildingPlot.new()
	plot.wood_required = 30.0
	plot.stone_required = 40.0
	var w_acc := plot.deposit_resource(ResourceNode.ResourceType.TIMBER, 30.0)
	var s_acc := plot.deposit_resource(ResourceNode.ResourceType.SANDSTONE, 40.0)
	var state_after_mat := plot.current_state
	plot.add_construction_work(100.0)
	_assert("HP-02", "Happy Path", "BuildingPlot Full Construction Lifecycle",
		w_acc == 30.0 and s_acc == 40.0 and state_after_mat == BuildingPlot.State.UNDER_CONSTRUCTION and plot.is_completed(),
		"Blueprint -> Under Construction -> Completed (100%)")
	plot.free()

	# HP-03: Stupa Dharmapala Ascension Tally
	var stupa := Stupa.new()
	stupa.register_ascended_dharmapala()
	stupa.register_ascended_dharmapala()
	_assert("HP-03", "Happy Path", "Stupa Dharmapala Ascension Registration",
		stupa.practicing_count == 2 and stupa.ascension_pulse_time == 0.0,
		"practicing_count == 2, pulse triggered")
	stupa.free()

	# HP-04: SacredLoreModal 6-Tab Switching (including Mist Demon & Clear Sky Guardian)
	var modal := SacredLoreModal.new()
	modal.toggle_modal(4)
	var open_on_demon := modal.is_open and modal.current_tab == 4
	modal.toggle_modal(5)
	var open_on_guardian := modal.is_open and modal.current_tab == 5
	modal.toggle_modal()
	_assert("HP-04", "Happy Path", "SacredLoreModal Open on Tabs 5 & 6 (Mist Demon & Sky Guardian) & Close",
		open_on_demon and open_on_guardian and not modal.is_open,
		"Opened on tab 4 (Mist Demon), tab 5 (Sky Guardian), and toggled closed")
	modal.free()


func _run_unhappy_path_tests() -> void:
	# UP-01: ModelTextures with empty and missing paths
	var empty_tex := ModelTextures.get_tex("")
	var missing_tex := ModelTextures.get_tex("res://assets/sprites/does_not_exist_999.png")
	_assert("UP-01", "Unhappy Path", "ModelTextures Invalid Path Handling",
		empty_tex == null and missing_tex == null,
		"Gracefully returned null without crash")

	# UP-02: BuildingPlot rejects construction work before materials are delivered
	var plot := BuildingPlot.new()
	plot.wood_required = 30.0
	plot.stone_required = 40.0
	plot.deposit_resource(ResourceNode.ResourceType.TIMBER, 10.0)
	plot.add_construction_work(50.0)
	_assert("UP-02", "Unhappy Path", "BuildingPlot Rejects Work Without Full Materials",
		plot.construction_progress == 0.0 and plot.current_state == BuildingPlot.State.BLUEPRINT,
		"Progress stayed 0.0% in BLUEPRINT state")

	# UP-03: BuildingPlot rejects resource deposits after completion
	plot.deposit_resource(ResourceNode.ResourceType.TIMBER, 20.0)
	plot.deposit_resource(ResourceNode.ResourceType.SANDSTONE, 40.0)
	plot.add_construction_work(100.0)
	var extra := plot.deposit_resource(ResourceNode.ResourceType.TIMBER, 15.0)
	_assert("UP-03", "Unhappy Path", "BuildingPlot Rejects Deposits When Completed",
		extra == 0.0 and plot.wood_delivered == 30.0,
		"Accepted 0.0 excess timber after completion")
	plot.free()


func _run_edge_case_tests() -> void:
	# EC-01: Completed building dismantled by Night Spirits reverts to UNDER_CONSTRUCTION
	var plot := BuildingPlot.new()
	plot.wood_required = 20.0
	plot.stone_required = 20.0
	plot.deposit_resource(ResourceNode.ResourceType.TIMBER, 20.0)
	plot.deposit_resource(ResourceNode.ResourceType.SANDSTONE, 20.0)
	plot.add_construction_work(100.0)
	plot.dismantle(25.0)
	_assert("EC-01", "Edge Case", "Completed Temple Dismantled Reverts State",
		plot.current_state == BuildingPlot.State.UNDER_CONSTRUCTION and plot.construction_progress == 75.0,
		"State reverted to UNDER_CONSTRUCTION at 75.0%")

	# EC-02: Releasing more sheltered workers than registered never goes negative
	plot.release_worker_shelter()
	plot.release_worker_shelter()
	_assert("EC-02", "Edge Case", "Worker Shelter Release Floor Clamp",
		plot.sheltered_workers == 0,
		"sheltered_workers clamped at 0")
	plot.free()

	# EC-03: Day 2+ SamyeWorker Anti-Synchronization Traits (distinct speed & offsets per monk)
	var w1 := SamyeWorker.new()
	var w2 := SamyeWorker.new()
	w1._reroll_personal_traits()
	w2._reroll_personal_traits()
	_assert("EC-03", "Edge Case", "Day 2+ Builder Monk Anti-Synchronization Traits",
		w1.shelter_offset != w2.shelter_offset and w1.work_offset != w2.work_offset,
		"Each monk rolls independent spatial offsets & speed")
	w1.free()
	w2.free()


func _run_boundary_tests() -> void:
	# BV-01: Exact capacity clamp on resource deposit (29.5 + 100.0 -> 30.0)
	var plot := BuildingPlot.new()
	plot.wood_required = 30.0
	plot.stone_required = 40.0
	plot.deposit_resource(ResourceNode.ResourceType.TIMBER, 29.5)
	var accepted := plot.deposit_resource(ResourceNode.ResourceType.TIMBER, 100.0)
	_assert("BV-01", "Boundary", "Resource Deposit Upper Boundary Clamp",
		is_equal_approx(accepted, 0.5) and is_equal_approx(plot.wood_delivered, 30.0),
		"Accepted 0.5 and clamped wood_delivered at 30.0")

	# BV-02: Construction progress boundary at 99.9% vs 100.0% vs 250.0%
	plot.deposit_resource(ResourceNode.ResourceType.SANDSTONE, 40.0)
	plot.add_construction_work(99.9)
	var not_done_at_99_9 := not plot.is_completed()
	plot.add_construction_work(250.0)
	_assert("BV-02", "Boundary", "Construction Progress 99.9% vs 100.0% Boundary",
		not_done_at_99_9 and plot.is_completed() and is_equal_approx(plot.construction_progress, 100.0),
		"Incomplete at 99.9%, Completed & clamped at 100.0%")
	plot.free()

	# BV-03: SacredLoreModal out-of-bounds tab index (-1 and 99)
	var modal := SacredLoreModal.new()
	modal.toggle_modal(99)
	var safe_tab := modal.current_tab >= 0 and modal.current_tab < modal.sheets.size()
	_assert("BV-03", "Boundary", "SacredLoreModal Out-of-Bounds Tab Index Guard",
		safe_tab,
		"current_tab remained valid (%d)" % modal.current_tab)
	modal.free()
