class_name HeroSkills
extends RefCounted
## Arktan'ın gelişen yetenekleri. Q ve R baştan açık; F ilk bossu (kat 10), V üçüncü bossu (kat 30) yenince açılır.
## Her yeteneğin rütbesi (I–V) seviyeyle artar: hasar, alan ve rütbe III / IV / V'te ek etkiler. Bütün hasarlar
## toplam saldırı gücünden (seviye + eşya + kartlar) hesaplanır.

const F_UNLOCK_BOSSES := 1
const V_UNLOCK_BOSSES := 3
const F_CD := {"warrior": 480, "ranger": 420, "mage": 540}
const V_CD := 2400
const ROMAN := ["", "I", "II", "III", "IV", "V"]

## Tarz başına yetenek adları ve kısa açıklamaları (arayüz ipucu).
const NAMES := {
	"warrior": {"f": "KURT HAMLESİ", "v": "BÖRÜ YEMİNİ"},
	"ranger": {"f": "GERİ SIÇRAYIŞ", "v": "GÖK BÖRÜ YAĞMURU"},
	"mage": {"f": "BUZ HALKASI", "v": "BÖRÜ FIRTINASI"},
}

var p: Player
var f_cd := 0
var v_cd := 0
## Etkin nihai yetenek: kalan kare ve iç sayaç.
var v_left := 0
var v_t := 0
## Kurt Hamlesi: hamle süresi, yönü ve bu hamlede vurulanlar.
var lunge_left := 0
var lunge_dir := Vector2.ZERO
var lunge_hit: Array = []


func _init(player: Player) -> void:
	p = player


## Seviyeye bağlı rütbe: I (1–4), II (5–9), III (10–14), IV (15–19), V (20+).
func rank() -> int:
	return clampi(1 + p.level / 5, 1, 5)


## Rütbe hasar çarpanı: rütbe başına +%18.
func power() -> float:
	return 1.0 + 0.18 * (rank() - 1)


func f_unlocked() -> bool:
	return Game.bosses_killed >= F_UNLOCK_BOSSES or p.god_mode or p.full_power


func v_unlocked() -> bool:
	return Game.bosses_killed >= V_UNLOCK_BOSSES or p.god_mode or p.full_power


func f_max() -> int:
	return F_CD[p.style]


## Nöbetçi Yemini sürerken saldırı gücü çarpanı ve saldırı hızı.
func oath_active() -> bool:
	return p.style == "warrior" and v_left > 0


func tick() -> void:
	if f_cd > 0:
		f_cd -= 1
	if v_cd > 0:
		v_cd -= 1
	if lunge_left > 0:
		_lunge_step()
	if v_left > 0:
		v_left -= 1
		v_t += 1
		_ultimate_tick()


# ── F ────────────────────────────────────────────────────────────────

func use_f() -> void:
	if f_cd > 0 or not f_unlocked() or not p.alive():
		return
	var atk := p.total_atk()
	match p.style:
		"warrior":
			# Kurt Hamlesi: nişan yönünde ileri atılır, yoldaki herkesi biçer; atılma boyunca dokunulmaz.
			lunge_dir = Vector2.from_angle(p.aim)
			lunge_left = 12
			lunge_hit.clear()
			p.invincible = maxi(p.invincible, 18)
			p.facing_left = cos(p.aim) < 0
			Sfx.play("swing")
			p.main.shake(6)
		"ranger":
			# Geri Sıçrayış: geri sıçrar, önüne yelpaze ok salar (rütbe III'ten 7 ok).
			var back := -Vector2.from_angle(p.aim)
			p.position = p.main.world.move_circle(p.position, back * 110.0, Player.RADIUS)
			p.main.spawn_afterimage(p)
			p.invincible = maxi(p.invincible, 20)
			var n := 7 if rank() >= 3 else 5
			for i in n:
				var a := p.aim + (i - (n - 1) / 2.0) * 0.16
				p.main.spawn_projectile("arrow", p.muzzle(a), a, int(atk * 0.95 * power()), false, p.muzzle_lift())
			Sfx.play("archer")
		"mage":
			# Buz Halkası: çevresine dondurucu dalga; düşmanlar sersemler (rütbe IV'ten daha uzun).
			var r := 120.0 * (1.0 + 0.08 * (rank() - 1))
			p.main.fx.add_sprite(p.position, "fx_ring_blue", r * 2.2, Color(0.8, 0.95, 1.0), 26, 0.35)
			p.main.fx.add_sprite(p.position + Vector2(0, -10), "fx_ice_shards", r * 1.6, Color.WHITE, 22, 0.3)
			p.main.burst(p.position, r, Color(0.7, 0.9, 1.0))
			for e in p.main.targets():
				if e.position.distance_to(p.position) > r:
					continue
				e.take_damage(int(atk * 1.4 * power()), e.position - p.position, 1.2)
				if e is Enemy and is_instance_valid(e):
					e.stun = 120 if rank() >= 4 else 80
			p.main.shake(8)
			Sfx.play("mage")
	f_cd = f_max()
	if p.style != "warrior":
		p.show_pose("f", 22)


func _lunge_step() -> void:
	lunge_left -= 1
	var before := p.position
	p.position = p.main.world.move_circle(p.position, lunge_dir * 13.0, Player.RADIUS)
	p.moving = true
	p.main.spawn_afterimage(p)
	var dmg := int(p.total_atk() * 1.7 * power())
	for e in p.main.targets():
		if e in lunge_hit:
			continue
		if Geometry2D.get_closest_point_to_segment(e.position, before, p.position + lunge_dir * 30.0).distance_to(e.position) > 46.0:
			continue
		lunge_hit.append(e)
		if e is Enemy:
			e.hit_stop = 6
			e.stun = 40
		e.take_damage(dmg, lunge_dir, 0.4 if e is Boss else 1.6)
		p.main.slash_effect(p.position - lunge_dir * 40.0, e.position)
	if lunge_left == 0 and rank() >= 3:
		# Rütbe III: hamlenin sonunda kurt uluması gibi bir şok dalgası.
		p.main.burst(p.position, 80, Color(0.7, 0.85, 1.0))
		for e in p.main.targets():
			if e.position.distance_to(p.position) < 80.0 and not e in lunge_hit:
				e.take_damage(int(dmg * 0.6), e.position - p.position, 1.0)


# ── V (nihai) ────────────────────────────────────────────────────────

func use_v() -> void:
	if v_cd > 0 or not v_unlocked() or not p.alive():
		return
	var atk := p.total_atk()
	v_t = 0
	# Bütün T yetenekleri Gök Börü'nündür (aynı kan): Kalp'in bekçisinin altın ruhu Arktan'ın üstünde ulur.
	p.main.fx.add_sprite(p.position + Vector2(0, -110), "fx_ruh_kurt_howl", 250, Color(1, 1, 1, 0.9), 95, 0.2)
	p.main.fx.add_sprite(p.position + Vector2(0, -60), "fx_ring_gold", 220, Color.WHITE, 40, 0.4)
	p.main.burst(p.position + Vector2(0, -70), 110, SpiritWolf.GOLD)
	p.main.float_text(p.position + Vector2(0, -80), NAMES[p.style].v, Color(1.0, 0.9, 0.55))
	match p.style:
		"warrior":
			# Börü Yemini: altın şok dalgası; 7 sn (rütbe V'te 9 sn) güç, hız, can emme ve yanında avlanan ruh kurdu.
			v_left = 540 if rank() >= 5 else 420
			for e in p.main.targets():
				if e.position.distance_to(p.position) < 140.0:
					e.take_damage(int(atk * 2.0 * power()), e.position - p.position, 1.5)
			_wolf("hunt", p.position + Vector2(-40.0 if p.facing_left else 40.0, 10), int(atk * 0.9 * power()), v_left)
		"ranger":
			# Gök Börü Yağmuru: 4 sn boyunca en yakın düşmanlara durmadan gökten ok iner.
			v_left = 240
		"mage":
			# Börü Fırtınası: 5 sn boyunca altın ışık sütunları düşmanları çarpar; sonunda ruh kurdu hedefe atlar.
			v_left = 300
			p.main.fx.add_sprite(p.position, "fx_gravity_rune", 260, Color(1.0, 0.85, 0.5), 40, 0.2)
	p.main.shake(14)
	p.main.hit_freeze(4)
	p.show_pose("v", 70)
	v_cd = V_CD


func _ultimate_tick() -> void:
	var atk := p.total_atk()
	match p.style:
		"warrior":
			if v_t % 20 == 0:
				p.main.fx.add_sprite(p.position + Vector2(0, -30), "fx_spark", 70, Color(1.0, 0.85, 0.4, 0.7), 16, 0.5, randf() * TAU)
		"ranger":
			var every := 9 if rank() >= 4 else 12
			if v_t % every == 0:
				var list := _nearest(4)
				var at: Vector2 = list[randi() % list.size()].position if not list.is_empty() \
					else p.position + Vector2.from_angle(randf() * TAU) * randf_range(60, 180)
				p.main.spawn_strike("arrow", at + Vector2(randf_range(-14, 14), randf_range(-10, 10)), 70.0, int(atk * 1.0 * power()), 0)
		"mage":
			if v_t % 22 == 0:
				var list := _nearest(6)
				if not list.is_empty():
					var e: Node2D = list[randi() % list.size()]
					p.main.fx.add_sprite(e.position + Vector2(0, -60), "fx_light_pillar", 150, Color(1.0, 0.86, 0.5), 18, 0.15)
					p.main.burst(e.position, 50, SpiritWolf.GOLD)
					e.take_damage(int(atk * 1.6 * power()), Vector2.ZERO, 0.6)
			if v_left == 1:
				var t := p.skill_target(320, TAU)
				var at: Vector2 = t.position if t else p.position + Vector2.from_angle(p.aim) * 120.0
				var w := _wolf("pounce", p.position + Vector2(0, 6), int(atk * 3.0 * power()), 0)
				w.to = at
				w.scale_k = 0.42


## Gök Börü'nün ruh kurdunu çağırır (spirit_wolf.gd).
func _wolf(mode: String, at: Vector2, dmg: int, life: int) -> SpiritWolf:
	var w := SpiritWolf.new()
	w.mode = mode
	w.damage = dmg
	if life > 0:
		w.life = life
	w.main = p.main
	w.position = at
	if mode == "pounce":
		w.to = at
	p.main._spawn(w, at)
	return w


func _nearest(n: int) -> Array:
	var list: Array = p.main.targets().filter(func(e): return e.position.distance_to(p.position) < 380.0)
	list.sort_custom(func(a, b): return a.position.distance_to(p.position) < b.position.distance_to(p.position))
	return list.slice(0, n)


## Can emme (Nöbetçi Yemini): her vuruşta.
func on_hit() -> void:
	if oath_active():
		p.heal(2 + rank())
