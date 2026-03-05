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

# Доступные мячи (пути к текстурам)
var balls: Array = [
	"res://assets/images/ball_1.png",
	"res://assets/images/ball_2.png",
	"res://assets/images/ball_3.png",
	"res://assets/images/ball_gold.png"
]

# Настройки
var sound_enabled: bool = true:
	set(value):
		sound_enabled = value
		save_settings()

var music_enabled: bool = true:
	set(value):
		music_enabled = value
		save_settings()

var music_volume: float = 0.8:
	set(value):
		music_volume = value
		save_settings()

func _ready():
	# Загружаем все сохраненные данные при старте
	load_game_data()

func load_game_data():
	# Загружаем прогресс (звезды, выбранный мяч)
	# TODO: загружать из файла
	stars = 1000
	selected_ball = 0
	
	# Загрузка настроек
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		sound_enabled = config.get_value("audio", "sound", true)
		music_enabled = config.get_value("audio", "music", true)
		music_volume = config.get_value("audio", "volume", 0.8)
	
func save_game_data():
	# Сохраняем прогресс
	pass

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "sound", sound_enabled)
	config.set_value("audio", "music", music_enabled)
	config.set_value("audio", "volume", music_volume)
	config.save("user://settings.cfg")
