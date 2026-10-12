shader_type canvas_item;
// Portal girdabını ve rünlerini gidilecek bölgenin rengine boyar: mavi baskın pikseller
// parlaklıkları korunarak hedef renge çevrilir, taşlar olduğu gibi kalır.

uniform vec3 target : source_color = vec3(0.55, 0.8, 1.0);

void fragment() {
	vec4 c = COLOR;
	float blue = c.b - max(c.r, c.g * 0.85);
	float k = smoothstep(0.02, 0.18, blue);
	float lum = dot(c.rgb, vec3(0.3, 0.45, 0.25));
	vec3 tinted = target * lum * 1.7 + vec3(lum * lum * 0.6);
	COLOR = vec4(mix(c.rgb, tinted, k), c.a);
}
