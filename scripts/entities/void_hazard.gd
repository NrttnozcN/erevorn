class_name VoidHazard
extends Actor
## Şeytan Kalesi'nin yerdeki tehlikeleri (bölge 7), FrostHazard ve ForestHazard'ın kardeşi:
##   portal  — yerde açılan küçük yokluk portalı (Gölge Yürüyücü'nün çıkacağı yer; tell halkası). Kendi başına zarar vermez.
##   crack   — Malakor'un çekiç yarığı: start'tan dir yönünde mor alevli yarık; üstünde duran yokluk yanığı alır.
##   beam    — portal ışını: portal açılır, hat boyunca ince çizgi dolar (tell), sonra mor alev ışını fışkırır.
##   shadow  — dalış gölgesi (Gargoyl, Malakor): yerde büyüyen koyu gölge (tell), sonra çakılma: hasar + itme.
##   ring    — Malakor'un çevresinde yanan mor alev halkası (faz 3): halkaya değen yanar. Boss'u izler (follow).
##   seal    — Kan Mühürü (boss arenası): 3 vuruşta kırılır. Main.lanterns listesinde durur, light_up() bir vuruştur.
## Y sıralı katmanda zemin işareti aktörlerin altında kalsın diye düğüm dairenin bir yarıçap üstüne konur.

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const VOID := Color(0.62, 0.28, 1.0)
const VOID_DARK := Color(0.16, 0.05, 0.24)
const BLOOD := Color(1.0, 0.18, 0.15)
const PORTAL_LIFE := 60
const CRACK_LIFE := 200
const BEAM_TELL := 60
const BEAM_LIFE := 26
const SHADOW_TELL := 48
const SHADOW_LIFE := 20
const SEAL_HP := 3
const SEAL_H := 40.0

var kind := "portal"
var radius := 30.0
var damage := 0
var t := 0
var life := PORTAL_LIFE
var _cd := 0
var _hit := false
var _seed := randf() * TAU
## Yarık ve ışın: uçlar (düğüme göre).
var _a := Vector2.ZERO
var _b := Vector2.ZERO
## Alev halkası: izlediği aktör.
var follow: Node2D
## Kan Mühürü: kalan dayanıklılık.
var seal_hp := SEAL_HP
## İsabetin bulaştırdığı etki (bölge 7: yokluk yanığı; başka bölgeler kendi etkisini verir, "" = yok).
var debuff := "void"
## Rengi (bölge 7 mor yokluk; başka bölgelerde değişebilir).
var tint := VOID
var _light: PointLight2D


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	match kind:
		"portal": life = PORTAL_LIFE
		"shadow": life = SHADOW_TELL + SHADOW_LIFE
		"ring": life = 1 << 30
		"seal": life = 1 << 30
	position = center - Vector2(0, _sort_up())
	add_child(GlowLayer.make(_paint))
	_light = PointLight2D.new()
	_light.texture = Atmosphere.light_texture()
	_light.texture_scale = radius / 50.0
	_light.color = BLOOD if kind == "seal" else VOID
	_light.energy = 0.5
	_light.position = Vector2(0, _sort_up())
	add_child(_light)


## Yarık / ışın: start'tan dir yönünde length boyunca.
func setup_line(p_kind: String, start: Vector2, dir: Vector2, length: float, p_damage: int) -> void:
	kind = p_kind
	damage = p_damage
	radius = 16.0
	life = CRACK_LIFE if kind == "crack" else BEAM_TELL + BEAM_LIFE
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var end := start + dir * length
	position = Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - 10.0)
	_a = start - position
	_b = end - position
	add_child(GlowLayer.make(_paint))
	for u in [0.2, 0.8]:
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = length / 320.0 + 0.3
		l.color = VOID
		l.energy = 0.5
		l.position = _a.lerp(_b, u)
		add_child(l)
		_light = l


func center() -> Vector2:
	return position + Vector2(0, _sort_up())


func _sort_up() -> float:
	return 8.0 if kind == "ring" else radius


## Kan Mühürü: vuruş noktası (taşın üstü).
func head() -> Vector2:
	return center() + Vector2(0, -SEAL_H * 0.5)


func warms(_at: Vector2) -> bool:
	return false


func intact() -> bool:
	return kind == "seal" and seal_hp > 0


## Ok / kılıç Kan Mühürü'ne değdi: bir vuruş.
func light_up() -> void:
	if kind != "seal" or seal_hp <= 0 or _cd > 0:
		return
	_cd = 12
	seal_hp -= 1
	main.burst(head(), 30, BLOOD)
	if seal_hp == 0:
		main.shake(8)
		main.burst(head(), 60, BLOOD)
		main.float_text(head() + Vector2(0, -36), "MÜHÜR KIRILDI", BLOOD.lightened(0.3))
	else:
		main.float_text(head() + Vector2(0, -30), "%d/%d" % [SEAL_HP - seal_hp, SEAL_HP], BLOOD.lightened(0.35))


func triggered() -> bool:
	match kind:
		"beam": return t >= BEAM_TELL
		"shadow": return t >= SHADOW_TELL
	return true


func _feet_in(at: Vector2, c: Vector2, r: float) -> bool:
	var d := (at + Vector2(0, 14) - c) * Vector2(1, 1.0 / 0.42)
	return d.length() < r


func _near_line(p: Player, w: float) -> bool:
	var feet := p.position + Vector2(0, 14) - position
	var q := Geometry2D.get_closest_point_to_segment(feet, _a, _b)
	return feet.distance_to(q) < w


func _hurt(p: Player, dmg: int) -> void:
	if p.take_damage(dmg, self) and debuff != "":
		p.apply_debuff(debuff)


func tick() -> void:
	t += 1
	if _cd > 0:
		_cd -= 1
	var p := main.player
	match kind:
		"crack":
			if _cd == 0 and t > 6 and t < life - 20 and p.alive() and _near_line(p, 18.0):
				_cd = 50
				_hurt(p, damage)
		"beam":
			if t == BEAM_TELL:
				main.shake(5)
			if t >= BEAM_TELL and t < BEAM_TELL + 14 and not _hit and p.alive() and _near_line(p, 22.0):
				_hit = true
				_hurt(p, damage)
		"shadow":
			if t == SHADOW_TELL:
				main.shake(12)
				main.burst(center() + Vector2(0, -8), radius, VOID)
				if p.alive() and _feet_in(p.position, center(), radius):
					_hurt(p, damage)
					var push := (p.position - center()).normalized() * 26.0
					p.position = main.world.move_circle(p.position, push, Player.RADIUS)
		"ring":
			if follow == null or not is_instance_valid(follow) or (follow is Actor and follow.removed):
				remove()
				return
			position = follow.position + Vector2(0, 6) - Vector2(0, _sort_up())
			if _cd == 0 and p.alive():
				var rel := (p.position + Vector2(0, 14) - center()) * Vector2(1, 1.0 / 0.42)
				if absf(rel.length() - radius) < 16.0:
					_cd = 40
					_hurt(p, damage)
		"seal":
			_light.energy = lerpf(_light.energy, 0.7 if seal_hp > 0 else 0.0, 0.1)
	if t >= life:
		remove()
		return
	queue_redraw()


func _fade(fade_in: int, fade_out: int) -> float:
	return clampf(float(t) / fade_in, 0.0, 1.0) * clampf(float(life - t) / fade_out, 0.0, 1.0)


func _blot(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-r, -r, r * 2.0, r * 2.0), false, col)
	draw_set_transform(Vector2.ZERO)


## Yere yatık boyalı efekt (portal, mühür, krater, halka): genişliği w, a ile söner.
func _flat(key: String, c: Vector2, w: float, a: float) -> bool:
	var tex := Sprites.tex(key)
	if tex == null:
		return false
	var h := w * tex.get_height() / tex.get_width()
	draw_texture_rect(tex, Rect2(c.x - w / 2, c.y - h / 2, w, h), false, Color(1, 1, 1, a))
	return true


# ── Çizim (normal karışım) ───────────────────────────────────────────

func _draw() -> void:
	var c := Vector2(0, _sort_up())
	match kind:
		"portal":
			var a := _fade(8, 14)
			_blot(c, radius * 1.2, Color(VOID_DARK, 0.6 * a))
			_flat("fx_void_portal", c, radius * 2.4 * (0.5 + 0.5 * clampf(float(t) / 12.0, 0.0, 1.0)), a)
		"crack":
			var a := _fade(4, 30)
			var span := (_b - _a).length()
			var tex := Sprites.tex("fx_void_crack")
			if tex:
				# Yarık dokusu hat boyunca parça parça döşenir.
				var dir := (_b - _a) / maxf(span, 1.0)
				var seg := 70.0
				var n := maxi(1, int(ceil(span / seg)))
				for i in n:
					var m := _a + dir * (i + 0.5) * span / n
					draw_set_transform(m, dir.angle(), Vector2(1, 0.7))
					var w := span / n * 1.15
					var h := w * tex.get_height() / tex.get_width()
					draw_texture_rect(tex, Rect2(-w / 2, -h / 2, w, h), false, Color(1, 1, 1, a))
				draw_set_transform(Vector2.ZERO)
			else:
				draw_line(_a, _b, Color(0.08, 0.02, 0.12, a), 8.0, true)
		"beam":
			if t < BEAM_TELL:
				_flat("fx_void_portal", _a, 54.0, clampf(float(t) / 10.0, 0.0, 1.0))
		"shadow":
			if t < SHADOW_TELL:
				var k := float(t) / SHADOW_TELL
				_blot(c, radius * (0.3 + 0.8 * k), Color(0.02, 0.0, 0.04, 0.3 + 0.45 * k))
			else:
				var a := clampf(float(life - t) / 14.0, 0.0, 1.0)
				_flat("fx_void_crater", c + Vector2(0, -4), radius * 2.0, a)
		"ring":
			_flat("fx_void_ring", c, radius * 2.3, 1.0)
		"seal":
			_blot(c, 30.0, Color(0, 0, 0, 0.35))
			if seal_hp > 0:
				if not Sprites.draw_grounded(self, "prop_z7_seal", SEAL_H, c.y + 4, Color(1.1, 1.0, 1.0) if _cd > 0 else Color.WHITE):
					draw_circle(c, 18.0, Color(0.3, 0.05, 0.05))
			else:
				Sprites.draw_grounded(self, "fx_seal_broken", SEAL_H * 0.75, c.y + 4)


# ── Parıltılar (toplamalı) ───────────────────────────────────────────

func _paint(g: GlowLayer) -> void:
	var c := Vector2(0, _sort_up())
	var now := Time.get_ticks_msec() / 1000.0
	match kind:
		"portal":
			var a := _fade(8, 14)
			var blink := 0.75 + 0.25 * sin(now * 14.0)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.ring(Vector2.ZERO, radius, 2.0, Color(VOID, 0.7 * a * blink))
			g.glow(Vector2.ZERO, radius * 1.1, Color(VOID, 0.22 * a))
			g.draw_set_transform(Vector2.ZERO)
		"crack":
			var a := _fade(4, 30)
			var flick := 0.8 + 0.2 * sin(now * 9.0 + _seed)
			g.streak(PackedVector2Array([_a, _b]), 2.2, Color(VOID, 0.45 * a * flick))
			var n := maxi(3, int((_b - _a).length() / 26.0))
			for i in n:
				var u := (i + 0.5) / n
				var q := fmod(now * 1.4 + i * 0.37, 1.0)
				g.glow(_a.lerp(_b, u) + Vector2(0, -q * 26.0), 6.0 * (1.0 - q), Color(0.8, 0.5, 1.0, 0.6 * a * (1.0 - q)))
		"beam":
			if t < BEAM_TELL:
				var k := float(t) / BEAM_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				var reach := 0.25 + 0.75 * k
				g.streak(PackedVector2Array([_a, _a.lerp(_b, reach)]), 1.3, Color(VOID, (0.25 + 0.5 * k) * blink))
				for j in 16:
					var u := float(j + 1) / 16
					if u > reach:
						break
					g.glow(_a.lerp(_b, u), 4.0 + 2.0 * k, Color(VOID, (0.25 + 0.45 * k) * blink))
			else:
				var a := clampf(float(life - t) / 12.0, 0.0, 1.0)
				g.streak(PackedVector2Array([_a, _b]), 6.0, Color(VOID, 0.55 * a))
				g.streak(PackedVector2Array([_a, _b]), 2.0, Color(0.95, 0.85, 1.0, 0.8 * a))
				var n := maxi(4, int((_b - _a).length() / 30.0))
				for i in n:
					g.glow(_a.lerp(_b, (i + 0.5) / n), 14.0, Color(VOID, 0.25 * a))
		"shadow":
			if t < SHADOW_TELL:
				var k := float(t) / SHADOW_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius * (0.3 + 0.7 * k), 1.8, Color(VOID, (0.35 + 0.5 * k) * blink))
				g.draw_set_transform(Vector2.ZERO)
			else:
				var fl := clampf(1.0 - float(t - SHADOW_TELL) / 10.0, 0.0, 1.0)
				g.glow(c, radius * 1.3, Color(VOID, 0.5 * fl))
		"ring":
			var fl := 0.85 + 0.15 * sin(now * 7.0)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.ring(Vector2.ZERO, radius, 3.0, Color(VOID, 0.55 * fl))
			g.draw_set_transform(Vector2.ZERO)
		"seal":
			if seal_hp > 0:
				var k := 0.5 + 0.5 * sin(now * 2.0 + _seed)
				g.draw_set_transform(c + Vector2(0, -SEAL_H * 0.35), 0, Vector2(1, 0.45))
				g.glow(Vector2.ZERO, 26.0 + 4.0 * k, Color(BLOOD, 0.25 + 0.15 * k))
				g.draw_set_transform(Vector2.ZERO)
