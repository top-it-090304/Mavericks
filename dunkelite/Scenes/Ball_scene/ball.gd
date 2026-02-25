extends RigidBody2D

# --- Drag control ---
var drag_start: Vector2 = Vector2.ZERO
var dragging: bool = false

# --- Tunable parameters ---
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

	# Для теста на ПК (мышь)
	if event is InputEventMouseButton:
		if event.pressed:
			drag_start = event.position
			dragging = true
		else:
			if dragging:
				shoot(event.position)
				dragging = false


func shoot(release_pos: Vector2) -> void:
	var drag_vector: Vector2 = drag_start - release_pos

	if drag_vector.length() < min_drag_distance:
		return

	var force: Vector2 = drag_vector * power_multiplier

	# Аркадная коррекция траектории
	force.y *= 1.1
	force.x *= 0.95

	# Ограничение силы
	if force.length() > max_force:
		force = force.normalized() * max_force

	# Сброс старой скорости
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

	# Правильный метод для Godot 4
	apply_central_impulse(force)


func _physics_process(_delta: float) -> void:
	# Ограничение максимальной скорости
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

	# Ограничение вращения
	angular_velocity = clamp(angular_velocity, -1000.0, 1000.0)
