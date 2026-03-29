extends Node2D

var max_camera_y: float = 0.0
var _segments: Array[Sprite2D] = []
var _segment_tops: Array[float] = []
var _segment_bottoms: Array[float] = []
var _camera: Camera2D
var _last_top: float = 0.0

func _ready() -> void:
	_camera = get_node("../Camera2D")
	var textures: Array[Texture2D] = []
	var i = 1
	while true:
		var path = "res://assets/images/background/F%d.jpg" % i
		if not ResourceLoader.exists(path):
			break
		textures.append(load(path))
		i += 1

	var current_bottom = 960.0
	for tex in textures:
		var h = tex.get_height()
		var sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.z_index = -1
		sprite.modulate = Color(0.85, 0.85, 0.85)
		sprite.position = Vector2(270, current_bottom - h / 2.0)
		add_child(sprite)
		_segments.append(sprite)
		_segment_tops.append(current_bottom - h)
		_segment_bottoms.append(current_bottom)
		current_bottom -= h

	var n = _segments.size()
	_last_top = _segment_tops[n - 1]

	for j in range(1, n):
		var is_dark = j <= 4 or j >= 9
		var grad = _create_gradient(_segment_tops[j - 1], is_dark)
		add_child(grad)

func _create_gradient(y_pos: float, dark: bool) -> ColorRect:
	var grad = ColorRect.new()
	grad.z_index = 0
	var h = 140 if dark else 100
	grad.size = Vector2(540, h)
	grad.position = Vector2(0, y_pos - h / 2.0)
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	var c = "0.0" if dark else "1.0"
	shader.code = "shader_type canvas_item;
void fragment() {
	float a = 1.0 - abs(UV.y - 0.5) * 2.0;
	COLOR = vec4(%s, %s, %s, a * 0.3);
}" % [c, c, c]
	mat.shader = shader
	grad.material = mat
	return grad

func _process(_delta: float) -> void:
	var cam_y = _camera.global_position.y
	var view_top = cam_y - 960.0
	var view_bottom = cam_y + 1920.0
	for j in _segments.size():
		_segments[j].visible = _segment_bottoms[j] > view_top and _segment_tops[j] < view_bottom

	if cam_y < _last_top:
		var n = _segments.size()
		var offset_y = cam_y
		for k in range(n - 1, max(n - 3, -1), -1):
			var h = _segments[k].texture.get_height()
			_segments[k].position.y = offset_y + h / 2.0
			_segments[k].visible = true
			offset_y += h
