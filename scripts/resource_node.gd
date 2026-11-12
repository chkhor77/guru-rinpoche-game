class_name ResourceNode
extends Area2D

## Natural resource deposit (Sacred Himalayan Cedar Grove for Timber or Sandstone Quarry for Stone).
## Workers travel here during the Day to harvest resources.
## Visually transitions across 3 authentic model stages (Full -> Mid -> Low/Regrowing)
## extracted from `cedar_forest_sheet.jpg` and `sandstone_quarry_sheet.jpg`.
## Automatically replenishes resources every dawn so building never stalls.

enum ResourceType {
	TIMBER,
	SANDSTONE
}

signal resource_depleted()
signal resource_harvested(amount: float)

@export var resource_type: ResourceType = ResourceType.TIMBER
@export var max_resources: float = 300.0
@export var current_resources: float = 300.0
@export var daily_replenish: float = 150.0
@export var harvest_time_per_unit: float = 1.0
@export var node_radius: float = 48.0
@export var visual_draw_width: float = 136.0

@export_group("Visual Colors")
@export var timber_color: Color = Color(0.22, 0.52, 0.28, 0.95)
@export var sandstone_color: Color = Color(0.72, 0.60, 0.44, 0.95)
@export var trunk_color: Color = Color(0.38, 0.24, 0.15, 1.0)

var cycle_timer: DayNightCycle = null
var tex_full: Texture2D = null
var tex_mid: Texture2D = null
var tex_low: Texture2D = null

var harvest_flash_timer: float = 0.0
var sway_phase: float = 0.0


func _ready() -> void:
	add_to_group("resource_nodes")
	current_resources = max_resources
	sway_phase = randf_range(0.0, TAU)
	_ensure_collision_shape()
	_load_resource_textures()

	cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	if cycle_timer:
		cycle_timer.day_started.connect(_on_day_started)


func _load_resource_textures() -> void:
	if resource_type == ResourceType.TIMBER:
		tex_full = ModelTextures.get_tex(ModelTextures.CEDAR_FOREST_FULL)
		tex_mid  = ModelTextures.get_tex(ModelTextures.CEDAR_FOREST_MID)
		tex_low  = ModelTextures.get_tex(ModelTextures.CEDAR_FOREST_LOW)
	else:
		tex_full = ModelTextures.get_tex(ModelTextures.SANDSTONE_QUARRY_FULL)
		tex_mid  = ModelTextures.get_tex(ModelTextures.SANDSTONE_QUARRY_MID)
		tex_low  = ModelTextures.get_tex(ModelTextures.SANDSTONE_QUARRY_LOW)


func _process(delta: float) -> void:
	sway_phase += delta * 1.8
	if harvest_flash_timer > 0.0:
		harvest_flash_timer = maxf(0.0, harvest_flash_timer - delta)
		queue_redraw()
	elif resource_type == ResourceType.TIMBER:
		queue_redraw()


func _on_day_started(_day: int) -> void:
	current_resources = minf(max_resources, current_resources + daily_replenish)
	queue_redraw()


func _ensure_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)

	var circle := CircleShape2D.new()
	circle.radius = node_radius
	col.shape = circle


func harvest(requested_amount: float) -> float:
	if current_resources <= 0.0:
		return 0.0

	var harvested := minf(requested_amount, current_resources)
	current_resources -= harvested
	harvest_flash_timer = 0.45
	resource_harvested.emit(harvested)
	queue_redraw()

	if current_resources <= 0.0:
		resource_depleted.emit()

	return harvested


func is_available() -> bool:
	return current_resources > 0.0


func get_active_stage_texture() -> Texture2D:
	var ratio := current_resources / maxf(1.0, max_resources)
	if ratio >= 0.65 and tex_full != null:
		return tex_full
	elif ratio >= 0.25 and tex_mid != null:
		return tex_mid
	elif tex_low != null:
		return tex_low
	return tex_full


func _draw() -> void:
	var ratio := clampf(current_resources / maxf(1.0, max_resources), 0.0, 1.0)
	var active_tex := get_active_stage_texture()

	draw_circle(Vector2(0, 14), node_radius * 0.95, Color(0.08, 0.12, 0.09, 0.34))

	if active_tex != null:
		var stage_scale := 1.0
		if ratio < 0.25:
			stage_scale = 0.78
		elif ratio < 0.65:
			stage_scale = 0.88

		var draw_w := visual_draw_width * stage_scale
		var aspect := float(active_tex.get_height()) / float(maxi(1, active_tex.get_width()))
		var draw_h := draw_w * aspect
		var sway_x := sin(sway_phase) * 1.6 if resource_type == ResourceType.TIMBER else 0.0
		var shake_x := sin(harvest_flash_timer * 42.0) * 3.5 if harvest_flash_timer > 0.0 else 0.0

		var dst_rect := Rect2(
			Vector2(-draw_w * 0.5 + sway_x + shake_x, 22.0 - draw_h),
			Vector2(draw_w, draw_h)
		)
		var mod := Color(1.18, 1.15, 1.05, 1.0) if harvest_flash_timer > 0.0 else Color.WHITE
		draw_texture_rect(active_tex, dst_rect, false, mod)
	else:
		var dynamic_r := node_radius * (0.5 + 0.5 * ratio)
		if resource_type == ResourceType.TIMBER:
			draw_rect(Rect2(-8, -4, 16, 24), trunk_color)
			draw_circle(Vector2(0, -14), dynamic_r, timber_color)
		else:
			var pts: PackedVector2Array = [
				Vector2(-dynamic_r, 12),
				Vector2(-dynamic_r * 0.7, -dynamic_r * 0.6),
				Vector2(0, -dynamic_r),
				Vector2(dynamic_r * 0.8, -dynamic_r * 0.5),
				Vector2(dynamic_r, 12)
			]
			draw_colored_polygon(pts, sandstone_color)

	if harvest_flash_timer > 0.0:
		var chip_col := Color(0.32, 0.72, 0.36, harvest_flash_timer * 2.0) if resource_type == ResourceType.TIMBER else Color(0.88, 0.74, 0.42, harvest_flash_timer * 2.0)
		for i in range(5):
			var ang := float(i) * (TAU / 5.0) + harvest_flash_timer * 6.0
			var dist := (0.5 - harvest_flash_timer) * 65.0 + 12.0
			var p := Vector2(cos(ang) * dist, -18.0 + sin(ang) * dist * 0.6)
			draw_circle(p, 3.2, chip_col)

	var label_y := 34.0
	var bar_w := 68.0
	var bar_h := 5.0
	var bar_rect := Rect2(-bar_w * 0.5, label_y, bar_w, bar_h)
	draw_rect(bar_rect, Color(0.08, 0.09, 0.11, 0.78))
	var fill_col := Color(0.28, 0.76, 0.38, 0.92) if resource_type == ResourceType.TIMBER else Color(0.86, 0.68, 0.32, 0.92)
	draw_rect(Rect2(-bar_w * 0.5, label_y, bar_w * ratio, bar_h), fill_col)
	draw_rect(bar_rect, Color(0.92, 0.88, 0.72, 0.55), false, 1.0)
