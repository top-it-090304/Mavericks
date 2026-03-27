extends RigidBody2D

signal first_interaction
signal ball_stuck
signal rim_hit

var drag_start: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0
var dragging: bool = false
var can_shoot: bool = true
var has_started: bool = false

func _ready() -> void:
	freeze = true
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.name == "RimLeft" or body.name == "RimRight":
		rim_hit.emit()

@export var power_multiplier: float = 10.0
@export var max_force: float = 1600.0
@export var max_speed: float = 2200.0
@export var min_drag_distance: float = 20.0

func _input(event: InputEvent) -> void:
	if not can_shoot:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_first_interaction()
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
			_handle_first_interaction()
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
	stuck_timer = 0.0
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = -25.0 if force.x > 0 else 25.0
	apply_central_impulse(force)
	clear_trajectory()

func on_goal() -> void:
	stuck_timer = 0.0
	set_deferred("freeze", true)
	can_shoot = false
	dragging = false
	clear_trajectory()
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0

func enable_shoot() -> void:
	can_shoot = true

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
	var point_count = 10
	var time_step = 0.03
	var vel = force / mass
	var grav = Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity")) * gravity_scale
	var damp = linear_damp
	var pos = Vector2.ZERO
	for i in range(point_count):
		vel += grav * time_step
		vel *= 1.0 / (1.0 + damp * time_step)
		pos += vel * time_step
		var dot = TrajectoryDot.new()
		dot.position = pos
		var progress = float(i) / (point_count - 1)
		dot.radius = lerpf(8.0, 3.0, progress)
		dot.color = Color(1, 1, 1, 1)
		add_child(dot)

func clear_trajectory() -> void:
	for child in get_children():
		if child is TrajectoryDot:
			child.queue_free()

class TrajectoryDot extends Node2D:
	var radius: float = 6.0
	var color: Color = Color(1, 0.5, 0.1)
	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, color)

func _physics_process(delta: float) -> void:
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	if not can_shoot and not freeze and linear_velocity.length() < 30:
		stuck_timer += delta
		if stuck_timer > 2.5:
			stuck_timer = 0.0
			ball_stuck.emit()
	else:
		stuck_timer = 0.0

func _handle_first_interaction():
	if has_started:
		return
	
	has_started = true
	first_interaction.emit()
