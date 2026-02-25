extends Node2D

# Ссылка на меню
@onready var menu = $MenuLayer

func _ready():
	# Подключаемся к сигналам меню
	menu.game_started.connect(_on_game_started)
	menu.game_exited.connect(_on_game_exited)
	
	# Показываем меню при старте
	menu.show_menu()
	
	# Тут твоя обычная логика игры
	print("Игра загружена, меню показано")

func _on_game_started():
	print("Игра началась!")
	# Здесь можно активировать игровые объекты (мяч, кольцо и т.д.)
	# Например: $Ball.start_moving()

func _on_game_exited():
	print("Выход из игры")
	# Здесь можно сохранить прогресс перед выходом

func _input(event):
	# По ESC показываем/скрываем меню
	if event.is_action_pressed("ui_cancel"):
		if menu.visible:
			menu.hide_menu()
			# Если скрыли меню - значит игра продолжается
			_on_game_started()
		else:
			menu.show_menu()
			# Если показали меню - игру на паузу
			_on_game_paused()

func _on_game_paused():
	print("Игра на паузе")
	# Здесь можно остановить игровые объекты
	# Например: $Ball.stop_moving()
