extends Node2D

var radius: float = 10.0
var max_radius: float = 120.0
var width: float = 6.0
var alpha: float = 1.0

func _process(delta):
	radius += 400 * delta
	alpha -= 2.5 * delta
	
	queue_redraw()
	
	if alpha <= 0:
		queue_free()

func _draw():
	draw_arc(
		Vector2.ZERO,
		radius,
		0,
		TAU,
		32,
		Color(1, 1, 1, alpha),
		width
	)
