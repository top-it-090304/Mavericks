class_name Ring
extends Node2D

signal goal_scored

var _goal_allowed: bool = true
var _scored: bool = false
var net_stretch_offset: Vector2 = Vector2.ZERO:
	set(value):
		if net_stretch_offset != value:
			net_stretch_offset = value
			queue_redraw()

const NET_COLOR := Color(1, 1, 1, 0.7)
const NET_COLOR_SCORED := Color(0.5, 0.5, 0.5, 0.7)
const NET_WIDTH := 4
const NET_COLS := 6
const NET_ROWS := 4
const RIM_LEFT := Vector2(-61, -8)
const RIM_RIGHT := Vector2(62, -8)
const FRONT_ARC_DIP := 5.0
const NET_HEIGHT := 38.0
const BOTTOM_WIDTH_RATIO := 0.55
const BOTTOM_ARC_DIP := 13.0

@onready var goal_zone: Area2D = $GoalZone

func _ready() -> void:
	goal_zone.body_entered.connect(_on_goal_zone_entered)
	queue_redraw()

func _draw() -> void:
	var color = NET_COLOR_SCORED if _scored else NET_COLOR

	# Build grid of net points
	var rows: Array = []

	# Row 0: 8 attachment points on the rim
	var top_points: Array[Vector2] = []
	for c in NET_COLS:
		var ct = float(c) / (NET_COLS - 1)
		var x = lerp(RIM_LEFT.x, RIM_RIGHT.x, ct)
		var y = lerp(RIM_LEFT.y, RIM_RIGHT.y, ct) + sin(ct * PI) * FRONT_ARC_DIP
		top_points.append(Vector2(x, y))
	rows.append(top_points)

	# Intermediate and bottom rows
	var top_y = RIM_LEFT.y
	var half_top = (RIM_RIGHT.x - RIM_LEFT.x) / 2.0
	for r in range(1, NET_ROWS):
		var rt = float(r) / (NET_ROWS - 1)
		var half_w = lerp(half_top, half_top * BOTTOM_WIDTH_RATIO, rt)
		var base_y = lerp(top_y, top_y + NET_HEIGHT, rt)
		var arc_dip = lerp(FRONT_ARC_DIP, BOTTOM_ARC_DIP, rt)
		var row_stretch = net_stretch_offset * rt
		var points: Array[Vector2] = []
		for c in NET_COLS:
			var ct = float(c) / (NET_COLS - 1)
			var x = lerp(-half_w, half_w, ct) + row_stretch.x
			var y = base_y + sin(ct * PI) * arc_dip + row_stretch.y
			points.append(Vector2(x, y))
		rows.append(points)

	# Diamond mesh: edges straight, interior X-crossings
	for r in NET_ROWS - 1:
		for c in NET_COLS:
			if c == 0 or c == NET_COLS - 1:
				draw_line(rows[r][c], rows[r + 1][c], color, NET_WIDTH)
			else:
				draw_line(rows[r][c], rows[r + 1][c - 1], color, NET_WIDTH)
				draw_line(rows[r][c], rows[r + 1][c + 1], color, NET_WIDTH)

	# Smooth semicircular arc at bottom
	var bottom = rows[NET_ROWS - 1]
	var left_pt = bottom[0]
	var right_pt = bottom[NET_COLS - 1]
	var cx = (left_pt.x + right_pt.x) / 2.0
	var edge_y = (left_pt.y + right_pt.y) / 2.0
	var rx = (right_pt.x - left_pt.x) / 2.0
	var mid_pt = bottom[NET_COLS / 2]
	var ry = mid_pt.y - edge_y
	if ry < 1.0:
		ry = BOTTOM_ARC_DIP
	var arc_segs = 24
	var prev_pt = left_pt
	for i in range(1, arc_segs + 1):
		var t = float(i) / arc_segs
		var angle = PI * (1.0 - t)
		var px = cx + cos(angle) * rx
		var py = edge_y + sin(angle) * ry
		var pt = Vector2(px, py)
		draw_line(prev_pt, pt, color, NET_WIDTH)
		prev_pt = pt

func animate_net_return() -> void:
	var tween = create_tween()
	tween.tween_method(_set_net_stretch, net_stretch_offset, Vector2.ZERO, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _set_net_stretch(value: Vector2) -> void:
	net_stretch_offset = value

func mark_scored() -> void:
	_scored = true
	queue_redraw()
	var gray := Color(0.5, 0.5, 0.5, 1.0)
	$RimFront.modulate = gray
	$RimBack.modulate = gray

func _on_goal_zone_entered(body: Node2D) -> void:
	if not body.is_in_group("ball"):
		return
	if not _goal_allowed:
		return
	if body.linear_velocity.y < 0:
		return
	if body.linear_velocity.length() < 50:
		return
	_goal_allowed = false
	goal_scored.emit()

func set_physics_enabled(enabled: bool) -> void:
	$RimLeft/CollisionShape2D.set_deferred("disabled", not enabled)
	$RimRight/CollisionShape2D.set_deferred("disabled", not enabled)
	$NetBlocker/CollisionShape2D.set_deferred("disabled", not enabled)

func reset() -> void:
	_goal_allowed = true
	_scored = false
	net_stretch_offset = Vector2.ZERO
	queue_redraw()
	$RimFront.modulate = Color(1, 1, 1, 1)
	$RimBack.modulate = Color(1, 1, 1, 1)
