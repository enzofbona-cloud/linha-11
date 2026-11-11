shader_type canvas_item;

void fragment() {
	float left_shade = 1.0 - smoothstep(0.0, 0.78, UV.x);
	float vignette = smoothstep(0.28, 0.82, length((UV - vec2(0.5)) * vec2(1.15, 1.0)));
	float alpha = clamp(0.12 + left_shade * 0.30 + vignette * 0.16, 0.0, 0.62);
	COLOR = vec4(0.004, 0.003, 0.003, alpha);
}
