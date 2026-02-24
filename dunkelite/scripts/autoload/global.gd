extends Node

# Сигналы для обновления UI
signal stars_changed(value)
signal selected_ball_changed(index)

# Данные игрока
var stars: int = 1000:  # Начальное количество звезд
	set(value):
		stars = value
		stars_changed.emit(stars)  # Автоматически обновляем UI
		
var selected_ball: int = 0:
	set(value):
		selected_ball = value
		selected_ball_changed.emit(selected_ball)

# Доступные мячи (пути к сценам или текстурам)
var balls: Array = [
	"res://assets/images/ball_1.png",
	"res://assets/images/ball_2.png",
	"res://assets/images/ball_3.png",
	"res://assets/images/ball_gold.png"
]

func _ready():
	# Загружаем сохраненные данные
	load_game_data()

func load_game_data():
	# Здесь можно загружать из файла
	# Пока используем тестовые значения
	stars = 1000
	selected_ball = 0
	
func save_game_data():
	# Сохраняем прогресс
	pass
