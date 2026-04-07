extends Control

signal back

@onready var back_btn: Button = $Panel/BackBtn
@onready var sound_slider: HSlider = $Panel/SoundSlider
@onready var music_slider: HSlider = $Panel/MusicSlider


func _ready() -> void:
	back_btn.pressed.connect(func(): back.emit())
	sound_slider.value = Global.sfx_volume
	music_slider.value = Global.music_volume
	sound_slider.value_changed.connect(func(v): Global.set_sfx_volume(v))
	music_slider.value_changed.connect(func(v): Global.set_music_volume(v))
