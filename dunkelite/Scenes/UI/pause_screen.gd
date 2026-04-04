extends Control

signal resume
signal go_home

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$PausePopup/ContinueBtn.pressed.connect(func(): resume.emit())
	$PausePopup/BackHomeBtn.pressed.connect(func(): go_home.emit())
