class_name DayNightCycle
extends Node

## Day/Night cycle timer for the Samye Monastery building & defense phases.
## Controls phase progression, emits signals for gameplay events, and tracks day count.

enum Phase {
	DAY,
	NIGHT
}

signal phase_changed(new_phase: Phase)
signal day_started(day_number: int)
signal night_started(day_number: int)
signal time_updated(normalized_phase_time: float, seconds_left: float)

@export_group("Durations (Seconds)")
@export var day_duration: float = 120.0
@export var night_duration: float = 60.0

@export_group("Cycle State")
@export var auto_start: bool = true
@export var start_phase: Phase = Phase.DAY
@export var time_scale: float = 1.0

var current_phase: Phase = Phase.DAY
var current_day: int = 1
var elapsed_phase_time: float = 0.0
var is_active: bool = false


func _ready() -> void:
	current_phase = start_phase
	if auto_start:
		start_cycle()


func _process(delta: float) -> void:
	if not is_active or time_scale <= 0.0:
		return

	elapsed_phase_time += delta * time_scale
	var duration := get_current_phase_duration()
	var seconds_left := maxf(0.0, duration - elapsed_phase_time)
	var normalized_time := clampf(elapsed_phase_time / duration, 0.0, 1.0)

	time_updated.emit(normalized_time, seconds_left)

	if elapsed_phase_time >= duration:
		advance_phase()


func start_cycle() -> void:
	is_active = true
	elapsed_phase_time = 0.0
	_emit_phase_start()


func pause_cycle() -> void:
	is_active = false


func resume_cycle() -> void:
	is_active = true


func advance_phase() -> void:
	elapsed_phase_time = 0.0
	if current_phase == Phase.DAY:
		current_phase = Phase.NIGHT
		phase_changed.emit(current_phase)
		night_started.emit(current_day)
	else:
		current_phase = Phase.DAY
		current_day += 1
		phase_changed.emit(current_phase)
		day_started.emit(current_day)


func _emit_phase_start() -> void:
	phase_changed.emit(current_phase)
	if current_phase == Phase.DAY:
		day_started.emit(current_day)
	else:
		night_started.emit(current_day)


func get_current_phase_duration() -> float:
	return day_duration if current_phase == Phase.DAY else night_duration


func get_normalized_time() -> float:
	var duration := get_current_phase_duration()
	if duration <= 0.0:
		return 1.0
	return clampf(elapsed_phase_time / duration, 0.0, 1.0)


func get_seconds_left() -> float:
	return maxf(0.0, get_current_phase_duration() - elapsed_phase_time)


func is_day() -> bool:
	return current_phase == Phase.DAY


func is_night() -> bool:
	return current_phase == Phase.NIGHT
