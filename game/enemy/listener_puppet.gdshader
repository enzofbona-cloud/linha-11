shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;
// Anima a imagem do Ouvinte como um boneco articulado: o desenho é uma malha
// subdividida e cada região do corpo (pernas, tronco, braços, cabeça) é
// deformada de um jeito. Não é um modelo 3D com esqueleto, mas tira a
// aparência de "foto deslizando".

uniform sampler2D creature : source_color, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.72);
// 0 = parado, 1 = andando, 2 ou mais = perseguindo
uniform float walk = 0.0;
// Avança conforme a distância percorrida: um passo a cada PI.
uniform float gait_phase = 0.0;
// 0..1: espasmo curto de cabeça e ombros
uniform float twitch = 0.0;
// Inclinação do corpo para a frente/lado (em metros no topo da cabeça)
uniform float lean = 0.0;

void vertex() {
	float h = 1.0 - UV.y;      // 0 nos pés, 1 no topo da cabeça
	float side = UV.x - 0.5;   // -0.5 esquerda, +0.5 direita
	float which = side < 0.0 ? -1.0 : 1.0;
	vec3 p = VERTEX;

	// Respiração: o peito alarga e estreita devagar.
	float chest = smoothstep(0.45, 0.72, h) * (1.0 - smoothstep(0.74, 0.92, h));
	p.x += side * chest * sin(TIME * 1.25) * 0.06;
	p.y += chest * sin(TIME * 1.25) * 0.008;

	// Tronco: balança com pivô nos pés. Quanto mais alto, mais desloca.
	float sway = sin(gait_phase) * (0.025 + 0.06 * walk);
	p.x += (sway + lean) * h * h * 1.25;

	// O corpo sobe e desce a cada passo (afunda quando o pé apoia).
	float bob = abs(sin(gait_phase));
	p.y -= (1.0 - bob) * 0.04 * walk * smoothstep(0.05, 0.35, h);

	// Pernas: a metade esquerda e a direita alternam.
	float leg = 1.0 - smoothstep(0.30, 0.47, h);
	float stride = sin(gait_phase) * which;
	float lift = max(stride, 0.0);
	p.y += lift * leg * (1.0 - h * 1.6) * 0.09 * walk;
	p.x += stride * leg * 0.045 * walk;
	// o joelho dobra para fora quando a perna sobe
	float knee = leg * smoothstep(0.12, 0.26, h);
	p.x += which * lift * knee * 0.03 * walk;

	// Braços: pendem das laterais e balançam defasados, a mão mais que o ombro.
	float arm = smoothstep(0.20, 0.36, abs(side))
		* smoothstep(0.24, 0.42, h) * (1.0 - smoothstep(0.72, 0.86, h));
	float hang = clamp(1.0 - (h - 0.24) / 0.60, 0.0, 1.0);
	p.x += sin(gait_phase + which * 1.3) * arm * hang * 0.11 * (0.35 + walk);
	p.y += cos(gait_phase * 2.0 + which) * arm * hang * 0.025 * (0.35 + walk);
	// dedos tremem
	p.x += arm * hang * hang * sin(TIME * 9.0 + which * 2.0) * 0.006;

	// Cabeça: pende de lado, procura o som e dá espasmos.
	float head = smoothstep(0.78, 0.90, h);
	float jerk = twitch * sin(TIME * 41.0);
	p.x += head * (sin(TIME * 0.6) * 0.035 + jerk * 0.07);
	p.y += head * (sin(TIME * 0.43) * 0.012 + abs(jerk) * 0.03);
	// os ombros acompanham o espasmo
	float shoulders = smoothstep(0.66, 0.78, h) * (1.0 - head);
	p.y += shoulders * which * jerk * 0.02;

	VERTEX = p;

	// Fica de frente para a câmera girando só no eixo vertical.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 c = texture(creature, UV);
	ALBEDO = c.rgb * tint;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.08;
}
