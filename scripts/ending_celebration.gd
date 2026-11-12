class_name EndingCelebration
extends Control

## Celebratory Level 1 Ending Movie / Cutscene for Samye Monastery.
## Triggers automatically via signal when all temples in the sacred mandala are completed.
## Features cinematic letterbox bars, drifting lotus petals, victory lore scroll, and stats.

signal celebration_started()

var is_celebrating: bool = false
var anim_t: float = 0.0
var letterbox_height: float = 0.0
var target_letterbox: float = 70.0

# Petals particle array for Ghibli aesthetic
var petals: Array[Dictionary] = []

var cycle_timer: DayNightCycle = null
var stupa: Stupa = null
var audio_manager: MonasteryAudio = null

var final_days: int = 1
var final_protectors: int = 0

var tex_samye_hero: Texture2D = null
var tex_stupa_hero: Texture2D = null
var tex_guru_portrait: Texture2D = null


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(false)

	cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	audio_manager = get_tree().root.find_child("MonasteryAudio", true, false) as MonasteryAudio

	tex_samye_hero = ModelTextures.get_tex(ModelTextures.SAMYE_HERO)
	tex_stupa_hero = ModelTextures.get_tex(ModelTextures.STUPA_HERO)
	tex_guru_portrait = ModelTextures.get_tex(ModelTextures.GURU_PORTRAIT)

	for i in range(36):
		petals.append({
			"pos": Vector2(randf_range(0, 1152), randf_range(-100, 648)),
			"speed": randf_range(40, 85),
			"sway_offset": randf_range(0, TAU),
			"sway_speed": randf_range(1.5, 3.0),
			"size": randf_range(5.0, 10.0),
			"color": Color(1.0, randf_range(0.75, 0.95), randf_range(0.4, 0.7), randf_range(0.7, 0.95))
		})

	# Connect event-driven completion check instead of polling every frame
	for node in get_tree().get_nodes_in_group("building_plots"):
		var plot := node as BuildingPlot
		if plot:
			plot.building_completed.connect(_check_victory_condition)


func _process(delta: float) -> void:
	if not is_celebrating:
		return

	anim_t = minf(1.0, anim_t + delta / 1.8)
	letterbox_height = lerpf(letterbox_height, target_letterbox, delta * 3.0)

	# Update drifting lotus petals
	for p in petals:
		p.pos.y += p.speed * delta
		p.pos.x += sin(anim_t * p.sway_speed + p.sway_offset) * 35.0 * delta
		if p.pos.y > 680:
			p.pos.y = -20
			p.pos.x = randf_range(0, 1152)

	queue_redraw()


func _check_victory_condition() -> void:
	if is_celebrating:
		return

	var plots := get_tree().get_nodes_in_group("building_plots")
	if plots.is_empty():
		return

	for p in plots:
		var plot := p as BuildingPlot
		if plot and not plot.is_completed():
			return

	start_celebration()


func start_celebration() -> void:
	is_celebrating = true
	anim_t = 0.0
	set_process(true)

	if cycle_timer:
		final_days = cycle_timer.current_day
	stupa = get_tree().get_first_node_in_group("stupa") as Stupa
	if stupa:
		final_protectors = stupa.practicing_count

	if audio_manager:
		audio_manager.play_mantra_chime()

	celebration_started.emit()


func _unhandled_input(event: InputEvent) -> void:
	if is_celebrating and event.is_pressed() and anim_t >= 0.9:
		if event is InputEventKey and event.keycode == KEY_R:
			get_tree().reload_current_scene()


func _draw() -> void:
	if not is_celebrating:
		return

	var vp_size := size if size.x > 0 else Vector2(1152, 648)
	var w := vp_size.x
	var h := vp_size.y

	# 1. Cinematic Letterbox Bars (Top & Bottom)
	draw_rect(Rect2(0, 0, w, letterbox_height), Color(0.04, 0.04, 0.05, 1.0))
	draw_rect(Rect2(0, h - letterbox_height, w, letterbox_height), Color(0.04, 0.04, 0.05, 1.0))

	# 2. Golden Radial Light Beams
	var center := Vector2(w * 0.5, h * 0.45)
	var beam_alpha := anim_t * 0.22
	for i in range(12):
		var angle := (float(i) / 12.0) * TAU + (anim_t * 0.3)
		var p1 := center
		var p2 := center + Vector2(cos(angle - 0.12), sin(angle - 0.12)) * 800.0
		var p3 := center + Vector2(cos(angle + 0.12), sin(angle + 0.12)) * 800.0
		var pts: PackedVector2Array = [p1, p2, p3]
		draw_colored_polygon(pts, Color(1.0, 0.9, 0.4, beam_alpha))

	# 3. Drifting Lotus Petals
	for p in petals:
		draw_circle(p.pos, p.size, p.color)

	# 4. Consecration Victory Scroll Banner
	if anim_t > 0.2:
		var banner_alpha := clampf((anim_t - 0.2) / 0.6, 0.0, 1.0)
		var banner_w := 680.0
		var banner_h := 390.0
		var banner_pos := Vector2((w - banner_w) * 0.5, (h - banner_h) * 0.5 - 6.0)

		# Parchment background
		draw_rect(Rect2(banner_pos, Vector2(banner_w, banner_h)), Color(0.12, 0.10, 0.08, banner_alpha * 0.94))
		# Ornate double gold border
		draw_rect(Rect2(banner_pos, Vector2(banner_w, banner_h)), Color(0.95, 0.82, 0.35, banner_alpha), false, 2.5)
		draw_rect(Rect2(banner_pos.x + 6, banner_pos.y + 6, banner_w - 12, banner_h - 12), Color(0.85, 0.65, 0.25, banner_alpha * 0.6), false, 1.0)

		# Title
		var title_txt := "✨ LEVEL 1 COMPLETED ✨\nSAMYE MONASTERY CONSECRATED"
		draw_string(ThemeDB.fallback_font, Vector2(banner_pos.x, banner_pos.y + 38), title_txt, HORIZONTAL_ALIGNMENT_CENTER, int(banner_w), 18, Color(1.0, 0.92, 0.4, banner_alpha))

		# Hero Artwork Cards (Samye Monastery, Guru Rinpoche Portrait, Great Stupa)
		var art_y := banner_pos.y + 72.0
		if tex_samye_hero:
			var r1 := Rect2(banner_pos.x + 48, art_y, 175, 130)
			draw_texture_rect(tex_samye_hero, r1, false, Color(1, 1, 1, banner_alpha))
			draw_rect(r1, Color(0.95, 0.82, 0.35, banner_alpha), false, 1.5)
		if tex_guru_portrait:
			var r2 := Rect2(banner_pos.x + (banner_w - 94) * 0.5, art_y - 4, 94, 138)
			draw_texture_rect(tex_guru_portrait, r2, false, Color(1, 1, 1, banner_alpha))
			draw_rect(r2, Color(1.0, 0.88, 0.4, banner_alpha), false, 2.0)
		if tex_stupa_hero:
			var r3 := Rect2(banner_pos.x + banner_w - 223, art_y, 175, 130)
			draw_texture_rect(tex_stupa_hero, r3, false, Color(1, 1, 1, banner_alpha))
			draw_rect(r3, Color(0.95, 0.82, 0.35, banner_alpha), false, 1.5)

		# Mythic Lore quote
		var quote_txt := "\"Through the wisdom and boundless compassion of Guru Padmasambhava,\nthe wrathful mountain spirits have been pacified into Dharmapalas,\nand the sacred mandala of Samye stands eternal across Tibet.\""
		draw_string(ThemeDB.fallback_font, Vector2(banner_pos.x + 20, banner_pos.y + 235), quote_txt, HORIZONTAL_ALIGNMENT_CENTER, int(banner_w - 40), 12, Color(0.95, 0.92, 0.85, banner_alpha * 0.9))

		# Statistics Line
		var stats_txt := "🏛️ Temples Built: 3 / 3    |    🛕 Dharmapalas Bound: %d    |    ☀️ Days Taken: %d" % [final_protectors, final_days]
		draw_string(ThemeDB.fallback_font, Vector2(banner_pos.x, banner_pos.y + 312), stats_txt, HORIZONTAL_ALIGNMENT_CENTER, int(banner_w), 14, Color(1.0, 0.85, 0.35, banner_alpha))

		# Hint
		var hint_txt := "[ Press 'R' to Replay | Press 'L' to View Sacred Model Sheets ]"
		draw_string(ThemeDB.fallback_font, Vector2(banner_pos.x, banner_pos.y + 360), hint_txt, HORIZONTAL_ALIGNMENT_CENTER, int(banner_w), 12, Color(0.8, 0.8, 0.8, banner_alpha * 0.75))
