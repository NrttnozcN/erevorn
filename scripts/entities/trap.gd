class_name Trap
extends Actor
## Diken ya da ateş tuzağı: 120 karelik döngünün son 15 karesinde etkin (entities.js:4143-4213).

var type := "spike"
var cycle := randi() % 120
var cooldown := 0


func _ready() -> void:
	if type == "fire":
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(GlowLayer.make(_paint_fire))


func tick() -> void:
	cycle = (cycle + 1) % 120
	if cooldown > 0:
		cooldown -= 1
	if cycle >= 105 and cooldown == 0:
		var p := main.player
		if p.position.distance_to(position) < 18.0 and p.take_damage(8 if type == "spike" else 12, self):
			cooldown = 60
			if type == "fire":
				p.apply_debuff("burn")
	queue_redraw()


func _draw() -> void:
	var warning := cycle >= 95 and cycle < 105
	var active := cycle >= 105
	if type == "spike":
		draw_rect(Rect2(-13, -3, 26, 6), Color("4a4a55"))
		if warning:
			draw_rect(Rect2(-13, -3, 26, 6), Color(1, 0.2, 0.2, 0.4))
		if active:
			for i in 3:
				var x := -9 + i * 9
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -3), Vector2(x + 3, -3), Vector2(x, -14)]), Color("d8d8e0"))
	else:
		draw_rect(Rect2(-7, -7, 14, 14), Color("3a2a25"))
		draw_rect(Rect2(-4, -4, 8, 8), Color("120806"))


## Ateş tuzağının alevi: boyalı fx sprite'ları, toplamalı ışıkla (hasar alanı aynı: 18 px).
func _paint_fire(g: GlowLayer) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var flick := 0.85 + 0.15 * sin(t * 31.0) * sin(t * 17.0 + 1.3)
	if cycle >= 105:
		# Püskürme: hızla yükselir, son karelerde söner.
		var k := (cycle - 105) / 15.0
		var rise := minf(1.0, k * 4.0)
		var fade := 1.0 - maxf(0.0, (k - 0.6) / 0.4)
		var h := 64.0 * rise * flick
		g.glow(Vector2(0, -10), 34, Color(1.0, 0.45, 0.1, 0.55 * fade))
		g.sprite("fx_fireball", Vector2(0, -h * 0.45), Vector2(h, h * 0.42), Color(1.0, 0.55, 0.2, 0.95 * fade), -PI / 2)
		g.sprite("fx_explosion", Vector2(0, -8), Vector2(36, 30) * (0.8 + 0.25 * flick), Color(1.0, 0.6, 0.25, 0.75 * fade), t * 2.0)
		g.sprite("fx_spark", Vector2(sin(t * 9.0) * 4, -h * 0.75), Vector2.ONE * 26 * flick, Color(1.0, 0.8, 0.4, 0.6 * fade), t * 5.0)
	elif cycle >= 95:
		# Uyarı: ızgaradan közler kabarır.
		var w := (cycle - 95) / 10.0
		g.glow(Vector2.ZERO, 12 + 10 * w, Color(1.0, 0.35, 0.05, (0.3 + 0.4 * w) * flick))
		g.sprite("fx_spark", Vector2(0, -4), Vector2.ONE * (10 + 10 * w), Color(1.0, 0.6, 0.2, 0.5 * w), t * 4.0)
	else:
		g.glow(Vector2.ZERO, 9, Color(1.0, 0.3, 0.05, 0.16 * flick))
