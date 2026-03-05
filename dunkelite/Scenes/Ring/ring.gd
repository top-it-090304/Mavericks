class_name Ring
extends Node2D

signal goal_scored

var _goal_allowed: bool = true

@onready var goal_zone: Area2D = $GoalZone

func _ready() -> void:
	goal_zone.body_entered.connect(_on_goal_zone_entered)

func _on_goal_zone_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return
	if not _goal_allowed:
		return
	if body.linear_velocity.y < 0:
		return

	_goal_allowed = false
	goal_scored.emit()

	await get_tree().create_timer(0.8).timeout
	reset()

func reset() -> void:
	_goal_allowed = true
