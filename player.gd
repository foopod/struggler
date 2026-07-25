extends AnimatedSprite2D



func _input(event):
	if event.is_action_pressed("struggle"):
		self.play("default")
