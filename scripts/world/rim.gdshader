shader_type canvas_item;
render_mode unshaded;
// Boss silüet halesi: dokunun alfa şekli, düz bölge renginde.
uniform vec4 tint : source_color;

void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * tint.a * COLOR.a);
}
