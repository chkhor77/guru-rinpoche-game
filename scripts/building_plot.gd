class_name BuildingPlot
extends Area2D

## A construction plot for Samye Monastery buildings (Utse Temple, Cardinal Shrines).
## Workers deliver Timber and Sandstone here during the Day to erect structures.
## Visually shows construction progress in distinct architectural stages and progress bars.
## At Night, wilderness spirits target and dismantle them if not defended by Guru Rinpoche!

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
var construction_progress: float = 0.0 ## 0.0 to 100.0
var max_shelter_capacity: int = 4
var sheltered_workers: int = 0

var tex_completed: Texture2D = null
var tex_layout: Texture2D = null


func _ready() -> void:
	add_to_group("building_plots")
	_ensure_collision_shape()
	_resolve_visual_models()

	var cycle := get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	if cycle:
		cycle.day_started.connect(func(_day: int) -> void:
			sheltered_workers = 0
		)


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


## Deposit resource into this building plot
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


## Workers spend time building after resources are delivered
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


## Called when night spirits attack and tear down stones/timber
func dismantle(amount: float) -> void:
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
	var rect := Rect2(-half, plot_size)

	# 1. Base Ground outline / Foundation
	draw_rect(rect, Color(0.3, 0.25, 0.2, 0.45))

	if current_state == State.COMPLETED:
		# --- FULLY CONSECRATED SAMYE MONASTERY TEMPLE ---
		draw_circle(Vector2.ZERO, half.x * 1.15, Color(1.0, 0.9, 0.45, 0.18))
		draw_arc(Vector2.ZERO, half.x * 1.15, 0.0, TAU, 48, Color(1.0, 0.86, 0.35, 0.65), 2.5)

		if tex_completed:
			var draw_w := plot_size.x * (1.45 if is_central_temple else 1.35)
			var aspect := float(tex_completed.get_height()) / float(maxi(1, tex_completed.get_width()))
			var draw_h := draw_w * aspect
			var dst_rect := Rect2(Vector2(-draw_w * 0.5, half.y - draw_h + 12.0), Vector2(draw_w, draw_h))
			draw_texture_rect(tex_completed, dst_rect, false)
		else:
			draw_rect(rect, Color(0.96, 0.95, 0.92, 1.0))
			draw_rect(Rect2(-half.x, -half.y, plot_size.x, 26), Color(0.68, 0.16, 0.16, 1.0))

	elif current_state == State.UNDER_CONSTRUCTION or construction_progress > 0.0:
		# --- UNDER ACTIVE CONSTRUCTION (Progressive Bottom-to-Top Reveal + Scaffolding) ---
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
			var dst_rect := Rect2(Vector2(-draw_w * 0.5, (half.y + 12.0) - visible_h), Vector2(draw_w, visible_h))
			draw_texture_rect_region(tex_completed, dst_rect, src_rect)
		else:
			var wall_height := plot_size.y * pct
			var rising_rect := Rect2(-half.x, half.y - wall_height, plot_size.x, wall_height)
			draw_rect(rising_rect, Color(0.78, 0.32, 0.22, 0.95))

		# Wooden scaffolding poles & cross-bracing
		draw_line(Vector2(-half.x - 4, half.y), Vector2(-half.x - 4, -half.y), Color(0.45, 0.3, 0.18, 0.9), 3.0)
		draw_line(Vector2(half.x + 4, half.y), Vector2(half.x + 4, -half.y), Color(0.45, 0.3, 0.18, 0.9), 3.0)
		draw_line(Vector2(-half.x - 4, 0), Vector2(half.x + 4, 0), Color(0.55, 0.38, 0.22, 0.75), 2.0)

	else:
		# --- BLUEPRINT FOUNDATION (Top-View Mandala Layout) ---
		if tex_layout:
			draw_texture_rect(tex_layout, rect.grow(-4.0), false, Color(1.0, 0.92, 0.55, 0.42))
		else:
			draw_rect(rect, Color(1.0, 0.88, 0.35, 0.12))
		draw_rect(rect, Color(1.0, 0.85, 0.35, 0.75), false, 2.0)

	# =========================================================================
	# Prominent Floating Progress Bar & Progress Text Header
	# =========================================================================
	var header_y := -half.y - 36.0

	# 1. Building Name
	draw_string(ThemeDB.fallback_font, Vector2(-120, header_y - 18), building_name, HORIZONTAL_ALIGNMENT_CENTER, 240, 13, Color(1.0, 0.95, 0.7))

	# 2. Progress Bar
	var bar_w := 140.0
	var bar_h := 10.0
	var bar_rect := Rect2(-bar_w / 2.0, header_y, bar_w, bar_h)

	draw_rect(bar_rect, Color(0.12, 0.12, 0.15, 0.85))
	var fill_ratio := 1.0 if current_state == State.COMPLETED else (construction_progress / 100.0)
	var fill_w := bar_w * fill_ratio
	var fill_col := Color(0.4, 0.85, 0.45) if current_state == State.COMPLETED else Color(1.0, 0.75, 0.25)
	draw_rect(Rect2(-bar_w / 2.0, header_y, fill_w, bar_h), fill_col)
	draw_rect(bar_rect, Color(0.9, 0.85, 0.7, 0.7), false, 1.0)

	# 3. Progress Percentage Text
	var status_text: String
	if current_state == State.COMPLETED:
		status_text = "100% Completed (Consecrated)"
	elif has_all_materials():
		status_text = "Constructing: %d%%" % int(construction_progress)
	else:
		status_text = "Waiting Materials (🪵 %.0f/%.0f | 🪨 %.0f/%.0f)" % [wood_delivered, wood_required, stone_delivered, stone_required]

	draw_string(ThemeDB.fallback_font, Vector2(-120, header_y + 24), status_text, HORIZONTAL_ALIGNMENT_CENTER, 240, 11, Color(1.0, 1.0, 0.9))
