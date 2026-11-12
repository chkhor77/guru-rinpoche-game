class_name DayNightLighting
extends CanvasModulate

## Smoothly tints ambient lighting between Day and Night using a Gradient
## or custom color keys matching the Studio Ghibli inspired palette.

@export var cycle_timer: DayNightCycle

@export_group("Palette Colors")
## Warm morning/daylight: bright soft gold and clean daylight
@export var day_color: Color = Color(1.0, 0.98, 0.92, 1.0)
## Sunset / dusk transition
@export var dusk_color: Color = Color(0.95, 0.65, 0.45, 1.0)
## Mystical night: deep indigo / moonlit navy that lets golden auras pop
@export var night_color: Color = Color(0.22, 0.25, 0.42, 1.0)
## Dawn / sunrise transition
@export var dawn_color: Color = Color(0.98, 0.82, 0.65, 1.0)

## Optional Gradient to sample from (overrides the 4 colors above if set)
@export var custom_gradient: Gradient

@export_group("Transition Settings")
## Percentage of the phase duration spent transitioning (0.0 to 0.5)
@export_range(0.05, 0.5, 0.05) var transition_window: float = 0.2


func _ready() -> void:
	if cycle_timer == null:
		cycle_timer = get_node_or_null("../DayNightCycle") as DayNightCycle

	if cycle_timer:
		cycle_timer.time_updated.connect(_on_time_updated)
		_update_lighting(cycle_timer.get_normalized_time())
	else:
		push_warning("DayNightLighting: No DayNightCycle assigned.")


func _on_time_updated(normalized_time: float, _seconds_left: float) -> void:
	_update_lighting(normalized_time)


func _update_lighting(normalized_time: float) -> void:
	if custom_gradient:
		# If a custom gradient is provided, sample from it across the 24h cycle
		# Day is 0.0 -> 0.5, Night is 0.5 -> 1.0
		var full_cycle_t: float
		if cycle_timer.is_day():
			full_cycle_t = normalized_time * 0.5
		else:
			full_cycle_t = 0.5 + (normalized_time * 0.5)
		color = custom_gradient.sample(full_cycle_t)
		return

	# Fallback: Smooth 4-way color interpolation
	if cycle_timer.is_day():
		if normalized_time < transition_window:
			# Dawn -> Full Day
			var t := normalized_time / transition_window
			color = dawn_color.lerp(day_color, t)
		elif normalized_time > (1.0 - transition_window):
			# Full Day -> Dusk
			var t := (normalized_time - (1.0 - transition_window)) / transition_window
			color = day_color.lerp(dusk_color, t)
		else:
			color = day_color
	else:
		if normalized_time < transition_window:
			# Dusk -> Deep Night
			var t := normalized_time / transition_window
			color = dusk_color.lerp(night_color, t)
		elif normalized_time > (1.0 - transition_window):
			# Deep Night -> Dawn
			var t := (normalized_time - (1.0 - transition_window)) / transition_window
			color = night_color.lerp(dawn_color, t)
		else:
			color = night_color

