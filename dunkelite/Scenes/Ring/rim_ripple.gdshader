shader_type canvas_item;

uniform float amplitude : hint_range(0.0, 0.1) = 0.0;
uniform float frequency : hint_range(1.0, 30.0) = 12.0;
uniform float speed : hint_range(0.0, 20.0) = 10.0;

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x * frequency + TIME * speed) * amplitude;
	uv.x += sin(uv.y * frequency + TIME * speed) * amplitude * 0.6;
	COLOR = texture(TEXTURE, uv);
}
