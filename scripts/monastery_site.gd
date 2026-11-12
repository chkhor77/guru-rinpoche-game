class_name MonasterySite
extends Area2D

## Interactive construction and foundation site for Samye Monastery.
## During the Day phase, Guru Rinpoche builds and repairs the foundation here.

signal building_worked(amount: float)

@export var phase_manager: MonasteryPhaseManager
@export var cycle_timer: DayNightCycle

@export var build_rate_per_sec: float = 120.0
@export var site_size: Vector2 = Vector2(240, 240)

var is_player_present: bool = false
var is_building_active: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if phase_manager == null:
		phase_manager = get_tree().root.find_child("MonasteryPhaseManager", true, false) as MonasteryPhaseManager
	if cycle_timer == null:
		cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle

	if phase_manager:
		phase_manager.foundation_progress_updated.connect(_on_foundation_updated)
		phase_manager.monastery_foundation_completed.connect(_on_foundation_completed)

	if cycle_timer:
		cycle_timer.phase_changed.connect(_on_phase_changed)

	_ensure_collision_shape()


func _ensure_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = site_size
	col.shape = rect_shape


func _process(delta: float) -> void:
	if is_player_present and is_building_active and is_day_time():
		var amount := build_rate_per_sec * delta
		if phase_manager and phase_manager.can_build():
			phase_manager.add_foundation_work(amount)
			building_worked.emit(amount)
			queue_redraw()


func start_building() -> void:
	if is_player_present and is_day_time():
		is_building_active = true
		queue_redraw()


func stop_building() -> void:
	is_building_active = false
	queue_redraw()


func is_day_time() -> bool:
	if cycle_timer:
		return cycle_timer.is_day()
	return true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_present = true
		queue_redraw()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_present = false
		is_building_active = false
		queue_redraw()


func _on_phase_changed(_new_phase: DayNightCycle.Phase) -> void:
	if not is_day_time():
		is_building_active = false
	queue_redraw()


func _on_foundation_updated(_cur: float, _target: float) -> void:
	queue_redraw()


func _on_foundation_completed() -> void:
	is_building_active = false
	queue_redraw()


func _draw() -> void:
	var half := site_size / 2.0
	var rect := Rect2(-half, site_size)
	var progress := phase_manager.get_foundation_ratio() if phase_manager else 0.0

	# 1. Base foundation soil / stone floor (earthy warm stone)
	draw_rect(rect, Color(0.38, 0.32, 0.28, 0.75))

	# 2. Progress fill (radiant sandstone / gold)
	if progress > 0.0:
		var fill_h := site_size.y * progress
		var fill_rect := Rect2(-half.x, half.y - fill_h, site_size.x, fill_h)
		draw_rect(fill_rect, Color(0.85, 0.72, 0.45, 0.6))

	# 3. Outer boundary walls & corners (Tibetan monastery style)
	draw_rect(rect, Color(0.9, 0.8, 0.5, 0.9), false, 3.0)

	# 4. Sacred center mandala circle
	draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 36, Color(1.0, 0.88, 0.5, 0.8), 2.0)
	if progress >= 1.0:
		draw_circle(Vector2.ZERO, 20.0, Color(1.0, 0.92, 0.6, 0.9))

	# 5. Interaction prompt during Day
	if is_player_present and is_day_time() and phase_manager and phase_manager.can_build():
		var prompt_text := "Chanting & Building..." if is_building_active else "[SPACE] Hold to Build Foundation"
		var prompt_color := Color(1.0, 0.95, 0.6) if is_building_active else Color(1.0, 1.0, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(-80, -half.y - 14), prompt_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, prompt_color)

