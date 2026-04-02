extends Control

@onready var score_label: Label = $ScoreLabel
@onready var stars_label: Label = $StarsLabel
@onready var hearts_label: Label = $HeartsLabel
@onready var combo_label: Label = $ComboLabel

func update_score(value: int) -> void:
	score_label.text = str(value)

func update_stars(value: int) -> void:
	stars_label.text = " " + str(value)

func update_hearts(value: int) -> void:
	hearts_label.text = " " + str(value)

func show_combo(points: int) -> void:
	combo_label.text = "+%d" % points
	combo_label.visible = true
	combo_label.modulate = Color(1, 1, 1, 1)
	var t = create_tween()
	t.tween_property(combo_label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	t.tween_callback(func(): combo_label.visible = false)

func hide_combo() -> void:
	combo_label.visible = false
