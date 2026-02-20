extends Area2D
func _on_area_body_entered(body):
	if body.name == "Ball":
		if body.linear_velocity.y > 0:
			score()
			
