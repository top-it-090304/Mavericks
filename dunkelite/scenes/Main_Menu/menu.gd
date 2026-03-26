extends Control

signal start_game

@onready var tap_label: Label = $TapLabel
@onready var best_score_label: Label = $BestScoreLabel

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS


func update_best_score(value: int):
	best_score_label.text = "BEST: " + str(value)
