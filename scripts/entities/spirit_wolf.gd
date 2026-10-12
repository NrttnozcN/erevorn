class_name SpiritWolf
extends Actor
## Gök Börü'nün altın ruhu (T yetenekleri: Arktan'ın soyu Gök Börü'nün kanını taşır).
## "hunt": belirir, ulur, sonra en yakın düşmanlara koşup ısırır; süre bitince ışığa dağılır.
## "pounce": oyuncunun yanından hedefe tek bir dev sıçrayış; indiği yerde altın patlama.
## Kareler: Gök Börü karelerinden üretilen altın ruh görselleri fx_ruh_kurt_* (konsept/kahraman/proc_ruh_kurt.py;
## 420x470, ayak çapası 210,462), ışık gibi toplamalı çizilir.

const GOLD := Color(1.0, 0.84, 0.45)
const ANCHOR := Vector2(210, 462)
const CANVAS := Vector2(420, 470)
const SPEED := 6.5

var mode := "hunt"
var life := 420
var damage := 10
var scale_k := 0.3
var t := 0
var bite_cd := 0
var lunge_t := 0
var flip := false
## Sıçrayış: başlangıç, hedef, süre.
var from := Vector2.ZERO
var to := Vector2.ZERO
var leap := 22


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material = GlowLayer.additive()
	z_index = 5
	from = position
	main.burst(position + Vector2(0, -30), 60, GOLD)


func tick() -> void:
	t += 1
	if mode == "pounce":
		_pounce()
	else:
		_hunt()
	queue_redraw()


func _hunt() -> void:
	life -= 1
	if bite_cd > 0:
		bite_cd -= 1
	if lunge_t > 0:
		lunge_t -= 1
	if life <= 0:
		main.burst(position + Vector2(0, -30), 50, GOLD)
		remove()
		return
	if t < 36:
		return  # belirirken uluma
	var target: Node2D = null
	var best := 420.0
	for e in main.targets():
		var d: float = e.position.distance_to(main.player.position)
		if d < best:
			best = d
			target = e
	var goal: Vector2 = target.position if target else main.player.position + Vector2(-50.0 if main.player.facing_left else 50.0, 14)
	var to_goal := goal - position
	if to_goal.length() > (40.0 if target else 30.0):
		position += to_goal.normalized() * minf(SPEED, to_goal.length())
		flip = to_goal.x < 0
	elif target and bite_cd == 0:
		bite_cd = 26
		lunge_t = 12
		target.take_damage(damage, to_goal, 0.4 if target is Boss else 1.2)
		main.fx.add_sprite(target.position + Vector2(0, -24), "fx_slash_w", 70, GOLD, 12, 0.3, randf() * TAU)
		if target is Enemy and is_instance_valid(target):
			target.hit_stop = 4


func _pounce() -> void:
	if t == 1:
		flip = to.x < from.x  # hedef çağrıdan sonra verilir
	var k := clampf(float(t) / leap, 0.0, 1.0)
	position = from.lerp(to, k)
	if t == leap:
		main.shake(16)
		main.hit_freeze(5)
		main.fx.add_sprite(to, "fx_ring_gold", 320, Color.WHITE, 30, 0.35)
		main.burst(to, 150, GOLD)
		for e in main.targets():
			if e.position.distance_to(to) < 150.0:
				e.take_damage(damage, e.position - to, 1.6)
	if t >= leap + 18:
		remove()


func _draw() -> void:
	var key := "fx_ruh_kurt_idle%d" % (1 + (t / 10) % 2)
	var hop := 0.0
	var a := 0.82
	if mode == "pounce":
		var k := clampf(float(t) / leap, 0.0, 1.0)
		key = "fx_ruh_kurt_lunge"
		hop = sin(k * PI) * 90.0
		if t > leap:
			a *= 1.0 - float(t - leap) / 18.0
			key = "fx_ruh_kurt_howl"
	elif t < 36:
		key = "fx_ruh_kurt_howl"
		a *= clampf(t / 10.0, 0.0, 1.0)
	elif lunge_t > 0:
		key = "fx_ruh_kurt_lunge"
	if mode == "hunt" and life < 30:
		a *= life / 30.0
	var tex := Sprites.tex(key)
	if tex == null:
		return
	# Altın parıltı halkası ve gölge.
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.soft_texture(), Rect2(-60, -60, 120, 120), false, Color(GOLD, 0.25 * a))
	draw_set_transform(Vector2(0, -hop), 0, Vector2(-scale_k if flip else scale_k, scale_k))
	draw_texture_rect(tex, Rect2(-ANCHOR, CANVAS), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
