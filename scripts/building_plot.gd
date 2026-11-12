class_name BuildingPlot
extends Area2D

## A construction plot for Samye Monastery buildings (Utse Temple, Cardinal Shrines).
## Workers deliver Timber and Sandstone here during the Day to erect structures.
## Visually shows construction progress in distinct architectural stages and progress bars.
## At Night, wilderness spirits target and dismantle them if not defended by Guru Rinpoche,
## triggering archetype-specific visual destruction effects based on each spirit's modal abilities!

signal resources_changed(wood: float, stone: float)
signal progress_changed(progress: float)
signal building_completed()
signal building_dismantled()

enum State {
	BLUEPRINT,
	UNDER_CONSTRUCTION,
	COMPLETED
}

enum ArchitectureStyle {
	AUTO,
	CENTRAL_UTSE,
	WEST_PAVILION,
	EAST_PAVILION,
	FRONT_SHRINE
}

@export_group("Building Identity & Requirements")
@export var building_name: String = "Central Utse Temple"
@export var wood_required: float = 30.0
@export var stone_required: float = 40.0
@export var plot_size: Vector2 = Vector2(160, 160)
@export var is_central_temple: bool = false

@export_group("Visual Model")
@export var architecture_style: ArchitectureStyle = ArchitectureStyle.AUTO
@export var custom_completed_texture: Texture2D = null

var current_state: State = State.BLUEPRINT
var wood_delivered: float = 0.0
var stone_delivered: float = 0.0
var construction_progress: float = 0.0
var max_shelter_capacity: int = 4
var sheltered_workers: int = 0

var tex_completed: Texture2D = null
var tex_layout: Texture2D = null

var active_affliction_archetype: int = -1
var affliction_timer: float = 0.0
var affliction_anim_time: float = 0.0


func _ready() -> void:
	add_to_group("building_plots")
	_ensure_collision_shape()
	_resolve_visual_models()

	var cycle := get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	if cycle:
		cycle.day_started.connect(func(_day: int) -> void:
			sheltered_workers = 0
			affliction_timer = 0.0
			active_affliction_archetype = -1
			queue_redraw()
		)


func _process(delta: float) -> void:
	if affliction_timer > 0.0:
		affliction_timer = maxf(0.0, affliction_timer - delta)
		affliction_anim_time += delta * 6.5
		if affliction_timer <= 0.0:
			active_affliction_archetype = -1
		queue_redraw()


func _resolve_visual_models() -> void:
	tex_layout = ModelTextures.get_tex(ModelTextures.SAMYE_TOP_LAYOUT)

	if custom_completed_texture != null:
		tex_completed = custom_completed_texture
		return

	var style := architecture_style
	if style == ArchitectureStyle.AUTO:
		if is_central_temple:
			style = ArchitectureStyle.CENTRAL_UTSE
		elif "West" in building_name:
			style = ArchitectureStyle.WEST_PAVILION
		elif "East" in building_name:
			style = ArchitectureStyle.EAST_PAVILION
		else:
			style = ArchitectureStyle.FRONT_SHRINE

	match style:
		ArchitectureStyle.CENTRAL_UTSE:
			tex_completed = ModelTextures.get_tex(ModelTextures.SAMYE_ISOMETRIC)
		ArchitectureStyle.WEST_PAVILION:
			tex_completed = ModelTextures.get_tex(ModelTextures.SAMYE_SIDE_LEFT)
		ArchitectureStyle.EAST_PAVILION:
			tex_completed = ModelTextures.get_tex(ModelTextures.SAMYE_SIDE_RIGHT)
		_:
			tex_completed = ModelTextures.get_tex(ModelTextures.SAMYE_FRONT)


func _ensure_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)

	var rect := RectangleShape2D.new()
	rect.size = plot_size
	col.shape = rect


func deposit_resource(type: ResourceNode.ResourceType, amount: float) -> float:
	if current_state == State.COMPLETED:
		return 0.0

	var accepted: float = 0.0
	if type == ResourceNode.ResourceType.TIMBER:
		var needed := wood_required - wood_delivered
		accepted = clampf(amount, 0.0, needed)
		wood_delivered += accepted
	else:
		var needed := stone_required - stone_delivered
		accepted = clampf(amount, 0.0, needed)
		stone_delivered += accepted

	resources_changed.emit(wood_delivered, stone_delivered)
	_check_state()
	queue_redraw()
	return accepted


func add_construction_work(amount: float) -> void:
	if current_state == State.COMPLETED:
		return

	if has_all_materials():
		current_state = State.UNDER_CONSTRUCTION
		construction_progress = minf(100.0, construction_progress + amount)
		progress_changed.emit(construction_progress)

		if construction_progress >= 100.0:
			current_state = State.COMPLETED
			building_completed.emit()

		queue_redraw()


func dismantle(amount: float, attacker_archetype: int = -1) -> void:
	if attacker_archetype >= 0:
		active_affliction_archetype = attacker_archetype
		affliction_timer = 0.55

	if construction_progress > 0.0:
		construction_progress = maxf(0.0, construction_progress - amount)
		if construction_progress < 100.0 and current_state == State.COMPLETED:
			current_state = State.UNDER_CONSTRUCTION
		progress_changed.emit(construction_progress)
		building_dismantled.emit()
		queue_redraw()
	elif wood_delivered > 0.0 or stone_delivered > 0.0:
		wood_delivered = maxf(0.0, wood_delivered - amount * 0.5)
		stone_delivered = maxf(0.0, stone_delivered - amount * 0.5)
		resources_changed.emit(wood_delivered, stone_delivered)
		queue_redraw()
	elif attacker_archetype >= 0:
		queue_redraw()


func has_all_materials() -> bool:
	return wood_delivered >= wood_required and stone_delivered >= stone_required


func needs_resource(type: ResourceNode.ResourceType) -> bool:
	if current_state == State.COMPLETED:
		return false
	if type == ResourceNode.ResourceType.TIMBER:
		return wood_delivered < wood_required
	else:
		return stone_delivered < stone_required


func needs_work() -> bool:
	return has_all_materials() and current_state != State.COMPLETED


func is_completed() -> bool:
	return current_state == State.COMPLETED


func can_shelter_worker() -> bool:
	return is_completed() and sheltered_workers < max_shelter_capacity


func register_worker_sheltered() -> void:
	sheltered_workers += 1


func release_worker_shelter() -> void:
	sheltered_workers = maxi(0, sheltered_workers - 1)


func _check_state() -> void:
	if has_all_materials() and current_state == State.BLUEPRINT:
		current_state = State.UNDER_CONSTRUCTION


func _draw() -> void:
	var half := plot_size / 2.0
	var shake_offset := Vector2.ZERO
	if affliction_timer > 0.0:
		var shake_amp := 3.5 if active_affliction_archetype == 3 else 1.8
		shake_offset = Vector2(sin(affliction_anim_time * 7.0) * shake_amp, cos(affliction_anim_time * 5.3) * (shake_amp * 0.6))

	var rect := Rect2(-half + shake_offset, plot_size)

	draw_rect(rect, Color(0.3, 0.25, 0.2, 0.45))

	if current_state == State.COMPLETED:
		draw_circle(shake_offset, half.x * 1.15, Color(1.0, 0.9, 0.45, 0.18))
		draw_arc(shake_offset, half.x * 1.15, 0.0, TAU, 48, Color(1.0, 0.86, 0.35, 0.65), 2.5)

		if tex_completed:
			var draw_w := plot_size.x * (1.45 if is_central_temple else 1.35)
			var aspect := float(tex_completed.get_height()) / float(maxi(1, tex_completed.get_width()))
			var draw_h := draw_w * aspect
			var dst_rect := Rect2(Vector2(-draw_w * 0.5, half.y - draw_h + 12.0) + shake_offset, Vector2(draw_w, draw_h))
			draw_texture_rect(tex_completed, dst_rect, false)
		else:
			draw_rect(rect, Color(0.96, 0.95, 0.92, 1.0))
			draw_rect(Rect2(-half.x, -half.y, plot_size.x, 26), Color(0.68, 0.16, 0.16, 1.0))

	elif current_state == State.UNDER_CONSTRUCTION or construction_progress > 0.0:
		var pct := clampf(construction_progress / 100.0, 0.08, 1.0)

		if tex_layout:
			draw_texture_rect(tex_layout, rect, false, Color(1.0, 0.9, 0.55, 0.35))

		if tex_completed:
			var draw_w := plot_size.x * (1.45 if is_central_temple else 1.35)
			var tex_w := float(tex_completed.get_width())
			var tex_h := float(tex_completed.get_height())
			var draw_h := draw_w * (tex_h / maxf(1.0, tex_w))

			var visible_h := draw_h * pct
			var src_h := tex_h * pct
			var src_rect := Rect2(0.0, tex_h - src_h, tex_w, src_h)
			var dst_rect := Rect2(Vector2(-draw_w * 0.5, (half.y + 12.0) - visible_h) + shake_offset, Vector2(draw_w, visible_h))
			draw_texture_rect_region(tex_completed, dst_rect, src_rect)
		else:
			var wall_height := plot_size.y * pct
			var rising_rect := Rect2(-half.x, half.y - wall_height, plot_size.x, wall_height)
			draw_rect(rising_rect, Color(0.78, 0.32, 0.22, 0.95))

		draw_line(Vector2(-half.x - 4, half.y) + shake_offset, Vector2(-half.x - 4, -half.y) + shake_offset, Color(0.45, 0.3, 0.18, 0.9), 3.0)
		draw_line(Vector2(half.x + 4, half.y) + shake_offset, Vector2(half.x + 4, -half.y) + shake_offset, Color(0.45, 0.3, 0.18, 0.9), 3.0)
		draw_line(Vector2(-half.x - 4, 0) + shake_offset, Vector2(half.x + 4, 0) + shake_offset, Color(0.55, 0.38, 0.22, 0.75), 2.0)

	else:
		if tex_layout:
			draw_texture_rect(tex_layout, rect.grow(-4.0), false, Color(1.0, 0.92, 0.55, 0.42))
		else:
			draw_rect(rect, Color(1.0, 0.88, 0.35, 0.12))
		draw_rect(rect, Color(1.0, 0.85, 0.35, 0.75), false, 2.0)

	if affliction_timer > 0.0 and active_affliction_archetype >= 0:
		_draw_spirit_affliction_effect(half)

	var header_y := -half.y - 36.0
	draw_string(ThemeDB.fallback_font, Vector2(-120, header_y - 18), building_name, HORIZONTAL_ALIGNMENT_CENTER, 240, 13, Color(1.0, 0.95, 0.7))

	var bar_w := 140.0
	var bar_h := 10.0
	var bar_rect := Rect2(-bar_w / 2.0, header_y, bar_w, bar_h)

	draw_rect(bar_rect, Color(0.12, 0.12, 0.15, 0.85))
	var fill_ratio := 1.0 if current_state == State.COMPLETED else (construction_progress / 100.0)
	var fill_w := bar_w * fill_ratio
	var fill_col := Color(0.4, 0.85, 0.45) if current_state == State.COMPLETED else Color(1.0, 0.75, 0.25)
	draw_rect(Rect2(-bar_w / 2.0, header_y, fill_w, bar_h), fill_col)
	draw_rect(bar_rect, Color(0.9, 0.85, 0.7, 0.7), false, 1.0)

	var status_text: String
	if current_state == State.COMPLETED:
		status_text = "100% Completed (Consecrated)"
	elif has_all_materials():
		status_text = "Constructing: %d%%" % int(construction_progress)
	else:
		status_text = "Waiting Materials (🪵 %.0f/%.0f | 🪨 %.0f/%.0f)" % [wood_delivered, wood_required, stone_delivered, stone_required]

	draw_string(ThemeDB.fallback_font, Vector2(-120, header_y + 24), status_text, HORIZONTAL_ALIGNMENT_CENTER, 240, 11, Color(1.0, 1.0, 0.9))


func _draw_spirit_affliction_effect(half: Vector2) -> void:
	var intensity := clampf(affliction_timer / 0.55, 0.0, 1.0)
	var t := affliction_anim_time

	match active_affliction_archetype:
		0:
			for i in range(6):
				var ang := float(i) * (TAU / 6.0) + t * 0.45
				var r_dist := half.x * (0.42 + 0.22 * sin(t + float(i)))
				var p := Vector2(cos(ang) * r_dist, sin(ang) * r_dist * 0.65 - 10.0)
				draw_circle(p, 28.0 + 6.0 * sin(t * 1.5 + float(i)), Color(0.55, 0.62, 0.78, 0.34 * intensity))
				draw_circle(p + Vector2(6, -4), 18.0, Color(0.88, 0.91, 0.98, 0.28 * intensity))
			draw_arc(Vector2(0, -8), half.x * 0.85, t * 0.5, t * 0.5 + PI * 1.35, 32, Color(0.75, 0.82, 0.96, 0.55 * intensity), 3.0)

		1:
			draw_circle(Vector2(0, 6), half.x * 0.82, Color(0.78, 0.16, 0.12, 0.22 * intensity))
			for i in range(8):
				var ang := float(i) * (TAU / 8.0) + t * 1.2
				var burst_r := half.x * (0.35 + fmod(t * 0.55 + float(i) * 0.17, 0.65))
				var spark_pos := Vector2(cos(ang) * burst_r, sin(ang) * burst_r * 0.7 - 14.0)
				draw_circle(spark_pos, 7.5, Color(0.94, 0.47, 0.12, 0.75 * intensity))
				draw_circle(spark_pos + Vector2(0, -5), 4.0, Color(1.0, 0.90, 0.32, 0.90 * intensity))
				var tail := spark_pos - Vector2(cos(ang) * 14.0, sin(ang) * 10.0 - 12.0)
				draw_line(spark_pos, tail, Color(1.0, 0.55, 0.15, 0.80 * intensity), 2.2)

		2:
			draw_circle(Vector2(0, 0), half.x * 0.90, Color(0.10, 0.08, 0.14, 0.42 * intensity))
			for i in range(5):
				var ang := float(i) * (TAU / 5.0) - t * 0.8
				var shard_pos := Vector2(cos(ang) * half.x * 0.68, sin(ang) * half.y * 0.52 - 12.0)
				var shard_pts := PackedVector2Array([
					shard_pos + Vector2(0, -10),
					shard_pos + Vector2(6, 0),
					shard_pos + Vector2(0, 10),
					shard_pos + Vector2(-6, 0)
				])
				draw_colored_polygon(shard_pts, Color(0.61, 0.36, 0.88, 0.82 * intensity))
				var mid := (shard_pos + Vector2(0, -8)) * 0.5 + Vector2(sin(t * 3.0 + float(i)) * 10.0, cos(t * 2.5 + float(i)) * 8.0)
				draw_line(shard_pos, mid, Color(0.82, 0.62, 1.0, 0.85 * intensity), 2.0)
				draw_line(mid, Vector2(0, -8), Color(0.61, 0.36, 0.88, 0.75 * intensity), 2.0)

		3:
			var shock_r := half.x * (0.35 + fmod(t * 0.45, 0.75))
			draw_arc(Vector2(0, 12), shock_r, 0.0, TAU, 36, Color(0.48, 0.30, 0.18, 0.72 * intensity), 3.5)
			draw_arc(Vector2(0, 12), shock_r * 0.68, 0.0, TAU, 32, Color(0.40, 0.38, 0.35, 0.65 * intensity), 2.5)
			for i in range(6):
				var ang := float(i) * (TAU / 6.0) + 0.3
				var rock_r := half.x * (0.45 + 0.18 * absf(sin(t + float(i))))
				var rpos := Vector2(cos(ang) * rock_r, sin(ang) * rock_r * 0.6 + 8.0)
				draw_rect(Rect2(rpos - Vector2(6, 5), Vector2(12, 10)), Color(0.39, 0.38, 0.35, 0.88 * intensity))
				draw_rect(Rect2(rpos - Vector2(4, 5), Vector2(6, 4)), Color(0.35, 0.41, 0.20, 0.82 * intensity))
