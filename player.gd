class_name Player
extends AnimatedSprite2D

@onready var main = get_tree().current_scene
@onready var struggle1_sfx: AudioStreamPlayer2D = $Struggle1SoundPlayer
@onready var struggle2_sfx: AudioStreamPlayer2D = $Struggle2SoundPlayer
@export var chair: Node2D
@export var blackColor: ColorRect
@export var killerTiedUp: Sprite2D
@export var killer: AnimatedSprite2D

func is_struggling() -> bool:
	if self.is_playing() and self.animation == "struggle" and self.speed_scale > 0.2:
		return true
	return false
		

func kill() -> void:
	self.play("dead")

func struggle() -> void:
	self.play("struggle")

func untangle() -> void:
	self.play("getting_up")

func play_walking() -> void:
	self.play("walking")

func play_struggle_sound() -> void:
	if randf() < 0.5:
		struggle1_sfx.play()
	else:
		struggle2_sfx.play()

func free_player() -> void:
	untangle()
	await get_tree().create_timer(1).timeout
	chair.visible = true
	play_walking()
	await move_to(Vector2(91, 57), 20.0)
	self.visible = false
	blackColor.color.a = 1
	await get_tree().create_timer(1).timeout
	blackColor.color.a = 0
	killerTiedUp.visible = true
	killer.visible = false
	await get_tree().create_timer(5).timeout
	blackColor.color.a = 1

func move_to(target: Vector2, speed: float) -> void:
	var distance := global_position.distance_to(target)
	if distance < 1.0:
		return
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, distance / speed)
	await tween.finished
