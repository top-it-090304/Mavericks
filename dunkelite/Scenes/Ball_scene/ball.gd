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
var _drag_offset: Vector2 = Vector2.ZERO

const TRAJECTORY_COUNT = 12
var _traj_dots: Array = []
var _gravity: float = 0.0

# Trail
var _is_flying: bool = false

@onready var _trail = $"../BallTrail"

@export var power_multiplier: float = 14.0
@export var max_force: float = 2300.0
@export var max_speed: float = 1900.0
@export var max_drag_radius: float = 200.0
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound

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
		if event.index != 0:
			return
		if event.pressed:
			_drag_start = get_canvas_transform().affine_inverse() * event.position
		else:
			if dragging:
				_shoot()
			dragging = false

	elif event is InputEventScreenDrag:
		if event.index != 0:
			return
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
	var visual_offset = offset
	if visual_offset.length() > 80.0:
		visual_offset = visual_offset.normalized() * 80.0
	global_position = ring_center + visual_offset
	if current_ring:
		current_ring.net_stretch_offset = visual_offset.rotated(-current_ring.rotation)
		var aim_dir = -offset
		if aim_dir.length() > 10.0:
			var target_angle = clampf(aim_dir.angle() + PI / 2.0, -0.45, 0.45)
			current_ring.rotation = lerp_angle(current_ring.rotation, target_angle, 0.15)
		else:
			current_ring.rotation = lerp_angle(current_ring.rotation, 0.0, 0.15)
	_drag_offset = offset
	_preview_trajectory()
	_handle_first_interaction()

func _shoot() -> void:
	var drag_vector = -_drag_offset
	if drag_vector.length() < 10.0:
		global_position = ring_center
		if current_ring:
			current_ring.net_stretch_offset = Vector2.ZERO
			current_ring.rotation = 0.0
		clear_trajectory()
		return
	can_shoot = false
	dragging = false
	var force = drag_vector * power_multiplier
	force.y *= 0.85
	force.x *= 1.25
	if force.length() > max_force:
		force = force.normalized() * max_force
		max_force_shot.emit()
	stuck_timer = 0.0
	_drag_offset = Vector2.ZERO
	if current_ring:
		current_ring.rotation = 0.0
	global_position = ring_center
	freeze = false
	linear_velocity = Vector2.ZERO
	angular_velocity = -25.0 if force.x > 0 else 25.0
	# звук броска
	var vol = clamp(Global.sfx_volume, 0.001, 1.0)
	shoot_sound.volume_db = linear_to_db(vol)

	var force_ratio = clampf(force.length() / max_force, 0.0, 1.0)
	shoot_sound.pitch_scale = lerpf(0.9, 1.2, force_ratio)

	shoot_sound.play()
	apply_central_impulse(force)
	clear_trajectory()
	_is_flying = true
	_trail.clear_trail()
	_trail.visible = _trail._max_points > 0
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
	_is_flying = false
	_trail.visible = false
	_trail.clear_trail()

func enable_shoot() -> void:
	can_shoot = true
	_is_flying = false
	_trail.visible = false
	_trail.clear_trail()

func _preview_trajectory() -> void:
	var drag_vector = -_drag_offset
	if drag_vector.length() < 10.0:
		clear_trajectory()
		return
	var force = drag_vector * power_multiplier
	force.y *= 0.85
	force.x *= 1.25
	if force.length() > max_force:
		force = force.normalized() * max_force
	var force_ratio = clampf(force.length() / max_force, 0.0, 1.0)
	draw_trajectory(force, force_ratio)

func draw_trajectory(force: Vector2, force_ratio: float) -> void:
	var traj_color: Color
	if force_ratio < 0.7:
		var t = force_ratio / 0.7
		traj_color = Color(1.0, 0.9, 0.3, 0.8).lerp(Color(1.0, 0.55, 0.15, 0.88), t)
	elif force_ratio < 0.85:
		var t = (force_ratio - 0.7) / 0.15
		traj_color = Color(1.0, 0.55, 0.15, 0.88).lerp(Color(0.85, 0.25, 0.1, 0.92), t)
	else:
		var t = (force_ratio - 0.85) / 0.15
		traj_color = Color(0.85, 0.25, 0.1, 0.92).lerp(Color(0.72, 0.12, 0.1, 0.95), t)
	var time_step = lerpf(0.05, 0.03, force_ratio)
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
		dot.color = traj_color
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
	if _is_flying and not freeze:
		var trail_pos = global_position
		if linear_velocity.length_squared() > 0.0:
			# Сдвиг назад от центра: меньше радиуса (≈33), чтобы голова трейла
			# заходила внутрь мяча и линия выглядела продолжением шара, а не
			# начиналась от его заднего края.
			trail_pos -= linear_velocity.normalized() * 15.0
		_trail.add_pos(trail_pos)

func _handle_first_interaction():
	if has_started:
		return
	has_started = true
	first_interaction.emit()
