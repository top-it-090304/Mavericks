extends Node2D

var radius: float = 10.0
var max_radius: float = 120.0
var width: float = 6.0
var alpha: float = 1.0
# Outward direction from the surface that was hit. Zero = full circle.
var normal: Vector2 = Vector2.ZERO

func _process(delta):
	radius += 400 * delta
	alpha -= 2.5 * delta

	queue_redraw()

	if alpha <= 0:
		queue_free()

func _draw():
	var color := Color(1, 1, 1, alpha)
	if normal == Vector2.ZERO:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, width)
	else:
		var center_angle: float = normal.angle()
		draw_arc(
			Vector2.ZERO,
			radius,
			center_angle - PI / 2.0,
			center_angle + PI / 2.0,
			24,
			color,
			width
		)
