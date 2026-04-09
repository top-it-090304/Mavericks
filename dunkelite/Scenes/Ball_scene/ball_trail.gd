extends Line2D

func _ready() -> void:
	top_level = true
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.18))
	curve.add_point(Vector2(0.5, 0.45))
	curve.add_point(Vector2(1.0, 1.0))
	width_curve = curve

var _max_points: int = 0
var _cached_tex: Texture2D = null

func set_combo(combo: int) -> void:
	if combo == 0:
		_max_points = 0
		return
	width = 55.0 + combo * 2.0
	_max_points = 10 + combo * 2

func add_pos(p: Vector2) -> void:
	add_point(p)
	if get_point_count() > _max_points:
		remove_point(0)

func clear_trail() -> void:
	clear_points()

func set_trail_color_from_texture(tex: Texture2D) -> void:
	if tex == _cached_tex:
		return
	_cached_tex = tex
	var col := _sample_main_color(tex)
	var tail_col := Color(col.r, col.g, col.b, 0.7)
	var head_col := col.lightened(0.3)
	head_col.a = 0.45
	var g := Gradient.new()
	g.set_color(0, tail_col)
	g.set_color(1, head_col)
	gradient = g

func _sample_main_color(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img == null:
		return Color(1.0, 0.5, 0.1)
	var w := img.get_width()
	var h := img.get_height()
	var hw := int(w * 0.5)
	var hh := int(h * 0.5)
	var tw := int(w / 3.0)
	var th := int(h / 3.0)
	for pt in [Vector2i(hw, hh), Vector2i(tw, hh), Vector2i(w - tw, hh), Vector2i(hw, th), Vector2i(hw, h - th)]:
		var c := img.get_pixel(pt.x, pt.y)
		if c.a > 0.5:
			return Color(c.r, c.g, c.b, 1.0)
	return Color(1.0, 0.5, 0.1)
