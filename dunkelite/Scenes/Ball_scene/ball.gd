extends RigidBody2D

signal first_interaction
signal ball_stuck
signal rim_hit
signal ball_shot
signal max_force_shot

var dragging: bool = false
var can_shoot: bool = true
var has_started: bool = false
var stuck_timer: float = 0.0
var ring_center: Vector2 = Vector2.ZERO
var current_ring: Ring = null
var _drag_start: Vector2 = Vector2.ZERO

const TRAJECTORY_COUNT = 10
var _traj_dots: Array = []
var _gravity: float = 0.0

@export var power_multiplier: float = 30.0
@export var max_force: float = 1800.0
@export var max_speed: float = 2000.0
@export var max_drag_radius: float = 80.0

func _ready() -> void:
	freeze = true
	body_entered.connect(_on_body_entered)
	_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	for i in TRAJECTORY_COUNT:
		var dot = TrajectoryDot.new()
		dot.visible = false
		add_child(dot)
		_traj_dots.append(dot)

func _on_body_entered(body: Node) -> void:
	if body.name == "RimLeft" or body.name == "RimRight":
		rim_hit.emit()

func _input(event: InputEvent) -> void:
	if not can_shoot:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_drag_start = get_canvas_transform().affine_inverse() * event.position
		else:
			if dragging:
				_shoot()
			dragging = false

	elif event is InputEventScreenDrag:
		dragging = true
		_handle_drag(event.position)

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start = get_canvas_transform().affine_inverse() * event.position
		else:
			if dragging:
				_shoot()
			dragging = false

	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = true
		_handle_drag(event.position)

func _handle_drag(screen_pos: Vector2) -> void:
	var canvas_pos = get_canvas_transform().affine_inverse() * screen_pos
	var offset = canvas_pos - _drag_start
	if offset.y < 0:
		offset.y = 0
	if offset.length() > max_drag_radius:
		offset = offset.normalized() * max_drag_radius
	global_position = ring_center + offset
	if current_ring:
		current_ring.net_stretch_offset = global_position - ring_center
	_preview_trajectory()
	_handle_first_interaction()

func _shoot() -> void:
	var drag_vector = ring_center - global_position
	if drag_vector.length() < 10.0:
		global_position = ring_center
		if current_ring:
			current_ring.net_stretch_offset = Vector2.ZERO
		clear_trajectory()
		return
	can_shoot = false
	dragging = false
	var force = drag_vector * power_multiplier
	force.y *= 1.25
	force.x *= 0.85
	if force.length() > max_force:
		force = force.normalized() * max_force
		max_force_shot.emit()
	stuck_timer = 0.0
	global_position = ring_center
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = -25.0 if force.x > 0 else 25.0
	apply_central_impulse(force)
	clear_trajectory()
	ball_shot.emit()

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

func _preview_trajectory() -> void:
	var drag_vector = ring_center - global_position
	if drag_vector.length() < 10.0:
		clear_trajectory()
		return
	var force = drag_vector * power_multiplier
	force.y *= 1.25
	force.x *= 0.85
	if force.length() > max_force:
		force = force.normalized() * max_force
	draw_trajectory(force)

func draw_trajectory(force: Vector2) -> void:
	var time_step = 0.03
	var vel = force / mass
	var grav = Vector2(0, _gravity) * gravity_scale
	var damp = linear_damp
	var pos = Vector2.ZERO
	for i in TRAJECTORY_COUNT:
		vel += grav * time_step
		vel *= 1.0 / (1.0 + damp * time_step)
		pos += vel * time_step
		var dot: TrajectoryDot = _traj_dots[i]
		dot.position = pos
		dot.radius = lerpf(8.0, 3.0, float(i) / (TRAJECTORY_COUNT - 1))
		dot.visible = true
		dot.queue_redraw()

func clear_trajectory() -> void:
	for dot in _traj_dots:
		dot.visible = false

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
