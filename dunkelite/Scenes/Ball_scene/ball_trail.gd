extends Line2D

var _glow: Line2D
var _max_points: int = 0
var _combo: int = 0
var _cached_tex: Texture2D = null
var _base_color: Color = Color(1.0, 0.5, 0.1)

func _ready() -> void:
	top_level = true

	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.12, 0.3))
	curve.add_point(Vector2(0.45, 0.6))
	curve.add_point(Vector2(0.8, 0.88))
	curve.add_point(Vector2(1.0, 1.0))
	width_curve = curve

	_glow = Line2D.new()
	_glow.top_level = true
	_glow.z_index = z_index - 1
	_glow.joint_mode = 2
	_glow.begin_cap_mode = 2
	_glow.end_cap_mode = 2
	var glow_curve = Curve.new()
	glow_curve.add_point(Vector2(0.0, 0.0))
	glow_curve.add_point(Vector2(0.3, 0.45))
	glow_curve.add_point(Vector2(1.0, 1.0))
	_glow.width_curve = glow_curve
	add_child(_glow)

func set_combo(combo: int) -> void:
	_combo = combo
	if combo == 0:
		_max_points = 0
		return
	width = 48.0 + combo * 3.0
	_glow.width = width * 2.1
	_max_points = 12 + combo * 2
	_update_gradient()

func _update_gradient() -> void:
	var t := clampf(float(_combo - 1) / 4.0, 0.0, 1.0)

	var fire := Color(1.0, 0.4, 0.05)
	var warm := _base_color.lerp(fire, 0.3 + t * 0.3)

	# ── main trail ──
	var tail := Color(warm.r, warm.g, warm.b, 0.0)
	var mid := Color(warm.r, warm.g * 0.9, warm.b * 0.6, 0.72 + t * 0.18)
	var head := warm.lightened(0.35 + t * 0.15)
	head.a = 0.55 + t * 0.2
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([tail, mid, head])
	gradient = g

	# ── glow ──
	var g_tail := Color(warm.r, warm.g, warm.b, 0.0)
	var g_mid := Color(warm.r, warm.g, warm.b, 0.15 + t * 0.1)
	var g_head := warm.lightened(0.4)
	g_head.a = 0.12 + t * 0.08
	var gg := Gradient.new()
	gg.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	gg.colors = PackedColorArray([g_tail, g_mid, g_head])
	_glow.gradient = gg

func add_pos(p: Vector2) -> void:
	add_point(p)
	_glow.add_point(p)
	if get_point_count() > _max_points:
		remove_point(0)
	if _glow.get_point_count() > _max_points:
		_glow.remove_point(0)

func clear_trail() -> void:
	clear_points()
	if _glow:
		_glow.clear_points()

func set_trail_color_from_texture(tex: Texture2D) -> void:
	if tex == _cached_tex:
		return
	_cached_tex = tex
	_base_color = _sample_main_color(tex)
	if _combo > 0:
		_update_gradient()

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
