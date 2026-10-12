class_name SkyHazard
extends Actor
## Gökyüzü Kalesi'nin tehlikeleri (bölge 8), FrostHazard ve VoidHazard'ın kardeşi:
##   lance   — Konsey Bilgesi'nin ışık mızrağı: yerde altın daire dolar (tell), tepeden ışık mızrağı iner.
##   gravity — Rün Bekçisi'nin yerçekimi rünü: ayağın altında dönen altın rün (tell), sonra bastırır: hasar + ağırlık.
##   line    — Valerius'un hüküm sütunu: yerde altın çizgi dolar (tell), sonra çizgi boyunca ışık sütunları fışkırır.
##   blade   — Valerius'un çift uçlu ışık kılıcı: hat boyunca gidip geri döner (hat tell'i, sonra uçuş).
##   sweep   — Valerius'un son hükmü (faz 3): çevresinde yavaşça dönen iki ışık hattı; boss'u izler.
## fake: Konsey Bilgesi'nin ayna kopyalarının mızrakları (soluk, hasarsız).

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const GOLD := Color(1.0, 0.82, 0.35)
const GOLD_WHITE := Color(1.0, 0.96, 0.82)
const LANCE_TELL := 54
const LANCE_LIFE := 30
const GRAV_TELL := 54
const GRAV_LIFE := 30
const LINE_TELL := 60
const LINE_LIFE := 30
const BLADE_TELL := 48
const BLADE_FLY := 32
const SWEEP_TELL := 60
const SWEEP_LIFE := 360
const SWEEP_LEN := 300.0

var kind := "lance"
var radius := 30.0
var damage := 0
var t := 0
var life := LANCE_TELL + LANCE_LIFE
var fake := false
var _cd := 0
var _hit := false
var _hits := 0
var _seed := randf() * TAU
## Çizgi / kılıç: uçlar (düğüme göre).
var _a := Vector2.ZERO
var _b := Vector2.ZERO
## Pervane: izlediği aktör, açı ve dönüş hızı.
var follow: Node2D
var ang := 0.0
var spin := 0.011


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	match kind:
		"lance": life = LANCE_TELL + LANCE_LIFE
		"gravity": life = GRAV_TELL + GRAV_LIFE
		"sweep": life = SWEEP_TELL + SWEEP_LIFE
	position = center - Vector2(0, _sort_up())
	add_child(GlowLayer.make(_paint))
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = (radius if kind != "sweep" else SWEEP_LEN) / 50.0
	l.color = GOLD
	l.energy = 0.0 if fake else 0.45
	l.position = Vector2(0, _sort_up())
	add_child(l)


## Hüküm sütunu ve ışık kılıcı: start'tan dir yönünde length boyunca.
func setup_line(p_kind: String, start: Vector2, dir: Vector2, length: float, p_damage: int) -> void:
	kind = p_kind
	damage = p_damage
	radius = 16.0
	life = LINE_TELL + LINE_LIFE if kind == "line" else BLADE_TELL + BLADE_FLY * 2 + 6
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var end := start + dir * length
	position = Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - 10.0)
	_a = start - position
	_b = end - position
	add_child(GlowLayer.make(_paint))
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = length / 300.0 + 0.4
	l.color = GOLD
	l.energy = 0.5
	l.position = (_a + _b) * 0.5
	add_child(l)


func center() -> Vector2:
	return position + Vector2(0, _sort_up())


func _sort_up() -> float:
	return 8.0 if kind == "sweep" else radius


func triggered() -> bool:
	match kind:
		"lance": return t >= LANCE_TELL
		"gravity": return t >= GRAV_TELL
		"line": return t >= LINE_TELL
		"blade": return t >= BLADE_TELL
		"sweep": return t >= SWEEP_TELL
	return true


func _feet_in(at: Vector2, c: Vector2, r: float) -> bool:
	var d := (at + Vector2(0, 14) - c) * Vector2(1, 1.0 / 0.42)
	return d.length() < r


func _feet_near_segment(p: Player, a: Vector2, b: Vector2, w: float) -> bool:
	var feet := p.position + Vector2(0, 14) - position
	return feet.distance_to(Geometry2D.get_closest_point_to_segment(feet, a, b)) < w


## Kılıcın şu anki yeri (düğüme göre): tell'de başta, sonra uca gidip geri döner.
func blade_pos() -> Vector2:
	if t < BLADE_TELL:
		return _a
	var u := float(t - BLADE_TELL) / BLADE_FLY
	if u <= 1.0:
		return _a.lerp(_b, sin(u * PI * 0.5))
	return _b.lerp(_a, 1.0 - cos(minf(u - 1.0, 1.0) * PI * 0.5))


## Pervanenin iki hattının uçları (düğüme göre).
func sweep_arms() -> Array:
	var c := Vector2(0, _sort_up())
	var d := Vector2.from_angle(ang) * Vector2(1, 0.6)
	return [[c - d * 30.0, c - d * SWEEP_LEN], [c + d * 30.0, c + d * SWEEP_LEN]]


func tick() -> void:
	t += 1
	if _cd > 0:
		_cd -= 1
	var p := main.player
	match kind:
		"lance":
			if t == LANCE_TELL and not fake:
				main.shake(3)
				if p.alive() and _feet_in(p.position, center(), radius):
					p.take_damage(damage, self)
		"gravity":
			if t == GRAV_TELL:
				main.shake(5)
				if p.alive() and _feet_in(p.position, center(), radius):
					if p.take_damage(damage, self):
						p.apply_debuff("heavy")
		"line":
			if t == LINE_TELL:
				main.shake(5)
			if t >= LINE_TELL and t < LINE_TELL + 10 and not _hit and p.alive() and _feet_near_segment(p, _a, _b, 22.0):
				_hit = true
				p.take_damage(damage, self)
		"blade":
			if t >= BLADE_TELL and p.alive() and _cd == 0:
				var at := blade_pos()
				var feet := p.position + Vector2(0, -10) - position
				if feet.distance_to(at) < 30.0:
					_cd = 30
					p.take_damage(damage, self)
		"sweep":
			if follow == null or not is_instance_valid(follow) or (follow is Actor and follow.removed):
				remove()
				return
			position = follow.position + Vector2(0, 6) - Vector2(0, _sort_up())
			ang += spin * (0.35 if t < SWEEP_TELL else 1.0)
			if t >= SWEEP_TELL and _cd == 0 and p.alive():
				for arm in sweep_arms():
					if _feet_near_segment(p, arm[0], arm[1], 18.0):
						_cd = 45
						p.take_damage(damage, self)
						break
	if t >= life:
		remove()
		return
	queue_redraw()


func _blot(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-r, -r, r * 2.0, r * 2.0), false, col)
	draw_set_transform(Vector2.ZERO)


func _sprite(key: String, base: Vector2, h: float, a: float, rot := 0.0, flat := false) -> bool:
	var tex := Sprites.tex(key)
	if tex == null:
		return false
	var w := h * tex.get_width() / tex.get_height()
	# Yere yatık doku zaten perspektifle çizildi: ek basıklık yok.
	draw_set_transform(base, rot, Vector2.ONE)
	if flat:
		draw_texture_rect(tex, Rect2(-w / 2, -h / 2, w, h), false, Color(1, 1, 1, a))
	else:
		draw_texture_rect(tex, Rect2(-w / 2, -h, w, h), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	return true


func _draw() -> void:
	var c := Vector2(0, _sort_up())
	var fa := 0.4 if fake else 1.0
	match kind:
		"lance":
			if t >= LANCE_TELL - 10:
				# Tepeden inen ışık mızrağı, sonra yere saplanmış hali söner.
				var k := clampf(float(t - (LANCE_TELL - 10)) / 10.0, 0.0, 1.0)
				var a := clampf(float(life - t) / 16.0, 0.0, 1.0) * fa
				_sprite("fx_light_lance", c + Vector2(0, 6 - 220.0 * (1.0 - k)), 92.0, a)
		"gravity":
			var k := clampf(float(t) / GRAV_TELL, 0.0, 1.0)
			var a := clampf(float(life - t) / 16.0, 0.0, 1.0)
			var pulse := 1.0 + 0.04 * sin(t * 0.3)
			_sprite("fx_gravity_rune", c, radius * 2.0 * 0.79 * pulse, (0.35 + 0.65 * k) * a, 0.0, true)
		"line":
			if t >= LINE_TELL:
				var a := clampf(float(life - t) / 16.0, 0.0, 1.0)
				var n := maxi(3, int((_b - _a).length() / 40.0))
				for i in n:
					var u := (i + 0.5) / n
					var rise := clampf(float(t - LINE_TELL) * 0.5 - u * 2.0, 0.0, 1.0)
					_sprite("fx_light_pillar", _a.lerp(_b, u) + Vector2(0, 6), 80.0 * rise, a)
		"blade":
			if t >= BLADE_TELL - 6:
				var at := blade_pos()
				_sprite("fx_light_blade", at + Vector2(0, -10), 64.0, 1.0, t * 0.45, false)


# ── Parıltılar (toplamalı) ───────────────────────────────────────────

func _paint(g: GlowLayer) -> void:
	var c := Vector2(0, _sort_up())
	var now := Time.get_ticks_msec() / 1000.0
	var fa := 0.4 if fake else 1.0
	match kind:
		"lance":
			if t < LANCE_TELL:
				var k := float(t) / LANCE_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius, 2.0, Color(GOLD, (0.35 + 0.55 * k) * blink * fa))
				g.ring(Vector2.ZERO, radius * maxf(k, 0.05), 1.3, Color(GOLD_WHITE, 0.6 * fa))
				g.glow(Vector2.ZERO, radius, Color(GOLD, (0.06 + 0.16 * k) * fa))
				g.draw_set_transform(Vector2.ZERO)
			else:
				var fl := clampf(1.0 - float(t - LANCE_TELL) / 12.0, 0.0, 1.0)
				g.glow(c, radius * 1.4, Color(GOLD_WHITE, 0.55 * fl * fa))
				g.glow(c + Vector2(0, -40), 18.0, Color(GOLD, 0.3 * fa * clampf(float(life - t) / 16.0, 0.0, 1.0)))
		"gravity":
			var k := clampf(float(t) / GRAV_TELL, 0.0, 1.0)
			if t < GRAV_TELL:
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius, 1.8, Color(GOLD, (0.3 + 0.5 * k) * blink))
				g.glow(Vector2.ZERO, radius * 1.05, Color(GOLD, 0.06 + 0.16 * k))
				g.draw_set_transform(Vector2.ZERO)
			else:
				var fl := clampf(1.0 - float(t - GRAV_TELL) / 12.0, 0.0, 1.0)
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.glow(Vector2.ZERO, radius * 1.3, Color(GOLD_WHITE, 0.55 * fl))
				g.draw_set_transform(Vector2.ZERO)
		"line":
			if t < LINE_TELL:
				var k := float(t) / LINE_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				var reach := 0.25 + 0.75 * k
				g.streak(PackedVector2Array([_a, _a.lerp(_b, reach)]), 1.4, Color(GOLD, (0.25 + 0.55 * k) * blink))
				for j in 16:
					var u := float(j + 1) / 16
					if u > reach:
						break
					g.glow(_a.lerp(_b, u), 4.0 + 2.0 * k, Color(GOLD, (0.25 + 0.45 * k) * blink))
			else:
				var a := clampf(float(life - t) / 16.0, 0.0, 1.0)
				g.streak(PackedVector2Array([_a, _b]), 5.0, Color(GOLD, 0.45 * a))
				g.streak(PackedVector2Array([_a, _b]), 1.8, Color(GOLD_WHITE, 0.8 * a))
		"blade":
			if t < BLADE_TELL:
				# Gidiş-dönüş hattı: soluk altın noktalar uca kadar dolar.
				var k := float(t) / BLADE_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				for j in 14:
					var u := float(j + 1) / 14
					if u > 0.3 + 0.7 * k:
						break
					g.glow(_a.lerp(_b, u) + Vector2(0, -10), 3.5, Color(GOLD, (0.25 + 0.45 * k) * blink))
			else:
				var at := blade_pos() + Vector2(0, -10)
				g.glow(at, 30.0, Color(GOLD, 0.45))
				g.glow(at, 10.0, Color(GOLD_WHITE, 0.8))
		"sweep":
			var on := t >= SWEEP_TELL
			var a := clampf(float(life - t) / 20.0, 0.0, 1.0)
			for arm in sweep_arms():
				if on:
					g.streak(PackedVector2Array([arm[0], arm[1]]), 5.0, Color(GOLD, 0.45 * a))
					g.streak(PackedVector2Array([arm[0], arm[1]]), 1.6, Color(GOLD_WHITE, 0.8 * a))
				else:
					var k := float(t) / SWEEP_TELL
					var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
					g.streak(PackedVector2Array([arm[0], arm[1]]), 1.2, Color(GOLD, (0.2 + 0.4 * k) * blink))
