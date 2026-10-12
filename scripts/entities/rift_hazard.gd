class_name RiftHazard
extends Actor
## Yokluk Alemi'nin tehlikeleri (bölge 9), diğer bölge tehlikelerinin kardeşi:
##   gaze    — Yokluk Gözü'nün bakışı: gözden oyuncuya ince hat kilitlenir ve yavaşça izler (tell), sonra kısa ışın: hasar + çarpıklık.
##   orbit   — Yörünge Taşı'nın taş halkası: taşlar merkezden dışa fırlar, menzilde geri döner; halkada boşluk var.
##   rift    — Boşluk Yiyici'nin yırtığı: oyuncunun altında camgöbeği yırtık açılır (tell), yaratık fırlayıp ısırır.
##   wave    — Nihil'in obsidyen parça dalgası: merkezden dışa genişleyen parça halkası; halkada 3 boşluk var.
##   tear    — Nihil'in yutan yırtığı (faz 2): zeminde girdap; içindekini merkeze çeker ve yakar.
##   beam    — Nihil'in bakış ışını: önce kilitlenir (tell), sonra uzun ışın oyuncuyu sınırlı hızla döndürerek izler.
## Bakış ve ışın, kaynağı (follow) izler; kaynak ölürse söner.

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const CYAN := Color(0.45, 0.95, 1.0)
const VOID := Color(0.6, 0.3, 1.0)
const GAZE_TELL := 54
const GAZE_FIRE := 16
const ORBIT_OUT := 50
const ORBIT_BACK := 34
const RIFT_TELL := 48
const RIFT_LIFE := 26
const WAVE_GROW := 90
const BEAM_TELL := 50
const BEAM_FIRE := 150
const BEAM_LEN := 520.0
const BEAM_TURN := 0.012

var kind := "gaze"
var radius := 30.0
var damage := 0
var t := 0
var life := GAZE_TELL + GAZE_FIRE
var follow: Node2D
## Bakış / ışın: açı (dünya), kaynağa göre çıkış noktası.
var ang := 0.0
var muzzle := Vector2(0, -30)
## Taş halkası / dalga: menzil, taş sayısı, boşluk açıları.
var reach := 220.0
var count := 10
var gaps: Array = []
var _cd := 0
var _hit_ids := {}
var _seed := randf() * TAU
## Dalga / yırtık isabetinin etkisi (bölge 9: çarpıklık).
var debuff := "warp"


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	match kind:
		"gaze": life = GAZE_TELL + GAZE_FIRE
		"orbit": life = ORBIT_OUT + ORBIT_BACK
		"rift": life = RIFT_TELL + RIFT_LIFE
		"wave": life = WAVE_GROW + 10
		"tear": life = 600
		"beam": life = BEAM_TELL + BEAM_FIRE
	position = center - Vector2(0, _sort_up())
	add_child(GlowLayer.make(_paint))
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = maxf(radius, 40.0) / 50.0
	l.color = CYAN if kind in ["gaze", "rift", "beam"] else VOID
	l.energy = 0.45
	l.position = Vector2(0, _sort_up())
	add_child(l)


func center() -> Vector2:
	return position + Vector2(0, _sort_up())


func _sort_up() -> float:
	return 8.0 if kind in ["gaze", "orbit", "wave", "beam"] else radius


func triggered() -> bool:
	match kind:
		"gaze": return t >= GAZE_TELL
		"rift": return t >= RIFT_TELL
		"beam": return t >= BEAM_TELL
	return true


func _feet(p: Player) -> Vector2:
	return p.position + Vector2(0, 14)


func _feet_in(at: Vector2, c: Vector2, r: float) -> bool:
	return ((at - c) * Vector2(1, 1.0 / 0.42)).length() < r


## Kaynağa göre ışının başlangıcı ve ucu (düğüme göre).
func _ray(length: float) -> Array:
	var a := muzzle
	if follow and is_instance_valid(follow):
		a = follow.position + muzzle - position
	return [a, a + Vector2.from_angle(ang) * length]


func _target_angle(p: Player) -> float:
	var r := _ray(1.0)
	# Işın oyuncunun ayağına iner (isabet de ayaktan ölçülür).
	return (_feet(p) - (position + r[0])).angle()


## Halkadaki i. taşın / parçanın açısı boşluğa düşüyor mu?
func _in_gap(a: float) -> bool:
	for g in gaps:
		if absf(angle_difference(g, a)) < 0.36:
			return true
	return false


func _ring_r() -> float:
	if kind == "wave":
		return 40.0 + (reach - 40.0) * clampf(float(t) / WAVE_GROW, 0.0, 1.0)
	if t < ORBIT_OUT:
		return 30.0 + (reach - 30.0) * sin(float(t) / ORBIT_OUT * PI * 0.5)
	return 30.0 + (reach - 30.0) * cos(float(t - ORBIT_OUT) / ORBIT_BACK * PI * 0.5)


func _warp(p: Player, dmg: int) -> void:
	if p.take_damage(dmg, self) and debuff != "":
		p.apply_debuff(debuff)


func tick() -> void:
	t += 1
	if _cd > 0:
		_cd -= 1
	var p := main.player
	if kind in ["gaze", "beam", "orbit"] and follow != null:
		if not is_instance_valid(follow) or (follow is Actor and follow.removed):
			remove()
			return
		if kind == "orbit":
			position = follow.position - Vector2(0, _sort_up())
	match kind:
		"gaze":
			if t < GAZE_TELL - 14 and p.alive():
				# Tell'in büyük kısmında hat oyuncuyu yavaşça izler, son anda kilitlenir.
				ang = lerp_angle(ang, _target_angle(p), 0.08)
			if t >= GAZE_TELL and _cd == 0 and p.alive():
				var r := _ray(360.0)
				var feet := _feet(p) - position
				if feet.distance_to(Geometry2D.get_closest_point_to_segment(feet, r[0], r[1])) < 20.0:
					_cd = 999
					_warp(p, damage)
		"beam":
			if p.alive():
				var want := _target_angle(p)
				if t < BEAM_TELL:
					ang = lerp_angle(ang, want, 0.15)
				else:
					var diff := angle_difference(ang, want)
					ang += clampf(diff, -BEAM_TURN, BEAM_TURN)
			if t >= BEAM_TELL and _cd == 0 and p.alive():
				var r := _ray(BEAM_LEN)
				var feet := _feet(p) - position
				if feet.distance_to(Geometry2D.get_closest_point_to_segment(feet, r[0], r[1])) < 22.0:
					_cd = 40
					_warp(p, damage)
		"orbit", "wave":
			var rr := _ring_r()
			if p.alive() and _cd == 0:
				var rel := (_feet(p) - center()) * Vector2(1, 1.0 / 0.6)
				if absf(rel.length() - rr) < 16.0 and not _in_gap(rel.angle()):
					_cd = 30
					if kind == "wave":
						_warp(p, damage)
					else:
						p.take_damage(damage, self)
		"rift":
			if t == RIFT_TELL:
				main.shake(6)
				main.burst(center() + Vector2(0, -10), radius * 1.2, CYAN)
				if p.alive() and _feet_in(_feet(p), center(), radius):
					_warp(p, damage)
		"tear":
			if p.alive() and t > 20 and t < life - 20:
				var rel := _feet(p) - center()
				var dd := (rel * Vector2(1, 1.0 / 0.42)).length()
				if dd < radius * 1.6 and p.dash_left == 0:
					# Yutan girdap: kenara yakınken bile içeri çeker.
					p.position = main.world.move_circle(p.position, -rel.normalized() * 0.7, Player.RADIUS)
				if dd < radius and _cd == 0:
					_cd = 45
					if p.take_damage(damage, self):
						p.apply_debuff("void")
	if t >= life:
		remove()
		return
	queue_redraw()


func _blot(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-r, -r, r * 2.0, r * 2.0), false, col)
	draw_set_transform(Vector2.ZERO)


func _flat(key: String, c: Vector2, w: float, a: float, rot := 0.0) -> bool:
	var tex := Sprites.tex(key)
	if tex == null:
		return false
	var h := w * tex.get_height() / tex.get_width()
	draw_set_transform(c, rot, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-w / 2, -h / 2, w, h), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	return true


func _draw() -> void:
	var c := Vector2(0, _sort_up())
	match kind:
		"orbit", "wave":
			var rr := _ring_r()
			var a := clampf(float(life - t) / 10.0, 0.0, 1.0) * clampf(float(t) / 4.0, 0.0, 1.0)
			var n := count if kind == "orbit" else maxi(12, int(rr * TAU / 40.0))
			for i in n:
				var aa := _seed + i * TAU / n
				if _in_gap(aa):
					continue
				var at := c + Vector2(cos(aa), sin(aa) * 0.6) * rr + Vector2(0, -16)
				if kind == "orbit":
					if not _flat("fx_rift_rock", at, 26.0, a, t * 0.2 + i):
						draw_circle(at, 7.0, Color(0.15, 0.1, 0.2, a))
				else:
					if not _flat("fx_rift_shard", at, 34.0, a, aa):
						draw_line(at - Vector2.from_angle(aa) * 10.0, at + Vector2.from_angle(aa) * 10.0, Color(0.1, 0.05, 0.15, a), 4.0)
		"rift":
			var k := clampf(float(t) / RIFT_TELL, 0.0, 1.0)
			var a := clampf(float(life - t) / 12.0, 0.0, 1.0)
			_blot(c, radius * (0.5 + 0.7 * k), Color(0.05, 0.0, 0.1, 0.4 + 0.3 * k))
			_flat("fx_rift_tear", c, radius * 2.2 * (0.4 + 0.6 * k), a)
			if t >= RIFT_TELL:
				_flat("fx_rift_burst", c + Vector2(0, -radius * 0.8), radius * 2.4, a)
		"tear":
			var a := clampf(float(t) / 20.0, 0.0, 1.0) * clampf(float(life - t) / 20.0, 0.0, 1.0)
			_flat("fx_rift_pit", c, radius * 2.6, a, sin(t * 0.02) * 0.05)


func _paint(g: GlowLayer) -> void:
	var c := Vector2(0, _sort_up())
	var now := Time.get_ticks_msec() / 1000.0
	match kind:
		"gaze", "beam":
			var tell := GAZE_TELL if kind == "gaze" else BEAM_TELL
			var length := 360.0 if kind == "gaze" else BEAM_LEN
			var r := _ray(length)
			if t < tell:
				var k := float(t) / tell
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				g.streak(PackedVector2Array([r[0], r[1]]), 1.0 + k, Color(CYAN, (0.2 + 0.5 * k) * blink))
				g.glow(r[0], 8.0 + 10.0 * k, Color(CYAN, 0.4 + 0.4 * k))
			else:
				var a := 1.0 if kind == "beam" else clampf(float(life - t) / 8.0, 0.0, 1.0)
				g.streak(PackedVector2Array([r[0], r[1]]), 7.0, Color(CYAN, 0.45 * a))
				g.streak(PackedVector2Array([r[0], r[1]]), 2.2, Color(0.9, 1.0, 1.0, 0.85 * a))
				g.glow(r[0], 20.0, Color(CYAN, 0.6 * a))
				for j in 6:
					var u := fmod(now * 2.0 + j / 6.0, 1.0)
					g.glow((r[0] as Vector2).lerp(r[1], u), 10.0, Color(CYAN, 0.25 * a))
		"orbit", "wave":
			var rr := _ring_r()
			g.draw_set_transform(c + Vector2(0, -10), 0, Vector2(1, 0.6))
			g.ring(Vector2.ZERO, rr, 1.4, Color(VOID if kind == "wave" else CYAN, 0.35 * clampf(float(life - t) / 10.0, 0.0, 1.0)))
			g.draw_set_transform(Vector2.ZERO)
		"rift":
			if t < RIFT_TELL:
				var k := float(t) / RIFT_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius, 2.0, Color(CYAN, (0.35 + 0.55 * k) * blink))
				g.glow(Vector2.ZERO, radius, Color(CYAN, 0.08 + 0.18 * k))
				g.draw_set_transform(Vector2.ZERO)
			else:
				var fl := clampf(1.0 - float(t - RIFT_TELL) / 12.0, 0.0, 1.0)
				g.glow(c, radius * 1.3, Color(CYAN, 0.5 * fl))
		"tear":
			var a := clampf(float(t) / 20.0, 0.0, 1.0) * clampf(float(life - t) / 20.0, 0.0, 1.0)
			var k := 0.5 + 0.5 * sin(now * 3.0 + _seed)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.glow(Vector2.ZERO, radius * 1.3, Color(VOID, (0.15 + 0.1 * k) * a))
			g.ring(Vector2.ZERO, radius * 1.05, 1.6, Color(CYAN, 0.45 * a))
			g.draw_set_transform(Vector2.ZERO)
