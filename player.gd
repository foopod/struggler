class_name Player
extends AnimatedSprite2D

@onready var main = get_tree().current_scene
@onready var struggle1_sfx: AudioStreamPlayer2D = $Struggle1SoundPlayer
@onready var struggle2_sfx: AudioStreamPlayer2D = $Struggle2SoundPlayer

func kill() -> void:
	self.play("dead")
	
func struggle() -> void:
	self.play("struggle")
	
func untangle() -> void:
	self.play("getting_up")

func play_walking() -> void:
	self.play("play_walking")

func play_struggle_sound() -> void:
	if randf() < 0.5:
		struggle1_sfx.play()
	else:
		struggle2_sfx.play()
