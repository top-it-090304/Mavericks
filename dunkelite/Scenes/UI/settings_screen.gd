extends Control

signal back

@onready var back_btn: Button = $Panel/Header/Content/BackBtn
@onready var sound_slider: HSlider = $Panel/SoundSlider
@onready var music_slider: HSlider = $Panel/MusicSlider
@onready var add_coins_btn: Button = $Panel/AddCoinsBtn


var _volumes_dirty: bool = false


func _ready() -> void:
	back_btn.add_to_group("header_ui")
	back_btn.modulate = Color(6.0, 6.0, 6.0, 1.0)
	back_btn.pressed.connect(_on_back_pressed)
	sound_slider.value = Global.sfx_volume
	music_slider.value = Global.music_volume
	sound_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sound_slider.drag_ended.connect(_on_slider_drag_ended)
	music_slider.drag_ended.connect(_on_slider_drag_ended)
	add_coins_btn.modulate.a = 0.0
	add_coins_btn.pressed.connect(func(): Global.add_stars(500))


func _on_sfx_changed(v: float) -> void:
	Global.set_sfx_volume(v)
	_volumes_dirty = true


func _on_music_changed(v: float) -> void:
	Global.set_music_volume(v)
	_volumes_dirty = true


func _on_slider_drag_ended(value_changed: bool) -> void:
	if value_changed and _volumes_dirty:
		Global.request_save()
		_volumes_dirty = false


func _on_back_pressed() -> void:
	if _volumes_dirty:
		Global.request_save()
		_volumes_dirty = false
	back.emit()
