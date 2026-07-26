class_name Enemy
extends AnimatedSprite2D

@onready var sprite: AnimatedSprite2D = self
@onready var water_sfx: AudioStreamPlayer = $AudioStreamPlayer


func play_walk() -> void:
	sprite.play("walking")


func play_idle() -> void:
	sprite.play("idle")


func play_interact() -> void:
	sprite.play("interacting")

func play_open_door() -> void:
	sprite.play("opening_door")

func play_killing() -> void:
	sprite.play("killing")


func face_toward(target: Vector2) -> void:
	sprite.flip_h = target.x < global_position.x


# Moves to target at a given speed. Returns when arrival completes.
func move_to(target: Vector2, speed: float) -> void:
	var distance := global_position.distance_to(target)
	if distance < 1.0:
		return
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, distance / speed)
	await tween.finished


func start_water() -> void:
	water_sfx.play()
