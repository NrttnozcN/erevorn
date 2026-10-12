class_name BossRest
extends Actor
## Bölge 1–3 muhafızlarının ölüm karesi: bossun son karesi (huzur / yenilgi) yerinde kalır, kısa bir söz çıkar.
## Kareler Boss ile aynı 420x470 tuvalde, çapa ayak tabanı. İlerde her boss için kısa ölüm sinematikleri gelecek.

var key := ""
var flip := false
var scale_k := 0.5
var line := ""
var line_color := Color(0.9, 0.9, 1.0)
var light_color := Color(0.6, 0.75, 1.0)
var t := 0
const ANCHOR := Vector2(210, 462)
const CANVAS := Vector2(420, 470)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = 1.4
	l.color = light_color
	l.energy = 0.5
	l.position = Vector2(0, -60)
	add_child(l)


func tick() -> void:
	t += 1
	if t == 50 and line != "":
		main.float_text(position + Vector2(0, -170), line, line_color)
	queue_redraw()


func _draw() -> void:
	if Sprites.tex(key) == null:
		return
	var b := Rect2(-ANCHOR * scale_k, CANVAS * scale_k)
	if flip:
		b.position.x = -(CANVAS.x - ANCHOR.x) * scale_k
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-70, -70, 140, 140), false, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO)
	Sprites.draw_actor(self, key, b, flip, false, false, Color(1, 1, 1, clampf(t / 20.0, 0.0, 1.0)))
