extends Control

signal pause_pressed

@onready var score_label: Label = $ScoreLabel
@onready var stars_label: Label = $StarsLabel
@onready var hearts_label: Label = $HeartsLabel

func _ready() -> void:
	$PauseBtn.pressed.connect(func(): pause_pressed.emit())

func update_score(value: int) -> void:
	score_label.text = str(value)

func update_stars(value: int) -> void:
	stars_label.text = " " + str(value)

func update_hearts(value: int) -> void:
	hearts_label.text = " " + str(value)

func animate_star_fly(from_global: Vector2) -> void:
	var icon = Sprite2D.new()
	icon.texture = preload("res://assets/UIassets/StarIcon.svg")
	icon.scale = Vector2(0.55, 0.55)
	icon.global_position = from_global
	add_child(icon)
	var target = $stars.global_position + Vector2(20, 20)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(icon, "global_position", target, 0.55)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(icon, "scale", Vector2(0.3, 0.3), 0.55)\
		.set_ease(Tween.EASE_IN)
	await tween.finished
	icon.queue_free()
