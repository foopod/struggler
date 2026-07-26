extends AnimatedSprite2D

@onready var main = get_tree().current_scene
@onready var struggle1_sfx: AudioStreamPlayer2D = $Struggle1SoundPlayer
@onready var struggle2_sfx: AudioStreamPlayer2D = $Struggle2SoundPlayer

func _input(event):
	if event.is_action_pressed("struggle"):
		self.play("struggle")
		main.add_noise(10)
		if randf() < 0.5:
			struggle1_sfx.play()
		else:
			struggle2_sfx.play()
