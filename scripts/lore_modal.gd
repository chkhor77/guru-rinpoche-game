class_name SacredLoreModal
extends Control

## Interactive Sacred Lore & Model Reference Modal powered by the `samye-visual-models` skill.
## Lets players inspect all 12 full concept & turnaround sheets:
##   1. Padmasambhava (Guru Rinpoche)
##   2. Great Enlightenment Stupa
##   3. Samye Monastery
##   4. Monastery Builder Monk
##   5. Mountain Mist Demon (Before Cleansing)
##   6. Clear Sky Guardian (After Cleansing)
##   7. Wrathful Fire Imp (Before Cleansing)
##   8. Fire Imp / Courage Flame Guardian (After Cleansing)
##   9. Shadow Cave Demon — Wrathful (Before Cleansing)
##  10. Shadow Cave / Cave Light Guardian (After Cleansing)
##  11. Stone Giant Demon — Wrathful (Before Cleansing)
##  12. Stone Giant / Temple Guardian (After Cleansing)
## Toggle with [L] or [TAB], switch tabs with [1]-[9], [0], [-], [=], [Left/Right], or click tabs.

var is_open: bool = false
var current_tab: int = 0

var sheets: Array[Dictionary] = [
	{
		"title": "1. Guru",
		"subtitle": "Compassion · Wisdom · Courage — \"A kinder heart creates a brighter world.\"",
		"path": ModelTextures.SHEET_PADMASAMBHAVA,
		"tex": null
	},
	{
		"title": "2. Stupa",
		"subtitle": "Peace in the Heart · Wisdom in the Mind — \"Small Acts of Kindness Build a Brighter World.\"",
		"path": ModelTextures.SHEET_STUPA,
		"tex": null
	},
	{
		"title": "3. Samye",
		"subtitle": "A Place of Learning · A Beacon of Peace — \"May all beings be happy.\"",
		"path": ModelTextures.SHEET_SAMYE,
		"tex": null
	},
	{
		"title": "4. Monk",
		"subtitle": "Monastery Builder Monk — \"Building Wisdom, One Stone at a Time.\"",
		"path": ModelTextures.SHEET_MONK,
		"tex": null
	},
	{
		"title": "5. Mist (Wrath)",
		"subtitle": "Before Cleansing: Mountain Mist Demon — \"When the path disappears... wisdom shows the way.\"",
		"path": ModelTextures.SHEET_SPIRIT_CORRUPTED,
		"tex": null
	},
	{
		"title": "6. Mist (Pure)",
		"subtitle": "After Cleansing: Clear Sky Guardian — \"Think a little deeper. The answers are always there.\"",
		"path": ModelTextures.SHEET_SPIRIT_CLEANSED,
		"tex": null
	},
	{
		"title": "7. Fire (Wrath)",
		"subtitle": "Before Cleansing: Wrathful Fire Imp — \"When Anger Takes Control — Healing Brings Brighter Tomorrows.\"",
		"path": ModelTextures.SHEET_FIRE_IMP_CORRUPTED,
		"tex": null
	},
	{
		"title": "8. Fire (Pure)",
		"subtitle": "After Cleansing: Fire Imp / Courage Flame Guardian — \"Turning Anger into Courage.\"",
		"path": ModelTextures.SHEET_FIRE_IMP_CLEANSED,
		"tex": null
	},
	{
		"title": "9. Cave (Wrath)",
		"subtitle": "Before Cleansing: Shadow Cave Demon (Wrathful) — \"Sometimes anger is a shield for a hurting heart.\"",
		"path": ModelTextures.SHEET_SHADOW_CAVE_CORRUPTED,
		"tex": null
	},
	{
		"title": "10. Cave (Pure)",
		"subtitle": "After Cleansing: Cave Light Guardian — \"Discovering Courage Through Understanding.\"",
		"path": ModelTextures.SHEET_SHADOW_CAVE_CLEANSED,
		"tex": null
	},
	{
		"title": "11. Giant (Wrath)",
		"subtitle": "Before Cleansing: Stone Giant Demon — \"Blocked by Anger. Waiting for Understanding.\"",
		"path": ModelTextures.SHEET_STONE_GIANT_CORRUPTED,
		"tex": null
	},
	{
		"title": "12. Giant (Pure)",
		"subtitle": "After Cleansing: Temple Guardian Giant — \"Learning Flexibility and Patience.\"",
		"path": ModelTextures.SHEET_STONE_GIANT_CLEANSED,
		"tex": null
	}
]

var tab_rects: Array[Rect2] = []
var close_rect: Rect2 = Rect2()


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = MOUSE_FILTER_IGNORE

	for item in sheets:
		item["tex"] = ModelTextures.get_tex(item["path"] as String)


func toggle_modal(tab_index: int = -1) -> void:
	if tab_index >= 0 and tab_index < sheets.size():
		current_tab = tab_index
		is_open = true
	else:
		is_open = not is_open

	mouse_filter = MOUSE_FILTER_STOP if is_open else MOUSE_FILTER_IGNORE
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_L or k == KEY_TAB:
			toggle_modal()
			get_viewport().set_input_as_handled()
		elif is_open:
			if k == KEY_ESCAPE:
				toggle_modal()
				get_viewport().set_input_as_handled()
			elif k == KEY_LEFT:
				current_tab = (current_tab - 1 + sheets.size()) % sheets.size()
				queue_redraw()
				get_viewport().set_input_as_handled()
			elif k == KEY_RIGHT:
				current_tab = (current_tab + 1) % sheets.size()
				queue_redraw()
				get_viewport().set_input_as_handled()
			elif k == KEY_1:
				current_tab = 0; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_2:
				current_tab = 1; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_3:
				current_tab = 2; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_4:
				current_tab = 3; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_5:
				current_tab = 4; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_6:
				current_tab = 5; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_7:
				current_tab = 6; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_8:
				current_tab = 7; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_9:
				current_tab = 8; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_0:
				current_tab = 9; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_MINUS:
				current_tab = 10; queue_redraw(); get_viewport().set_input_as_handled()
			elif k == KEY_EQUAL:
				current_tab = 11; queue_redraw(); get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mpos: Vector2 = event.position
		if close_rect.has_point(mpos):
			toggle_modal()
			accept_event()
			return

		for i in range(tab_rects.size()):
			if tab_rects[i].has_point(mpos):
				current_tab = i
				queue_redraw()
				accept_event()
				return


func _draw() -> void:
	if not is_open:
		return

	var vp := size if size.x > 0 else Vector2(1152, 648)
	var w := vp.x
	var h := vp.y

	# 1. Dimmed backdrop
	draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.04, 0.06, 0.84))

	# 2. Modal Frame
	var modal_w := minf(1040.0, w - 32.0)
	var modal_h := minf(616.0, h - 24.0)
	var modal_pos := Vector2((w - modal_w) * 0.5, (h - modal_h) * 0.5)
	var modal_rect := Rect2(modal_pos, Vector2(modal_w, modal_h))

	draw_rect(modal_rect, Color(0.11, 0.09, 0.08, 0.98))
	draw_rect(modal_rect, Color(0.95, 0.80, 0.32, 1.0), false, 2.5)
	draw_rect(modal_rect.grow(-5.0), Color(0.75, 0.58, 0.22, 0.6), false, 1.0)

	# 3. Top Header & 2-Row Tabs (6 tabs per row for all 12 sheets)
	tab_rects.clear()
	var cols := 6
	var tab_w := (modal_w - 136.0 - float(cols - 1) * 6.0) / float(cols)
	var tab_h := 24.0

	for i in range(sheets.size()):
		var col_idx := i % cols
		var row_idx := int(i / cols)
		var tx := modal_pos.x + 14.0 + col_idx * (tab_w + 6.0)
		var ty := modal_pos.y + 10.0 + row_idx * (tab_h + 4.0)
		var tr := Rect2(tx, ty, tab_w, tab_h)
		tab_rects.append(tr)

		var is_active := (i == current_tab)
		var bg_col := Color(0.62, 0.16, 0.17, 0.95) if is_active else Color(0.20, 0.17, 0.15, 0.9)
		var border_col := Color(1.0, 0.86, 0.35, 1.0) if is_active else Color(0.55, 0.45, 0.3, 0.6)
		draw_rect(tr, bg_col)
		draw_rect(tr, border_col, false, 1.5 if is_active else 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(tx + 4, ty + 16), sheets[i]["title"] as String, HORIZONTAL_ALIGNMENT_CENTER, tab_w - 8, 11, Color(1.0, 0.95, 0.8))

	# Close Button
	close_rect = Rect2(modal_pos.x + modal_w - 94.0, modal_pos.y + 10.0, 80.0, 52.0)
	draw_rect(close_rect, Color(0.35, 0.14, 0.14, 0.95))
	draw_rect(close_rect, Color(0.95, 0.75, 0.35, 0.9), false, 1.2)
	draw_string(ThemeDB.fallback_font, Vector2(close_rect.position.x, close_rect.position.y + 30), "Close [L]", HORIZONTAL_ALIGNMENT_CENTER, close_rect.size.x, 12, Color(1.0, 0.92, 0.75))

	# 4. Active Reference Sheet Image
	var active_item := sheets[current_tab]
	var tex: Texture2D = active_item["tex"] as Texture2D
	var img_area := Rect2(modal_pos.x + 18.0, modal_pos.y + 68.0, modal_w - 36.0, modal_h - 104.0)

	if tex:
		var tex_aspect := float(tex.get_width()) / float(maxi(1, tex.get_height()))
		var draw_h := img_area.size.y
		var draw_w := draw_h * tex_aspect
		if draw_w > img_area.size.x:
			draw_w = img_area.size.x
			draw_h = draw_w / tex_aspect
		var dst := Rect2(
			img_area.position.x + (img_area.size.x - draw_w) * 0.5,
			img_area.position.y + (img_area.size.y - draw_h) * 0.5,
			draw_w,
			draw_h
		)
		draw_texture_rect(tex, dst, false)
		draw_rect(dst, Color(0.95, 0.82, 0.38, 0.85), false, 1.5)

	# 5. Footer Subtitle & Controls Hint
	var footer_y := modal_pos.y + modal_h - 12.0
	draw_string(ThemeDB.fallback_font, Vector2(modal_pos.x + 20, footer_y), (active_item["subtitle"] as String) + "   |   [Left/Right or Click Tabs]: Switch Sheet   |   [L / TAB / ESC]: Close", HORIZONTAL_ALIGNMENT_CENTER, modal_w - 40, 12, Color(1.0, 0.92, 0.65))
