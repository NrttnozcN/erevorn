class_name Projectile
extends Actor
## Ok, büyü mermisi, delici ok ve ateş topu (entities.js:3859-3988, 5079-5227).

var kind := "arrow"
var dir := Vector2.RIGHT
var speed := 8.5
var life := 90
var damage := 10
var crit := false
var hit_pad := 8.0
var pierce_left := 0
var hits := {}
var arrow_key := "projectile_arrow_common"
var tint := Color.WHITE
## Görsel yükseklik: mermi silahın ucundan (yay, avuç) çıkar, kısa sürede hedef gövdesi hizasına iner.
## Çarpışma yer düzleminde (position) hesaplanır; yükseklik yalnızca çizimdir.
var lift := 0.0
const FLIGHT_LIFT := 22.0
## Buz aynası kabuğundan yansıyan mermi: oyuncuya döner, yarı hasar verir.
var reflected := false
const UNSHADED := preload("res://scripts/world/unshaded.tres")
const ARROW_FALLBACK := {"mythic": "legendary", "epic": "rare"}


func setup(p_kind: String, angle: float, p_damage: int, p_crit: bool) -> void:
	kind = p_kind
	dir = Vector2.from_angle(angle)
	damage = p_damage
	crit = p_crit
	match kind:
		"piercing":
			speed = 11.5; life = 70; hit_pad = 14.0; pierce_left = 4
		"fireball":
			speed = 3.4; life = 170; hit_pad = 18.0
	material = UNSHADED
	# Proje varsayılanı piksel süzme; küçültülen ok ve iz sprite'ları kumlanmasın.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var r: String = main.player.equipment.weapon.get("rarity", "common")
	tint = ItemData.fx_color(r)
	arrow_key = "projectile_arrow_%s" % r
	if Sprites.tex(arrow_key) == null:
		arrow_key = "projectile_arrow_%s" % ARROW_FALLBACK.get(r, "common")
	if kind == "piercing" and Sprites.tex("projectile_arrow_spirit"):
		arrow_key = "projectile_arrow_spirit"


func tick() -> void:
	lift = move_toward(lift, FLIGHT_LIFT, 2.5)
	position += dir * speed
	life -= 1
	if life <= 0 or not main.world.is_walkable(position):
		if kind == "fireball":
			_explode(null)
		remove()
		return
	if reflected:
		var p := main.player
		if p.alive() and position.distance_to(p.position) < 24.0:
			p.take_damage(damage, self)
			main.fx.add_sprite(position, "fx_spark", 40.0, Color(0.85, 0.95, 1.0), 12, 0.4, randf() * TAU)
			remove()
			return
		queue_redraw()
		return
	if not main.lanterns.is_empty() and main.hit_lanterns(position + Vector2(0, -30), hit_pad):
		remove()
		return
	for e in main.targets():
		if hits.has(e.get_instance_id()):
			continue
		var radius: float = (e.size if e is Enemy else e.box.x) / 2.0 + hit_pad
		if position.distance_to(e.position) >= radius:
			continue
		hits[e.get_instance_id()] = true
		_hit(e)
		if reflected:
			break
		if kind == "piercing" and pierce_left > 1:
			pierce_left -= 1
			continue
		remove()
		return
	queue_redraw()


func _hit(e: Node2D) -> void:
	var p := main.player
	var dmg := damage
	match kind:
		"arrow":
			pass
		"spell":
			if p.roll_crit():
				dmg *= 2
				crit = true
		"piercing":
			if hits.size() > 1:
				dmg = int(dmg * 0.6)
			if e is Enemy:
				e.marked = 360
			if crit:
				p.heal(2)
		"fireball":
			_explode(e)
			return
	if e is Enemy and e.marked > 0:
		dmg = int(dmg * 1.25)
		e.marked = maxi(0, e.marked - 90)
	if e is Enemy and e.type == "buz_aynasi":
		if kind == "piercing":
			e.crack_shell()
		elif kind in ["arrow", "spell"] and e.mirrors(dir):
			_reflect(e, dmg)
			return
	if e is Enemy and e.deflects(dir):
		# Kristal sırt önden gelen mermiyi kısmen sektirir: yarım hasar ve küçük kıvılcım.
		dmg = maxi(1, int(dmg * 0.5))
		main.fx.add_sprite(e.position + Vector2(0, -22) - dir * 10, "fx_spark", 34.0, Color(0.85, 0.7, 1.0), 10, 0.5, randf() * TAU)
		main.float_text(e.position + Vector2(0, -50), "SEKTİ", Color(0.8, 0.7, 1.0))
	var knock := dir
	var mult := 1.5
	if kind == "spell":
		knock = Vector2(dir.x * 0.25, -randf_range(5, 8) / 8.0)
		mult = 1.0
	var killed: bool = e.take_damage(dmg, knock, mult)
	main.fx.add_sprite(e.position + Vector2(0, -24), "fx_spark", 70.0 if crit else 46.0, tint, 14, 0.4, randf() * TAU)
	if crit:
		main.float_text(e.position + Vector2(0, -60), "KRİTİK!", Color("ffd700"))
	if not killed:
		p.apply_weapon_effect(e, dmg)


## Ayna kabuk mermiyi geri yansıtır: oyuncuya doğru döner, yarı hasarla vurur.
func _reflect(e: Enemy, dmg: int) -> void:
	reflected = true
	damage = maxi(1, int(dmg * 0.5))
	dir = (main.player.position - position).normalized()
	life = 80
	tint = Color(0.8, 0.95, 1.0)
	main.fx.add_sprite(position, "fx_spark", 52.0, Color(0.9, 0.97, 1.0), 12, 0.5, randf() * TAU)
	main.float_text(e.position + Vector2(0, -60), "YANSIDI", Color(0.8, 0.94, 1.0))
	queue_redraw()


func _explode(direct: Node2D) -> void:
	main.burst(position, 58.0, Color(1.0, 0.45, 0.1))
	main.fx.add_sprite(position, "fx_explosion", 150.0, Color.WHITE, 22, 0.25)
	for e in main.targets():
		var d: float = e.position.distance_to(position)
		if e == direct or d < 58.0:
			var dmg := damage if e == direct else int(damage * 0.55)
			if e is Enemy:
				e.burned = 240
			e.take_damage(dmg, e.position - position, 1.2)


func _draw() -> void:
	var a := dir.angle()
	var up := Vector2(0, -lift)
	match kind:
		"arrow", "piercing":
			draw_set_transform(up, a)
			if kind == "piercing":
				if Sprites.tex("fx_trail_wind"):
					Sprites.draw_flat(self, "fx_trail_wind", Rect2(-78, -15, 78, 30), Color(1, 1, 1, 0.9))
				else:
					draw_line(Vector2(-30, 0), Vector2(0, 0), Color(1, 0.85, 0.3, 0.5), 4)
			elif Sprites.tex("fx_trail_w"):
				Sprites.draw_flat(self, "fx_trail_w", Rect2(-62, -10, 56, 20), Color(tint, 0.8))
			if Sprites.tex(arrow_key) and Sprites.tex(arrow_key).get_width() > Sprites.tex(arrow_key).get_height() * 2:
				Sprites.draw_flat(self, arrow_key, Rect2(-30, -5, 38, 9.5))
			else:
				Sprites.draw_flat(self, arrow_key, Rect2(-20, -20, 40, 40))
			draw_set_transform(Vector2.ZERO)
		"spell":
			if Sprites.tex("fx_orb_w"):
				draw_set_transform(up, a)
				Sprites.draw_flat(self, "fx_orb_w", Rect2(-66, -20, 80, 30), tint)
				draw_circle(Vector2(1, 0), 4, Color(1, 1, 1, 0.7))
				draw_set_transform(Vector2.ZERO)
			else:
				draw_circle(Vector2.ZERO, 9, Color(0.55, 0.25, 1.0, 0.35))
				draw_circle(Vector2.ZERO, 5, Color(0.85, 0.65, 1.0))
				draw_line(Vector2.ZERO, -dir * 18, Color(0.6, 0.3, 1.0, 0.5), 3)
		"fireball" when Sprites.tex("fx_fireball") != null:
			draw_set_transform(up, a)
			var pulse := 1.0 + 0.06 * sin(Time.get_ticks_msec() / 60.0)
			Sprites.draw_flat(self, "fx_fireball", Rect2(-80 * pulse, -18 * pulse, 96 * pulse, 36 * pulse))
			draw_set_transform(Vector2.ZERO)
		"fireball":
			var pulse := 1.0 + 0.15 * sin(Time.get_ticks_msec() / 60.0)
			draw_circle(Vector2.ZERO, 16 * pulse, Color(1, 0.35, 0.05, 0.35))
			draw_circle(Vector2.ZERO, 10, Color(1, 0.6, 0.1))
			draw_circle(Vector2.ZERO, 5, Color(1, 0.95, 0.6))
