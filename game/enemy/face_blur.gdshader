shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

void fragment() {
	vec2 centered = (UV - vec2(0.5)) * 2.0;
	float radial_fade = exp(-dot(centered, centered) * 2.5);
	ALBEDO = vec3(0.004, 0.003, 0.003);
	ALPHA = 0.98 * radial_fade;
}
