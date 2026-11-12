class_name GuruPlayer
extends CharacterBody2D

## Player controller for Guru Padmasambhava (Guru Rinpoche).
## - Day Phase: Chants "Om Ma Ni Pema Hom" to empower nearby craftsmen (2x speed) and aid construction.
## - Night Phase: Pulses the Purification Aura to pacify corrupted spirits into Dharmapalas.
## - Visuals: Uses 4-directional turnaround sprites extracted via the `samye-visual-models` skill.

enum FacingDirection {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

@export_group("Movement & Mantra")
@export var speed: float = 300.0
@export var guru_build_power: float = 35.0 ## Extra building speed when Guru aids workers
@export var mantra_radius: float = 220.0
@export var mantra_boost_duration: float = 3.0

@export_group("Visual Presentation")
@export var base_sprite_scale: Vector2 = Vector2(0.24, 0.24)
@export var sprite_foot_offset: Vector2 = Vector2(0.0, -34.0)

@onready var aura: PurificationAura = get_node_or_null("PurificationAura") as PurificationAura
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

var cycle_timer: DayNightCycle = null
var audio_manager: MonasteryAudio = null
var is_helping_build: bool = false
var mantra_wave_progress: float = 1.0 ## 0.0 to 1.0 when chanting
var mantra_text_progress: float = 1.0 ## 0.0 to 1.0 for floating chant

var current_facing: FacingDirection = FacingDirection.DOWN
var directional_textures: Dictionary = {}
var walk_anim_time: float = 0.0


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_register_default_input_bindings()

	cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	audio_manager = get_tree().root.find_child("MonasteryAudio", true, false) as MonasteryAudio

	_setup_guru_turnaround_sprites()


func _register_default_input_bindings() -> void:
	_add_key_to_action("ui_up", KEY_W)
	_add_key_to_action("ui_left", KEY_A)
	_add_key_to_action("ui_down", KEY_S)
	_add_key_to_action("ui_right", KEY_D)
	_add_key_to_action("purify", KEY_SPACE)


func _setup_guru_turnaround_sprites() -> void:
	directional_textures[FacingDirection.DOWN] = ModelTextures.get_tex(ModelTextures.GURU_FRONT)
	directional_textures[FacingDirection.UP] = ModelTextures.get_tex(ModelTextures.GURU_BACK)
	directional_textures[FacingDirection.LEFT] = ModelTextures.get_tex(ModelTextures.GURU_LEFT)
	directional_textures[FacingDirection.RIGHT] = ModelTextures.get_tex(ModelTextures.GURU_RIGHT)

	_apply_facing_texture(FacingDirection.DOWN)
	if sprite:
		sprite.scale = base_sprite_scale
		sprite.position = sprite_foot_offset


func _apply_facing_texture(facing: FacingDirection) -> void:
	current_facing = facing
	if sprite == null:
		return
	var tex := directional_textures.get(facing) as Texture2D
	if tex:
		sprite.texture = tex


func _add_key_to_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _unhandled_input(event: InputEvent) -> void:
	var is_action_key := event.is_action("purify") or event.is_action("ui_accept")
	if not is_action_key:
		return

	var is_day := cycle_timer.is_day() if cycle_timer else true

	if event.is_pressed() and not event.is_echo():
		trigger_mantra_chant()

		if is_day:
			is_helping_build = true
			chant_daytime_mantra()
		else:
			if aura:
				aura.trigger_pulse()
	elif not event.is_pressed():
		is_helping_build = false


## Plays sacred singing bowl sound and spawns the floating chant "Om Ma Ni Pema Hom"
func trigger_mantra_chant() -> void:
	if audio_manager:
		audio_manager.play_mantra_chime()
	mantra_text_progress = 0.0
	queue_redraw()


## Chants the sacred mantra to double workers' actions for `mantra_boost_duration` seconds!
func chant_daytime_mantra() -> void:
	mantra_wave_progress = 0.0
	queue_redraw()

	var workers := get_tree().get_nodes_in_group("workers")
	for w in workers:
		var worker := w as SamyeWorker
		if worker and global_position.distance_to(worker.global_position) <= mantra_radius:
			worker.apply_mantra_boost(mantra_boost_duration)


func _process(delta: float) -> void:
	var needs_redraw := false

	if mantra_wave_progress < 1.0:
		mantra_wave_progress = minf(1.0, mantra_wave_progress + delta / 0.45)
		needs_redraw = true

	if mantra_text_progress < 1.0:
		mantra_text_progress = minf(1.0, mantra_text_progress + delta / 1.1)
		needs_redraw = true

	if needs_redraw:
		queue_redraw()


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

	_update_directional_sprite(direction, delta)

	# If holding Space near a building plot during Day, help construct it
	if is_helping_build and cycle_timer and cycle_timer.is_day():
		var plot := _get_nearest_building_plot(150.0)
		if plot and plot.needs_work():
			plot.add_construction_work(guru_build_power * delta)


func _update_directional_sprite(direction: Vector2, delta: float) -> void:
	if sprite == null:
		return

	if direction.length_squared() > 0.01:
		walk_anim_time += delta * 10.0
		if absf(direction.x) > absf(direction.y):
			_apply_facing_texture(FacingDirection.LEFT if direction.x < 0.0 else FacingDirection.RIGHT)
		else:
			_apply_facing_texture(FacingDirection.UP if direction.y < 0.0 else FacingDirection.DOWN)

		var bob := sin(walk_anim_time) * 2.5
		sprite.position = sprite_foot_offset + Vector2(0.0, bob)
		sprite.scale = base_sprite_scale * Vector2(1.0, 1.0 + sin(walk_anim_time * 2.0) * 0.02)
	else:
		walk_anim_time += delta * 2.5
		var breath := sin(walk_anim_time) * 0.015
		sprite.position = sprite_foot_offset
		sprite.scale = base_sprite_scale * Vector2(1.0 - breath * 0.5, 1.0 + breath)


func _get_nearest_building_plot(max_dist: float) -> BuildingPlot:
	var best_plot: BuildingPlot = null
	var best_dist := max_dist

	for node in get_tree().get_nodes_in_group("building_plots"):
		var plot := node as BuildingPlot
		if plot:
			var dist := global_position.distance_to(plot.global_position)
			if dist < best_dist:
				best_dist = dist
				best_plot = plot

	return best_plot


func _draw() -> void:
	# Subtle golden lotus ground shadow/halo beneath Guru Rinpoche's boots
	draw_circle(Vector2(0, 18), 22.0, Color(1.0, 0.9, 0.45, 0.22))
	draw_arc(Vector2(0, 18), 22.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, 0.55), 1.5)

	# Expanding golden wave when chanting mantra by day
	if mantra_wave_progress < 1.0:
		var r := mantra_radius * ease(mantra_wave_progress, 0.25)
		var alpha := (1.0 - mantra_wave_progress) * 0.9
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 0.9, 0.3, alpha), 3.0)
		draw_circle(Vector2.ZERO, r * 0.35, Color(1.0, 0.95, 0.5, alpha * 0.25))

	# Floating Sacred Chant: "Om Ma Ni Pema Hom"
	if mantra_text_progress < 1.0:
		var float_y := -96.0 - (mantra_text_progress * 42.0)
		var alpha := (1.0 - mantra_text_progress)
		var chant_text := "Om Ma Ni Pema Hom"

		# Glowing background aura for the text
		var bg_rect := Rect2(-95, float_y - 14, 190, 22)
		draw_rect(bg_rect, Color(0.15, 0.1, 0.05, alpha * 0.75))
		draw_rect(bg_rect, Color(1.0, 0.85, 0.2, alpha * 0.85), false, 1.5)

		# Radiant golden mantra text
		draw_string(ThemeDB.fallback_font, Vector2(-90, float_y + 2), chant_text, HORIZONTAL_ALIGNMENT_CENTER, 180, 14, Color(1.0, 0.95, 0.5, alpha))
