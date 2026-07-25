extends PointLight2D

@export var base_energy := 2.0
@export var flicker_energy := 0.4
@export var min_wait := 2.0
@export var max_wait := 5.0

func _ready() -> void:
	energy = base_energy
	_loop()

func _loop() -> void:
	while true:
		await get_tree().create_timer(randf_range(min_wait, max_wait)).timeout
		# quick flicker burst
		for i in randi_range(2, 4):
			energy = flicker_energy
			await get_tree().create_timer(0.05).timeout
			energy = base_energy
			await get_tree().create_timer(randf_range(0.05, 0.12)).timeout
