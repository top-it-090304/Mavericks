extends Node2D

const RING_SPACING_MIN = 200
const RING_SPACING_MAX = 320
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
var combo: int = 0
var _clean_shot: bool = true

@onready var death_zone: Area2D = $Game_world/Camera2D/DeathZone
@onready var ball: RigidBody2D      = $Game_world/Ball/Ball
@onready var score_label: Label     = $UI/ScoreLabel
@onready var camera: Camera2D       = $Game_world/Camera2D
@onready var ring_pool_node: Node2D = $Game_world/RingPool
@onready var menu = $UI/Menu
@onready var combo_label: Label = $UI/ComboLabel


func _ready() -> void:
	score_label.text = "0"
	score_label.visible = false

	_build_pool()
	_setup_rings()

	camera_target_y = camera.global_position.y

	ball.first_interaction.connect(_on_first_interaction)
	ball.ball_stuck.connect(_trigger_game_over)
	ball.rim_hit.connect(_on_rim_hit)
	ball.ball_shot.connect(_on_ball_shot)
	ball.process_mode = Node.PROCESS_MODE_ALWAYS

	death_zone.body_entered.connect(_on_death_zone_entered)
	menu.start_game.connect(_start_game)

	best_score = _load_best_score()
	menu.update_best_score(best_score)

	state = GameState.MENU
	get_tree().paused = true

func _on_death_zone_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		_trigger_game_over()

func _trigger_game_over() -> void:
	if state != GameState.PLAYING:
		return
	_save_best_score()
	get_tree().paused = false
	get_tree().call_deferred("reload_current_scene")

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
	var start_ring = active_ring
	start_ring.position = Vector2(ball.global_position.x, ball.global_position.y)
	start_ring.visible = true
	start_ring.get_node("GoalZone").set_deferred("monitoring", false)
	ball.global_position = start_ring.global_position

	launch_ring.position = start_ring.global_position
	launch_ring.visible = true
	launch_ring.set_physics_enabled(true)
	launch_ring.get_node("GoalZone").set_deferred("monitoring", true)
	if not launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
		launch_ring.goal_scored.connect(_on_launch_ring_goal)

	_assign_ball_to_ring(launch_ring)

	active_ring = next_ring
	active_ring.position = Vector2(
		_get_next_x(),
		start_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	active_ring.visible = true
	active_ring.set_physics_enabled(true)
	active_ring.goal_scored.connect(_on_goal_scored)

	next_ring = hidden_ring
	next_ring.position = Vector2(
		_get_next_x(),
		active_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	next_ring.visible = false
	next_ring.set_physics_enabled(false)

	hidden_ring = start_ring
	hidden_ring.get_node("GoalZone").set_deferred("monitoring", true)
	hidden_ring.position = Vector2(
		_get_next_x(),
		next_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	hidden_ring.visible = false
	hidden_ring.set_physics_enabled(false)

	_is_first_ring = false

func _on_rim_hit() -> void:
	_clean_shot = false

func _on_ball_shot() -> void:
	if ball.current_ring:
		ball.current_ring.animate_net_return()

func _assign_ball_to_ring(ring: Ring) -> void:
	ball.ring_center = ring.global_position
	ball.current_ring = ring

func _on_goal_scored() -> void:
	if state != GameState.PLAYING:
		return
	if launch_ring and launch_ring.visible:
		launch_ring.visible = false
		launch_ring.set_physics_enabled(false)
		launch_ring.get_node("GoalZone").set_deferred("monitoring", false)
		if launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
			launch_ring.goal_scored.disconnect(_on_launch_ring_goal)

	ball.on_goal()
	active_ring.get_node("GoalZone").set_deferred("monitoring", false)
	_spawn_goal_particles(active_ring.global_position)
	_flash_ring(active_ring)
	var tween = create_tween()
	tween.tween_property(
		ball, "global_position", active_ring.global_position, 0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	if not _is_first_ring:
		var points = 1
		if _clean_shot:
			combo += 1
			points += combo
			_show_combo(points)
		else:
			combo = 0
			combo_label.visible = false
		score += points
		score_label.text = str(score)
	_is_first_ring = false
	_clean_shot = true

	launch_ring.position = active_ring.global_position
	launch_ring.reset()
	launch_ring.mark_scored()
	launch_ring.visible = true
	launch_ring.set_physics_enabled(true)
	launch_ring.get_node("GoalZone").set_deferred("monitoring", true)
	if not launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
		launch_ring.goal_scored.connect(_on_launch_ring_goal)

	active_ring.goal_scored.disconnect(_on_goal_scored)
	active_ring.visible = false
	active_ring.set_physics_enabled(false)
	active_ring.reset()
	active_ring.get_node("GoalZone").set_deferred("monitoring", true)

	var old_active = active_ring
	active_ring = next_ring
	active_ring.visible = true
	active_ring.set_physics_enabled(true)
	active_ring.goal_scored.connect(_on_goal_scored)
	next_ring = hidden_ring
	next_ring.visible = false
	next_ring.set_physics_enabled(false)
	hidden_ring = old_active
	hidden_ring.position = Vector2(
		_get_next_x(),
		next_ring.position.y - randf_range(RING_SPACING_MIN, RING_SPACING_MAX)
	)
	hidden_ring.visible = false
	hidden_ring.set_physics_enabled(false)

	_assign_ball_to_ring(launch_ring)
	ball.enable_shoot()

func _on_launch_ring_goal() -> void:
	ball.on_goal()
	launch_ring.get_node("GoalZone").set_deferred("monitoring", false)

	var tween = create_tween()
	tween.tween_property(
		ball, "global_position", launch_ring.global_position, 0.2
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	_assign_ball_to_ring(launch_ring)
	ball.enable_shoot()
	launch_ring._goal_allowed = true
	launch_ring.get_node("GoalZone").set_deferred("monitoring", true)
	_clean_shot = true


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("ui_up"):
		var jump = -3000.0
		ball.global_position.y += jump
		active_ring.position.y += jump
		next_ring.position.y += jump
		hidden_ring.position.y += jump
		launch_ring.position.y += jump
		camera_target_y += jump
		camera.global_position.y += jump

func _physics_process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	var target = active_ring.global_position.y - 350
	if target < camera_target_y:
		camera_target_y = target
	camera.global_position.y = lerp(camera.global_position.y, camera_target_y, 8.0 * delta)

func _show_combo(points: int) -> void:
	combo_label.text = "+%d" % points
	combo_label.visible = true
	combo_label.modulate = Color(1, 1, 1, 1)
	var t = create_tween()
	t.tween_property(combo_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	t.tween_callback(func(): combo_label.visible = false)

func _flash_ring(ring: Ring) -> void:
	var sprite = ring.get_node("RimFront") as Sprite2D
	sprite.modulate = Color(1.6, 1.6, 1.6, 1.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.25).set_ease(Tween.EASE_OUT)

func _spawn_goal_particles(pos: Vector2) -> void:
	var p = CPUParticles2D.new()
	p.global_position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = 45
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 450.0
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color(1, 0.8, 0.2)
	$Game_world.add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

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

	_reset_run()

	state = GameState.MENU
	menu.hide()
	get_tree().paused = false

func _reset_run() -> void:
	score = 0
	score_label.text = "0"

	_is_first_ring = true
	_next_side = 1
	ball.has_started = false
	ball.can_shoot = true

	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0
	ball.freeze = true

	camera.global_position.y = 0
	camera_target_y = camera.global_position.y

	if active_ring.goal_scored.is_connected(_on_goal_scored):
		active_ring.goal_scored.disconnect(_on_goal_scored)
	if launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
		launch_ring.goal_scored.disconnect(_on_launch_ring_goal)

	for ring in ring_pool_node.get_children():
		ring.reset()
		ring.visible = false
		ring.set_physics_enabled(false)

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
	score_label.visible = true

	menu.hide()
	get_tree().paused = false
