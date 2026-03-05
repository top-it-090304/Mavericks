extends CanvasLayer

signal back_pressed

@onready var sound_check = $Panel/VBoxContainer/SoundCheck
@onready var music_check = $Panel/VBoxContainer/MusicCheck
@onready var volume_slider = $Panel/VBoxContainer/VolumeSlider
@onready var back_button = $Panel/VBoxContainer/BackButton

func _ready():
	# Загружаем сохраненные настройки из Global
	sound_check.button_pressed = Global.sound_enabled
	music_check.button_pressed = Global.music_enabled
	volume_slider.value = Global.music_volume
	
	# Подключаем сигналы
	sound_check.toggled.connect(_on_sound_toggled)
	music_check.toggled.connect(_on_music_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	back_button.pressed.connect(_on_back_pressed)

func _on_sound_toggled(enabled):
	Global.sound_enabled = enabled
	print("Звук: ", enabled)

func _on_music_toggled(enabled):
	Global.music_enabled = enabled
	print("Музыка: ", enabled)

func _on_volume_changed(value):
	Global.music_volume = value
	print("Громкость: ", value)
	# Здесь можно менять громкость аудиобусов
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_back_pressed():
	Global.save_settings()  # Сохраняем настройки
	hide()
	back_pressed.emit()
