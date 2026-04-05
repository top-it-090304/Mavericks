extends Control

signal back

@onready var back_btn: Button = $Panel/BackBtn


func _ready() -> void:
	back_btn.pressed.connect(func(): back.emit())
	
