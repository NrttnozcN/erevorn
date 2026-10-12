class_name GoblinHazard
extends Actor
## Goblin Yurdu'nun yerdeki tehlikeleri (bölge 3):
##   bomb  — Bombacı'nın lağım bombası: düşeceği yerde ~1 sn kırmızı/sarı uyarı dairesi dolar, sonra patlar
##           ve yerde kısa süren zehir gölü bırakır. Ölen bombacının düşürdüğü bomba goblinleri de yakar.
##   pool  — zehir gölü: üstünde duran oyuncu zehirlenir.
##   shock — Kölebaşı'nın yere vuruşundan yayılan küçük şok dalgası.
## Y sıralı katmanda zemin işareti aktörlerin altında kalsın diye düğüm dairenin üst kenarına konur,
## çizim ve vuruş merkezi `center` (aşağı kaydırılmış) üstünden yapılır.

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const POISON := Color(0.72, 1.0, 0.18)
const BOMB_FUSE := 60
const POOL_LIFE := 180

var kind := "bomb"
var radius := 44.0
var damage := 10
## Patlama goblinleri de vurur mu (ölen bombacının bombası).
var hurts_enemies := false
## Fırlatılan bombanın çıktığı yer (dünya koordinatı); boşsa bomba olduğu yerde yanar.
var from := Vector2.INF
var t := 0
var life := BOMB_FUSE
var _hit_player := false
var _poison_cd := 0
var _seed := randf() * TAU


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	match kind:
		"bomb": life = BOMB_FUSE
		"pool": life = POOL_LIFE
		"shock": life = 16
	position = center - Vector2(0, _ry())


func center() -> Vector2:
	return position + Vector2(0, _ry())


func _ry() -> float:
	return radius * 0.42


func tick() -> void:
	t += 1
	match kind:
		"bomb":
			if t >= life:
				_explode()
				return
		"pool":
			if _poison_cd > 0:
				_poison_cd -= 1
			var p := main.player
			var d := (p.position - center()) * Vector2(1, 1.0 / 0.42)
			if _poison_cd == 0 and p.alive() and d.length() < radius * 0.85:
				_poison_cd = 30
				p.apply_debuff("poison")
				main.float_text(p.position + Vector2(0, -56), "ZEHİR", POISON)
			if t >= life:
				remove()
				return
		"shock":
			var r := _shock_r()
			var p := main.player
			var d := p.position.distance_to(center())
			if not _hit_player and p.alive() and absf(d - r) < 18.0:
				_hit_player = true
				if p.take_damage(damage, self):
					p.apply_debuff("slow")
			if t >= life:
				remove()
				return
	queue_redraw()


func _shock_r() -> float:
	return radius * clampf(float(t) / life, 0.0, 1.0)


func _explode() -> void:
	var c := center()
	main.shake(10)
	main.burst(c, radius, Color(1.0, 0.55, 0.15))
	main.fx.add_sprite(c + Vector2(0, -14), "fx_explosion", radius * 2.6, Color(1.0, 0.95, 0.7), 22, 0.25)
	var p := main.player
	if p.alive() and p.position.distance_to(c) < radius:
		p.take_damage(damage, self)
	if hurts_enemies:
		for e in main.enemies.duplicate():
			if is_instance_valid(e) and not e.removed and e.position.distance_to(c) < radius:
				e.take_damage(damage, e.position - c, 1.2)
	var pool := GoblinHazard.new()
	pool.setup("pool", c, radius * 0.85, 0)
	main._spawn(pool, pool.position)
	remove()


func _draw() -> void:
	var c := Vector2(0, _ry())
	match kind:
		"bomb": _draw_bomb(c)
		"pool": _draw_pool(c)
		"shock": _draw_shock(c)


## Uyarı dairesi: kırmızı kenar, içten dışa dolan sarı; bomba yayla havada gelir, fitili kıvılcım saçar.
func _draw_bomb(c: Vector2) -> void:
	var k := clampf(float(t) / life, 0.0, 1.0)
	var blink := 0.65 + 0.35 * sin(t * (0.35 + k * 0.6))
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.15, 0.05, 0.16 * blink))
	draw_circle(Vector2.ZERO, radius * k, Color(1.0, 0.82, 0.15, 0.30))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1.0, 0.2, 0.08, 0.9 * blink), 3.0)
	draw_arc(Vector2.ZERO, radius * k, 0, TAU, 32, Color(1.0, 0.9, 0.3, 0.8), 1.6)
	draw_set_transform(Vector2.ZERO)
	var at := c
	if from != Vector2.INF:
		# Uçuş: ilk %70'te yay çizerek iner, kalanında yerde fitil yanar.
		var f := clampf(k / 0.7, 0.0, 1.0)
		at = (from - position).lerp(c, f) + Vector2(0, -sin(f * PI) * 70.0)
	draw_circle(at + Vector2(0, -6), 7.0, Color(0.1, 0.09, 0.08))
	draw_circle(at + Vector2(-2, -8), 2.2, Color(0.5, 0.45, 0.4, 0.7))
	var spark := at + Vector2(4, -14)
	draw_circle(spark, 2.5 + 1.5 * sin(t * 0.9), Color(1.0, 0.85, 0.3))
	draw_circle(spark, 5.0 + 2.0 * sin(t * 0.7), Color(1.0, 0.5, 0.1, 0.35))


## Zehir gölü: sarı-yeşil, kenarı koyu, yüzeyinde kabarcıklar; son saniyede söner.
func _draw_pool(c: Vector2) -> void:
	var fade := clampf(float(life - t) / 50.0, 0.0, 1.0) * clampf(t / 10.0, 0.0, 1.0)
	var pulse := 0.85 + 0.15 * sin(t * 0.12 + _seed)
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_circle(Vector2.ZERO, radius * 1.08, Color(0.12, 0.16, 0.02, 0.55 * fade))
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.7, 0.05, 0.55 * fade * pulse))
	draw_circle(Vector2(-radius * 0.15, -radius * 0.1), radius * 0.6, Color(0.8, 1.0, 0.25, 0.35 * fade * pulse))
	for i in 5:
		var a := _seed + i * 1.3
		var bt := fmod(t * 0.03 + i * 0.37, 1.0)
		var bp := Vector2(cos(a), sin(a)) * radius * (0.2 + 0.55 * fmod(i * 0.61, 1.0))
		draw_circle(bp, 2.0 + 3.0 * bt, Color(0.9, 1.0, 0.45, 0.6 * (1.0 - bt) * fade))
	draw_set_transform(Vector2.ZERO)


func _draw_shock(c: Vector2) -> void:
	var r := _shock_r()
	var a := 1.0 - float(t) / life
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(0.85, 0.6, 1.0, 0.85 * a), 5.0)
	draw_arc(Vector2.ZERO, r * 0.8, 0, TAU, 40, Color(1.0, 0.85, 0.6, 0.5 * a), 2.0)
	draw_set_transform(Vector2.ZERO)
