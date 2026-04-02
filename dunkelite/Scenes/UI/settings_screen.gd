extends Control

signal back

@onready var back_btn: Button = $Panel/BackBtn
@onready var sound_btn: Button = $Panel/SoundBtn
@onready var music_btn: Button = $Panel/MusicBtn

func _ready() -> void:
	back_btn.pressed.connect(func(): back.emit())
	sound_btn.pressed.connect(_toggle_sound)
	music_btn.pressed.connect(_toggle_music)

func _toggle_sound() -> void:
	Global.sound_on = not Global.sound_on
	Global.save_data()

func _toggle_music() -> void:
	Global.music_on = not Global.music_on
	Global.save_data()
