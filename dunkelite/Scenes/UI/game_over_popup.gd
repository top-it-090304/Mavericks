extends Control

signal restart
signal continue_game
signal go_home

@onready var best_label: Label = $Panel/BestLabel
@onready var score_label: Label = $Panel/ScoreLabel
@onready var restart_btn: Button = $Panel/RestartButton
@onready var continue_btn: Button = $Panel/ContinueBtn
@onready var home_btn: Button = $Panel/HomeBtn
@onready var stars_label: Label = $StarsLabel
@onready var hearts_label: Label = $HeartsLabel

func _ready() -> void:
	best_label.add_to_group("dark_text")
	score_label.add_to_group("dark_text")
	restart_btn.pressed.connect(func(): restart.emit())
	continue_btn.pressed.connect(func(): continue_game.emit())
	home_btn.pressed.connect(func(): go_home.emit())

func show_popup(score: int, best: int) -> void:
	score_label.text = str(score)
	best_label.text = str(best)
	stars_label.text = " " + str(Global.stars)
	hearts_label.text = " " + str(Global.hearts)
	if Global.hearts <= 0:
		continue_btn.disabled = true
	else:
		continue_btn.disabled = false
	show()
