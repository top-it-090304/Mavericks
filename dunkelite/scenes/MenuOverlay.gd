extends CanvasLayer

signal play_pressed
signal shop_pressed
signal settings_pressed
signal rank_pressed

@onready var title_texture = $TitleTexture
@onready var panel = $Panel
@onready var play_btn = $Panel/VBoxContainer/PlayButton
@onready var shop_btn = $Panel/VBoxContainer/ShopButton
@onready var settings_btn = $Panel/VBoxContainer/SettingsButton
@onready var rank_btn = $Panel/VBoxContainer/RankButton

func _ready():
	# Подключаем кнопки
	play_btn.pressed.connect(_on_play_pressed)
	shop_btn.pressed.connect(_on_shop_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	rank_btn.pressed.connect(_on_rank_pressed)
	
	# Настраиваем текст на кнопках из GameManager
	#_update_button_texts()
	#GameManager.language_changed.connect(_update_button_texts)
	
	# Анимация появления
	_animate_in()
	
	# Добавляем в группу
	add_to_group("main_menu")

#func _update_button_texts():
	#play_btn.text = GameManager.get_text("play")
	#shop_btn.text = GameManager.get_text("shop")
	#settings_btn.text = GameManager.get_text("settings")
	#rank_btn.text = GameManager.get_text("rank")

func _animate_in():
	# Начальное состояние
	#modulate = Color(1, 1, 1, 0)
	title_texture.modulate = Color(1, 1, 1, 0)
	panel.modulate = Color(1, 1, 1, 0)
	
	# Анимация появления
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Появление текстуры (чуть раньше)
	tween.tween_property(title_texture, "modulate", Color(1, 1, 1, 1), 0.4)
	
	# Появление панели (чуть позже)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0.9), 0.5)
	
	# Небольшое движение сверху
	title_texture.position.y -= 20
	panel.position.y += 20
	
	tween.tween_property(title_texture, "position:y", title_texture.position.y + 20, 0.5)
	tween.tween_property(panel, "position:y", panel.position.y - 20, 0.5)

func _on_play_pressed():
	_animate_button(play_btn)
	await get_tree().create_timer(0.2).timeout
	play_pressed.emit()

func _on_shop_pressed():
	_animate_button(shop_btn)
	await get_tree().create_timer(0.2).timeout
	shop_pressed.emit()

func _on_settings_pressed():
	_animate_button(settings_btn)
	await get_tree().create_timer(0.2).timeout
	settings_pressed.emit()

func _on_rank_pressed():
	_animate_button(rank_btn)
	await get_tree().create_timer(0.2).timeout
	rank_pressed.emit()

func _animate_button(btn):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(btn, "scale", Vector2(1, 1), 0.1)

func _setup_hover_effects():
	for button in [play_btn, shop_btn, settings_btn, rank_btn]:
		button.mouse_entered.connect(_on_hover.bind(button))
		button.mouse_exited.connect(_on_unhover.bind(button))

func _on_hover(button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property(button, "modulate", Color(1, 1, 0.9, 1), 0.2)

func _on_unhover(button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1, 1), 0.2)
	tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.2)

func hide_menu():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_texture, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	queue_free()
