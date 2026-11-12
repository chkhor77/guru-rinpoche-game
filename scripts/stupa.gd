class_name Stupa
extends Area2D

## Sacred Buddhist Stupa (Chorten) where subjugated Dharmapalas reside.
## Once a Dharmapala reaches the Stupa, it ascends into the sanctuary,
## increasing the protector tally and freeing the screen so Guru Rinpoche is never blocked.

signal dharmapala_joined(total_practicing: int)

@export var stupa_radius: float = 110.0
@export var stupa_name: String = "Great Enlightenment Stupa"
@export var model_draw_size: Vector2 = Vector2(196, 162)

var practicing_count: int = 0
var ascension_pulse_time: float = 1.0
var stupa_iso_tex: Texture2D = null


func _ready() -> void:
	add_to_group("stupa")
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	_ensure_collision_shape()
	stupa_iso_tex = ModelTextures.get_tex(ModelTextures.STUPA_ISOMETRIC)
	queue_redraw()


func _ensure_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)

	var circle := CircleShape2D.new()
	circle.radius = stupa_radius
	col.shape = circle


func _on_body_entered(body: Node2D) -> void:
	var spirit := body as CorruptedSpirit
	if spirit and spirit.is_subjugated and not spirit.is_ascended:
		spirit.ascend_into_stupa(self)


func register_ascended_dharmapala() -> void:
	practicing_count += 1
	ascension_pulse_time = 0.0
	dharmapala_joined.emit(practicing_count)
	queue_redraw()


func _process(delta: float) -> void:
	if ascension_pulse_time < 1.0:
		ascension_pulse_time = minf(1.0, ascension_pulse_time + delta / 0.6)
		queue_redraw()


func _draw() -> void:
	# 1. Meditation Sanctuary Sacred Circle (Golden floor mandala)
	draw_circle(Vector2.ZERO, stupa_radius, Color(1.0, 0.92, 0.6, 0.14))
	draw_arc(Vector2.ZERO, stupa_radius, 0.0, TAU, 48, Color(1.0, 0.85, 0.35, 0.65), 2.0)

	# 2. Golden ascension pulse wave when a Dharmapala enters
	if ascension_pulse_time < 1.0:
		var r := stupa_radius * (0.3 + 0.7 * ease(ascension_pulse_time, 0.3))
		var a := (1.0 - ascension_pulse_time) * 0.9
		draw_arc(Vector2(0, -32), r, 0.0, TAU, 36, Color(1.0, 0.9, 0.4, a), 3.0)

	# 3. Render the Isometric Stupa Model from the `samye-visual-models` skill
	if stupa_iso_tex:
		var dst_rect := Rect2(Vector2(-model_draw_size.x * 0.5, -model_draw_size.y * 0.68), model_draw_size)
		draw_texture_rect(stupa_iso_tex, dst_rect, false)
	else:
		# Fallback procedural Stupa
		draw_rect(Rect2(-32, -8, 64, 20), Color(0.85, 0.82, 0.78, 1.0))
		draw_rect(Rect2(-26, -18, 52, 10), Color(0.92, 0.9, 0.86, 1.0))
		draw_circle(Vector2(0, -32), 22.0, Color(0.98, 0.98, 0.96, 1.0))
		draw_rect(Rect2(-12, -36, 24, 6), Color(0.75, 0.2, 0.2, 1.0))
		var spire_pts: PackedVector2Array = [
			Vector2(-8, -54),
			Vector2(8, -54),
			Vector2(2, -82),
			Vector2(-2, -82)
		]
		draw_colored_polygon(spire_pts, Color(1.0, 0.84, 0.25, 1.0))
		draw_circle(Vector2(0, -88), 6.0, Color(1.0, 0.92, 0.4, 1.0))

	# 4. Label & Count of Dharmapalas residing in the Stupa
	var label_txt := "%s\n[ %d Dharmapala%s Preserved in Stupa ]" % [
		stupa_name,
		practicing_count,
		"s" if practicing_count != 1 else ""
	]
	draw_string(ThemeDB.fallback_font, Vector2(-160, -118), label_txt, HORIZONTAL_ALIGNMENT_CENTER, 320, 13, Color(1.0, 0.95, 0.7))
