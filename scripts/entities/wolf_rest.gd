class_name WolfRest
extends Actor
## Gök Börü'nün arınması (bölge 10): mor kristaller kırılıp dökülür, kurt yıldız ışığıyla kıvrılıp uyur.
## İlerde her boss için kısa ölüm sinematikleri gelecek; bu oyun içi kısa geçiştir.

var flip := false
var t := 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = 1.6
	l.color = Color(0.6, 0.75, 1.0)
	l.energy = 0.6
	l.position = Vector2(0, -50)
	add_child(l)


func tick() -> void:
	t += 1
	if t == 4:
		main.burst(position + Vector2(0, -60), 110, Color(0.72, 0.32, 1.0))
		main.shake(10)
	if t == 70:
		main.float_text(position + Vector2(0, -160), "Gök Börü arındı", Color(0.75, 0.85, 1.0))
	queue_redraw()


func _draw() -> void:
	var tex := Sprites.tex("boss_z10_peace")
	if tex == null:
		return
	var s := Boss.GB_SCALE
	var b := Rect2(-Boss.GB_ANCHOR * s, Boss.GB_CANVAS * s)
	if flip:
		b.position.x = -(Boss.GB_CANVAS.x - Boss.GB_ANCHOR.x) * s
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-110, -110, 220, 220), false, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO)
	Sprites.draw_actor(self, "boss_z10_peace", b, flip, false, false, Color(1, 1, 1, clampf(t / 20.0, 0.0, 1.0)))
