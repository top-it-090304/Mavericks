extends Control

signal back

@onready var back_btn: Button = $Panel/Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.pressed.connect(func(): back.emit())
