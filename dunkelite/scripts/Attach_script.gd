extends CanvasLayer

signal game_started
signal game_exited

var settings_menu = null  # сюда сохраним ссылку на настройки

func _ready():
	# Подключаем кнопки главного меню
	$ButtonContainer/PlayButton.pressed.connect(_on_play_pressed)
	$ButtonContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)
	
	# Загружаем сцену настроек
	var settings_scene = load("res://scenes/menus/settings_menu.tscn")
	settings_menu = settings_scene.instantiate()
	add_child(settings_menu)  # добавляем как дочерний узел к главному меню
	
	# Подключаем сигнал возврата из настроек
	settings_menu.back_pressed.connect(_on_settings_back)
	
	# Показываем главное меню при старте

func _on_play_pressed():
	print("GOAL! - начало игры")
	game_started.emit()

func _on_settings_pressed():
	print("CUSTOMIZE - открываем настройки")
	hide()  # прячем главное меню
	settings_menu.show()  # показываем настройки

func _on_settings_back():
	print("Возврат в главное меню")
	settings_menu.hide()  # прячем настройки
	show()  # показываем главное меню

func _on_quit_pressed():
	print("Выход")
	game_exited.emit()
	get_tree().quit()
