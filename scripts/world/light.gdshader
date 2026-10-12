shader_type canvas_item;
// Oyuncunun etrafındaki meşale ışığı ve bölge atmosfer rengi (world.js:377-448).

uniform vec2 center;
uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform float inner = 76.0;
uniform float outer = 370.0;
uniform vec4 tint : source_color = vec4(0.0);

float cut(float t) {
	if (t <= 0.0) return 1.0;
	if (t < 0.35) return mix(1.0, 0.85, t / 0.35);
	if (t < 0.75) return mix(0.85, 0.18, (t - 0.35) / 0.4);
	if (t < 1.0) return mix(0.18, 0.0, (t - 0.75) / 0.25);
	return 0.0;
}

void fragment() {
	vec2 p = UV * rect_size;
	float d = distance(p, center);
	float dark = 1.0 - cut((d - inner) / max(outer - inner, 1.0));
	vec3 base = tint.rgb;
	float a_tint = tint.a;
	vec3 mask = vec3(0.012, 0.012, 0.02);
	vec3 col = mix(base, mask, dark);
	float a = 1.0 - (1.0 - a_tint) * (1.0 - dark);
	COLOR = vec4(col, a);
}
