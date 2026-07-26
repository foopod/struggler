class_name Enemy
extends AnimatedSprite2D

@onready var sprite: AnimatedSprite2D = self
@onready var water_sfx: AudioStreamPlayer2D = $WashSoundPlayer
@onready var sharpen_sfx: AudioStreamPlayer2D = $SharpenSoundPlayer
@onready var footsteps_sfx: AudioStreamPlayer2D = $FootstepsSoundPlayer
@onready var kill_sfx: AudioStreamPlayer2D = $KillSoundPlayer



func play_walk() -> void:
	sprite.play("walking")

func play_idle() -> void:
	sprite.play("idle")

func play_interact() -> void:
	sprite.play("interacting")

func play_open_door() -> void:
	sprite.play("opening_door")

func play_close_door() -> void:
	sprite.play("closing_door")

func play_killing() -> void:
	sprite.play("killing")


func face_toward(target: Vector2) -> void:
	sprite.flip_h = target.x < global_position.x


func move_to(target: Vector2, speed: float) -> void:
	var distance := global_position.distance_to(target)
	if distance < 1.0:
		return
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, distance / speed)
	await tween.finished


func play_water_sound() -> void:
	water_sfx.play()
	
func play_kill_sound() -> void:
	kill_sfx.play()
	
func play_sharpen_sound() -> void:
	sharpen_sfx.play()
	
func start_footsteps_sound() -> void:
	footsteps_sfx.play()
	
func stop_footsteps_sound() -> void:
	footsteps_sfx.stop()
