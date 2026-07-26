extends AnimatedSprite2D

@onready var main = get_tree().current_scene


func _input(event):
	if event.is_action_pressed("struggle"):
		self.play("struggle")
		main.add_noise(10)
