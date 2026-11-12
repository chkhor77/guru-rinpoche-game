class_name AmbientEcosystem
extends Node2D

## Realistic Day & Night Ambient Ecosystem for Samye Monastery:
## - DAYTIME:
##   * Flocks of Himalayan Birds (swallows, cranes, sunbirds) soaring overhead with flapping wings & ground shadows.
##   * Woodland Critters (Rabbits hopping with long ears & cotton tails; Squirrels scurrying with bushy tails)
##     foraging, pausing, and darting around the Cedar Groves, meadows, and temple courtyards.
## - NIGHTTIME:
##   * Rolling Himalayan Mountain Fog & Mist Banks drifting across the valley floor.
##   * Nocturnal Spirit Wisps / Fireflies pulsing softly through the fog for an immersive night defense scene.

enum CritterType { RABBIT = 0, SQUIRREL = 1 }

@export_group("Daytime Wildlife")
@export var bird_count: int = 12
@export var critter_count: int = 14
@export var world_bounds: Rect2 = Rect2(-380.0, -80.0, 1920.0, 780.0)

@export_group("Nighttime Fog & Atmosphere")
@export var fog_bank_count: int = 18
@export var night_wisp_count: int = 26

var cycle_timer: DayNightCycle = null
var is_night_phase: bool = false

## Smooth 0.0 .. 1.0 blend factors for Day wildlife and Night fog
var day_blend: float = 1.0
var night_blend: float = 0.0

var birds: Array[Dictionary] = []
var critters: Array[Dictionary] = []
var fog_banks: Array[Dictionary] = []
var night_wisps: Array[Dictionary] = []


func _ready() -> void:
	z_index = 20
	cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	if cycle_timer:
		cycle_timer.phase_changed.connect(_on_phase_changed)
		is_night_phase = (cycle_timer.current_phase == DayNightCycle.Phase.NIGHT)
		day_blend = 0.0 if is_night_phase else 1.0
		night_blend = 1.0 if is_night_phase else 0.0

	_init_birds()
	_init_critters()
	_init_fog_banks()
	_init_night_wisps()


func _on_phase_changed(new_phase: DayNightCycle.Phase) -> void:
	is_night_phase = (new_phase == DayNightCycle.Phase.NIGHT)
	if not is_night_phase:
		# Scatter critters across the sunlit meadows at Dawn
		for c in critters:
			c["target"] = _random_meadow_point()
			c["pause_timer"] = randf_range(0.2, 1.2)


func _init_birds() -> void:
	birds.clear()
	for i in range(bird_count):
		var dir := Vector2(randf_range(0.6, 1.0) * (1.0 if i % 2 == 0 else -1.0), randf_range(-0.35, 0.35)).normalized()
		birds.append({
			"pos": Vector2(
				randf_range(world_bounds.position.x, world_bounds.end.x),
				randf_range(world_bounds.position.y, world_bounds.end.y)
			),
			"dir": dir,
			"speed": randf_range(75.0, 125.0),
			"flap_phase": randf_range(0.0, TAU),
			"flap_speed": randf_range(9.0, 14.0),
			"wingspan": randf_range(11.0, 17.0),
			"altitude": randf_range(55.0, 95.0),
			"color": Color(0.95, 0.94, 0.90) if i % 3 == 0 else (Color(0.26, 0.36, 0.52) if i % 3 == 1 else Color(0.88, 0.68, 0.28))
		})


func _init_critters() -> void:
	critters.clear()
	for i in range(critter_count):
		var ctype: CritterType = CritterType.RABBIT if (i % 2 == 0) else CritterType.SQUIRREL
		var start_pos := _random_meadow_point()
		critters.append({
			"type": ctype,
			"pos": start_pos,
			"target": _random_meadow_point(),
			"speed": randf_range(52.0, 74.0) if ctype == CritterType.RABBIT else randf_range(68.0, 96.0),
			"hop_phase": randf_range(0.0, TAU),
			"pause_timer": randf_range(0.0, 2.2),
			"facing_x": 1.0 if randf() > 0.5 else -1.0,
			"coat_color": (
				Color(0.92, 0.89, 0.84) if (ctype == CritterType.RABBIT and i % 4 == 0)
				else (Color(0.76, 0.68, 0.58) if ctype == CritterType.RABBIT else Color(0.68, 0.38, 0.20))
			)
		})


func _init_fog_banks() -> void:
	fog_banks.clear()
	for i in range(fog_bank_count):
		fog_banks.append({
			"pos": Vector2(
				randf_range(world_bounds.position.x, world_bounds.end.x),
				randf_range(world_bounds.position.y, world_bounds.end.y)
			),
			"vel": Vector2(randf_range(14.0, 32.0) * (1.0 if i % 2 == 0 else -0.7), randf_range(-4.0, 4.0)),
			"radius": randf_range(115.0, 230.0),
			"aspect": randf_range(1.6, 2.4),
			"phase": randf_range(0.0, TAU),
			"alpha": randf_range(0.11, 0.22),
			"tint": Color(0.46, 0.54, 0.76) if i % 2 == 0 else Color(0.34, 0.38, 0.58)
		})


func _init_night_wisps() -> void:
	night_wisps.clear()
	for i in range(night_wisp_count):
		night_wisps.append({
			"pos": Vector2(
				randf_range(world_bounds.position.x + 80.0, world_bounds.end.x - 80.0),
				randf_range(world_bounds.position.y + 60.0, world_bounds.end.y - 60.0)
			),
			"phase": randf_range(0.0, TAU),
			"speed": randf_range(12.0, 26.0),
			"radius": randf_range(2.8, 5.2),
			"color": Color(0.55, 0.85, 1.0) if i % 3 == 0 else (Color(0.78, 0.58, 1.0) if i % 3 == 1 else Color(1.0, 0.86, 0.42))
		})


func _random_meadow_point() -> Vector2:
	var zone := randi() % 3
	if zone == 0:
		return Vector2(randf_range(-240.0, 220.0), randf_range(120.0, 560.0))
	elif zone == 1:
		return Vector2(randf_range(920.0, 1280.0), randf_range(120.0, 560.0))
	else:
		return Vector2(randf_range(180.0, 960.0), randf_range(60.0, 590.0))


func _process(delta: float) -> void:
	var target_day := 0.0 if is_night_phase else 1.0
	var target_night := 1.0 if is_night_phase else 0.0
	day_blend = move_toward(day_blend, target_day, delta * 0.65)
	night_blend = move_toward(night_blend, target_night, delta * 0.55)

	if day_blend > 0.01:
		_update_birds(delta)
		_update_critters(delta)

	if night_blend > 0.01:
		_update_fog_banks(delta)
		_update_night_wisps(delta)

	queue_redraw()


func _update_birds(delta: float) -> void:
	for b in birds:
		var pos: Vector2 = b["pos"]
		var dir: Vector2 = b["dir"]
		var spd: float = b["speed"]
		pos += dir * spd * delta
		b["flap_phase"] = float(b["flap_phase"]) + float(b["flap_speed"]) * delta

		if pos.x > world_bounds.end.x + 120.0:
			pos.x = world_bounds.position.x - 100.0
			pos.y = randf_range(world_bounds.position.y, world_bounds.end.y)
		elif pos.x < world_bounds.position.x - 120.0:
			pos.x = world_bounds.end.x + 100.0
			pos.y = randf_range(world_bounds.position.y, world_bounds.end.y)

		if pos.y > world_bounds.end.y + 100.0:
			pos.y = world_bounds.position.y - 80.0
		elif pos.y < world_bounds.position.y - 100.0:
			pos.y = world_bounds.end.y + 80.0

		b["pos"] = pos


func _update_critters(delta: float) -> void:
	for c in critters:
		var pause_t: float = c["pause_timer"]
		if pause_t > 0.0:
			c["pause_timer"] = pause_t - delta
			c["hop_phase"] = float(c["hop_phase"]) + delta * 3.0
			continue

		var pos: Vector2 = c["pos"]
		var target: Vector2 = c["target"]
		var diff := target - pos
		if diff.length() <= 10.0:
			c["pause_timer"] = randf_range(0.9, 2.8)
			c["target"] = _random_meadow_point()
		else:
			var dir := diff.normalized()
			if absf(dir.x) > 0.05:
				c["facing_x"] = 1.0 if dir.x > 0.0 else -1.0
			var spd: float = c["speed"]
			pos += dir * spd * delta
			c["pos"] = pos
			c["hop_phase"] = float(c["hop_phase"]) + delta * 14.0


func _update_fog_banks(delta: float) -> void:
	for f in fog_banks:
		var pos: Vector2 = f["pos"]
		var vel: Vector2 = f["vel"]
		pos += vel * delta
		f["phase"] = float(f["phase"]) + delta * 0.8

		var margin := float(f["radius"]) * 2.5
		if pos.x > world_bounds.end.x + margin:
			pos.x = world_bounds.position.x - margin
		elif pos.x < world_bounds.position.x - margin:
			pos.x = world_bounds.end.x + margin
		f["pos"] = pos


func _update_night_wisps(delta: float) -> void:
	for w in night_wisps:
		var phase: float = float(w["phase"]) + delta * 2.2
		w["phase"] = phase
		var spd: float = w["speed"]
		var pos: Vector2 = w["pos"]
		pos += Vector2(cos(phase * 0.7), sin(phase * 1.1)) * spd * delta
		w["pos"] = pos


func _draw() -> void:
	if day_blend > 0.01:
		_draw_daytime_critters(day_blend)
		_draw_daytime_birds(day_blend)

	if night_blend > 0.01:
		_draw_nighttime_fog_and_wisps(night_blend)


func _draw_daytime_critters(alpha_scale: float) -> void:
	for c in critters:
		var pos: Vector2 = c["pos"]
		var ctype: CritterType = c["type"]
		var facing: float = c["facing_x"]
		var hop_phase: float = c["hop_phase"]
		var is_moving: bool = float(c["pause_timer"]) <= 0.0
		var hop_y := -absf(sin(hop_phase)) * (6.5 if ctype == CritterType.RABBIT else 4.0) if is_moving else 0.0
		var coat: Color = c["coat_color"]
		coat.a = alpha_scale

		draw_circle(pos + Vector2(0, 3), 6.5, Color(0.08, 0.14, 0.10, 0.28 * alpha_scale))

		var body_pos := pos + Vector2(0, hop_y)
		if ctype == CritterType.RABBIT:
			draw_circle(body_pos, 5.5, coat)
			var head_pos := body_pos + Vector2(facing * 4.5, -2.5)
			draw_circle(head_pos, 4.0, coat)
			var ear_tip1 := head_pos + Vector2(-facing * 1.0, -8.5)
			var ear_tip2 := head_pos + Vector2(facing * 1.5, -8.0)
			draw_line(head_pos + Vector2(0, -2), ear_tip1, coat, 2.2)
			draw_line(head_pos + Vector2(facing * 1.0, -2), ear_tip2, coat, 2.2)
			draw_line(head_pos + Vector2(0, -2), ear_tip1, Color(0.95, 0.72, 0.74, 0.75 * alpha_scale), 1.0)
			draw_circle(body_pos + Vector2(-facing * 5.5, -1.0), 2.6, Color(0.98, 0.98, 1.0, alpha_scale))
			draw_circle(head_pos + Vector2(facing * 1.8, -0.8), 1.1, Color(0.12, 0.10, 0.10, alpha_scale))
		else:
			var tail_wag := sin(hop_phase * 1.5) * 2.0
			var tail_base := body_pos + Vector2(-facing * 4.5, 0.0)
			var tail_mid := tail_base + Vector2(-facing * 5.5, -6.5 + tail_wag)
			var tail_tip := tail_mid + Vector2(facing * 2.0, -4.5)
			draw_circle(tail_mid, 4.8, Color(coat.r * 0.92, coat.g * 0.88, coat.b * 0.82, alpha_scale))
			draw_circle(tail_tip, 3.6, coat)
			draw_circle(body_pos, 4.6, coat)
			var head_pos := body_pos + Vector2(facing * 4.2, -2.2)
			draw_circle(head_pos, 3.4, coat)
			draw_circle(head_pos + Vector2(0, -3.5), 1.6, coat)
			draw_circle(head_pos + Vector2(facing * 1.6, -0.6), 1.0, Color(0.10, 0.08, 0.08, alpha_scale))


func _draw_daytime_birds(alpha_scale: float) -> void:
	for b in birds:
		var pos: Vector2 = b["pos"]
		var dir: Vector2 = b["dir"]
		var flap := sin(float(b["flap_phase"]))
		var span: float = b["wingspan"]
		var alt: float = b["altitude"]
		var col: Color = b["color"]
		col.a = alpha_scale

		var shadow_pos := pos + Vector2(12.0, alt)
		draw_circle(shadow_pos, span * 0.42, Color(0.06, 0.12, 0.08, 0.18 * alpha_scale))

		var perp := Vector2(-dir.y, dir.x)
		var nose := pos + dir * (span * 0.45)
		var tail := pos - dir * (span * 0.42)
		var wing_lift := -dir * (flap * span * 0.32) + Vector2(0, flap * 4.5)
		var left_tip := pos + perp * span + wing_lift
		var right_tip := pos - perp * span + wing_lift

		draw_line(pos, left_tip, col, 2.4)
		draw_line(pos, right_tip, col, 2.4)
		draw_line(tail, nose, col.darkened(0.15), 2.8)


func _draw_nighttime_fog_and_wisps(alpha_scale: float) -> void:
	for f in fog_banks:
		var pos: Vector2 = f["pos"]
		var r: float = f["radius"]
		var phase: float = f["phase"]
		var base_a: float = float(f["alpha"]) * alpha_scale
		var tint: Color = f["tint"]

		var drift_offset := Vector2(cos(phase) * 18.0, sin(phase * 0.7) * 9.0)
		var c_outer := Color(tint.r, tint.g, tint.b, base_a * 0.55)
		var c_inner := Color(tint.r + 0.08, tint.g + 0.08, tint.b + 0.10, base_a * 0.85)

		draw_circle(pos + drift_offset, r, c_outer)
		draw_circle(pos + drift_offset + Vector2(r * 0.48, -r * 0.12), r * 0.78, c_outer)
		draw_circle(pos + drift_offset + Vector2(-r * 0.45, r * 0.10), r * 0.74, c_outer)
		draw_circle(pos + drift_offset * 0.5, r * 0.62, c_inner)

	for w in night_wisps:
		var pos: Vector2 = w["pos"]
		var phase: float = w["phase"]
		var pulse := 0.45 + 0.55 * (0.5 + 0.5 * sin(phase * 2.0))
		var r: float = float(w["radius"]) * (0.85 + 0.3 * pulse)
		var col: Color = w["color"]

		draw_circle(pos, r * 2.8, Color(col.r, col.g, col.b, 0.16 * pulse * alpha_scale))
		draw_circle(pos, r, Color(col.r, col.g, col.b, 0.88 * pulse * alpha_scale))
		draw_circle(pos, r * 0.45, Color(1.0, 0.98, 0.92, 0.95 * pulse * alpha_scale))
