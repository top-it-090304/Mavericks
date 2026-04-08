extends Node2D

const RING_SPACING_MIN = 200
const RING_SPACING_MAX = 320
const RING_SCENE = preload("res://Scenes/Ring/Ring.tscn")

const LEFT_X_MIN = 80
const LEFT_X_MAX = 180
const RIGHT_X_MIN = 360
const RIGHT_X_MAX = 460

const START_BALL_POS = Vector2(170, 680)
const START_RING_POS = Vector2(170, 680)

# ── Каталоги косметики ───────────────────────────────────────────
const BALL_TEXTURES := {
	"default": "res://assets/Balls/NewBall2.png",
	"ball1":   "res://assets/Balls/ball1.png",
	"ball2":   "res://assets/Balls/ball2.png",
	"ball3":   "res://assets/Balls/ball3.png",
	"ball4":   "res://assets/Balls/ball4.png",
	"ball5":   "res://assets/Balls/ball5.png",
	"ball6":   "res://assets/Balls/ball6.png",
	"ball7":   "res://assets/Balls/ball7.png",
	"ball8":     "res://assets/Balls/ball8.png",
	"ball9":     "res://assets/Balls/ball9.png",
	"ball10":    "res://assets/Balls/ball10.png",
	"ball11":    "res://assets/Balls/ball11.png",
	"cosmoball": "res://assets/Balls/CosmoBall.png",
	"discoball": "res://assets/Balls/DiscoBall.png",
	"earthball": "res://assets/Balls/EarthBall.png",
}
const DARK_BG_IDS    := ["cosmos", "arena", "marvel", "nightcourt", "rocket", "soprano"]
const ICON_BTN_NAMES := ["SettingsBtn", "PauseBtn", "Button", "BackBtn"]

const BG_TEXTURES := {
	"default":    "res://assets/Fones/FonMain.png",
	"fon2":       "res://assets/Fones/Fon2.jpg",
	"fon3":       "res://assets/Fones/Fon3.jpg",
	"fon4":       "res://assets/Fones/Fon4.jpg",
	"fon5":       "res://assets/Fones/Fon5.jpg",
	"fon6":       "res://assets/Fones/Fon6.jpg",
	"arena":      "res://assets/Fones/Arena.jpeg",
	"cosmos":     "res://assets/Fones/Cosmos.jpeg",
	"mountains":  "res://assets/Fones/Mountains.jpeg",
	"nightcourt": "res://assets/Fones/NightCourt.jpeg",
	"snow":       "res://assets/Fones/Snow.jpeg",
	"street":     "res://assets/Fones/Street.jpeg",
	"soprano":    "res://assets/Fones/Soprano.jpeg",
	"marvel":     "res://assets/Fones/Marvel.jpeg",
	"rocket":     "res://assets/Fones/Rocket.jpeg",
}

var _theme_labels:             Array      = []
var _label_original_colors:    Dictionary = {}
var _theme_buttons:            Array      = []
var _button_original_modulates: Dictionary = {}

var _soundtrack: AudioStreamPlayer
var _swish: AudioStreamPlayer
var _hits: Array = []
var _hit_index: int = 0

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
var _combo5_reached: bool = false
var _goals_this_game: int = 0

@onready var death_zone: Area2D = $Game_world/Camera2D/DeathZone
@onready var ball: RigidBody2D      = $Game_world/Ball/Ball
@onready var ball_sprite: Sprite2D  = $Game_world/Ball/Ball/ball_sprite
@onready var _ball_trail            = $Game_world/Ball/BallTrail
@onready var fon: Sprite2D          = $Game_world/Camera2D/Fon
@onready var camera: Camera2D       = $Game_world/Camera2D
@onready var ring_pool_node: Node2D = $Game_world/RingPool
@onready var hud = $UI/HUD
@onready var main_menu = $UI/MainMenu
@onready var settings_screen = $UI/SettingsScreen
@onready var game_over_popup = $UI/GameOverPopup
@onready var store_screen = $UI/StoreScreen
@onready var challenges_screen = $UI/ChallengesScreen
@onready var pause_screen = $UI/PauseScreen
# Панели-фоны UI-экранов, которые должны меняться вместе с фоном игры
@onready var _ui_panels: Array = [
	$UI/SettingsScreen/Panel,
	$UI/ChallengesScreen/Panel,
]

enum GameState { MENU, PLAYING, GAME_OVER }
var state = GameState.MENU

func _ready() -> void:
	if OS.is_debug_build():
		process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio()
	_build_pool()
	_setup_rings()
	camera_target_y = camera.global_position.y

	ball.first_interaction.connect(_on_first_interaction)
	ball.ball_stuck.connect(_trigger_game_over)
	ball.rim_hit.connect(_on_rim_hit)
	ball.ball_shot.connect(_on_ball_shot)
	ball.max_force_shot.connect(Global.notifyMaxForceShot)
	ball.process_mode = Node.PROCESS_MODE_ALWAYS

	death_zone.body_entered.connect(_on_death_zone_entered)

	main_menu.open_settings.connect(func(): _switch_screen("SettingsScreen"))
	main_menu.open_shop.connect(func(): _switch_screen("StoreScreen"))
	main_menu.open_quests.connect(func(): _switch_screen("ChallengesScreen"))
	settings_screen.back.connect(func(): _switch_screen("MainMenu"))
	store_screen.back.connect(func(): _switch_screen("MainMenu"))
	challenges_screen.back.connect(func(): _switch_screen("MainMenu"))
	game_over_popup.restart.connect(_on_restart)
	game_over_popup.continue_game.connect(_on_continue)
	game_over_popup.go_home.connect(_on_go_home)
	hud.pause_pressed.connect(_on_pause_pressed)
	pause_screen.resume.connect(_on_pause_resume)
	pause_screen.go_home.connect(_on_pause_go_home)

	_show_only(main_menu)
	hud.hide()
	game_over_popup.hide()
	pause_screen.hide()

	Global.volumes_changed.connect(_apply_volumes)

	_collect_theme_labels()
	Global.cosmetics_changed.connect(_apply_cosmetics)
	_apply_cosmetics()
	state = GameState.MENU
	get_tree().paused = true

# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------

func _setup_audio() -> void:
	_soundtrack = AudioStreamPlayer.new()
	var st := load("res://assets/sounds/soundtrack.ogg") as AudioStreamOggVorbis
	st.loop = true
	_soundtrack.stream = st
	_soundtrack.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_soundtrack)

	_swish = AudioStreamPlayer.new()
	_swish.stream = load("res://assets/sounds/swish.ogg")
	_swish.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_swish)

	for i in range(1, 4):
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/sounds/hit%d.ogg" % i)
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_hits.append(p)

	_apply_volumes()
	_soundtrack.play()

func _apply_volumes() -> void:
	_soundtrack.volume_db = linear_to_db(Global.music_volume)
	_swish.volume_db = linear_to_db(Global.sfx_volume)
	for p: AudioStreamPlayer in _hits:
		p.volume_db = linear_to_db(Global.sfx_volume)

# ---------------------------------------------------------------------------
# Screen helpers
# ---------------------------------------------------------------------------

func _show_only(target: Control) -> void:
	for s in [main_menu, settings_screen, store_screen, challenges_screen]:
		s.hide()
	target.show()

func _switch_screen(screen_name: String) -> void:
	_show_only(get_node("UI/" + screen_name))
	ball.set_process_input(screen_name == "MainMenu")

func _apply_cosmetics() -> void:
	# ── Мяч: меняем текстуру, нормализуем размер под коллизию ──────
	var ball_path: String = BALL_TEXTURES.get(Global.equipped_ball, BALL_TEXTURES["default"])
	var ball_tex := load(ball_path) as Texture2D
	ball_sprite.texture = ball_tex
	_ball_trail.set_trail_color_from_texture(ball_tex)
	# Диаметр коллизии = 2 * 33.0151 ≈ 66 пикселей
	const DIAM := 66.0
	var sz := ball_tex.get_size()
	ball_sprite.scale    = Vector2(DIAM / sz.x, DIAM / sz.y)
	# centered=false → сдвигаем origin так, чтобы центр спрайта совпал с центром тела
	ball_sprite.position = Vector2(-DIAM / 2.0, -DIAM / 2.0 - 1.0)

	# ── Фон: применяем к игровому миру и всем UI-экранам ────────────
	var bg_path: String = BG_TEXTURES.get(Global.equipped_bg, BG_TEXTURES["default"])
	var bg_tex := load(bg_path) as Texture2D
	fon.texture = bg_tex
	for ui_panel in _ui_panels:
		ui_panel.texture = bg_tex

	# ── Цвет текста и иконок: светлый для тёмных фонов ──────────
	var use_light := Global.equipped_bg in DARK_BG_IDS
	for lbl in _theme_labels:
		if use_light:
			lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			var orig = _label_original_colors.get(lbl)
			if orig != null:
				lbl.add_theme_color_override("font_color", orig)
			else:
				lbl.remove_theme_color_override("font_color")
	for btn in _theme_buttons:
		btn.modulate = Color(6.0, 6.0, 6.0, 1.0) if use_light \
			else _button_original_modulates.get(btn, Color(1.0, 1.0, 1.0, 1.0))

# ---------------------------------------------------------------------------
# Label theme helpers
# ---------------------------------------------------------------------------

func _collect_theme_labels() -> void:
	_theme_labels.clear()
	_label_original_colors.clear()
	_theme_buttons.clear()
	_button_original_modulates.clear()
	_collect_ui_recursive($UI)
	for lbl in _theme_labels:
		if lbl.has_theme_color_override("font_color"):
			_label_original_colors[lbl] = lbl.get_theme_color("font_color")
		else:
			_label_original_colors[lbl] = null


func _collect_ui_recursive(node: Node) -> void:
	if node is Label and node.name != "WLabel" and not node.is_in_group("dark_text"):
		_theme_labels.append(node)
	elif node is Button and node.name in ICON_BTN_NAMES:
		_theme_buttons.append(node)
		_button_original_modulates[node] = node.modulate
	for child in node.get_children():
		_collect_ui_recursive(child)


# ---------------------------------------------------------------------------
# Game state transitions
# ---------------------------------------------------------------------------

func _on_first_interaction() -> void:
	if state != GameState.MENU:
		return
	state = GameState.PLAYING
	main_menu.hide()
	hud.update_score(0)
	hud.update_stars(Global.stars)
	hud.update_hearts(Global.hearts)
	hud.show()
	get_tree().paused = false

func _trigger_game_over() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.GAME_OVER
	Global.update_best_score(score)
	hud.hide()
	game_over_popup.show_popup(score, Global.best_score)
	get_tree().paused = true

func _on_restart() -> void:
	if state != GameState.GAME_OVER:
		return
	Global.notifyRestartAfterLoss()
	state = GameState.PLAYING
	game_over_popup.hide()
	_reset_run()
	hud.update_score(0)
	hud.update_stars(Global.stars)
	hud.update_hearts(Global.hearts)
	hud.show()
	get_tree().paused = false

func _on_continue() -> void:
	if state != GameState.GAME_OVER:
		return
	if not Global.use_heart():
		return
	state = GameState.PLAYING
	game_over_popup.hide()
	hud.update_hearts(Global.hearts)
	hud.show()
	ball.global_position = launch_ring.global_position
	ball.rotation = 0.0
	ball.linear_velocity = Vector2.ZERO
	ball.angular_velocity = 0
	ball.freeze = true
	ball.enable_shoot()
	_assign_ball_to_ring(launch_ring)
	get_tree().paused = false

func _on_go_home() -> void:
	if state != GameState.GAME_OVER:
		return
	state = GameState.MENU
	game_over_popup.hide()
	hud.hide()
	_reset_run()
	main_menu.update_data()
	_show_only(main_menu)
	get_tree().paused = true

func _on_pause_pressed() -> void:
	if state != GameState.PLAYING:
		return
	pause_screen.show()
	get_tree().paused = true

func _on_pause_resume() -> void:
	pause_screen.hide()
	get_tree().paused = false

func _on_pause_go_home() -> void:
	pause_screen.hide()
	state = GameState.MENU
	hud.hide()
	_reset_run()
	main_menu.update_data()
	_show_only(main_menu)
	get_tree().paused = true

func _on_death_zone_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		_trigger_game_over()

# ---------------------------------------------------------------------------
# Ring pool
# ---------------------------------------------------------------------------

func _build_pool() -> void:
	for i in 4:
		var ring = RING_SCENE.instantiate() as Ring
		ring_pool_node.add_child(ring)
		ring.star_collected.connect(_on_star_collected)
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
	start_ring.visible = false
	start_ring.get_node("GoalZone").set_deferred("monitoring", false)

	ball.global_position = START_BALL_POS
	ball.rotation = 0.0

	launch_ring.position = START_RING_POS
	launch_ring.visible = true
	launch_ring.set_physics_enabled(true)
	launch_ring.get_node("GoalZone").set_deferred("monitoring", true)
	if not launch_ring.goal_scored.is_connected(_on_launch_ring_goal):
		launch_ring.goal_scored.connect(_on_launch_ring_goal)

	_assign_ball_to_ring(launch_ring)

	active_ring = next_ring
	active_ring.position = Vector2(390, 490)
	active_ring.visible = true
	active_ring.set_physics_enabled(true)
	active_ring.goal_scored.connect(_on_goal_scored)

	next_ring = hidden_ring
	_next_side = 0
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
	active_ring.try_spawn_stars()
	next_ring.try_spawn_stars()
	hidden_ring.try_spawn_stars()

# ---------------------------------------------------------------------------
# Ball / ring callbacks
# ---------------------------------------------------------------------------

func _on_rim_hit() -> void:
	_clean_shot = false
	Global.notifyRimHit()
	_hits[_hit_index].play()
	_hit_index = (_hit_index + 1) % 3

func _on_ball_shot() -> void:
	if ball.current_ring:
		ball.current_ring.animate_net_return()

func _assign_ball_to_ring(ring: Ring) -> void:
	ball.ring_center = ring.global_position
	ball.current_ring = ring

func _on_goal_scored() -> void:
	if state != GameState.PLAYING:
		return
	_swish.play()
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
		_goals_this_game += 1
		Global.notifyGoalScored(_goals_this_game)
		var points = 1
		if _clean_shot:
			combo += 1
			points += combo
			_spawn_combo_label(active_ring.global_position, points, combo)
			Global.notifyCleanShot(combo)
			if combo >= 5 and not _combo5_reached:
				_combo5_reached = true
				Global.notifyComboFiveGame()
		else:
			combo = 0
		score += points
		hud.update_score(score)
		_ball_trail.set_combo(combo)
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
	hidden_ring.try_spawn_stars()

	_assign_ball_to_ring(launch_ring)
	ball.enable_shoot()

func _on_star_collected(amount: int, worldPos: Vector2) -> void:
	Global.add_stars(amount)
	hud.update_stars(Global.stars)
	var screenPos = get_viewport().get_canvas_transform() * worldPos
	hud.animate_star_fly(screenPos)

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

# ---------------------------------------------------------------------------
# Debug
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey and event.keycode == KEY_RIGHT and event.pressed and not event.echo:
		Global.add_stars(500)
		hud.update_stars(Global.stars)
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.keycode == KEY_C and event.pressed and not event.echo:
		combo += 1
		_ball_trail.set_combo(combo)
		_spawn_combo_label(ball.global_position + Vector2(0, -60), 1 + combo, combo)
		get_viewport().set_input_as_handled()

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

# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	var target = active_ring.global_position.y - 350
	if target < camera_target_y:
		camera_target_y = target
	camera.global_position.y = lerp(camera.global_position.y, camera_target_y, 8.0 * delta)

# ---------------------------------------------------------------------------
# Visual helpers
# ---------------------------------------------------------------------------

func _flash_ring(ring: Ring) -> void:
	var sprite = ring.get_node("RimFront") as Sprite2D
	sprite.modulate = Color(1.6, 1.6, 1.6, 1.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.25).set_ease(Tween.EASE_OUT)

func _spawn_combo_label(pos: Vector2, points: int, combo: int) -> void:
	var label := Label.new()
	label.text = "+%d" % points
	label.add_theme_color_override("font_color", Color(1, 0.5, 0.1))
	label.add_theme_font_size_override("font_size", 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(120, 70)
	label.pivot_offset = Vector2(60, 35)
	label.global_position = pos + Vector2(-60, -110)
	$Game_world.add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 80.0, 1.0)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.25)
	tween.finished.connect(label.queue_free)

	# ×5: свечение — яркий modulate + упругий bounce масштаба
	if combo >= 5:
		label.modulate = Color(2.0, 1.4, 0.6, 1.0)
		label.scale = Vector2(1.35, 1.35)
		var scale_tween = create_tween()
		scale_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.4)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# ×7: взрыв частиц вокруг текста
	if combo >= 7:
		var p := CPUParticles2D.new()
		p.global_position = pos + Vector2(0, -80)
		p.emitting = true
		p.one_shot = true
		p.amount = 30
		p.lifetime = 0.8
		p.explosiveness = 1.0
		p.direction = Vector2(0, -1)
		p.spread = 180.0
		p.initial_velocity_min = 80.0
		p.initial_velocity_max = 220.0
		p.gravity = Vector2(0, 200)
		p.scale_amount_min = 3.0
		p.scale_amount_max = 6.0
		p.color = Color(1, 0.5, 0.1)
		$Game_world.add_child(p)
		get_tree().create_timer(1.0).timeout.connect(p.queue_free)

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

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------

func _reset_run() -> void:
	score = 0
	combo = 0
	_ball_trail.set_combo(0)
	_clean_shot = true
	_is_first_ring = true
	_combo5_reached = false
	_goals_this_game = 0
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
