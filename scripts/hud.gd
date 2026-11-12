class_name MonasteryHUD
extends CanvasLayer

## Event-driven HUD for Samye Monastery.
## Subscribes to signals from DayNightCycle, MonasteryPhaseManager, BuildingPlot, and Stupa
## instead of polling the scene tree every frame.

@export var cycle_timer: DayNightCycle
@export var phase_manager: MonasteryPhaseManager

@onready var margin_container: MarginContainer = $MarginContainer
@onready var vbox: VBoxContainer = $MarginContainer/VBoxContainer
@onready var phase_label: Label = $MarginContainer/VBoxContainer/PhaseLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var foundation_label: Label = $MarginContainer/VBoxContainer/FoundationLabel
@onready var sanctity_label: Label = $MarginContainer/VBoxContainer/SanctityLabel
@onready var controls_label: Label = $MarginContainer/VBoxContainer/ControlsLabel

var lore_modal: SacredLoreModal = null


func _ready() -> void:
	if cycle_timer == null:
		cycle_timer = get_node_or_null("../DayNightCycle") as DayNightCycle
	if phase_manager == null:
		phase_manager = get_node_or_null("../MonasteryPhaseManager") as MonasteryPhaseManager

	_setup_portrait_and_lore_ui()
	_connect_gameplay_signals()
	_refresh_buildings_hud()
	_refresh_sanctity_and_protectors()


func _connect_gameplay_signals() -> void:
	if cycle_timer:
		cycle_timer.time_updated.connect(_on_time_updated)
		cycle_timer.phase_changed.connect(_on_phase_changed)
		_update_phase_text(cycle_timer.current_phase)

	if phase_manager:
		phase_manager.monastery_sanctity_changed.connect(_on_sanctity_changed)

	for node in get_tree().get_nodes_in_group("building_plots"):
		var plot := node as BuildingPlot
		if plot:
			plot.building_completed.connect(_refresh_buildings_hud)
			plot.building_dismantled.connect(_refresh_buildings_hud)

	var stupa := get_tree().get_first_node_in_group("stupa") as Stupa
	if stupa:
		stupa.dharmapala_joined.connect(func(_total: int) -> void:
			_refresh_sanctity_and_protectors()
		)


func _setup_portrait_and_lore_ui() -> void:
	# 1. Add Guru Rinpoche Close-Up Portrait Frame next to HUD labels
	var portrait_tex := ModelTextures.get_tex(ModelTextures.GURU_PORTRAIT)
	if portrait_tex and margin_container and vbox:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)

		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.10, 0.08, 0.92)
		style.border_color = Color(0.95, 0.80, 0.32, 1.0)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)
		panel.custom_minimum_size = Vector2(76, 108)

		var tex_rect := TextureRect.new()
		tex_rect.texture = portrait_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.custom_minimum_size = Vector2(72, 104)
		tex_rect.tooltip_text = "Click to inspect Padmasambhava Model Sheet [L]"
		panel.add_child(tex_rect)

		margin_container.remove_child(vbox)
		hbox.add_child(panel)
		hbox.add_child(vbox)
		margin_container.add_child(hbox)

	# 2. Add interactive Sacred Lore & Models Button
	if vbox:
		var lore_btn := Button.new()
		lore_btn.text = "📜 Inspect Sacred Models: Guru · Stupa · Samye · Monk [Press L / TAB]"
		lore_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		lore_btn.custom_minimum_size = Vector2(0, 28)
		lore_btn.pressed.connect(func() -> void:
			if lore_modal:
				lore_modal.toggle_modal()
		)
		vbox.add_child(lore_btn)

	# 3. Instantiate SacredLoreModal overlay inside HUD CanvasLayer
	lore_modal = SacredLoreModal.new()
	lore_modal.name = "SacredLoreModal"
	add_child(lore_modal)


func _on_time_updated(_normalized_time: float, seconds_left: float) -> void:
	var total_sec := int(ceilf(seconds_left))
	var mins := total_sec / 60
	var secs := total_sec % 60
	time_label.text = "Time Left: %02d:%02d" % [mins, secs]


func _on_phase_changed(phase: DayNightCycle.Phase) -> void:
	_update_phase_text(phase)


func _update_phase_text(phase: DayNightCycle.Phase) -> void:
	var phase_name := "Day (Workers Building)" if phase == DayNightCycle.Phase.DAY else "Night (Spirits Attacking!)"
	var day_num := cycle_timer.current_day if cycle_timer else 1
	phase_label.text = "Day %d — %s" % [day_num, phase_name]

	if controls_label:
		if phase == DayNightCycle.Phase.DAY:
			controls_label.text = "[WASD]: Move | [SPACE]: Chant Mantra (2x Workers!) | [L]: Sacred Models"
			controls_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45, 0.95))
		else:
			controls_label.text = "[WASD]: Move | [SPACE]: Cleanse Spirits | [L]: Sacred Models"
			controls_label.add_theme_color_override("font_color", Color(0.45, 0.88, 1.0, 0.95))


func _refresh_buildings_hud() -> void:
	var plots := get_tree().get_nodes_in_group("building_plots")
	var completed := 0
	var total := plots.size()
	for p in plots:
		var plot := p as BuildingPlot
		if plot and plot.is_completed():
			completed += 1

	if total > 0:
		foundation_label.text = "Samye Temples: %d / %d Completed" % [completed, total]


func _on_sanctity_changed(_current: float, _max_val: float) -> void:
	_refresh_sanctity_and_protectors()


func _refresh_sanctity_and_protectors() -> void:
	var stupa := get_tree().get_first_node_in_group("stupa") as Stupa
	var practicing_count: int = stupa.practicing_count if stupa else 0
	var sanct_val := phase_manager.current_sanctity if phase_manager else 100.0
	var max_s := phase_manager.max_sanctity if phase_manager else 100.0
	sanctity_label.text = "Sanctity: %d / %d | 🛕 Stupa Protectors: %d" % [int(sanct_val), int(max_s), practicing_count]
