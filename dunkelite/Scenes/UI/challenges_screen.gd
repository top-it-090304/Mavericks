extends Control

signal back

@onready var back_btn: Button = $Panel/Button
@onready var cardList: VBoxContainer = $Panel/ScrollContainer/CardList

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_btn.pressed.connect(func(): back.emit())
	var i = 0
	for child in cardList.get_children():
		if child.has_method("setup"):
			child.setup(Global.CHALLENGE_DEFS[i])
			i += 1
	Global.challenge_updated.connect(func():
		if visible:
			_refresh()
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_refresh()

func _refresh() -> void:
	for child in cardList.get_children():
		if child.has_method("refresh"):
			child.refresh()
