class_name Portal
extends Actor
## Çıkış portalı. Kattaki tüm düşmanlar ölünce açılır; E ile girilir.

var active := false
var timer := 0
var _light: PointLight2D

## Gidilecek bölgenin portal rengi (bölge 1..10). Geçiş katlarında bir sonraki bölgenin rengi görünür.
const ZONE_COLORS := [
	Color(0.55, 0.8, 1.0), Color(0.7, 0.35, 1.0), Color(1.0, 0.7, 0.3), Color(1.0, 0.4, 0.15), Color(0.55, 0.92, 1.0),
	Color(0.45, 1.0, 0.5), Color(1.0, 0.2, 0.3), Color(1.0, 0.95, 0.75), Color(0.85, 0.3, 1.0), Color(1.0, 0.6, 0.1),
]


static func zone_color() -> Color:
	return ZONE_COLORS[EnemyData.zone_of(Game.floor_number + 1) - 1]


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_light = PointLight2D.new()
	_light.texture = Atmosphere.light_texture()
	_light.texture_scale = 1.3
	_light.position = Vector2(0, -10)
	add_child(_light)
	if Sprites.tex("portal_on") != null:
		var m := ShaderMaterial.new()
		m.shader = preload("res://scripts/world/portal.gdshader")
		m.set_shader_parameter("target", zone_color())
		material = m


func tick() -> void:
	timer += 1
	queue_redraw()


func _draw() -> void:
	var on_c := zone_color()
	_light.color = on_c if active else Color(0.55, 0.4, 0.85)
	_light.energy = (1.5 + 0.25 * sin(timer / 9.0)) if active else 0.45
	if Sprites.tex("portal_on") != null:
		if active:
			var g := 0.18 + 0.08 * sin(timer / 10.0)
			draw_set_transform(Vector2(0, 14), 0, Vector2(1, 0.4))
			draw_circle(Vector2.ZERO, 46, Color(on_c, g))
			draw_set_transform(Vector2.ZERO)
		Sprites.draw_grounded(self, "portal_on" if active else "portal_off", 96.0, 22.0)
		if position.distance_to(main.player.position) < 70:
			main.draw_hint(self, Vector2(0, -84), "[E] İNİŞ" if active else "PORTAL KAPALI")
		return
	var key := "portal1" if (timer / 15) % 2 == 0 else "portal2"
	var mod := Color.WHITE if active else Color(0.35, 0.35, 0.4)
	if active:
		var g := 0.25 + 0.1 * sin(timer / 10.0)
		draw_circle(Vector2.ZERO, 34, Color(0.0, 0.94, 1.0, g))
	Sprites.draw_flat(self, key, Rect2(-24, -24, 48, 48), mod)
	if position.distance_to(main.player.position) < 70:
		main.draw_hint(self, Vector2(0, -36), "[E] İNİŞ" if active else "PORTAL KAPALI")
