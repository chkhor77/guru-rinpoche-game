class_name SamyeWorker
extends CharacterBody2D

## Monastery Builder Monk ("Building Wisdom, One Stone at a Time").
## Gathers timber from forests, quarries sandstone, and raises Samye temples by day.
## Seeks shelter inside completed shrines when night spirits attack!
## When blessed by Guru Rinpoche's daytime mantra, all activities are doubled for 3 seconds!
## Uses 4-directional turnaround sprites extracted via the `samye-visual-models` skill.
##
## Anti-Synchronization Design (Day 2+ Independence):
## - Each monk maintains a personal speed multiplier (`personal_speed_factor`), staggered
##   decision timer (`think_delay_timer`), and individualized spatial offsets (`shelter_offset`,
##   `work_offset`, `harvest_offset`) so monks never stack on a single coordinate or walk in lockstep.
## - Task, building, and resource node selection randomize across eligible candidates.

enum State {
	IDLE,
	MOVING_TO_RESOURCE,
	HARVESTING,
	HAULING,
	BUILDING,
	SHELTERING
}

enum FacingDirection {
	DOWN,
	UP,
	LEFT,
	RIGHT
}

@export_group("Craftsman Stats")
@export var move_speed: float = 95.0
@export var carry_capacity: float = 10.0
@export var harvest_speed: float = 6.0 ## Units harvested per second
@export var build_speed: float = 14.0  ## Construction work added per second

@export_group("Visual Presentation")
@export var monk_draw_size: Vector2 = Vector2(36.0, 92.0)

var current_state: State = State.IDLE
var current_facing: FacingDirection = FacingDirection.DOWN
var carried_type: ResourceNode.ResourceType = ResourceNode.ResourceType.TIMBER
var carried_amount: float = 0.0

var target_resource: ResourceNode = null
var target_building: BuildingPlot = null
var target_shelter: BuildingPlot = null

var harvest_timer: float = 0.0
var is_blessed: bool = false
var mantra_boost_timer: float = 0.0 ## 3-second 2x multiplier from Guru Rinpoche
var cycle_timer: DayNightCycle = null
var player: Node2D = null

var directional_textures: Dictionary = {}
var anim_time: float = 0.0

# Individualized movement & anti-stacking state (prevents unified Day 2 clone walking)
var personal_speed_factor: float = 1.0
var think_delay_timer: float = 0.0
var shelter_offset: Vector2 = Vector2.ZERO
var work_offset: Vector2 = Vector2.ZERO
var harvest_offset: Vector2 = Vector2.ZERO
var stroll_target: Vector2 = Vector2.ZERO
var stroll_pause_timer: float = 0.0


func _ready() -> void:
	add_to_group("workers")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# Collision layer 2, mask 0 so workers never wedge or block Guru Rinpoche
	collision_layer = 2
	collision_mask = 0

	anim_time = randf_range(0.0, TAU)
	_reroll_personal_traits()
	think_delay_timer = randf_range(0.05, 0.75)
	_pick_new_stroll_target()

	cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle
	player = get_tree().get_first_node_in_group("player")

	if cycle_timer:
		cycle_timer.night_started.connect(_on_night_started)
		cycle_timer.day_started.connect(_on_day_started)

	_ensure_collision_shape()
	_setup_monk_turnaround_sprites()


func _reroll_personal_traits() -> void:
	personal_speed_factor = randf_range(0.86, 1.16)
	var angle_s := randf_range(0.0, TAU)
	shelter_offset = Vector2(cos(angle_s), sin(angle_s)) * randf_range(28.0, 72.0)
	var angle_w := randf_range(0.0, TAU)
	work_offset = Vector2(cos(angle_w), sin(angle_w)) * randf_range(18.0, 42.0)
	var angle_h := randf_range(0.0, TAU)
	harvest_offset = Vector2(cos(angle_h), sin(angle_h)) * randf_range(10.0, 26.0)


func _setup_monk_turnaround_sprites() -> void:
	directional_textures[FacingDirection.DOWN]  = ModelTextures.get_tex(ModelTextures.MONK_FRONT)
	directional_textures[FacingDirection.UP]    = ModelTextures.get_tex(ModelTextures.MONK_BACK)
	directional_textures[FacingDirection.LEFT]  = ModelTextures.get_tex(ModelTextures.MONK_LEFT)
	directional_textures[FacingDirection.RIGHT] = ModelTextures.get_tex(ModelTextures.MONK_RIGHT)
	queue_redraw()


func _ensure_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		add_child(col)

	var circle := CircleShape2D.new()
	circle.radius = 14.0
	col.shape = circle


## Called when Guru Rinpoche chants a daytime mantra to the worker
func apply_mantra_boost(duration: float = 3.0) -> void:
	mantra_boost_timer = duration
	queue_redraw()


func _physics_process(delta: float) -> void:
	_check_guru_blessing()

	if mantra_boost_timer > 0.0:
		mantra_boost_timer = maxf(0.0, mantra_boost_timer - delta)

	var speed_mult := personal_speed_factor
	if mantra_boost_timer > 0.0:
		speed_mult *= 2.0
	elif is_blessed:
		speed_mult *= 1.4

	var effective_speed := move_speed * speed_mult

	match current_state:
		State.IDLE:
			if think_delay_timer > 0.0:
				think_delay_timer = maxf(0.0, think_delay_timer - delta)
				_process_idle_stroll(delta, effective_speed * 0.55)
			else:
				_evaluate_next_task()
				if current_state == State.IDLE:
					_process_idle_stroll(delta, effective_speed * 0.55)

		State.MOVING_TO_RESOURCE:
			if target_resource == null or not is_instance_valid(target_resource) or not target_resource.is_available():
				current_state = State.IDLE
				think_delay_timer = randf_range(0.1, 0.4)
			else:
				var dest := target_resource.global_position + harvest_offset
				var dist := global_position.distance_to(dest)
				if dist > 24.0:
					velocity = (dest - global_position).normalized() * effective_speed
				else:
					velocity = Vector2.ZERO
					_face_towards(target_resource.global_position)
					current_state = State.HARVESTING
					harvest_timer = carry_capacity / (harvest_speed * speed_mult)

		State.HARVESTING:
			velocity = Vector2.ZERO
			harvest_timer -= delta
			if harvest_timer <= 0.0:
				if target_resource and is_instance_valid(target_resource):
					carried_type = target_resource.resource_type
					carried_amount = target_resource.harvest(carry_capacity)
				current_state = State.HAULING
				queue_redraw()

		State.HAULING:
			if target_building == null or not is_instance_valid(target_building) or not target_building.needs_resource(carried_type):
				target_building = _find_building_needing_resource(carried_type)

			if target_building:
				var dest := target_building.global_position + work_offset
				var threshold: float = (target_building.plot_size.x * 0.5) + 18.0
				var dist := global_position.distance_to(dest)

				if dist > threshold:
					velocity = (dest - global_position).normalized() * effective_speed
				else:
					velocity = Vector2.ZERO
					var accepted := target_building.deposit_resource(carried_type, carried_amount)
					carried_amount = maxf(0.0, carried_amount - accepted)
					if carried_amount <= 0.0:
						current_state = State.IDLE
						think_delay_timer = randf_range(0.08, 0.35)
					else:
						target_building = _find_building_needing_resource(carried_type)
						if target_building == null:
							carried_amount = 0.0
							current_state = State.IDLE
							think_delay_timer = randf_range(0.08, 0.35)
					queue_redraw()
			else:
				carried_amount = 0.0
				current_state = State.IDLE
				think_delay_timer = randf_range(0.1, 0.4)

		State.BUILDING:
			if target_building == null or not is_instance_valid(target_building) or target_building.is_completed():
				current_state = State.IDLE
				think_delay_timer = randf_range(0.1, 0.45)
			else:
				var dest := target_building.global_position + work_offset
				var threshold: float = (target_building.plot_size.x * 0.5) + 20.0
				var dist := global_position.distance_to(dest)
				if dist > threshold:
					velocity = (dest - global_position).normalized() * effective_speed
				else:
					velocity = Vector2.ZERO
					_face_towards(target_building.global_position)
					target_building.add_construction_work(build_speed * speed_mult * delta)
					if not target_building.needs_work():
						current_state = State.IDLE
						think_delay_timer = randf_range(0.1, 0.45)

		State.SHELTERING:
			if target_shelter and is_instance_valid(target_shelter):
				var shelter_dest := target_shelter.global_position + shelter_offset * 0.35
				var threshold: float = (target_shelter.plot_size.x * 0.5) + 12.0
				var dist := global_position.distance_to(shelter_dest)
				if dist > threshold:
					velocity = (shelter_dest - global_position).normalized() * (effective_speed * 1.3)
				else:
					velocity = Vector2.ZERO
					visible = false
			else:
				# Spread around the central courtyard using personal shelter_offset so monks never stack at one point
				var courtyard_spot := Vector2(576, 330) + shelter_offset
				if global_position.distance_to(courtyard_spot) > 18.0:
					velocity = (courtyard_spot - global_position).normalized() * effective_speed
				else:
					velocity = Vector2.ZERO

	move_and_slide()
	_update_facing_and_animation(delta * speed_mult)


func _process_idle_stroll(delta: float, stroll_speed: float) -> void:
	if stroll_pause_timer > 0.0:
		stroll_pause_timer -= delta
		velocity = Vector2.ZERO
		return

	if global_position.distance_to(stroll_target) > 18.0:
		velocity = (stroll_target - global_position).normalized() * stroll_speed
	else:
		velocity = Vector2.ZERO
		stroll_pause_timer = randf_range(0.5, 1.6)
		_pick_new_stroll_target()


func _pick_new_stroll_target() -> void:
	stroll_target = Vector2(
		randf_range(240.0, 910.0),
		randf_range(190.0, 480.0)
	)


func _face_towards(target_pos: Vector2) -> void:
	var diff := target_pos - global_position
	if absf(diff.x) > absf(diff.y):
		current_facing = FacingDirection.LEFT if diff.x < 0.0 else FacingDirection.RIGHT
	else:
		current_facing = FacingDirection.UP if diff.y < 0.0 else FacingDirection.DOWN


func _update_facing_and_animation(scaled_delta: float) -> void:
	if velocity.length_squared() > 4.0:
		anim_time += scaled_delta * 11.0
		if absf(velocity.x) > absf(velocity.y):
			current_facing = FacingDirection.LEFT if velocity.x < 0.0 else FacingDirection.RIGHT
		else:
			current_facing = FacingDirection.UP if velocity.y < 0.0 else FacingDirection.DOWN
		queue_redraw()
	elif current_state == State.BUILDING or current_state == State.HARVESTING:
		anim_time += scaled_delta * 14.0
		queue_redraw()
	elif mantra_boost_timer > 0.0:
		queue_redraw()


func _evaluate_next_task() -> void:
	if cycle_timer and cycle_timer.is_night():
		_seek_shelter()
		return

	_reroll_personal_traits()

	# Priority 1: Work on buildings that have materials ready
	var work_building := _find_building_needing_work()
	if work_building:
		target_building = work_building
		current_state = State.BUILDING
		return

	# Priority 2 & 3: Randomize resource type check order so monks split between Timber and Sandstone!
	var resource_order: Array[ResourceNode.ResourceType] = [
		ResourceNode.ResourceType.TIMBER,
		ResourceNode.ResourceType.SANDSTONE
	]
	if randf() < 0.5:
		resource_order.reverse()

	for r_type in resource_order:
		var needy_building := _find_building_needing_resource(r_type)
		if needy_building:
			var res_node := _find_nearest_resource(r_type)
			if res_node:
				target_building = needy_building
				target_resource = res_node
				current_state = State.MOVING_TO_RESOURCE
				return

	# Nothing needs resources or work right now; stroll independently and re-evaluate soon
	think_delay_timer = randf_range(0.6, 1.5)


func _seek_shelter() -> void:
	if current_state == State.SHELTERING and target_shelter != null:
		return

	current_state = State.SHELTERING
	target_shelter = null
	var shelters: Array[BuildingPlot] = []

	for node in get_tree().get_nodes_in_group("building_plots"):
		var plot := node as BuildingPlot
		if plot and plot.can_shelter_worker():
			shelters.append(plot)

	if not shelters.is_empty():
		target_shelter = shelters.pick_random()
		target_shelter.register_worker_sheltered()


func _on_night_started(_day: int) -> void:
	_reroll_personal_traits()
	_seek_shelter()


func _on_day_started(_day: int) -> void:
	if target_shelter and is_instance_valid(target_shelter):
		target_shelter.release_worker_shelter()

	visible = true
	target_shelter = null
	target_resource = null
	target_building = null
	current_state = State.IDLE

	# Re-roll personal speed & offsets and stagger wake-up so monks disperse naturally on Day 2+
	_reroll_personal_traits()
	think_delay_timer = randf_range(0.12, 1.15)
	stroll_pause_timer = 0.0
	stroll_target = global_position + shelter_offset
	queue_redraw()


func _check_guru_blessing() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player:
		var dist := global_position.distance_to(player.global_position)
		var was_blessed := is_blessed
		is_blessed = dist < 160.0
		if was_blessed != is_blessed:
			queue_redraw()


func _find_building_needing_work() -> BuildingPlot:
	var candidates: Array[BuildingPlot] = []
	for node in get_tree().get_nodes_in_group("building_plots"):
		var plot := node as BuildingPlot
		if plot and plot.needs_work():
			candidates.append(plot)
	if candidates.is_empty():
		return null
	return candidates.pick_random()


func _find_building_needing_resource(type: ResourceNode.ResourceType) -> BuildingPlot:
	var candidates: Array[BuildingPlot] = []
	for node in get_tree().get_nodes_in_group("building_plots"):
		var plot := node as BuildingPlot
		if plot and plot.needs_resource(type):
			candidates.append(plot)
	if candidates.is_empty():
		return null
	return candidates.pick_random()


func _find_nearest_resource(type: ResourceNode.ResourceType) -> ResourceNode:
	var candidates: Array[ResourceNode] = []
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		var r_node := node as ResourceNode
		if r_node and r_node.resource_type == type and r_node.is_available():
			candidates.append(r_node)

	if candidates.is_empty():
		return null

	# Pick randomly among available resource nodes so monks spread across different trees/quarries
	return candidates.pick_random()


func _draw() -> void:
	if not visible:
		return

	# 1. Ground shadow / Mantra Empowerment Aura beneath sandals
	if mantra_boost_timer > 0.0:
		draw_circle(Vector2(0, -18), 32.0, Color(1.0, 0.95, 0.3, 0.35))
		draw_arc(Vector2(0, -18), 34.0, 0.0, TAU, 32, Color(1.0, 0.88, 0.2, 0.95), 2.5)
		draw_string(ThemeDB.fallback_font, Vector2(-36, -86), "Mantra 2X!", HORIZONTAL_ALIGNMENT_CENTER, 72, 12, Color(1.0, 0.95, 0.2))
	elif is_blessed:
		draw_circle(Vector2(0, -18), 26.0, Color(1.0, 0.9, 0.4, 0.22))
		draw_arc(Vector2(0, -18), 26.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.3, 0.6), 1.5)
	else:
		draw_circle(Vector2(0, 2), 13.0, Color(0.1, 0.08, 0.05, 0.28))

	# 2. Monastery Builder Monk 4-Directional Sprite
	var tex := directional_textures.get(current_facing) as Texture2D
	if tex == null:
		tex = directional_textures.get(FacingDirection.DOWN) as Texture2D

	if tex:
		var bob_y := 0.0
		if velocity.length_squared() > 4.0 or current_state == State.BUILDING or current_state == State.HARVESTING:
			bob_y = sin(anim_time) * 2.2
		var dst_rect := Rect2(
			Vector2(-monk_draw_size.x * 0.5, -monk_draw_size.y + 8.0 + bob_y),
			monk_draw_size
		)
		draw_texture_rect(tex, dst_rect, false)
	else:
		# Fallback procedural monk
		draw_circle(Vector2(0, -10), 8.0, Color(0.9, 0.75, 0.6))
		draw_rect(Rect2(-7, -2, 14, 16), Color(0.85, 0.52, 0.15))
		draw_rect(Rect2(-5, 0, 10, 4), Color(0.65, 0.22, 0.22))

	# 3. Carried resource bundle indicator
	if carried_amount > 0.0:
		if carried_type == ResourceNode.ResourceType.TIMBER:
			draw_rect(Rect2(-18, -38, 7, 16), Color(0.45, 0.28, 0.15))
			draw_circle(Vector2(-14.5, -38), 3.5, Color(0.68, 0.48, 0.26))
		else:
			draw_rect(Rect2(-19, -36, 10, 12), Color(0.82, 0.74, 0.60))
			draw_rect(Rect2(-19, -36, 10, 12), Color(0.45, 0.38, 0.30), false, 1.2)
