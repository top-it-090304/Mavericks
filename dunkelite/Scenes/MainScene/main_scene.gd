extends Node2D

const RING_SPACING_MIN = 300
const RING_SPACING_MAX = 420
const RING_SCENE = preload("res://Scenes/Ring/Ring.tscn")

const LEFT_X_MIN = 80
const LEFT_X_MAX = 180
const RIGHT_X_MIN = 360
const RIGHT_X_MAX = 460

var score: int = 0
var active_ring: Ring
var next_ring: Ring
var hidden_ring: Ring
var launch_ring: Ring
var _next_side: int = 0
var _is_first_ring: bool = true
var camera_target_y: float = 0.0

@onready var ball: RigidBody2D      = $Game_world/Ball/Ball
@onready var score_label: Label     = $UI/ScoreLabel
@onready var camera: Camera2D       = $Game_world/Camera2D
@onready var ring_pool_node: Node2D = $Game_world/RingPool

func _ready() -> void:
	score_label.text = "0"
	_build_pool()
	_setup_rings()
	camera_target_y = camera.global_position.y

func _build_pool() -> void:
	for i in 4:
		var ring = RING_SCENE.instantiate() as Ring
		ring_pool_node.add_child(ring)
		if i == 0:
			active_ring = ring
		elif i == 1:
			next_ring = ring
		elif i == 2:
			hidden_ring = ring
		else:
			launch_ring = ring
			launch_ring.visible = false

func _setup_rings() -> void:
	active_ring.position = Vector2(
		ball.global_position.x,
		ball.global_position.y + 150
	)
	active_ring.visible = true
	active_ring.goal_scored.connect(_on_goal_scored)

	next_ring.position = Vector2(
		_get_next_x(),
		active_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	next_ring.visible = true

	hidden_ring.position = Vector2(
		_get_next_x(),
		next_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	hidden_ring.visible = false
func _on_goal_scored() -> void:
	if launch_ring and launch_ring.visible:
		launch_ring.visible = false

	if _is_first_ring:
		_is_first_ring = false
		active_ring.goal_scored.disconnect(_on_goal_scored)
		active_ring.visible = false
		active_ring.reset()
		var temp_ring = active_ring
		active_ring = next_ring
		active_ring.goal_scored.connect(_on_goal_scored)
		next_ring = hidden_ring
		next_ring.visible = true
		hidden_ring = temp_ring
		hidden_ring.position = Vector2(
			_get_next_x(),
			next_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
		)
		ball.enable_shoot()
		return

	ball.on_goal()
	active_ring.get_node("GoalZone").set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(
		ball,
		"global_position",
		active_ring.global_position,
		0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	await tween.finished

	score += 1
	score_label.text = str(score)

	# launch_ring показываем на месте active_ring — он отдельный, в пул не входит
	launch_ring.position = active_ring.global_position
	launch_ring.visible = true

	active_ring.goal_scored.disconnect(_on_goal_scored)
	active_ring.visible = false
	active_ring.reset()
	active_ring.get_node("GoalZone").set_deferred("monitoring", true)

	var old_active = active_ring
	active_ring = next_ring
	active_ring.goal_scored.connect(_on_goal_scored)
	next_ring = hidden_ring
	next_ring.visible = true
	hidden_ring = old_active
	# hidden_ring уходит на следующую позицию — launch_ring не трогаем
	hidden_ring.position = Vector2(
		_get_next_x(),
		next_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	hidden_ring.visible = false

	ball.enable_shoot()



func _physics_process(delta: float) -> void:
	var target = active_ring.global_position.y - 350
	if target < camera_target_y:
		camera_target_y = target
	camera.global_position.y = lerp(camera.global_position.y, camera_target_y, 8.0 * delta)
	
func _get_next_x() -> float:
	_next_side = 1 - _next_side
	if _next_side == 0:
		return randf_range(RIGHT_X_MIN, RIGHT_X_MAX)
	else:
		return randf_range(LEFT_X_MIN, LEFT_X_MAX)
