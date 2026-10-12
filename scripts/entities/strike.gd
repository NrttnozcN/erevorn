class_name Strike
extends Actor
## Gökten düşen alan saldırıları: Gök Kılıcı, Ok Yağmuru oku ve Meteor (entities.js:3333-3530).

var kind := "sword"
var radius := 120.0
var damage := 10
var delay := 0
var warn := 0
var height := 380.0
var fall_speed := 9.5
var done := false
var fade := 0


func setup(p_kind: String, p_radius: float, p_damage: int, p_delay: int) -> void:
	material = preload("res://scripts/world/unshaded.tres")
	# Proje varsayılanı piksel süzme; gök kılıcı / ok / meteor sprite'ları kumlanmasın.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	kind = p_kind
	radius = p_radius
	damage = p_damage
	delay = p_delay
	match kind:
		"arrow":
			height = 340.0; fall_speed = 9.0
		"meteor":
			height = 420.0; fall_speed = 8.5; warn = 62


func tick() -> void:
	if done:
		fade -= 1
		if fade <= 0:
			remove()
		queue_redraw()
		return
	if delay > 0:
		delay -= 1
		return
	if warn > 0:
		warn -= 1
		queue_redraw()
		return
	height -= fall_speed
	if height <= 0:
		_land()
	queue_redraw()


func _land() -> void:
	done = true
	fade = 18
	main.shake(14 if kind != "arrow" else 4)
	main.burst(position, radius, {"sword": Color(0.5, 0.9, 1.0), "arrow": Color(1, 0.9, 0.5), "meteor": Color(1, 0.4, 0.1)}[kind])
	match kind:
		"sword": main.fx.add_sprite(position, "fx_ring_blue", radius * 2.3, Color.WHITE, 24, 0.2)
		"arrow": main.fx.add_sprite(position, "fx_spark", 52.0, ItemData.fx_color(main.player.equipment.weapon.get("rarity", "common")), 12, 0.4, randf() * TAU)
		"meteor": main.fx.add_sprite(position + Vector2(0, -20), "fx_explosion", radius * 2.4, Color.WHITE, 26, 0.25)
	for e in main.targets():
		var d: float = e.position.distance_to(position)
		if d > radius:
			continue
		var dmg := damage
		if kind == "meteor":
			dmg = int(damage * (1.0 - minf(0.45, d / radius * 0.45)))
			if e is Enemy:
				e.burned = 300
		elif randf() < 0.25:
			dmg = int(dmg * 1.5)
		var mult := 1.8 if kind == "meteor" else 1.0
		if e is Boss:
			mult = 0.7 if kind == "meteor" else 0.3
		e.take_damage(dmg, e.position - position, mult)


func _draw() -> void:
	if delay > 0:
		return
	if done:
		var a := fade / 18.0
		var fr := radius * (1.1 - a * 0.3)
		draw_texture_rect(Atmosphere.soft_texture(), Rect2(-fr, -fr, fr * 2.0, fr * 2.0), false, Color(1, 0.8, 0.5, 0.5 * a))
		return
	# Hedef halkası: yumuşak haleli, kenar yumuşatmalı (sert 2 px çember değil).
	# Ok yağmurunda çok sayıda ok iner: halkaları silik tut, ekran halkaya boğulmasın.
	var ring := Color(1, 0.3, 0.2, 0.5) if kind == "meteor" else (Color(1.0, 0.9, 0.6, 0.14) if kind == "arrow" else Color(0.6, 0.9, 1.0, 0.4))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 96, Color(ring, ring.a * 0.25), 7.0, true)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 96, ring, 1.6, true)
	if warn > 0:
		var wr := radius * (1.0 - warn / 62.0)
		draw_texture_rect(Atmosphere.soft_texture(), Rect2(-wr, -wr, wr * 2.0, wr * 2.0), false, Color(1, 0.2, 0.1, 0.4))
		return
	var top := Vector2(0, -height)
	if _draw_painted(top):
		return
	match kind:
		"sword":
			draw_rect(Rect2(top.x - 7, top.y - 90, 14, 90), Color(0.8, 0.95, 1.0))
			draw_rect(Rect2(top.x - 22, top.y - 98, 44, 8), Color(0.5, 0.75, 1.0))
			draw_rect(Rect2(top.x - 4, top.y - 120, 8, 22), Color(0.35, 0.5, 0.8))
			draw_line(top, top + Vector2(0, -90), Color(0.3, 0.9, 1.0, 0.6), 3)
		"arrow":
			draw_line(top + Vector2(0, -30), top, Color(0.85, 0.7, 0.4), 3)
			draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -6), top + Vector2(5, -6), top + Vector2(0, 4)]), Color(0.9, 0.9, 0.95))
		"meteor":
			draw_circle(top, 26, Color(1, 0.35, 0.05, 0.4))
			draw_circle(top, 17, Color(1, 0.55, 0.1))
			draw_circle(top, 8, Color(1, 0.95, 0.6))
			draw_line(top, top + Vector2(0, -60), Color(1, 0.5, 0.1, 0.4), 12)


## Boyalı düşen efektler; sprite yoksa eski çizime düşer.
func _draw_painted(top: Vector2) -> bool:
	match kind:
		"sword":
			if Sprites.tex("fx_skysword") == null:
				return false
			Sprites.draw_flat(self, "fx_skysword", Rect2(top.x - 80, top.y - 150, 160, 170))
		"arrow":
			var r: String = main.player.equipment.weapon.get("rarity", "common")
			var key := "projectile_arrow_%s" % r
			if Sprites.tex(key) == null:
				key = "projectile_arrow_%s" % {"mythic": "legendary", "epic": "rare"}.get(r, "common")
			if Sprites.tex(key) == null or Sprites.tex("fx_trail_w") == null:
				return false
			draw_set_transform(top, PI / 2)
			Sprites.draw_flat(self, "fx_trail_w", Rect2(-62, -9, 56, 18), Color(ItemData.fx_color(r), 0.7))
			Sprites.draw_flat(self, key, Rect2(-30, -5, 38, 9.5))
			draw_set_transform(Vector2.ZERO)
		"meteor":
			if Sprites.tex("fx_meteor") == null:
				return false
			Sprites.draw_flat(self, "fx_meteor", Rect2(top.x - 70, top.y - 120, 140, 140))
		_:
			return false
	return true
