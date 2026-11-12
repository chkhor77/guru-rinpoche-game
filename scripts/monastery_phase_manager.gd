class_name MonasteryPhaseManager
extends Node

## Manages Phase 2 gameplay at Samye Monastery as defined in .clinerules:
## - Day Phase: Foundation construction and preparation.
## - Night Phase: Grid-based Dharmapala placement and defense against shadow spirits.

signal build_phase_started(day_number: int)
signal defense_phase_started(day_number: int)
signal foundation_progress_updated(current_progress: float, target_progress: float)
signal monastery_foundation_completed()
signal monastery_sanctity_changed(current_sanctity: float, max_sanctity: float)
signal monastery_corrupted()

enum GameplayMode {
	BUILDING,
	DEFENDING
}

@export var cycle_timer: DayNightCycle

@export_group("Foundation Objectives")
## Total construction work needed to complete the Samye foundation
@export var target_foundation_work: float = 1000.0
## Sanctity (health equivalent, but non-violent karma based) of the monastery
@export var max_sanctity: float = 100.0

var current_mode: GameplayMode = GameplayMode.BUILDING
var current_foundation_work: float = 0.0
var current_sanctity: float = 100.0
var is_foundation_complete: bool = false


func _ready() -> void:
	current_sanctity = max_sanctity
	if cycle_timer == null:
		cycle_timer = get_node_or_null("../DayNightCycle") as DayNightCycle

	if cycle_timer:
		cycle_timer.day_started.connect(_on_day_started)
		cycle_timer.night_started.connect(_on_night_started)
		if cycle_timer.is_day():
			_on_day_started(cycle_timer.current_day)
		else:
			_on_night_started(cycle_timer.current_day)
	else:
		push_warning("MonasteryPhaseManager: No DayNightCycle assigned.")


func _on_day_started(day_number: int) -> void:
	current_mode = GameplayMode.BUILDING
	build_phase_started.emit(day_number)


func _on_night_started(day_number: int) -> void:
	current_mode = GameplayMode.DEFENDING
	defense_phase_started.emit(day_number)


## Called during the Day phase when the player contributes construction work
func add_foundation_work(amount: float) -> void:
	if current_mode != GameplayMode.BUILDING or is_foundation_complete:
		return

	current_foundation_work = minf(current_foundation_work + amount, target_foundation_work)
	foundation_progress_updated.emit(current_foundation_work, target_foundation_work)

	if current_foundation_work >= target_foundation_work:
		is_foundation_complete = true
		monastery_foundation_completed.emit()


## Decreases monastery sanctity if shadow spirits breach the perimeter at Night
func damage_sanctity(amount: float) -> void:
	current_sanctity = maxf(0.0, current_sanctity - amount)
	monastery_sanctity_changed.emit(current_sanctity, max_sanctity)

	if current_sanctity <= 0.0:
		monastery_corrupted.emit()


## Restores monastery sanctity (e.g., via Dharmapala blessings or morning mantras)
func restore_sanctity(amount: float) -> void:
	current_sanctity = minf(max_sanctity, current_sanctity + amount)
	monastery_sanctity_changed.emit(current_sanctity, max_sanctity)


func can_build() -> bool:
	return current_mode == GameplayMode.BUILDING and not is_foundation_complete


func can_place_defenders() -> bool:
	return current_mode == GameplayMode.DEFENDING


func get_foundation_ratio() -> float:
	return clampf(current_foundation_work / target_foundation_work, 0.0, 1.0)

