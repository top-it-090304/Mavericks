extends CanvasLayer

# Объявляем сигналы
signal game_started
signal game_exited

func _ready():
	$ButtonContainer/PlayButton.pressed.connect(_on_play_pressed)
	$ButtonContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	print("Нажали Играть")
	hide()
	game_started.emit()

func _on_settings_pressed():
	print("Нажали Настройки")
	hide()

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
			

# НОВЫЕ ФУНКЦИИ - добавляем их сюда
func show_menu():
	show()

func hide_menu():
	hide()
