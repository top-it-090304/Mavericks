extends CanvasLayer

# Эта функция вызывается автоматически, когда сцена загружается
func _ready():
	# Находим кнопки по их именам и подключаем сигналы
	$ButtonContainer/PlayButton.pressed.connect(_on_play_pressed)
	$ButtonContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonContainer/QuitButton.pressed.connect(_on_quit_pressed)

# Функция для кнопки "Играть"
func _on_play_pressed():
	print("Нажали Играть")  # Это появится в консоли (проверка)
	hide()  # Прячем меню

# Функция для кнопки "Настройки"
func _on_settings_pressed():
	print("Нажали Настройки")
	# Пока просто прячем меню (потом сделаем нормальные настройки)
	hide()

# Функция для кнопки "Выход"
func _on_quit_pressed():
	print("Нажали Выход")
	hide()  # Прячем меню
	get_tree().quit()  # Выходим из игры

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC на клавиатуре
		if visible:
			hide()
		else:
			show()
