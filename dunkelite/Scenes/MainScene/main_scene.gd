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
var _next_side: int = 1
var _is_first_ring: bool = true
var camera_target_y: float = 0.0

@onready var death_zone: Area2D = $Game_world/Camera2D/DeathZone
@onready var ball: RigidBody2D      = $Game_world/Ball/Ball
@onready var score_label: Label     = $UI/ScoreLabel
@onready var camera: Camera2D       = $Game_world/Camera2D
@onready var ring_pool_node: Node2D = $Game_world/RingPool
@onready var menu = $UI/Menu

func _ready() -> void:
	score_label.text = "0"
	
	_build_pool()
	_setup_rings()
	
	camera_target_y = camera.global_position.y
	
	ball.first_interaction.connect(_on_first_interaction)
	ball.process_mode = Node.PROCESS_MODE_ALWAYS
	
	death_zone.body_entered.connect(_on_death_zone_entered)
	menu.start_game.connect(_start_game)

	# загрузка рекорда
	best_score = _load_best_score()
	menu.update_best_score(best_score)

	# стартовое состояние
	state = GameState.MENU
	get_tree().paused = true

func _on_death_zone_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		_trigger_game_over()

func _trigger_game_over() -> void:
	if state != GameState.PLAYING:
		return

	state = GameState.GAME_OVER
	
	print("Game Over! Score: ", score)

	# сохраняем рекорд
	_save_best_score()

	menu.update_best_score(best_score)
	menu.show()

	get_tree().paused = true
	
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
	# Стартовое кольцо — мяч внутри, GoalZone выключен
	var start_ring = active_ring
	start_ring.position = Vector2(ball.global_position.x, ball.global_position.y)
	start_ring.visible = true
	start_ring.get_node("GoalZone").set_deferred("monitoring", false)
	ball.global_position = start_ring.global_position

	# launch_ring на позиции мяча (для возврата при промахе)
	launch_ring.position = start_ring.global_position
	launch_ring.visible = true
	launch_ring.get_node("GoalZone").set_deferred("monitoring", true)
	if not launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
		launch_ring.goal_scored.connect(_on_launch_ring_goal)

	# active_ring = первая цель для броска
	active_ring = next_ring
	active_ring.position = Vector2(
		_get_next_x(),
		start_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	active_ring.visible = true
	active_ring.goal_scored.connect(_on_goal_scored)

	# next_ring = вторая цель
	next_ring = hidden_ring
	next_ring.position = Vector2(
		_get_next_x(),
		active_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	next_ring.visible = true

	# hidden_ring = стартовое кольцо, переиспользуем
	hidden_ring = start_ring
	hidden_ring.get_node("GoalZone").set_deferred("monitoring", true)
	hidden_ring.position = Vector2(
		_get_next_x(),
		next_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	hidden_ring.visible = false

	_is_first_ring = false
func _on_goal_scored() -> void:
	if state != GameState.PLAYING:
		return
	if launch_ring and launch_ring.visible:
		launch_ring.visible = false
		launch_ring.get_node("GoalZone").set_deferred("monitoring", false)
		if launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
			launch_ring.goal_scored.disconnect(_on_launch_ring_goal)

	ball.on_goal()
	active_ring.get_node("GoalZone").set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(
		ball, "global_position", active_ring.global_position, 0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	
	if not _is_first_ring:
		score += 1
		score_label.text = str(score)
	_is_first_ring = false

	
	launch_ring.position = active_ring.global_position
	launch_ring.visible = true
	launch_ring.get_node("GoalZone").set_deferred("monitoring", true)
	if not launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
		launch_ring.goal_scored.connect(_on_launch_ring_goal)

	
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
	hidden_ring.position = Vector2(
		_get_next_x(),
		next_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	hidden_ring.visible = false

	ball.enable_shoot()

func _on_launch_ring_goal() -> void:
	ball.on_goal()
	launch_ring.get_node("GoalZone").set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(
		ball, "global_position", launch_ring.global_position, 0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	
	ball.enable_shoot()
	launch_ring.reset()  
	launch_ring.get_node("GoalZone").set_deferred("monitoring", true)


func _physics_process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
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

enum GameState {
	MENU,
	PLAYING,
	GAME_OVER
}

var state = GameState.MENU
var best_score: int = 0

func _start_game() -> void:
	if state == GameState.PLAYING:
		return

	state = GameState.PLAYING
	
	menu.hide()
	get_tree().paused = false
	
	_reset_run()
	
func _reset_run() -> void:
	score = 0
	score_label.text = "0"

	_is_first_ring = true
	_next_side = 1
	ball.has_started = false
	ball.can_shoot = true

	# сброс мяча
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0
	ball.freeze = true

	# вернуть камеру
	camera.global_position.y = 0
	camera_target_y = camera.global_position.y

	# отключить сигналы перед пересозданием
	if active_ring.goal_scored.is_connected(_on_goal_scored):
		active_ring.goal_scored.disconnect(_on_goal_scored)
	if launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
		launch_ring.goal_scored.disconnect(_on_launch_ring_goal)

	# пересоздать кольца
	for ring in ring_pool_node.get_children():
		ring.reset()
		ring.visible = false

	# вернуть исходный порядок пула
	var children = ring_pool_node.get_children()
	active_ring = children[0]
	next_ring = children[1]
	hidden_ring = children[2]
	launch_ring = children[3]
	launch_ring.visible = false

	_setup_rings()
	
func _save_best_score() -> void:
	if score > best_score:
		best_score = score
	
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_var(best_score)


func _load_best_score() -> int:
	if not FileAccess.file_exists("user://save.dat"):
		return 0
	
	var file = FileAccess.open("user://save.dat", FileAccess.READ)
	return file.get_var()

func _on_first_interaction():
	if state != GameState.MENU:
		return
	
	state = GameState.PLAYING
	
	menu.hide()
	get_tree().paused = false
