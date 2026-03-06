extends RigidBody2D

var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false
var can_shoot: bool = true

@export var power_multiplier: float = 7.0
@export var max_force: float = 1600.0
@export var max_speed: float = 2200.0
@export var min_drag_distance: float = 20.0

func _input(event: InputEvent) -> void:
	if not can_shoot:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			drag_start = event.position
			dragging = true
		else:
			if dragging:
				shoot(event.position)
				dragging = false

	if event is InputEventScreenDrag and dragging:
		_preview_trajectory(event.position)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start = event.position
			dragging = true
		else:
			if dragging:
				shoot(event.position)
				dragging = false

	if event is InputEventMouseMotion and dragging:
		_preview_trajectory(event.position)

func shoot(release_pos: Vector2) -> void:
	var drag_vector = drag_start - release_pos
	if drag_vector.length() < min_drag_distance:
		clear_trajectory()
		return

	can_shoot = false
	dragging = false

	var force = drag_vector * power_multiplier
	force.y *= 1.1
	force.x *= 0.95
	if force.length() > max_force:
		force = force.normalized() * max_force

	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = 30.0
	apply_central_impulse(force)
	clear_trajectory()

func on_goal() -> void:
	freeze = true
	can_shoot = false
	dragging = false
	clear_trajectory()
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func enable_shoot() -> void:
	freeze = false
	can_shoot = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func _preview_trajectory(current_pos: Vector2) -> void:
	var drag_vector = drag_start - current_pos
	if drag_vector.length() < min_drag_distance:
		clear_trajectory()
		return
	var force = drag_vector * power_multiplier
	force.y *= 1.1
	force.x *= 0.95
	if force.length() > max_force:
		force = force.normalized() * max_force
	draw_trajectory(force)

func draw_trajectory(force: Vector2) -> void:
	clear_trajectory()
	var line := Line2D.new()
	line.width = 8.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1.0))
	gradient.set_color(1, Color(1, 1, 1, 0.0))
	line.gradient = gradient
	add_child(line)

	var point_count = 6
	var time_step = 0.06
	var velocity = force / mass
	var gravity = Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity")) * gravity_scale

	for i in range(point_count):
		var t = i * time_step
		var pos = velocity * t + 0.5 * gravity * t * t
		line.add_point(pos)

func clear_trajectory() -> void:
	for child in get_children():
		if child is Line2D:
			child.queue_free()

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	angular_velocity = clamp(angular_velocity, -1000.0, 1000.0)
