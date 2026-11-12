class_name CorruptedSpirit
extends CharacterBody2D

## Wilderness Spirit with 4 distinct Spirit Archetypes and Dual-Appearance 4-Directional Turnaround Sprites:
##   0. MIST_DEMON  : Mountain Mist Demon (Wrathful) -> Clear Sky Guardian (Cleansed)
##   1. FIRE_IMP    : Wrathful Fire Imp (Wrathful)   -> Courage Flame Guardian (Cleansed)
##   2. SHADOW_CAVE : Shadow Cave Demon (Wrathful)   -> Cave Light Guardian (Cleansed)
##   3. STONE_GIANT : Stone Giant Demon (Wrathful)   -> Temple Guardian Giant (Cleansed)

enum FacingDirection { DOWN, UP, LEFT, RIGHT }

enum SpiritArchetype {
	MIST_DEMON = 0,
	FIRE_IMP = 1,
	SHADOW_CAVE = 2,
	STONE_GIANT = 3
}

static var active_archetype_pair: Array[SpiritArchetype] = []
static var _pair_spawn_counter: int = 0

@export_group("Archetype Selection")
@export var use_random_active_pair: bool = true
@export var spirit_archetype: SpiritArchetype = SpiritArchetype.MIST_DEMON

@export_group("Movement & Combat")
@export var move_speed: float = 65.0
@export var follow_speed: float = 120.0
@export var dismantle_power_per_sec: float = 14.0
@export var follow_distance: float = 75.0

@export_group("Visual Scale & Palette")
@export var corrupted_sprite_scale: Vector2 = Vector2(0.34, 0.34)
@export var cleansed_sprite_scale: Vector2 = Vector2(0.32, 0.32)
@export var corrupted_color: Color = Color(0.98, 0.98, 1.0, 1.0)
@export var subjugated_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var guardian_halo_color: Color = Color(0.48, 0.82, 1.0, 0.72)

@onready var corruption: CorruptionComponent = $CorruptionComponent
@onready var sprite: Sprite2D = $Sprite2D

var is_subjugated: bool = false
var is_ascended: bool = false

var player_target: Node2D = null
var cycle_timer: DayNightCycle = null
var target_building: BuildingPlot = null
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var is_attacking_building: bool = false
var attack_target_offset: Vector2 = Vector2.ZERO

var corrupted_dir_textures: Dictionary = {}
var cleansed_dir_textures: Dictionary = {}
var current_facing: FacingDirection = FacingDirection.DOWN
var hover_phase: float = 0.0


static func roll_random_archetype_pair() -> Array[SpiritArchetype]:
	var pool: Array[SpiritArchetype] = [
		SpiritArchetype.MIST_DEMON,
		SpiritArchetype.FIRE_IMP,
		SpiritArchetype.SHADOW_CAVE,
		SpiritArchetype.STONE_GIANT
	]
	pool.shuffle()
	active_archetype_pair = [pool[0], pool[1]]
	_pair_spawn_counter = 0
	return active_archetype_pair


static func pick_from_active_pair() -> SpiritArchetype:
	if active_archetype_pair.size() < 2:
		roll_random_archetype_pair()
	var idx := _pair_spawn_counter % 2
	_pair_spawn_counter += 1
	return active_archetype_pair[idx]


func _ready() -> void:
	add_to_group("spirits")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	hover_phase = randf_range(0.0, TAU)

	if use_random_active_pair:
		spirit_archetype = pick_from_active_pair()

	_load_spirit_textures_for_archetype(spirit_archetype)

	if corruption:
		corruption.cleansed.connect(_on_cleansed)
		corruption.corruption_changed.connect(_on_corruption_changed)

	cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	if cycle_timer:
		cycle_timer.phase_changed.connect(_on_phase_changed)
		_update_phase_visibility(cycle_timer.current_phase)

	_apply_visual_state()
	_pick_new_wander()


func _load_spirit_textures_for_archetype(arch: SpiritArchetype) -> void:
	corrupted_dir_textures.clear()
	cleansed_dir_textures.clear()

	match arch:
		SpiritArchetype.MIST_DEMON:
			corrupted_dir_textures[FacingDirection.DOWN]  = ModelTextures.get_tex(ModelTextures.SPIRIT_CORRUPTED_FRONT)
			corrupted_dir_textures[FacingDirection.UP]    = ModelTextures.get_tex(ModelTextures.SPIRIT_CORRUPTED_BACK)
			corrupted_dir_textures[FacingDirection.LEFT]  = ModelTextures.get_tex(ModelTextures.SPIRIT_CORRUPTED_LEFT)
			corrupted_dir_textures[FacingDirection.RIGHT] = ModelTextures.get_tex(ModelTextures.SPIRIT_CORRUPTED_RIGHT)

			cleansed_dir_textures[FacingDirection.DOWN]   = ModelTextures.get_tex(ModelTextures.SPIRIT_CLEANSED_FRONT)
			cleansed_dir_textures[FacingDirection.UP]     = ModelTextures.get_tex(ModelTextures.SPIRIT_CLEANSED_BACK)
			cleansed_dir_textures[FacingDirection.LEFT]   = ModelTextures.get_tex(ModelTextures.SPIRIT_CLEANSED_LEFT)
			cleansed_dir_textures[FacingDirection.RIGHT]  = ModelTextures.get_tex(ModelTextures.SPIRIT_CLEANSED_RIGHT)

			corrupted_sprite_scale = Vector2(0.34, 0.34)
			cleansed_sprite_scale  = Vector2(0.32, 0.32)
			guardian_halo_color    = Color(0.48, 0.82, 1.0, 0.75)

		SpiritArchetype.FIRE_IMP:
			corrupted_dir_textures[FacingDirection.DOWN]  = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CORRUPTED_FRONT)
			corrupted_dir_textures[FacingDirection.UP]    = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CORRUPTED_BACK)
			corrupted_dir_textures[FacingDirection.LEFT]  = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CORRUPTED_LEFT)
			corrupted_dir_textures[FacingDirection.RIGHT] = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CORRUPTED_RIGHT)

			cleansed_dir_textures[FacingDirection.DOWN]   = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CLEANSED_FRONT)
			cleansed_dir_textures[FacingDirection.UP]     = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CLEANSED_BACK)
			cleansed_dir_textures[FacingDirection.LEFT]   = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CLEANSED_LEFT)
			cleansed_dir_textures[FacingDirection.RIGHT]  = ModelTextures.get_tex(ModelTextures.FIRE_IMP_CLEANSED_RIGHT)

			corrupted_sprite_scale = Vector2(0.35, 0.35)
			cleansed_sprite_scale  = Vector2(0.34, 0.34)
			guardian_halo_color    = Color(1.0, 0.68, 0.22, 0.80)

		SpiritArchetype.SHADOW_CAVE:
			corrupted_dir_textures[FacingDirection.DOWN]  = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CORRUPTED_FRONT)
			corrupted_dir_textures[FacingDirection.UP]    = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CORRUPTED_BACK)
			corrupted_dir_textures[FacingDirection.LEFT]  = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CORRUPTED_LEFT)
			corrupted_dir_textures[FacingDirection.RIGHT] = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CORRUPTED_RIGHT)

			cleansed_dir_textures[FacingDirection.DOWN]   = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CLEANSED_FRONT)
			cleansed_dir_textures[FacingDirection.UP]     = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CLEANSED_BACK)
			cleansed_dir_textures[FacingDirection.LEFT]   = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CLEANSED_LEFT)
			cleansed_dir_textures[FacingDirection.RIGHT]  = ModelTextures.get_tex(ModelTextures.SHADOW_CAVE_CLEANSED_RIGHT)

			corrupted_sprite_scale = Vector2(0.44, 0.44)
			cleansed_sprite_scale  = Vector2(0.44, 0.44)
			guardian_halo_color    = Color(0.72, 0.62, 1.0, 0.80)

		SpiritArchetype.STONE_GIANT:
			corrupted_dir_textures[FacingDirection.DOWN]  = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CORRUPTED_FRONT)
			corrupted_dir_textures[FacingDirection.UP]    = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CORRUPTED_BACK)
			corrupted_dir_textures[FacingDirection.LEFT]  = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CORRUPTED_LEFT)
			corrupted_dir_textures[FacingDirection.RIGHT] = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CORRUPTED_RIGHT)

			cleansed_dir_textures[FacingDirection.DOWN]   = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CLEANSED_FRONT)
			cleansed_dir_textures[FacingDirection.UP]     = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CLEANSED_BACK)
			cleansed_dir_textures[FacingDirection.LEFT]   = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CLEANSED_LEFT)
			cleansed_dir_textures[FacingDirection.RIGHT]  = ModelTextures.get_tex(ModelTextures.STONE_GIANT_CLEANSED_RIGHT)

			corrupted_sprite_scale = Vector2(0.40, 0.40)
			cleansed_sprite_scale  = Vector2(0.40, 0.40)
			guardian_halo_color    = Color(0.88, 0.78, 0.36, 0.80)


func set_archetype(arch: SpiritArchetype) -> void:
	spirit_archetype = arch
	_load_spirit_textures_for_archetype(spirit_archetype)
	_apply_visual_state()


func _on_phase_changed(phase: DayNightCycle.Phase) -> void:
	_update_phase_visibility(phase)
	if phase == DayNightCycle.Phase.DAY and not is_subjugated:
		queue_free()


func _update_phase_visibility(phase: DayNightCycle.Phase) -> void:
	visible = (phase == DayNightCycle.Phase.NIGHT) and not is_ascended


func _physics_process(delta: float) -> void:
	if is_ascended:
		return

	if cycle_timer and cycle_timer.is_day():
		velocity = Vector2.ZERO
		return

	if is_subjugated:
		_process_follow_guru_rinpoche(delta)
	else:
		_process_corrupted_behavior(delta)

	move_and_slide()
	_update_turnaround_and_hover(delta)
	queue_redraw()


func _update_turnaround_and_hover(delta: float) -> void:
	hover_phase += delta * (4.2 if is_subjugated else 3.2)

	if velocity.length_squared() > 9.0:
		if absf(velocity.x) > absf(velocity.y):
			current_facing = FacingDirection.RIGHT if velocity.x > 0.0 else FacingDirection.LEFT
		else:
			current_facing = FacingDirection.DOWN if velocity.y > 0.0 else FacingDirection.UP
	elif not is_subjugated and target_building and is_instance_valid(target_building):
		_face_towards(target_building.global_position)
	elif is_subjugated and player_target and is_instance_valid(player_target):
		_face_towards(player_target.global_position)

	if sprite:
		var active_map: Dictionary = cleansed_dir_textures if is_subjugated else corrupted_dir_textures
		var tex: Texture2D = active_map.get(current_facing) as Texture2D
		if tex:
			sprite.texture = tex
		var base_scale := cleansed_sprite_scale if is_subjugated else corrupted_sprite_scale
		var pulse := 1.0 + sin(hover_phase) * 0.035
		sprite.scale = base_scale * Vector2(pulse, 2.0 - pulse)
		sprite.position = Vector2(0.0, -14.0 + sin(hover_phase) * 3.5)


func _face_towards(target_pos: Vector2) -> void:
	var diff := target_pos - global_position
	if absf(diff.x) > absf(diff.y):
		current_facing = FacingDirection.RIGHT if diff.x > 0.0 else FacingDirection.LEFT
	else:
		current_facing = FacingDirection.DOWN if diff.y >= 0.0 else FacingDirection.UP


func _process_corrupted_behavior(delta: float) -> void:
	is_attacking_building = false

	if player_target == null:
		player_target = get_tree().get_first_node_in_group("player")

	var player_dist := 999999.0
	if player_target:
		player_dist = global_position.distance_to(player_target.global_position)

	if player_dist < 140.0:
		var dir := (player_target.global_position - global_position).normalized()
		velocity = dir * move_speed
		return

	if target_building == null or not is_instance_valid(target_building):
		target_building = _find_nearest_building()

	if target_building:
		var dist := global_position.distance_to(target_building.global_position)
		if dist > 48.0:
			var dir := (target_building.global_position - global_position).normalized()
			velocity = dir * move_speed
		else:
			velocity = Vector2.ZERO
			is_attacking_building = true
			attack_target_offset = (target_building.global_position - global_position).limit_length(46.0)
			target_building.dismantle(dismantle_power_per_sec * delta, int(spirit_archetype))
	else:
		wander_timer -= delta
		if wander_timer <= 0.0:
			_pick_new_wander()
		velocity = wander_direction * (move_speed * 0.5)


func _process_follow_guru_rinpoche(delta: float) -> void:
	if is_ascended:
		return

	var stupa := get_tree().get_first_node_in_group("stupa") as Stupa
	if stupa and is_instance_valid(stupa):
		var stupa_dist := global_position.distance_to(stupa.global_position)
		if stupa_dist <= (stupa.stupa_radius + 20.0):
			ascend_into_stupa(stupa)
			return

	if player_target == null:
		player_target = get_tree().get_first_node_in_group("player")

	if player_target:
		var dist := global_position.distance_to(player_target.global_position)
		if dist > follow_distance:
			var dir := (player_target.global_position - global_position).normalized()
			velocity = dir * follow_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)
	else:
		velocity = Vector2.ZERO


func ascend_into_stupa(stupa: Stupa) -> void:
	if is_ascended:
		return
	is_ascended = true
	velocity = Vector2.ZERO
	stupa.register_ascended_dharmapala()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", stupa.global_position + Vector2(0, -32), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.45)
	tween.tween_property(self, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(queue_free)


func _find_nearest_building() -> BuildingPlot:
	var best_plot: BuildingPlot = null
	var best_dist := 999999.0

	for node in get_tree().get_nodes_in_group("building_plots"):
		var plot := node as BuildingPlot
		if plot and (plot.wood_delivered > 0 or plot.stone_delivered > 0 or plot.construction_progress > 0):
			var dist := global_position.distance_to(plot.global_position)
			if dist < best_dist:
				best_dist = dist
				best_plot = plot

	if best_plot == null:
		for node in get_tree().get_nodes_in_group("building_plots"):
			var plot := node as BuildingPlot
			if plot:
				var dist := global_position.distance_to(plot.global_position)
				if dist < best_dist:
					best_dist = dist
					best_plot = plot

	return best_plot


func _pick_new_wander() -> void:
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	wander_timer = randf_range(2.0, 4.0)


func _on_cleansed() -> void:
	is_subjugated = true
	add_to_group("dharmapalas")

	collision_layer = 0
	collision_mask = 0
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)

	_apply_visual_state()
	queue_redraw()


func _on_corruption_changed(_cur: float, _max: float) -> void:
	queue_redraw()


func _apply_visual_state() -> void:
	if sprite:
		var active_map: Dictionary = cleansed_dir_textures if is_subjugated else corrupted_dir_textures
		var tex: Texture2D = active_map.get(current_facing) as Texture2D
		if tex:
			sprite.texture = tex
		sprite.scale = cleansed_sprite_scale if is_subjugated else corrupted_sprite_scale

		var target_color := subjugated_color if is_subjugated else corrupted_color
		if is_subjugated:
			sprite.modulate = Color(1.6, 1.7, 2.0, 1.0)
			var tween := create_tween()
			tween.tween_property(sprite, "modulate", target_color, 0.45)
		else:
			sprite.modulate = target_color


func _draw() -> void:
	if not visible or corruption == null or is_ascended:
		return

	if not is_subjugated:
		draw_circle(Vector2(0, 18), 20.0, Color(0.18, 0.16, 0.24, 0.38))

		if is_attacking_building:
			_draw_archetype_attack_effect()

		var bar_width := 46.0
		var bar_height := 6.0
		var bar_pos := Vector2(-bar_width / 2.0, -64.0)

		draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.10, 0.11, 0.16, 0.85))
		var fill_width := bar_width * corruption.get_corruption_ratio()
		draw_rect(Rect2(bar_pos, Vector2(fill_width, bar_height)), Color(0.85, 0.32, 0.45, 0.95))
		draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.82, 0.84, 0.94, 0.55), false, 1.0)
	else:
		var halo_y := -14.0 + sin(hover_phase) * 3.5
		draw_circle(Vector2(0, halo_y), 32.0, Color(guardian_halo_color.r, guardian_halo_color.g, guardian_halo_color.b, 0.16))
		draw_arc(Vector2(0, halo_y), 30.0, 0.0, TAU, 32, guardian_halo_color, 2.0)
		draw_circle(Vector2(0, halo_y - 34.0), 3.5, Color(1.0, 0.92, 0.45, 0.95))


func _draw_archetype_attack_effect() -> void:
	var t := hover_phase * 1.6
	match spirit_archetype:
		SpiritArchetype.MIST_DEMON:
			for i in range(4):
				var frac := float(i + 1) / 4.0
				var puff_pos := attack_target_offset * frac + Vector2(cos(t + i * 1.5) * 10.0, sin(t * 1.3 + i) * 7.0)
				draw_circle(puff_pos, 10.0 + frac * 8.0, Color(0.55, 0.62, 0.82, 0.38))
				draw_arc(puff_pos, 12.0 + frac * 6.0, t + i, t + i + PI * 1.2, 16, Color(0.82, 0.84, 0.96, 0.55), 2.0)

		SpiritArchetype.FIRE_IMP:
			draw_circle(Vector2(0, -10), 26.0 + sin(t * 3.0) * 4.0, Color(0.95, 0.32, 0.12, 0.28))
			for i in range(6):
				var spark_phase := fmod(t * 2.2 + float(i) * 0.6, 1.0)
				var side := sin(t * 4.0 + i * 2.1) * 14.0
				var normal := Vector2(-attack_target_offset.y, attack_target_offset.x).normalized()
				var sp_pos := attack_target_offset * spark_phase + normal * side
				draw_circle(sp_pos, 4.5 * (1.0 - spark_phase * 0.4), Color(1.0, 0.48, 0.14, 0.85))
				draw_circle(sp_pos, 2.2, Color(1.0, 0.92, 0.35, 0.95))

		SpiritArchetype.SHADOW_CAVE:
			draw_circle(Vector2(0, -8), 28.0, Color(0.14, 0.08, 0.24, 0.42))
			var prev := Vector2(0, -8)
			for seg in range(1, 5):
				var frac := float(seg) / 4.0
				var jitter := Vector2(sin(t * 5.0 + seg * 2.3) * 9.0, cos(t * 4.5 + seg * 1.9) * 9.0)
				var next_pt := attack_target_offset * frac + (jitter if seg < 4 else Vector2.ZERO)
				draw_line(prev, next_pt, Color(0.72, 0.38, 0.98, 0.88), 2.4)
				prev = next_pt

		SpiritArchetype.STONE_GIANT:
			var slam := absf(sin(t * 1.8))
			var ring_r := 16.0 + slam * 28.0
			draw_arc(attack_target_offset * 0.6, ring_r, 0.0, TAU, 24, Color(0.62, 0.56, 0.46, (1.0 - slam) * 0.85), 3.0)
			for i in range(4):
				var ang := t * 1.2 + float(i) * (TAU / 4.0)
				var rock_pos := attack_target_offset * 0.5 + Vector2(cos(ang), sin(ang)) * (12.0 + slam * 14.0)
				draw_rect(Rect2(rock_pos - Vector2(4, 4), Vector2(8, 7)), Color(0.46, 0.44, 0.40, 0.90))
