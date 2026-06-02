shader_type canvas_item;

uniform float fade_start : hint_range(0.0, 1.0) = 0.55;
uniform float fade_end   : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0;
	float alpha = 1.0 - smoothstep(fade_start, fade_end, dist);
	color.a *= alpha;
	COLOR = color;
}
