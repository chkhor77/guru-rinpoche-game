class_name PurificationAura
extends Area2D

## 2D collision sphere that projects Guru Rinpoche's purification aura.
## Features both a continuous passive cleansing field and an active radiance pulse.
## As per .clinerules, active spellcasting is dedicated to the Night phase.

signal aura_pulsed(radius: float)

@export var cycle_timer: DayNightCycle
@export var night_only: bool = true
@export var aura_radius: float = 140.0
@export var passive_cleanse_rate: float = 20.0 ## Corruption cleansed per second
@export var pulse_cleanse_burst: float = 40.0   ## Corruption cleansed on pulse burst
@export var pulse_cooldown: float = 0.8        ## Seconds between active pulses

@export_group("Visuals")
@export var aura_color: Color = Color(1.0, 0.85, 0.3, 0.12)
@export var border_color: Color = Color(1.0, 0.9, 0.4, 0.45)
@export var pulse_color: Color = Color(1.0, 0.95, 0.6, 0.8)

var can_pulse: bool = true
var pulse_anim_progress: float = 1.0 ## 0.0 to 1.0 when pulsing
var pulse_anim_duration: float = 0.45
var is_aura_active: bool = false


func _ready() -> void:
	monitoring = true
	monitorable = false
	_ensure_collision_shape()

	if cycle_timer == null:
		cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle

	if cycle_timer:
		cycle_timer.phase_changed.connect(_on_phase_changed)
		_on_phase_changed(cycle_timer.current_phase)
	else:
		is_aura_active = true


func _on_phase_changed(phase: DayNightCycle.Phase) -> void:
	if night_only:
		is_aura_active = (phase == DayNightCycle.Phase.NIGHT)
	else:
		is_aura_active = true
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_aura_active:
		return

	# Passive cleansing of any overlapping corrupted targets
	if passive_cleanse_rate > 0.0:
		var targets := _get_overlapping_corrupted_targets()
		for target in targets:
			target.cleanse(passive_cleanse_rate * delta)


func _process(delta: float) -> void:
	if pulse_anim_progress < 1.0:
		pulse_anim_progress = minf(1.0, pulse_anim_progress + delta / pulse_anim_duration)
		queue_redraw()


func _ensure_collision_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)

	var circle := CircleShape2D.new()
	circle.radius = aura_radius
	shape_node.shape = circle


## Triggers an active purification pulse (Vajra / radiance burst)
func trigger_pulse() -> bool:
	if not is_aura_active or not can_pulse:
		return false

	can_pulse = false
	pulse_anim_progress = 0.0
	queue_redraw()
	aura_pulsed.emit(aura_radius)

	# Deliver instant burst cleanse to all entities within aura
	var targets := _get_overlapping_corrupted_targets()
	for target in targets:
		target.cleanse(pulse_cleanse_burst)

	# Cooldown timer
	get_tree().create_timer(pulse_cooldown).timeout.connect(func():
		can_pulse = true
	)
	return true


func _get_overlapping_corrupted_targets() -> Array[CorruptionComponent]:
	var result: Array[CorruptionComponent] = []

	for body in get_overlapping_bodies():
		var comp := body.get_node_or_null("CorruptionComponent") as CorruptionComponent
		if comp and not comp.is_cleansed:
			result.append(comp)

	for area in get_overlapping_areas():
		var comp := area.get_node_or_null("CorruptionComponent") as CorruptionComponent
		if comp and not comp.is_cleansed:
			result.append(comp)

	return result


func _draw() -> void:
	if not is_aura_active:
		return

	# Base ambient aura glow during night
	draw_circle(Vector2.ZERO, aura_radius, aura_color)
	draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 48, border_color, 2.0)

	# Expanding radiance wave when pulsed
	if pulse_anim_progress < 1.0:
		var current_r := aura_radius * ease(pulse_anim_progress, 0.3)
		var alpha := (1.0 - pulse_anim_progress) * pulse_color.a
		var cur_pulse_col := Color(pulse_color.r, pulse_color.g, pulse_color.b, alpha)
		draw_arc(Vector2.ZERO, current_r, 0.0, TAU, 64, cur_pulse_col, 4.0 * (1.0 - pulse_anim_progress) + 1.0)
		draw_circle(Vector2.ZERO, current_r * 0.4, Color(pulse_color.r, pulse_color.g, pulse_color.b, alpha * 0.3))
