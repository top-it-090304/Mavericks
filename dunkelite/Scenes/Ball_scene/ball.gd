extends RigidBody2D

@export var trajectory_container: Node2D

var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false

@export var power_multiplier: float = 4.8
@export var max_force: float = 1150.0
@export var max_speed: float = 1350.0
@export var min_drag_distance: float = 20.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			drag_start = event.position
			dragging = true
		else:
			if dragging:
				shoot(event.position)
				dragging = false
	if event is InputEventScreenDrag:
		if dragging:
			_preview_trajectory(event.position)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag_start = event.position
				dragging = true
			else:
				if dragging:
					shoot(event.position)
					dragging = false
	if event is InputEventMouseMotion:
		if dragging:
			_preview_trajectory(event.position)

func _preview_trajectory(current_pos: Vector2) -> void:
	var drag_vector: Vector2 = drag_start - current_pos
	if drag_vector.length() < min_drag_distance:
		clear_trajectory()
		return
	var force: Vector2 = drag_vector * power_multiplier
	force.y *= 1.1
	force.x *= 0.95
	if force.length() > max_force:
		force = force.normalized() * max_force
	draw_trajectory(force)

func shoot(release_pos: Vector2) -> void:
	var drag_vector: Vector2 = drag_start - release_pos
	if drag_vector.length() < min_drag_distance:
		clear_trajectory()
		return
	var force: Vector2 = drag_vector * power_multiplier
	force.y *= 1.1
	force.x *= 0.95
	if force.length() > max_force:
		force = force.normalized() * max_force
	linear_velocity = Vector2.ZERO
	angular_velocity = 30.0
	apply_central_impulse(force)
	clear_trajectory()

func draw_trajectory(force: Vector2) -> void:
	clear_trajectory()
	
	var line := Line2D.new()
	line.width = 8.0
	line.default_color = Color.WHITE
	
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1.0))
	gradient.set_color(1, Color(1, 1, 1, 0.0))
	line.gradient = gradient
	
	$CollisionShape2D.add_child(line)  # добавляем прямо к мячу, не к trajectory_container
	
	var point_count: int = 20
	var time_step: float = 0.06
	var velocity: Vector2 = -force / mass
	var gravity: Vector2 = Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity")) * gravity_scale
	
	for i in range(point_count):
		var t: float = i * time_step
		# Позиция относительно мяча, поэтому start_pos = Vector2.ZERO
		var pos: Vector2 = velocity * t + 0.5 * gravity * t * t
		line.add_point(pos)

func clear_trajectory() -> void:
	for child in $CollisionShape2D.get_children():
		if child is Line2D:
			child.queue_free()

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	angular_velocity = clamp(angular_velocity, -1000.0, 1000.0)
