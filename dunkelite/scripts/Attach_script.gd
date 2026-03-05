extends CanvasLayer

# Объявляем сигналы
signal game_started
signal game_exited

var settings_menu = null

func _ready():
	# У CanvasLayer нет mouse_filter, поэтому настраиваем только кнопки
	
	# Контейнер с кнопками должен ловить мышь
	$ButtonContainer.mouse_filter = Control.MOUSE_FILTER_STOP
	
	$ButtonContainer/PlayButton.pressed.connect(_on_play_pressed)
	$ButtonContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	# Загружаем сцену настроек (но не показываем)
	settings_menu = load("res://scenes/menus/settings_menu.tscn").instantiate()
	add_child(settings_menu)
	settings_menu.hide()
	settings_menu.back_pressed.connect(_on_settings_back)

func _on_play_pressed():
	print("Нажали Играть")
	hide()
	game_started.emit()

func _on_settings_pressed():
	print("Открываем настройки")
	hide()  # Прячем главное меню
	settings_menu.show()  # Показываем настройки

func _on_settings_back():
	print("Возврат в главное меню")
	settings_menu.hide()
	show()  # Показываем главное меню

func _on_quit_pressed():
	print("Нажали Выход")
	hide()
	game_exited.emit()
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			hide()
		else:
			show()

func show_menu():
	show()

func hide_menu():
	hide()
