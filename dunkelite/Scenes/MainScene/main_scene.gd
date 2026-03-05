extends Node2D

const POOL_SIZE = 2
const RING_SPACING_MIN = 300
const RING_SPACING_MAX = 420
const RING_SCENE = preload("res://Scenes/Ring/Ring.tscn")

const LEFT_X_MIN  = 80
const LEFT_X_MAX  = 180
const RIGHT_X_MIN = 360
const RIGHT_X_MAX = 460

var score: int = 0
var active_ring: Ring
var next_ring: Ring
var _next_side: int = 0

@onready var ball: RigidBody2D      = $Game_world/Ball/Ball
@onready var score_label: Label     = $UI/ScoreLabel
@onready var camera: Camera2D       = $Game_world/Camera2D
@onready var ring_pool_node: Node2D = $Game_world/RingPool

func _ready() -> void:
	score_label.text = "0" 
	_build_pool()
	_setup_rings()

func _build_pool() -> void:
	for i in POOL_SIZE:
		var ring = RING_SCENE.instantiate() as Ring
		ring_pool_node.add_child(ring)
		if i == 0:
			active_ring = ring
		else:
			next_ring = ring

func _setup_rings() -> void:
	active_ring.position = Vector2(
		ball.global_position.x,
		ball.global_position.y + 150
	)
	active_ring.goal_scored.connect(_on_goal_scored)

	next_ring.position = Vector2(
		_get_next_x(),
		active_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)

func _on_goal_scored() -> void:
	ball.on_goal()

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

	active_ring.goal_scored.disconnect(_on_goal_scored)
	var old_active = active_ring

	active_ring = next_ring
	active_ring.goal_scored.connect(_on_goal_scored)

	old_active.reset()
	old_active.position = Vector2(
		_get_next_x(),
		active_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	next_ring = old_active

	ball.enable_shoot()

func _physics_process(_delta: float) -> void:
	if ball.global_position.y < camera.global_position.y:
		camera.global_position.y = ball.global_position.y

func _get_next_x() -> float:
	_next_side = 1 - _next_side
	if _next_side == 0:
		return randf_range(RIGHT_X_MIN, RIGHT_X_MAX)
	else:
		return randf_range(LEFT_X_MIN, LEFT_X_MAX)
