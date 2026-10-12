class_name ValeriusRest
extends Actor
## Demir Maskeli Usta'nın ölümü (bölge 8): Kârun'un taktığı demir maske kırılıp düşer, Usta diz çöker; ataların hocası
## gerçek yüzüyle Arktan'daki kanı tanır. Düğüm Valerius'un düştüğü yerde. İlerde her boss için kısa ölüm sinematikleri gelecek; bu kısa geçiştir.

const SHATTER := 40
const GOLD := Color(1.0, 0.82, 0.35)

var flip := false
var t := 0
var _light: PointLight2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_light = PointLight2D.new()
	_light.texture = Atmosphere.light_texture()
	_light.texture_scale = 1.4
	_light.color = Color(1.0, 0.85, 0.6)
	_light.energy = 0.0
	_light.position = Vector2(0, -80)
	add_child(_light)
	add_child(GlowLayer.make(_paint))


func tick() -> void:
	t += 1
	if t == 6:
		main.fx.add_sprite(position + Vector2(0, -150), "fx_gold_shards", 90.0, Color.WHITE, 30, 0.5)
		main.shake(8)
	_light.energy = 0.5 * clampf(float(t - SHATTER) / 60.0, 0.0, 1.0)
	if t == SHATTER + 50:
		main.float_text(position + Vector2(0, -190), "\"Atanın gözleri... Affet beni, nöbetçi.\"", Color(1.0, 0.92, 0.75))
	queue_redraw()


func _draw() -> void:
	var tex := Sprites.tex("boss_z8_peace")
	if tex == null:
		return
	var s := Boss.VL_SCALE
	var b := Rect2(-Boss.VL_ANCHOR * s, Boss.VL_CANVAS * s)
	if flip:
		b.position.x = -(Boss.VL_CANVAS.x - Boss.VL_ANCHOR.x) * s
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-60, -60, 120, 120), false, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	var a := clampf(float(t) / 20.0, 0.0, 1.0)
	Sprites.draw_actor(self, "boss_z8_peace", b, flip, false, false, Color(1, 1, 1, a))


func _paint(g: GlowLayer) -> void:
	if t < SHATTER:
		var k := 1.0 - float(t) / SHATTER
		g.glow(Vector2(0, -160), 40.0 * k, Color(GOLD, 0.6 * k))
	else:
		var k := clampf(float(t - SHATTER) / 60.0, 0.0, 1.0)
		g.glow(Vector2(0, -120), 50.0, Color(1.0, 0.9, 0.7, 0.18 * k))
