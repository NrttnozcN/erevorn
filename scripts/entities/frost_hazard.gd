class_name FrostHazard
extends Actor
## Donmuş Tundra'nın yerdeki tehlikeleri (bölge 5), FireHazard'ın kardeşi:
##   patch   — Buz Zombisi ölünce kalan kaygan buz birikintisi: üstünde duran yavaşlar (~2 sn).
##   web     — Buz Aynası Örümceği'nin ağı: örümcekten fırlayıp yere yayılır; içinde kalan yavaşlar ve 1 kırağı alır.
##   ring    — Buz Ayısı'nın yere vuruşu: dışa yayılan kısa buz halkası (içindeki oyuncuya hasar + 1 kırağı).
##   spikes  — Kral Alden'ın buz dikeni hattı: yerde mavi çizgi uzar (~1 sn tell), sonra çizgi boyunca dikenler fışkırır.
##   icicle  — Kar fırtınasında tavandan düşen sarkıt: yerde büyüyen gölge (tell), düşer, sonra birkaç sn siper olur.
##   prison  — Buz hapsi: oyuncunun çevresinde halka (~1.2 sn tell), sonra buz duvarı; içinde kalan donar.
##   lantern — Boss arenasının soğuk rün kandili: okla / kılıçla vurulunca birkaç sn ılık ışık yayar, ışığın
##             içindeki oyuncunun kırağısı erir ve fırtına onu üşütmez.
## Y sıralı katmanda zemin işareti aktörlerin altında kalsın diye düğüm dairenin bir yarıçap üstüne konur
## (FireHazard ile aynı); çizim ve vuruş merkezi `center` üstünden yapılır.

const UNSHADED := preload("res://scripts/world/unshaded.tres")
const ICE := Color(0.55, 0.82, 1.0)
const ICE_WHITE := Color(0.88, 0.96, 1.0)
const WARM := Color(1.0, 0.68, 0.32)
const PATCH_LIFE := 120
const WEB_FLY := 14
const WEB_LIFE := 300
const RING_GROW := 14
const RING_LIFE := 40
const SPIKE_TELL := 60
const SPIKE_RISE := 12
const SPIKE_LIFE := 110
const ICICLE_TELL := 60
const ICICLE_STAY := 240
const PRISON_TELL := 72
const PRISON_WALL := 70
const LANTERN_LIT := 420
const LANTERN_R := 105.0

var kind := "patch"
var radius := 30.0
var damage := 0
var t := 0
var life := PATCH_LIFE
var _cd := 0
var _hit := false
var _seed := randf() * TAU
## Ağ: fırladığı nokta (merkeze göre).
var from := Vector2.ZERO
## Diken hattı: uçlar (düğüme göre) ve diken dizisi [u, boy, yana kayma].
var _a := Vector2.ZERO
var _b := Vector2.ZERO
var _spikes: Array = []
## Kandil: kalan ılık ışık süresi ve ışığı.
var lit := 0
var _light: PointLight2D


func setup(p_kind: String, center: Vector2, p_radius: float, p_damage: int) -> void:
	kind = p_kind
	radius = p_radius
	damage = p_damage
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	match kind:
		"patch": life = PATCH_LIFE
		"web": life = WEB_FLY + WEB_LIFE
		"ring": life = RING_LIFE
		"icicle": life = ICICLE_TELL + ICICLE_STAY
		"prison": life = PRISON_TELL + PRISON_WALL
		"lantern": life = 1 << 30
	position = center - Vector2(0, _sort_up())
	add_child(GlowLayer.make(_paint))
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = radius / 55.0
	l.color = ICE
	l.energy = 0.35 if kind in ["patch", "web"] else 0.55
	l.position = Vector2(0, _sort_up())
	if kind == "lantern":
		l.texture_scale = LANTERN_R / 48.0
		l.energy = 0.0
		l.color = WARM
		l.position = Vector2(13, _sort_up() - LANTERN_H * 0.56)
	add_child(l)
	_light = l


## Buz dikeni hattı: start'tan dir yönünde length boyunca. Düğüm hattın en üst noktasının biraz üstüne konur.
func setup_spikes(start: Vector2, dir: Vector2, length: float, p_damage: int) -> void:
	kind = "spikes"
	damage = p_damage
	life = SPIKE_TELL + SPIKE_LIFE
	radius = 18.0
	material = UNSHADED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var end := start + dir * length
	position = Vector2((start.x + end.x) * 0.5, minf(start.y, end.y) - 14.0)
	_a = start - position
	_b = end - position
	var n := maxi(3, int(length / 24.0))
	for i in n:
		# [u, boy, yana kayma, boyalı çeşit (1-4), aynalı mı]
		_spikes.append([(i + 0.5) / n, randf_range(40.0, 62.0), randf_range(-7.0, 7.0), randi_range(1, 4), randf() < 0.5])
	add_child(GlowLayer.make(_paint))
	for u in [0.25, 0.75]:
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = length / 300.0 + 0.3
		l.color = ICE
		l.energy = 0.6
		l.position = _a.lerp(_b, u)
		add_child(l)


func center() -> Vector2:
	return position + Vector2(0, _sort_up())


func _sort_up() -> float:
	return radius


## Oyuncu ayağının (yere yatık elipsteki) merkeze uzaklığı, yarıçap biriminde.
func _feet_in(p: Player, r: float) -> bool:
	var d := (p.position + Vector2(0, 14) - center()) * Vector2(1, 1.0 / 0.42)
	return d.length() < r


## Tell bitti mi (diken / sarkıt / hapis tetiklendi mi)?
func triggered() -> bool:
	match kind:
		"spikes": return t >= SPIKE_TELL
		"icicle": return t >= ICICLE_TELL
		"prison": return t >= PRISON_TELL
		"web": return t >= WEB_FLY
	return true


## Düşmüş sarkıt nefesi keser: a-b doğrusu sarkıta yakın mı?
func blocks(a: Vector2, b: Vector2) -> bool:
	if kind != "icicle" or t < ICICLE_TELL or t > life - 20:
		return false
	var c := center() + Vector2(0, -14)
	return c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)) < 26.0


## Kandilin asılı fenerinin (sprite'ta direğin sağında, orta yükseklikte) dünyadaki yeri.
const LANTERN_H := 92.0
func head() -> Vector2:
	return center() + Vector2(13, -LANTERN_H * 0.56)


## Kandil yanıyorsa ve nokta ışığının içindeyse true.
func warms(at: Vector2) -> bool:
	return kind == "lantern" and lit > 0 and ((at - center()) * Vector2(1, 1.0 / 0.6)).length() < LANTERN_R


## Kandili yakar (ok, büyü, kılıç).
func light_up() -> void:
	if lit == 0:
		main.burst(head(), 40, WARM)
		main.float_text(center() + Vector2(0, -80), "KANDİL YANDI", WARM.lightened(0.3))
	lit = LANTERN_LIT


func tick() -> void:
	t += 1
	if _cd > 0:
		_cd -= 1
	var p := main.player
	match kind:
		"patch":
			if _cd == 0 and p.alive() and _feet_in(p, radius) and t > 4 and t < life - 15:
				_cd = 30
				p.apply_debuff("slow")
				main.float_text(p.position + Vector2(0, -56), "KAYGAN", ICE_WHITE)
		"web":
			if t == WEB_FLY:
				main.burst(center(), radius * 0.9, ICE_WHITE)
			if t > WEB_FLY and _cd == 0 and p.alive() and _feet_in(p, radius) and t < life - 20:
				_cd = 90
				p.apply_debuff("slow")
				p.add_frost(1)
				main.float_text(p.position + Vector2(0, -56), "AĞ", ICE_WHITE)
		"ring":
			if not _hit and t <= RING_GROW and p.alive() and _feet_in(p, radius * float(t) / RING_GROW + 10.0):
				_hit = true
				if p.take_damage(damage, self):
					p.apply_debuff("frost")
		"spikes":
			if t == SPIKE_TELL:
				main.shake(6)
			if t >= SPIKE_TELL and t <= SPIKE_TELL + SPIKE_RISE + 4 and not _hit and p.alive():
				# Fışkıran kısım: oyuncunun ayağı hattın açılmış bölümüne yakınsa.
				var feet := p.position + Vector2(0, 16) - position
				var u := clampf(float(t - SPIKE_TELL) / SPIKE_RISE, 0.0, 1.0)
				var q := Geometry2D.get_closest_point_to_segment(feet, _a, _a.lerp(_b, u))
				if feet.distance_to(q) < 22.0:
					_hit = true
					if p.take_damage(damage, self):
						p.apply_debuff("frost")
		"icicle":
			if t == ICICLE_TELL:
				main.shake(5)
				main.burst(center() + Vector2(0, -10), radius * 1.3, ICE_WHITE)
				if p.alive() and _feet_in(p, radius):
					if p.take_damage(damage, self):
						p.apply_debuff("frost")
		"prison":
			if t == PRISON_TELL:
				main.shake(8)
				main.burst(center(), radius, ICE)
				if p.alive() and _feet_in(p, radius):
					p.take_damage(damage, self)
					p.freeze(70)
		"lantern":
			if lit > 0:
				lit -= 1
				if p.alive() and warms(p.position):
					p.melt_frost()
			_light.energy = lerpf(_light.energy, 1.3 if lit > 0 else 0.0, 0.1)
	if t >= life:
		remove()
		return
	queue_redraw()


func _fade(fade_in: int, fade_out: int) -> float:
	return clampf(float(t) / fade_in, 0.0, 1.0) * clampf(float(life - t) / fade_out, 0.0, 1.0)


# ── Çizim (normal karışım: yere yatık koyu / buzlu lekeler) ──────────

func _draw() -> void:
	var c := Vector2(0, _sort_up())
	match kind:
		"patch": _draw_patch(c)
		"web": _draw_web(c)
		"icicle": _draw_icicle(c)
		"prison": _draw_prison(c)
		"spikes": _draw_spikes()
		"lantern":
			_blot(c, 30.0, Color(0, 0, 0, 0.35))
			if not Sprites.draw_grounded(self, "prop_z5_lantern", LANTERN_H, c.y + 4, Color(1.0, 0.93, 0.85) if lit > 0 else Color.WHITE):
				draw_line(c, c + Vector2(0, -LANTERN_H), Color(0.2, 0.22, 0.28), 4.0)


func _blot(c: Vector2, r: float, col: Color) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-r, -r, r * 2.0, r * 2.0), false, col)
	draw_set_transform(Vector2.ZERO)


## Buz birikintisi: soluk mavi, kenarı yumuşak parlak buz; üstünde iki ince yansıma çizgisi.
func _draw_patch(c: Vector2) -> void:
	var a := _fade(6, 30)
	_blot(c, radius * 1.3, Color(0.5, 0.72, 0.9, 0.55 * a))
	_blot(c, radius * 0.9, Color(0.75, 0.9, 1.0, 0.45 * a))
	draw_set_transform(c, 0, Vector2(1, 0.42))
	draw_line(Vector2(-radius * 0.5, -radius * 0.25), Vector2(radius * 0.1, -radius * 0.45), Color(1, 1, 1, 0.55 * a), 2.0, true)
	draw_line(Vector2(radius * 0.05, radius * 0.2), Vector2(radius * 0.45, 0.0), Color(1, 1, 1, 0.4 * a), 1.5, true)
	draw_set_transform(Vector2.ZERO)


## Ağın yerdeki yayılmış hali: merkezden dışa ışınsal iplikler ve iç içe kırık halkalar.
func _web_shape(c: Vector2, r: float, col: Color, w: float) -> void:
	draw_set_transform(c, 0, Vector2(1, 0.42))
	var n := 10
	for i in n:
		var ang := _seed + i * TAU / n
		draw_line(Vector2.ZERO, Vector2.from_angle(ang) * r, col, w, true)
	for k in [0.35, 0.65, 0.95]:
		var ring := PackedVector2Array()
		for i in n + 1:
			var ang := _seed + i * TAU / n
			# İplikler arası hafif sarkma: halka düz değil, içe kıvrık.
			ring.append(Vector2.from_angle(ang) * r * k)
			if i < n:
				ring.append(Vector2.from_angle(ang + PI / n) * r * k * 0.9)
		draw_polyline(ring, col, w * 0.8, true)
	draw_set_transform(Vector2.ZERO)


func _draw_web(c: Vector2) -> void:
	if t < WEB_FLY:
		return
	var a := _fade(WEB_FLY + 4, 40)
	var grow := clampf(float(t - WEB_FLY) / 6.0, 0.4, 1.0)
	_blot(c, radius * 1.1, Color(0.6, 0.8, 1.0, 0.18 * a))
	_web_shape(c, radius * grow, Color(0.85, 0.95, 1.0, 0.75 * a), 1.4)


## Sarkıt: tell'de yerde büyüyen gölge; düştükten sonra yere saplanmış buz sarkıtı.
func _draw_icicle(c: Vector2) -> void:
	if t < ICICLE_TELL:
		var k := float(t) / ICICLE_TELL
		_blot(c, radius * (0.4 + 0.8 * k), Color(0.02, 0.04, 0.08, 0.25 + 0.4 * k))
		if k > 0.65:
			# Tavandan düşen boyalı sarkıt (yere saplanınca aynı sprite kalır).
			var y := -220.0 * (1.0 - k) / 0.35
			_ice_sprite("fx_icicle%d" % (1 + int(absf(_seed) * 10.0) % 3), c + Vector2(0, 4 + y), 74.0, 1.0, clampf((k - 0.65) * 8.0, 0.0, 1.0), _seed > PI)
		return
	var a := _fade(1, 25)
	_blot(c, radius * 1.2, Color(0.02, 0.04, 0.08, 0.45 * a))
	# Boyalı sarkıt: düşüş anında hafifçe ezilip oturur; sönerken buz kırıntısı yığınına döner.
	var land := clampf(float(t - ICICLE_TELL) / 6.0, 0.0, 1.0)
	var key := "fx_icicle%d" % (1 + int(absf(_seed) * 10.0) % 3)
	if life - t < 25 and Sprites.tex("fx_ice_shards"):
		_ice_sprite("fx_ice_shards", c + Vector2(0, 6), 26.0, 1.0, a)
		_ice_sprite(key, c + Vector2(0, 4), 74.0, 1.0, a * a, _seed > PI)
		return
	if _ice_sprite(key, c + Vector2(0, 4), 74.0, 0.85 + 0.15 * land, a, _seed > PI):
		return
	var h := 58.0
	var w := 13.0
	var base := c + Vector2(0, 2)
	# Gövde: koyu mavi kenarlı, içi açık; üstte kırık uç (yere saplanmış).
	var body := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.55, -h), base + Vector2(w * 0.1, -h * 1.12),
		base + Vector2(w * 0.6, -h * 0.95), base + Vector2(w, 0)])
	var cols := PackedColorArray([Color(0.3, 0.5, 0.75, a), Color(0.7, 0.88, 1.0, a), Color(0.92, 0.98, 1.0, a),
		Color(0.7, 0.88, 1.0, a), Color(0.35, 0.55, 0.8, a)])
	draw_polygon(body, cols)
	var rim := body.duplicate()
	rim.append(body[0])
	draw_polyline(rim, Color(0.15, 0.25, 0.4, 0.8 * a), 1.2, true)
	draw_line(base + Vector2(-w * 0.2, -4), base + Vector2(-w * 0.35, -h * 0.9), Color(1, 1, 1, 0.6 * a), 1.5, true)
	# Dibinde kırık buz parçaları.
	for i in 4:
		var o := Vector2(cos(_seed + i * 1.7) * w * 1.6, 2 + sin(_seed + i) * 3.0)
		draw_colored_polygon(PackedVector2Array([base + o + Vector2(-4, 0), base + o + Vector2(0, -7), base + o + Vector2(4, 0)]), Color(0.75, 0.9, 1.0, 0.8 * a))


## Buz hapsi: tell'de yerde ince halka; tetiklenince halkanın çevresinde buz duvarı (sivri buz parçaları).
func _draw_prison(c: Vector2) -> void:
	if t < PRISON_TELL:
		var k := float(t) / PRISON_TELL
		_blot(c, radius * 1.05, Color(0.3, 0.5, 0.8, 0.12 + 0.16 * k))
		return
	var a := _fade(1, 25)
	var rise := clampf(float(t - PRISON_TELL) / 8.0, 0.0, 1.0)
	# Arkadaki yarım önce, öndeki yarım sonra (öndeki dikenler oyuncunun önünde kalmasın diye kısa).
	var n := 16
	for pass_i in 2:
		for i in n:
			var ang := _seed + i * TAU / n
			var front := sin(ang) > 0.0
			if front != (pass_i == 1):
				continue
			var base := c + Vector2(cos(ang), sin(ang) * 0.42) * radius
			var h := (30.0 + 10.0 * sin(i * 2.3 + _seed)) * rise * (0.7 if front else 1.0)
			# Boyalı buz dikenleri halka boyunca: arkadakiler uzun, öndekiler oyuncuyu örtmesin diye kısa.
			if _ice_sprite("fx_ice_spike%d" % (1 + (i * 7 + int(_seed * 3.0)) % 4), base + Vector2(0, 2),
					(44.0 + 10.0 * sin(i * 2.3 + _seed)) * (0.62 if front else 1.0), rise, a, i % 2 == 0):
				continue
			var w := 9.0
			var poly := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(sin(i + _seed) * 3.0, -h), base + Vector2(w, 0)])
			draw_polygon(poly, PackedColorArray([Color(0.3, 0.5, 0.78, a), Color(0.92, 0.98, 1.0, a), Color(0.45, 0.66, 0.9, a)]))
			draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2]]), Color(0.15, 0.25, 0.4, 0.7 * a), 1.0, true)


## Diken hattı: fışkırınca hat boyunca sivri buz dikenleri (sırayla yükselir, sonra çöker).
func _draw_spikes() -> void:
	if t < SPIKE_TELL:
		return
	var a := clampf(float(life - t) / 25.0, 0.0, 1.0)
	var open := clampf(float(t - SPIKE_TELL) / SPIKE_RISE, 0.0, 1.0)
	var dir := (_b - _a).normalized()
	var perp := dir.orthogonal()
	# Arkadakiler önce (y sırası): hat yukarı doğru gidiyorsa uçtan başa çizilir.
	var order := _spikes.duplicate()
	order.sort_custom(func(p, q): return _a.lerp(_b, p[0]).y < _a.lerp(_b, q[0]).y)
	for sp in order:
		var u: float = sp[0]
		if u > open:
			continue
		var rise := clampf((open - u) * 5.0 + 0.2, 0.0, 1.0)
		var base: Vector2 = _a.lerp(_b, u) + perp * float(sp[2]) * 0.5
		_blot(base, 16.0, Color(0.05, 0.1, 0.2, 0.35 * a))
		_ice_sprite("fx_ice_spike%d" % sp[3], base + Vector2(0, 3), float(sp[1]), rise, a, sp[4])


## Boyalı buz sprite'ı: tabanı base'te, boyu h; rise ile yerden yükselir (dikey ölçek), a ile söner.
func _ice_sprite(key: String, base: Vector2, h: float, rise: float, a: float, flip := false) -> bool:
	var tex := Sprites.tex(key)
	if tex == null:
		return false
	var top := Sprites.content_top(key)
	var bot := Sprites.content_bottom(key)
	var full_h := h / maxf(bot - top, 0.05)
	var w := full_h * tex.get_width() / tex.get_height()
	draw_set_transform(base, 0, Vector2(-1.0 if flip else 1.0, maxf(rise, 0.01)))
	draw_texture_rect(tex, Rect2(-w / 2.0, -full_h * bot, w, full_h), false, Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO)
	return true


# ── Parıltılar (toplamalı, karanlıktan etkilenmez) ───────────────────

func _paint(g: GlowLayer) -> void:
	var c := Vector2(0, _sort_up())
	var now := Time.get_ticks_msec() / 1000.0
	match kind:
		"patch":
			var a := _fade(6, 30)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.glow(Vector2.ZERO, radius * 1.1, Color(ICE, 0.22 * a))
			g.glow(Vector2(-radius * 0.25, -radius * 0.2), radius * 0.4, Color(ICE_WHITE, 0.3 * a))
			g.draw_set_transform(Vector2.ZERO)
		"web":
			if t < WEB_FLY:
				# Fırlayan ağ yumağı: örümcekten hedefe yay çizerek uçar.
				var u := float(t) / WEB_FLY
				var at := from.lerp(c, u) + Vector2(0, -sin(u * PI) * 40.0)
				g.glow(at, 16.0, Color(ICE_WHITE, 0.7))
				g.glow(at, 7.0, Color(1, 1, 1, 0.9))
				return
			var a := _fade(WEB_FLY + 4, 40)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.glow(Vector2.ZERO, radius * 1.2, Color(ICE, 0.18 * a))
			g.draw_set_transform(Vector2.ZERO)
		"ring":
			var u := clampf(float(t) / RING_GROW, 0.0, 1.0)
			var a := clampf(float(life - t) / 20.0, 0.0, 1.0)
			g.draw_set_transform(c, 0, Vector2(1, 0.42))
			g.ring(Vector2.ZERO, radius * u, 3.0, Color(ICE_WHITE, 0.9 * a))
			g.glow(Vector2.ZERO, radius * u, Color(ICE, 0.2 * a))
			g.draw_set_transform(Vector2.ZERO)
			for i in 10:
				var ang := _seed + i * TAU / 10.0
				var p := c + Vector2(cos(ang), sin(ang) * 0.42) * radius * u
				g.glow(p + Vector2(0, -6.0 * u), 6.0, Color(ICE_WHITE, 0.7 * a))
		"spikes":
			_paint_spikes(g, now)
		"icicle":
			if t < ICICLE_TELL:
				var k := float(t) / ICICLE_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 14.0 * k))
				g.draw_set_transform(c, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, radius * (0.4 + 0.6 * k), 1.6, Color(ICE, (0.35 + 0.5 * k) * blink))
				g.draw_set_transform(Vector2.ZERO)
				if k > 0.65:
					# Son an: tepeden inen sarkıtın hız izi.
					var y := -220.0 * (1.0 - k) / 0.35
					g.glow(c + Vector2(0, y - 60), 18.0, Color(ICE_WHITE, 0.35))
			else:
				var a := _fade(1, 25)
				var fl := clampf(1.0 - float(t - ICICLE_TELL) / 12.0, 0.0, 1.0)
				g.glow(c + Vector2(0, -30), 22.0, Color(ICE, 0.25 * a))
				if fl > 0.0:
					g.glow(c, radius * 1.4, Color(ICE_WHITE, 0.6 * fl))
		"prison":
			_paint_prison(g, c, now)
		"lantern":
			var head := c + Vector2(13, -LANTERN_H * 0.56)
			if lit > 0:
				var fade := clampf(float(lit) / 60.0, 0.0, 1.0)
				var fl := 0.85 + 0.1 * sin(now * 11.0 + _seed) + 0.05 * sin(now * 23.0)
				g.glow(head, 30.0 * fl, Color(WARM, 0.55 * fade))
				g.glow(head, 11.0, Color(1.0, 0.92, 0.7, 0.8 * fade))
				g.draw_set_transform(c, 0, Vector2(1, 0.6))
				g.glow(Vector2.ZERO, LANTERN_R, Color(WARM, 0.16 * fade))
				g.ring(Vector2.ZERO, LANTERN_R, 1.2, Color(WARM, 0.25 * fade))
				g.draw_set_transform(Vector2.ZERO)
			else:
				var k := 0.5 + 0.5 * sin(now * 1.4 + _seed)
				g.glow(head, 16.0 + 3.0 * k, Color(ICE, 0.28 + 0.12 * k))
				g.glow(head, 5.0, Color(ICE_WHITE, 0.5))


## Diken hattı tell'i: önden uca dolan soluk mavi noktalar ve ince çizgi; fışkırınca dikenlerin dibinde parlama.
func _paint_spikes(g: GlowLayer, now: float) -> void:
	if t < SPIKE_TELL:
		var k := float(t) / SPIKE_TELL
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
		var reach := 0.25 + 0.75 * k
		var n := 20
		for j in n:
			var u := float(j + 1) / n
			if u > reach:
				break
			g.glow(_a.lerp(_b, u), 5.0 + 3.0 * k, Color(ICE, (0.3 + 0.5 * k) * blink))
		g.streak(PackedVector2Array([_a, _a.lerp(_b, reach)]), 1.4, Color(ICE, (0.25 + 0.5 * k) * blink))
		return
	var a := clampf(float(life - t) / 25.0, 0.0, 1.0)
	var open := clampf(float(t - SPIKE_TELL) / SPIKE_RISE, 0.0, 1.0)
	var flash := clampf(1.0 - float(t - SPIKE_TELL) / 16.0, 0.0, 1.0)
	for s in _spikes:
		var u: float = s[0]
		if u > open:
			continue
		var base := _a.lerp(_b, u)
		g.glow(base, 14.0, Color(ICE, 0.3 * a))
		g.glow(base + Vector2(0, -float(s[1]) * 0.5), 10.0, Color(ICE_WHITE, 0.25 * a + 0.4 * flash))


## Buz hapsi tell'i: halka içten dışa dolar, çevresinde yükselen buz kıymıkları; tetiklenince duvarın parıltısı.
func _paint_prison(g: GlowLayer, c: Vector2, now: float) -> void:
	if t < PRISON_TELL:
		var k := float(t) / PRISON_TELL
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
		g.draw_set_transform(c, 0, Vector2(1, 0.42))
		g.ring(Vector2.ZERO, radius, 2.4, Color(ICE, (0.45 + 0.5 * k) * blink))
		g.ring(Vector2.ZERO, radius * maxf(k, 0.05), 1.4, Color(ICE_WHITE, 0.7))
		g.glow(Vector2.ZERO, radius * 1.05, Color(ICE, 0.12 + 0.18 * k))
		g.draw_set_transform(Vector2.ZERO)
		for i in 12:
			var ang := _seed + i * TAU / 12.0 + now * 0.6
			var p := c + Vector2(cos(ang), sin(ang) * 0.42) * radius
			g.glow(p + Vector2(0, -10.0 * k), 4.0 + 3.0 * k, Color(ICE_WHITE, 0.4 + 0.5 * k))
		return
	var a := _fade(1, 25)
	var flash := clampf(1.0 - float(t - PRISON_TELL) / 14.0, 0.0, 1.0)
	g.draw_set_transform(c, 0, Vector2(1, 0.42))
	g.glow(Vector2.ZERO, radius * 1.2, Color(ICE, 0.2 * a + 0.4 * flash))
	g.ring(Vector2.ZERO, radius, 3.0, Color(ICE_WHITE, 0.6 * a))
	g.draw_set_transform(Vector2.ZERO)
