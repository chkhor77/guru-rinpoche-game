class_name NightWaveSpawner
extends Node

## Spawns wrathful wilderness spirits when Night falls over Samye Monastery.
## Each Night wave randomly picks 2 of the 4 Spirit Archetypes (Mist Demon, Fire Imp,
## Shadow Cave Demon, Stone Giant Demon) so gameplay features any 2 models at a time.

@export var spirit_scene: PackedScene
@export var base_spirits_per_wave: int = 3
@export var spawn_radius: float = 650.0

@export var cycle_timer: DayNightCycle


func _ready() -> void:
	# Initialize the first random pair of 2 active Spirit Archetypes for the session
	CorruptedSpirit.roll_random_archetype_pair()

	if cycle_timer == null:
		cycle_timer = get_tree().root.find_child("DayNightCycle", true, false) as DayNightCycle

	if cycle_timer:
		cycle_timer.night_started.connect(_on_night_started)


func _on_night_started(day_number: int) -> void:
	# Roll a fresh random pair of 2 Spirit Archetypes (out of the 4 models) for this Night wave
	CorruptedSpirit.roll_random_archetype_pair()

	var count := base_spirits_per_wave + (day_number - 1) * 2
	_spawn_spirit_wave(count)


func _spawn_spirit_wave(count: int) -> void:
	var center := Vector2(576, 324)

	for i in range(count):
		# Random angle in radians around perimeter
		var angle := randf_range(0.0, TAU)
		var spawn_pos := center + Vector2(cos(angle), sin(angle)) * spawn_radius

		# Instantiate spirit (automatically picks from the 2 active Spirit Archetypes)
		var spirit: CorruptedSpirit
		if spirit_scene:
			spirit = spirit_scene.instantiate() as CorruptedSpirit
		else:
			spirit = _create_procedural_spirit()

		spirit.global_position = spawn_pos
		get_parent().add_child(spirit)


func _create_procedural_spirit() -> CorruptedSpirit:
	var spirit := CorruptedSpirit.new()
	spirit.name = "WaveSpirit"
	spirit.use_random_active_pair = true

	# Sprite
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.scale = Vector2(0.34, 0.34)
	var spirit_tex := ModelTextures.get_tex(ModelTextures.SPIRIT_CORRUPTED_FRONT)
	if spirit_tex == null:
		spirit_tex = load("res://icon.svg") as Texture2D
	spr.texture = spirit_tex
	spirit.add_child(spr)

	# Collision
	var col := CollisionShape2D.new()
	col.name = "CollisionShape2D"
	var circ := CircleShape2D.new()
	circ.radius = 28.0
	col.shape = circ
	spirit.add_child(col)

	# Corruption component
	var corp := CorruptionComponent.new()
	corp.name = "CorruptionComponent"
	corp.max_corruption = 80.0
	spirit.add_child(corp)

	return spirit
