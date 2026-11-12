class_name CorruptionComponent
extends Node

## Manages the "Karmic Debt" / "Corruption" gauge as specified in .clinerules.
## Replaces traditional HP: when corruption reaches 0, the entity is subjugated / cleansed.

signal corruption_changed(current_corruption: float, max_corruption: float)
signal cleansed()

@export var max_corruption: float = 100.0
@export var current_corruption: float = 100.0

var is_cleansed: bool = false


func _ready() -> void:
	current_corruption = max_corruption
	corruption_changed.emit(current_corruption, max_corruption)


## Cleanses the entity by reducing its corruption gauge
func cleanse(amount: float) -> void:
	if is_cleansed or amount <= 0.0:
		return

	current_corruption = maxf(0.0, current_corruption - amount)
	corruption_changed.emit(current_corruption, max_corruption)

	if current_corruption <= 0.0:
		is_cleansed = true
		cleansed.emit()


## Increases corruption (e.g. from environmental miasma or dark curses)
func corrupt(amount: float) -> void:
	if is_cleansed:
		return
	current_corruption = minf(max_corruption, current_corruption + amount)
	corruption_changed.emit(current_corruption, max_corruption)


func get_corruption_ratio() -> float:
	return current_corruption / maxf(1.0, max_corruption)
