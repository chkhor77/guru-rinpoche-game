class_name ResourceNode
extends Area2D

## Natural resource deposit (Forest Trees for Timber or Quarry Outcrops for Sandstone).
## Workers travel here during the Day to harvest resources.
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
@export var node_radius: float = 36.0

@export_group("Visual Colors")
@export var timber_color: Color = Color(0.22, 0.52, 0.28, 0.95)   ## Forest foliage green
@export var sandstone_color: Color = Color(0.72, 0.60, 0.44, 0.95) ## Quarry sandstone beige
@export var trunk_color: Color = Color(0.38, 0.24, 0.15, 1.0)      ## Deep wood bark

var cycle_timer: DayNightCycle = null


func _ready() -> void:
	add_to_group("resource_nodes")
	current_resources = max_resources
	_ensure_collision_shape()

	cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	if cycle_timer:
		cycle_timer.day_started.connect(_on_day_started)


func _on_day_started(_day: int) -> void:
	# Regenerate trees and sandstone rocks at dawn
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


## Called by a worker when gathering. Returns the amount successfully harvested.
func harvest(requested_amount: float) -> float:
	if current_resources <= 0.0:
		return 0.0

	var harvested := minf(requested_amount, current_resources)
	current_resources -= harvested
	resource_harvested.emit(harvested)
	queue_redraw()

	if current_resources <= 0.0:
		resource_depleted.emit()

	return harvested


func is_available() -> bool:
	return current_resources > 0.0


func _draw() -> void:
	var ratio := current_resources / maxf(1.0, max_resources)
	var dynamic_r := node_radius * (0.5 + 0.5 * ratio)

	if resource_type == ResourceType.TIMBER:
		# Draw Bodhi Tree: Trunk + Lush Foliage Canopy
		draw_rect(Rect2(-8, -4, 16, 24), trunk_color)
		draw_circle(Vector2(0, -14), dynamic_r, timber_color)
		draw_circle(Vector2(-10, -22), dynamic_r * 0.7, timber_color.lightened(0.1))
		draw_circle(Vector2(10, -22), dynamic_r * 0.7, timber_color.darkened(0.1))
	else:
		# Draw Sandstone Quarry Outcrop: Layered rock facets
		var pts: PackedVector2Array = [
			Vector2(-dynamic_r, 12),
			Vector2(-dynamic_r * 0.7, -dynamic_r * 0.6),
			Vector2(0, -dynamic_r),
			Vector2(dynamic_r * 0.8, -dynamic_r * 0.5),
			Vector2(dynamic_r, 12)
		]
		draw_colored_polygon(pts, sandstone_color)
		draw_polyline(pts, sandstone_color.darkened(0.2), 2.0)
