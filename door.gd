class_name Door
extends AnimatedSprite2D

@onready var sprite: AnimatedSprite2D = self
@onready var open_sfx: AudioStreamPlayer2D = $OpenSoundPlayer
@onready var close_sfx: AudioStreamPlayer2D = $CloseSoundPlayer


func play_open() -> void:
	sprite.play("opening")
	open_sfx.play()

func play_close() -> void:
	sprite.play("closing")
	close_sfx.play()
