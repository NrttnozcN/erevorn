class_name Player
extends Actor
## Arktan. Dövüş tarzı (warrior / ranger / mage) eski oyundaki sınıfın aynısı:
## hareket hissi, temel saldırı, Q ve R yetenekleri, atılma ve seviye pasifleri (entities.js:1926-3530).

signal leveled_up
signal died

const RADIUS := 16.0
const BAG_SIZE := 30

var style := "warrior"
var base := {"maxHp": 100, "atk": 10, "def": 2, "spd": 2.5, "crit": 5, "luck": 5}
var hp := 100
var level := 1
var xp := 0
var next_xp := 100
var equipment := {}
var inventory: Array = []

var vel := Vector2.ZERO
var moving := false
var facing_left := false
var aim := 0.0
var anim_timer := 0
var frame := 1

var dash_cd_max := 45
var dash_duration := 8
var dash_mult := 3.2
var dash_cd := 0
var dash_left := 0
var dash_dir := Vector2.ZERO

var attack_cd := 0
var attack_cd_base := 28
var phase := "idle"
var phase_timer := 0
var swing_done := false
var execution_flash := 0

var q_cd_max := 720
var r_cd_max := 900
var q_cd := 0
var r_cd := 0

var invincible := 0
var since_hit := 0
var regen_timer := 0
var burn := 0
var poison := 0
var slow := 0
var dot_timer := 0
var shrine_type := ""
var shrine_left := 0
var shrine_tick := 0
var speed_potion := 0
var bow_kills := 0
var sword_kills := 0
var god_mode := false
## Kırağı (bölge 5): soğuk vuruşlar yığın biriktirir; FROST_MAX yığında oyuncu kısa süre donar (mavi buz kabuğu).
## Hareket etmek ve atılmak yığınları yavaşça eritir, yanan rün kandilinin ışığı hemen eritir.
const FROST_MAX := 3
const FREEZE := 48
const FROST_MELT := 110.0
var frost := 0
var frost_melt := 0.0
var frost_age := 0
var frozen := 0
## Kar fırtınası sürüyorsa (Kral Alden faz 2+) > 0: rüzgâr yürüyerek erimeyi yavaşlatır, atılma ve kandil yine eritir.
var in_storm := 0
## Kök sarması (bölge 6): ayağına sarılan kökler kısa süre yürümeyi ve atılmayı keser, saldırı serbest.
## Kutsal Taş'ın arınma ışığı kökü ve zehri çözer; ışıkta kaldıkça yeni kök ve zehir tutmaz.
const ROOT := 54
var rooted := 0
var cleansed := 0
## Bölge 7. Yokluk yanığı: mor alevli DoT; sürdükçe hiçbir yolla iyileşilemez. Kan işareti: alınan hasar %40 artar.
const VOID_BURN := 300
const MARK := 240
var void_burn := 0
var blood_mark := 0
## Bölge 8. Ağırlık (yerçekimi rünü): %45 yavaşlık, atılamaz.
const HEAVY := 90
var heavy := 0
## Bölge 9. Çarpıklık: gerçeklik bükülür, yön tuşları ters çalışır.
const WARP := 90
var warp := 0
## Bölge 10. Kristalleşme: yığın başına saldırı %15 düşer (en çok 3); zamanla ya da Kalp Pınarı'nın ışığıyla çözülür.
## Sera'nın ışığı (Kârun savaşı): içindeyken hasar alınmaz.
const CRYSTAL_MAX := 3
var crystal := 0
var crystal_t := 0
## Parçalama ve tutsaklardan gelen kalıcı kazanımlar (çanta ekranında gösterilir).
## F / V yetenekleri, rütbeler (hero_skills.gd).
var skills: HeroSkills
## Boyalı kahraman kareleri (konsept/kahraman/proc_kahraman.py): hero_<tarz>_<aşama>_<kare>.png, 840x560 tuval,
## ayak çapası (420, 552). Aşama hikâyeyle değişir: 1 Kırık Nöbetçi, 2 Mühür Nöbetçisi (3. boss), 3 Gök Nöbetçisi (6. boss).
const HERO_CANVAS := Vector2(840, 560)
const HERO_ANCHOR := Vector2(420, 552)
const HERO_SCALE := 0.24
## İlk bölgedeki boy; her 10 katta bir adım büyüyerek 10. bölgede HERO_SCALE'e ulaşır.
const HERO_SCALE_MIN := 0.175
const HERO_FEET := 28.0
## Gösterilen poz: yetenek ("q", "r", "f", "v", "power"), saldırı sonrası takip ve darbe alma süreleri.
## Geliştirici tam güç kısayolu (Ctrl+Shift+M): F / T açık, Gök Nöbetçisi zırhı.
var full_power := false
var pose := ""
var pose_t := 0
var post_t := 0
var hurt_t := 0
var perm := {"atk": 0, "def": 0, "maxHp": 0, "crit": 0}


func setup(chosen_style: String) -> void:
	style = chosen_style
	skills = HeroSkills.new(self)
	var s: Dictionary = ClassData.STYLES[style]
	for k: String in s.bonus:
		base[k] += s.bonus[k]
	for k: String in Game.meta:
		var lvl: int = Game.meta[k]
		match k:
			"atk": base.atk += 2 * lvl
			"def": base.def += 2 * lvl
			"hp": base.maxHp += 20 * lvl
			"crit": base.crit += 3 * lvl
	dash_cd_max = s.dash[0]
	dash_duration = s.dash[1]
	dash_mult = s.dash[2]
	attack_cd_base = {"warrior": 28, "ranger": 18, "mage": 32}[style]
	for slot: String in ItemData.SLOTS:
		equipment[slot] = {}
	equipment.weapon = ItemData.make(s.weapon, false)
	if s.armor != "":
		equipment.armor = ItemData.make(s.armor, false)
		equipment.armor.name = "Başlangıç Kalkanı"
	hp = max_hp()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(GlowLayer.make(_paint_armor_glow, true))
	add_child(GlowLayer.make(_paint_weapon_glow))
	add_child(GlowLayer.make(_paint_frost))


## Kalıcı güç ekler (parçalama, tutsak). Toplamı perm'de tutulur.
func add_permanent(stat: String, amount: int) -> void:
	base[stat] += amount
	perm[stat] = perm.get(stat, 0) + amount


func alive() -> bool:
	return hp > 0


func is_invincible() -> bool:
	return invincible > 0 or god_mode


# ── Türetilmiş değerler ──────────────────────────────────────────────

func _equip_sum(stat: String) -> float:
	var total := 0.0
	for slot: String in equipment:
		var it: Dictionary = equipment[slot]
		if not it.is_empty():
			total += it.stats.get(stat, 0)
	return total


func set_bonus() -> Dictionary:
	var b := {"atk": 0, "def": 0, "hp": 0, "crit": 0, "names": []}
	var legendary := 0
	var rare := 0
	var fx := {"burn": 0, "frost": 0, "focus": 0}
	for slot: String in equipment:
		var it: Dictionary = equipment[slot]
		if it.is_empty():
			continue
		if it.rarity == "legendary" or it.rarity == "mythic":
			legendary += 1
		elif it.rarity == "rare":
			rare += 1
		var t: String = it.effect.get("type", "")
		if t == "burn" or t == "burn_focus": fx.burn += 1
		if t == "frost": fx.frost += 1
		if t == "focus" or t == "burn_focus": fx.focus += 1
	if legendary >= 6:
		b.atk += 6; b.def += 3; b.crit += 5; b.names.append("Titan")
	elif rare >= 6:
		b.atk += 3; b.def += 2; b.hp += 15; b.names.append("Şövalye")
	if fx.burn >= 2:
		b.atk += 3; b.names.append("Alev")
	if fx.frost >= 2:
		b.def += 2; b.names.append("Buz")
	if fx.focus >= 2:
		b.crit += 4; b.names.append("Rün")
	return b


func total_atk() -> int:
	var v := int(base.atk + _equip_sum("atk") + set_bonus().atk)
	if shrine_type == "atk" and shrine_left > 0:
		v = int(v * 1.5)
	if skills and skills.oath_active():
		v = int(v * 1.5)
	if crystal > 0:
		# Kârun gücünü emer: kristal başına %15.
		v = int(v * (1.0 - 0.15 * crystal))
	return v


func total_def() -> int:
	var v := int(base.def + _equip_sum("def") + set_bonus().def)
	if style == "warrior" and hp <= max_hp() * 0.35:
		v += 6
	return v


func max_hp() -> int:
	return int(base.maxHp + _equip_sum("hp") + set_bonus().hp)


func total_crit() -> float:
	return base.crit + _equip_sum("crit") + set_bonus().crit


func total_spd() -> float:
	var v: float = base.spd + _equip_sum("spd")
	var kind: String = equipment.weapon.get("kind", "")
	if kind == "dagger" or kind == "bow":
		v += 0.15
	elif kind == "sword":
		v -= 0.15
	if shrine_type == "spd" and shrine_left > 0:
		v += 0.5
	if speed_potion > 0:
		v *= 1.35
	if slow > 0:
		v *= 0.6
	if heavy > 0:
		v *= 0.55
	return maxf(0.5, v)


func roll_crit() -> bool:
	return randf() * 100.0 < total_crit()


func weapon_kind() -> String:
	return equipment.weapon.get("kind", "")


# ── Kare güncellemesi ────────────────────────────────────────────────

func tick() -> void:
	if not alive():
		return
	_timers()
	if frozen > 0:
		# Donmuş: buz kabuğunun içinde ne yürür, ne saldırır, ne atılır.
		frozen -= 1
		vel = Vector2.ZERO
		moving = false
		if frozen == 0:
			main.burst(position + Vector2(0, -20), 30, Color(0.75, 0.92, 1.0))
		queue_redraw()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	input += main.touch_move
	input = input.limit_length(1.0)
	if warp > 0:
		input = -input
	aim = (main.aim_point() - position).angle()
	if rooted > 0:
		# Kök sarmış: yerinden kıpırdayamaz, atılamaz; ama nişan alıp ateş edebilir.
		rooted -= 1
		input = Vector2.ZERO
		vel = Vector2.ZERO
		if rooted == 0:
			main.burst(position + Vector2(0, 8), 26, Color(0.55, 0.42, 0.3))
	elif Input.is_action_just_pressed("dash") and heavy == 0:
		_try_dash(input)
	if dash_left > 0:
		_dash_step()
	else:
		_move(input)
	if (Input.is_action_pressed("attack") and main.mouse_in_world()) or main.touch_attack:
		_try_attack()
	_attack_phase()
	if Input.is_action_just_pressed("skill_q") or main.touch_q:
		use_q()
	if Input.is_action_just_pressed("skill_r") or main.touch_r:
		use_r()
	if Input.is_action_just_pressed("skill_f") or main.touch_f:
		skills.use_f()
	if Input.is_action_just_pressed("skill_t") or main.touch_v:
		skills.use_v()
	skills.tick()
	anim_timer += 1
	if anim_timer >= 8:
		anim_timer = 0
		frame = frame % 4 + 1
		if moving and (frame == 1 or frame == 3) and dash_left == 0:
			# Adım tozu: ayak yere bastığında küçük koyu bulut.
			main.burst(position + Vector2(-6.0 if facing_left else 6.0, HERO_FEET - 2), 9, Color(0.22, 0.2, 0.18))
	queue_redraw()


func _timers() -> void:
	for n: String in ["attack_cd", "dash_cd", "q_cd", "r_cd", "invincible", "execution_flash", "pose_t", "post_t", "hurt_t"]:
		if get(n) > 0:
			set(n, get(n) - 1)
	since_hit += 1
	if speed_potion > 0:
		speed_potion -= 1
	if slow > 0:
		slow -= 1
	if in_storm > 0:
		in_storm -= 1
	if cleansed > 0:
		cleansed -= 1
	if blood_mark > 0:
		blood_mark -= 1
	if heavy > 0:
		heavy -= 1
	if warp > 0:
		warp -= 1
	if crystal > 0:
		crystal_t += 1
		if crystal_t >= 360:
			crystal -= 1
			crystal_t = 0
	if frost > 0:
		# Yürümek yavaşça, atılmak hızlıca eritir; uzun süre yeni yığın gelmezse kendiliğinden azalır.
		frost_age += 1
		frost_melt += 4.0 if dash_left > 0 else ((0.5 if in_storm > 0 else 1.0) if moving else 0.0)
		if frost_melt >= FROST_MELT or frost_age >= 480:
			frost -= 1
			frost_melt = 0.0
			frost_age = 360 if frost_age >= 480 else frost_age
	if shrine_left > 0:
		shrine_left -= 1
		if shrine_type == "regen":
			shrine_tick += 1
			if shrine_tick >= 30:
				shrine_tick = 0
				heal(2)
	if burn > 0 or poison > 0 or void_burn > 0:
		dot_timer += 1
		if dot_timer >= 60:
			dot_timer = 0
			var dmg := (3 if burn > 0 else 0) + (2 if poison > 0 else 0) + (4 if void_burn > 0 else 0)
			hp = maxi(1, hp - dmg)
			main.float_text(position + Vector2(0, -50), str(dmg), Color("9cff2e") if poison > 0 else Color("ff6a00"))
		burn = maxi(0, burn - 1)
		poison = maxi(0, poison - 1)
		void_burn = maxi(0, void_burn - 1)
	elif since_hit > 300:
		regen_timer += 1
		if regen_timer >= 90:
			regen_timer = 0
			heal(1)


func _move(input: Vector2) -> void:
	var spd := total_spd()
	var target := input * spd
	match style:
		"warrior":
			vel += (target - vel) * 0.15
			vel *= 1.0 - (0.20 if input != Vector2.ZERO else 0.30)
		"mage":
			vel += (target - vel) * 0.22
			if input == Vector2.ZERO:
				vel *= 0.88
		_:
			vel = target
	if vel.length() < 0.02:
		vel = Vector2.ZERO
	moving = vel.length() > 0.15
	if vel != Vector2.ZERO:
		position = main.world.move_circle(position, vel, RADIUS)
	if vel.x > 0.3:
		facing_left = false
	elif vel.x < -0.3:
		facing_left = true
	elif not moving and phase != "idle":
		facing_left = cos(aim) < 0


func _try_dash(input: Vector2) -> void:
	if input == Vector2.ZERO or dash_cd > 0 or dash_left > 0:
		return
	dash_dir = input.normalized()
	dash_left = dash_duration
	dash_cd = dash_cd_max
	invincible = maxi(invincible, dash_duration + 5)


func _dash_step() -> void:
	dash_left -= 1
	position = main.world.move_circle(position, dash_dir * total_spd() * dash_mult, RADIUS)
	main.spawn_afterimage(self)
	moving = true


# ── Temel saldırı ────────────────────────────────────────────────────

func _try_attack() -> void:
	if attack_cd > 0 or phase != "idle":
		return
	facing_left = cos(aim) < 0
	# El Çabukluğu kartları attack_cd_base'i düşürür; saldırı beklemesi onunla orantılı kısalır.
	var speed_k: float = float(attack_cd_base) / float({"warrior": 28, "ranger": 18, "mage": 32}[style])
	if skills.oath_active():
		speed_k *= 0.6
	if style == "ranger" and weapon_kind() == "bow":
		attack_cd = int(30 * speed_k)
		phase = "draw"
		phase_timer = 15
	elif style == "mage":
		attack_cd = int(38 * speed_k)
		phase = "charge"
		phase_timer = 18
	else:
		attack_cd = int(55 * speed_k)
		phase = "windup"
		phase_timer = 10
		swing_done = false


func _attack_phase() -> void:
	if phase == "idle":
		return
	phase_timer -= 1
	match phase:
		"windup":
			if phase_timer <= 0:
				phase = "swing"
				phase_timer = 8
				Sfx.play("swing")
		"swing":
			if not swing_done:
				swing_done = _swing_hit()
			if phase_timer <= 0:
				phase = "recovery"
				phase_timer = 14
		"recovery":
			if phase_timer <= 0:
				phase = "idle"
		"draw":
			if phase_timer <= 0:
				var dmg := int(total_atk() * 1.35)
				var crit := roll_crit()
				main.spawn_projectile("arrow", muzzle(aim), aim, dmg * (2 if crit else 1), crit, muzzle_lift())
				Sfx.play("archer")
				post_t = 12
				phase = "idle"
		"charge":
			if phase_timer <= 0:
				main.spawn_projectile("spell", muzzle(aim), aim, int(total_atk() * 1.5), false, muzzle_lift())
				Sfx.play("mage")
				post_t = 12
				phase = "idle"


func is_attacking() -> bool:
	return phase == "swing" or phase == "draw" or phase == "charge"


## Savaşçı savuruşu: 70 piksel, 2 radyanlık yay; vurduğu ilk karede yaydaki herkese işler.
func _swing_hit() -> bool:
	var hit := false
	main.make_noise(position)
	if not main.lanterns.is_empty():
		# Kılıç ucu kandile değerse kandil yanar.
		for k in 3:
			var tip := position + Vector2.from_angle(aim + (k - 1) * 0.6) * 52.0 + Vector2(0, -24)
			if main.hit_lanterns(tip, 22.0):
				hit = true
				break
	for e in main.targets():
		var to: Vector2 = e.position - position
		if to.length() > 70.0 + (40.0 if e is Boss else 0.0):
			continue
		if absf(angle_difference(aim, to.angle())) > 1.0:
			continue
		hit = true
		var crit := roll_crit()
		var dmg := int(total_atk() * 1.4) * (2 if crit else 1)
		if e is Enemy:
			e.hit_stop = 5
			if crit:
				e.stun = 60
		if e is Enemy and e.type == "buz_aynasi":
			# Kılıç yansımaz: ayna kabuğu doğrudan çatlatır.
			e.crack_shell()
		var killed: bool = e.take_damage(dmg, to, 5.0 if crit else 3.0)
		skills.on_hit()
		if crit:
			main.float_text(e.position + Vector2(0, -60), "KRİTİK!", Color("ffd700"))
			main.shake(8)
			Sfx.play("critical")
		if not killed:
			apply_weapon_effect(e, dmg)
			if e is Enemy and e.hp > 0 and e.hp <= e.max_hp * 0.2:
				e.take_damage(e.hp)
				execution_flash = 22
				main.shake(28)
				main.float_text(e.position + Vector2(0, -70), "İDAM!", Color("ff3b30"))
	if hit:
		main.hit_freeze(4)
		main.shake(4)
	return hit


func apply_weapon_effect(e: Node2D, dmg: int) -> void:
	var fx: Dictionary = equipment.weapon.get("effect", {})
	if fx.is_empty() or randf() > fx.get("chance", 0):
		return
	match fx.type:
		"frost":
			if e is Enemy:
				e.stun = fx.duration
				e.hit_stop = 4
		"burn":
			if e is Enemy:
				e.burned = fx.duration
		"burn_focus", "focus":
			if fx.type == "burn_focus" and e is Enemy:
				e.burned = fx.duration
			q_cd = maxi(0, q_cd - int(fx.get("q", 0)))
			r_cd = maxi(0, r_cd - int(fx.get("w", 0)))
		"lifesteal":
			heal(maxi(1, int(dmg * fx.get("rate", 0.1))))


# ── Yetenekler ───────────────────────────────────────────────────────

func skill_target(max_range: float, cone: float) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	var nearest: Node2D = null
	var nearest_d := INF
	for e in main.targets():
		var to: Vector2 = e.position - position
		var d := to.length()
		if d > max_range:
			continue
		if d < nearest_d:
			nearest_d = d
			nearest = e
		var diff := absf(angle_difference(aim, to.angle()))
		if diff <= cone / 2.0:
			var score := d + diff * 90.0
			if score < best_score:
				best_score = score
				best = e
	return best if best else nearest


func use_q() -> void:
	if q_cd > 0 or not alive():
		return
	# Rütbe çarpanı: seviyeyle güçlenir (hero_skills.gd).
	var atk := int(total_atk() * skills.power())
	var rk := skills.rank()
	match style:
		"warrior":
			var t := skill_target(240, 0.55 * PI)
			if t == null:
				return
			var boss := t is Boss
			if t is Enemy:
				t.stun = 55
				t.hit_stop = 6
			t.take_damage(int(atk * 2.35), t.position - position, 0.5 if boss else 1.4)
			main.slash_effect(position, t.position)
			main.shake(12)
			if rk >= 3:
				# Rütbe III: darbe çevreye yarılır.
				main.burst(t.position, 70, Color(0.6, 0.85, 1.0))
				for e in main.targets():
					if e != t and e.position.distance_to(t.position) < 70.0:
						e.take_damage(int(atk * 1.2), e.position - t.position, 1.2)
		"ranger":
			var t := skill_target(360, 0.55 * PI)
			if t == null:
				return
			var a := (t.position - position).angle()
			main.spawn_projectile("piercing", muzzle(a), a, int(atk * 1.9), false, muzzle_lift())
			if rk >= 3:
				# Rütbe III: iki yan delici ok daha.
				for side in [-0.18, 0.18]:
					main.spawn_projectile("piercing", muzzle(a), a + side, int(atk * 1.3), false, muzzle_lift())
			Sfx.play("archer")
		"mage":
			var t := skill_target(240, PI)
			if t == null:
				return
			var a := (t.position - position).angle()
			main.spawn_projectile("fireball", muzzle(a), a, int(atk * 2.0), false, muzzle_lift())
			if rk >= 3:
				for side in [-0.22, 0.22]:
					main.spawn_projectile("fireball", muzzle(a), a + side, int(atk * 1.1), false, muzzle_lift())
			Sfx.play("mage")
	q_cd = q_cd_max
	show_pose("q", 22)


func use_r() -> void:
	if r_cd > 0 or not alive():
		return
	var atk := int(total_atk() * skills.power())
	var rk := skills.rank()
	var grow := 1.0 + 0.08 * (rk - 1)
	match style:
		"warrior":
			var at := position + Vector2.from_angle(aim) * 80.0
			main.spawn_strike("sword", at, 120.0 * grow, int(atk * 1.85), 0)
			if rk >= 4:
				# Rütbe IV: iki gök kılıcı daha yanlara iner.
				for side in [-1.0, 1.0]:
					main.spawn_strike("sword", at + Vector2.from_angle(aim + PI / 2) * side * 110.0, 90.0 * grow, int(atk * 1.2), 10)
		"ranger":
			var list := main.targets().duplicate()
			list.sort_custom(func(a, b): return a.position.distance_to(position) < b.position.distance_to(position))
			for i in (8 if rk >= 4 else 5):
				var at: Vector2
				if i < list.size():
					at = list[i].position
				else:
					at = position + Vector2.from_angle(randf() * TAU) * randf_range(50, 170)
				main.spawn_strike("arrow", at, 80.0 * grow, int(atk * 1.35), i * 7)
		"mage":
			var t := skill_target(320, PI)
			var at: Vector2 = t.position if t else position + Vector2.from_angle(aim) * 120.0
			main.spawn_strike("meteor", at, 125.0 * grow, int(atk * 2.25), 0)
			if rk >= 4:
				main.spawn_strike("meteor", at + Vector2.from_angle(randf() * TAU) * 110.0, 90.0 * grow, int(atk * 1.4), 24)
	r_cd = r_cd_max
	show_pose("r", 26)


# ── Hasar, iyileşme, seviye ──────────────────────────────────────────

## Hasar uygular; isabet ettiyse true.
func take_damage(raw: int, _src: Node2D = null) -> bool:
	if is_invincible() or not alive():
		return false
	if blood_mark > 0:
		# Kan işareti: hasar %40 artar.
		raw = int(raw * 1.4)
	for h in main.others:
		if h is HeartHazard and is_instance_valid(h) and h.shields(position):
			# Sera'nın ışığı.
			main.float_text(position + Vector2(0, -56), "SERA KORUDU", Color(1.0, 0.92, 0.7))
			invincible = 20
			return false
	var dmg := maxi(1, raw - total_def())
	hp -= dmg
	invincible = 35
	hurt_t = 12
	since_hit = 0
	Game.hit_this_floor = true
	main.float_text(position + Vector2(0, -50), "-%d" % dmg, Color("ff5a5a"))
	main.shake(4)
	if hp <= 0:
		hp = 0
		died.emit()
	return true


func apply_debuff(kind: String) -> void:
	match kind:
		"burn": burn = 300
		"poison": poison = 0 if cleansed > 0 else 480
		"slow": slow = 180
		# İsabet zaten gerçekleşti (take_damage geçti): vuruşun açtığı kısa dokunulmazlık yığını engellemesin.
		"frost": add_frost(1, true)
		"root": root()
		"crystal":
			if crystal < CRYSTAL_MAX:
				crystal += 1
				main.float_text(position + Vector2(0, -64), "KRİSTAL %d/%d" % [crystal, CRYSTAL_MAX], Color(0.8, 0.5, 1.0))
			crystal_t = 0
		"warp":
			if warp == 0:
				main.float_text(position + Vector2(0, -64), "ÇARPIKLIK", Color(0.5, 0.95, 1.0))
			warp = WARP
		"heavy":
			if heavy == 0:
				main.float_text(position + Vector2(0, -64), "AĞIRLIK", Color(1.0, 0.85, 0.4))
			heavy = HEAVY
		"void":
			if void_burn == 0:
				main.float_text(position + Vector2(0, -64), "YOKLUK YANIĞI", Color(0.78, 0.45, 1.0))
			void_burn = VOID_BURN


## Kırağı yığını ekler. force: vuruş sonrası dokunulmazlığı yok sayar (hasarlı isabetler ve buz hapsi).
## Atılmanın dokunulmazlığı yalnız hasarsız soğuğu (ağ, fırtına, nefes) savuşturur.
## gentle: kar fırtınası gibi yavaş soğuk; eriyen yığının ilerlemesini sıfırlamaz.
func add_frost(n: int, force := false, gentle := false) -> void:
	if not alive() or frozen > 0 or god_mode or (not force and invincible > 0):
		return
	frost += n
	if not gentle:
		frost_age = 0
		frost_melt = 0.0
	if frost >= FROST_MAX:
		freeze()
	else:
		main.float_text(position + Vector2(0, -64), "KIRAĞI %d/%d" % [frost, FROST_MAX], Color(0.65, 0.88, 1.0))


## Donma: kısa süre buz kabuğunda kalır, yığınlar sıfırlanır.
func freeze(frames := FREEZE) -> void:
	if god_mode or not alive():
		return
	frost = 0
	frozen = maxi(frozen, frames)
	dash_left = 0
	vel = Vector2.ZERO
	phase = "idle"
	main.float_text(position + Vector2(0, -70), "DONDUN!", Color(0.75, 0.93, 1.0))
	main.burst(position + Vector2(0, -24), 44, Color(0.6, 0.85, 1.0))
	main.shake(6)


## Kök sarması: kısa süre yürüyemez ve atılamaz. Atılırken (dokunulmazken) ve arınma ışığında tutmaz.
func root(frames := ROOT) -> void:
	if not alive() or god_mode or cleansed > 0 or dash_left > 0 or frozen > 0:
		return
	if rooted == 0:
		main.float_text(position + Vector2(0, -64), "KÖK SARDI", Color(0.78, 0.62, 0.4))
	rooted = maxi(rooted, frames)
	dash_left = 0
	vel = Vector2.ZERO


## Kutsal Taş'ın arınma ışığı: zehir ve kök çözülür, ışıkta kaldıkça yenisi tutmaz.
## Kalp Pınarı'nın ışığı: kristaller ve yanık çözülür.
func cleanse_heart() -> void:
	if crystal > 0 or burn > 0:
		main.float_text(position + Vector2(0, -64), "KALP IŞIĞI", Color(1.0, 0.85, 0.5))
	crystal = 0
	burn = 0


func cleanse() -> void:
	if rooted > 0 or poison > 0:
		main.float_text(position + Vector2(0, -64), "ARINDIN", Color(1.0, 0.94, 0.7))
	rooted = 0
	poison = 0
	cleansed = 10


## Sıcak ışık (rün kandili): yığınlar erir.
func melt_frost() -> void:
	if frost > 0:
		frost = 0
		frost_melt = 0.0
		main.float_text(position + Vector2(0, -64), "ERİDİ", Color(1.0, 0.8, 0.45))


func heal(amount: int) -> void:
	if void_burn > 0:
		# Yokluk yanığı sürdükçe iyileşme yok.
		return
	hp = mini(max_hp(), hp + amount)


## Kan Yazıcısı'nın mührü: 4 sn boyunca alınan hasar artar.
func mark_blood(frames := MARK) -> void:
	if not alive() or god_mode:
		return
	if blood_mark == 0:
		main.float_text(position + Vector2(0, -70), "KAN İŞARETİ", Color(1.0, 0.3, 0.3))
	blood_mark = maxi(blood_mark, frames)


func gain_xp(amount: int) -> void:
	xp += amount
	if xp >= next_xp:
		xp -= next_xp
		level += 1
		# Daha yumuşak eğri: 100 kat boyunca ~20. seviyeye kadar gelişim sürsün (eskiden 1.5 ile ~15'te tıkanıyordu).
		next_xp = int(next_xp * 1.3)
		_level_passive()
		leveled_up.emit()


func _level_passive() -> void:
	# Her seviye: saldırı ve can büyür (hasarın seviyeye bağlı olması için); tarz kendi ekini de alır.
	base.atk += {"warrior": 2, "ranger": 2, "mage": 1}[style]
	base.maxHp += {"warrior": 8, "ranger": 5, "mage": 5}[style]
	heal(8)
	match style:
		"warrior":
			base.maxHp += 4
			heal(4)
			if level % 2 == 0:
				base.def += 1
		"ranger":
			base.spd += 0.06
		"mage":
			base.atk += 2
			q_cd_max = maxi(420, int(q_cd_max * 0.97))
			r_cd_max = maxi(540, int(r_cd_max * 0.97))
	if level == 5:
		if bow_kills >= sword_kills:
			base.crit += 8
		else:
			base.atk += 5
			base.def += 3


func apply_upgrade(id: String) -> void:
	match id:
		"atk": base.atk += 4
		"def": base.def += 3
		"hp":
			base.maxHp += 25
			hp = max_hp()
		"spd": base.spd += 0.4
		"crit": base.crit += 7
		"lifesteal": Game.lifesteal_upgrade = true
		"atkspd": attack_cd_base = maxi(8, attack_cd_base - 5)
		"balanced":
			base.atk += 2; base.def += 2; base.maxHp += 10
		"ironheart":
			base.maxHp += 40; base.spd = maxf(1.0, base.spd - 0.1)
		"lethal":
			base.atk += 5; base.crit += 5
		"berserker":
			base.atk += 6; base.maxHp = maxi(30, base.maxHp - 10)
		"turtle":
			base.def += 5; base.spd = maxf(1.0, base.spd - 0.2)
		"fullheal":
			hp = max_hp(); burn = 0; poison = 0; slow = 0; frost = 0
		"dashmaster": dash_cd_max = 20
		"barter": Game.barter = true
		"luck": base.luck += 10
	hp = mini(hp, max_hp())


# ── Çanta ve ekipman ─────────────────────────────────────────────────

## Çantaya ekler; yer yoksa false.
func add_to_bag(item: Dictionary) -> bool:
	if ItemData.is_stackable(item):
		for it: Dictionary in inventory:
			if it.type == item.type:
				it.count += item.get("count", 1)
				return true
	if inventory.size() >= BAG_SIZE:
		return false
	inventory.append(item)
	return true


func equip(index: int) -> String:
	var item: Dictionary = inventory[index]
	var slot := ItemData.slot_of(item)
	if slot == "":
		return "Bu eşya kuşanılamaz."
	if item.kind == "dagger":
		return "Hançeri hiçbir dövüş tarzı kullanamıyor."
	var locks := {"sword": "warrior", "bow": "ranger", "staff": "mage"}
	if locks.has(item.kind) and locks[item.kind] != style:
		return "%s bu dövüş tarzıyla kullanılamaz." % item.name
	var old: Dictionary = equipment[slot]
	equipment[slot] = item
	Sfx.play_equip(item)
	inventory.remove_at(index)
	if not old.is_empty():
		inventory.insert(index, old)
	hp = mini(hp, max_hp())
	return ""


func unequip(slot: String) -> bool:
	var it: Dictionary = equipment[slot]
	if it.is_empty() or inventory.size() >= BAG_SIZE:
		return false
	if slot == "weapon":
		return false
	inventory.append(it)
	equipment[slot] = {}
	hp = mini(hp, max_hp())
	return true


## İksir kullanır. Kullanıldıysa true.
func use_consumable(index: int) -> bool:
	var it: Dictionary = inventory[index]
	match it.type:
		"potion_red":
			if hp >= max_hp():
				return false
			heal(30)
		"potion_blue":
			speed_potion = 600
		_:
			return false
	it.count -= 1
	if it.count <= 0:
		inventory.remove_at(index)
	main._quest_event("potion")
	return true


func potion_count(type: String) -> int:
	for it: Dictionary in inventory:
		if it.type == type:
			return it.get("count", 1)
	return 0


## Kısayol (1 / 2): çantadaki o türden iksiri kullanır.
func use_potion_type(type: String) -> bool:
	for i in inventory.size():
		if inventory[i].type == type:
			return use_consumable(i)
	return false


# ── Çizim ────────────────────────────────────────────────────────────

func _draw() -> void:
	var s: float = ClassData.STYLES[style].draw_scale
	var size := 48.0 * s
	var hover := sin(Time.get_ticks_msec() / 480.0) * 3.5 if style == "mage" else 0.0
	var box := Rect2(-size / 2, -size / 2 + hover, size, size)
	draw_set_transform(Vector2(0, 24), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 18, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO)
	_draw_attack_fx()
	var hk := hero_key()
	if hk != "":
		_draw_hero(hk)
		return
	var key := "%s_%s%d" % [style, "walk" if moving else "idle", frame]
	if moving:
		# 4 vuruşlu adım: adım1, geçiş, adım2, geçiş (walk3/walk4 varsa onlar).
		if Sprites.tex("%s_walk4" % style):
			key = "%s_walk%d" % [style, frame]
		else:
			key = ["%s_walk1", "%s_idle1", "%s_walk2", "%s_idle1"][frame - 1] % style
	else:
		key = "%s_idle1" % style
	if is_attacking():
		key = style + "_attack"
	var mod := Color.WHITE
	if invincible > 0 and (invincible / 4) % 2 == 0 and not god_mode:
		mod = Color(1.6, 0.6, 0.5, 0.45)
	if frozen > 0:
		mod = mod * Color(0.62, 0.85, 1.25)
	elif frost > 0:
		# Kırağı: yığın arttıkça soğuk mavi.
		var fk := float(frost) / FROST_MAX
		mod = mod * Color(1.0 - 0.25 * fk, 1.0 - 0.08 * fk, 1.0 + 0.15 * fk)
	Sprites.draw_actor(self, key, box, facing_left, moving and frozen == 0, is_attacking(), mod)
	if frozen > 0:
		_draw_ice_shell(box)
	if rooted > 0:
		_draw_roots(box)


## Kahramanın çizim ölçeği: 1. bölgede HERO_SCALE_MIN, her bölgede bir adım, 10. bölgede HERO_SCALE.
func hero_scale() -> float:
	if full_power:
		return HERO_SCALE
	return lerpf(HERO_SCALE_MIN, HERO_SCALE, clampf((Game.zone() - 1) / 9.0, 0.0, 1.0))


## Merminin çıktığı yer: silahın ucu (yay / avuç) nişan yönünde, karelerden ölçülmüş uzaklıkta.
## Ölçüler 840x560 tuvalde: yay ~165 px önde, büyücü avucu ~150 px önde (ölçekle küçülür).
func muzzle(angle: float) -> Vector2:
	var reach := (165.0 if style == "ranger" else 150.0) * hero_scale()
	var q := position + Vector2.from_angle(angle) * reach
	# Duvara dayalıyken uç duvarın içinde kalmasın (mermi doğar doğmaz söner).
	return q if main.world.is_walkable(q) else position


## Silah ucunun yerden yüksekliği (mermi çizimi buradan başlar): yay ~320, avuç ~280 px ayaktan yukarıda.
func muzzle_lift() -> float:
	return (320.0 if style == "ranger" else 280.0) * hero_scale() - HERO_FEET


func show_pose(p: String, frames: int) -> void:
	pose = p
	pose_t = frames
	facing_left = cos(aim) < 0


func hero_stage() -> int:
	if full_power:
		return 3
	return 1 + int(Game.bosses_killed >= 3) + int(Game.bosses_killed >= 6)


## Gösterilecek boyalı kare; kareler yoksa "" (eski çizime düşer).
func hero_key() -> String:
	var pre := "hero_%s_%d_" % [style, hero_stage()]
	if Sprites.tex(pre + "idle1") == null:
		return ""
	var k := ""
	if hurt_t > 0 and pose_t == 0:
		k = "hurt"
	elif pose_t > 0:
		k = pose
	elif dash_left > 0 or (skills and skills.lunge_left > 0):
		k = "f" if skills and skills.lunge_left > 0 else "dash"
	elif phase == "windup" or phase == "draw" or phase == "charge":
		k = "atk1"
	elif phase == "swing":
		k = "atk2"
	elif phase == "recovery":
		k = "atk3"
	elif post_t > 0:
		k = "atk2" if post_t > 7 else "atk3"
	elif moving:
		k = "walk%d" % frame
	else:
		k = "idle1" if (Time.get_ticks_msec() / 700) % 2 == 0 else "idle2"
	return pre + k


## Kahramanı çizer: ayak çapası HERO_FEET'te; nefes, adım sekmesi ve vuruş anında ileri hamle.
func _draw_hero(key: String) -> void:
	var tex := Sprites.tex(key)
	var now := Time.get_ticks_msec()
	var sx := 1.0
	var sy := 1.0
	var off := Vector2(0, HERO_FEET)
	var dir := -1.0 if facing_left else 1.0
	if style == "mage":
		off.y += sin(now / 480.0) * 2.5 - 2.0
	if key.ends_with("atk2"):
		off.x += 5.0 * dir
	elif key.contains("walk"):
		off.y -= absf(sin(now / 133.0)) * 2.0
	elif key.contains("idle"):
		var bt := sin(now / 260.0)
		sy = 1.0 + bt * 0.012
		sx = 1.0 - bt * 0.006
	var mod := Color.WHITE
	if invincible > 0 and (invincible / 4) % 2 == 0 and not god_mode:
		mod = Color(1.6, 0.6, 0.5, 0.55)
	if frozen > 0:
		mod = mod * Color(0.62, 0.85, 1.25)
	elif frost > 0:
		var fk := float(frost) / FROST_MAX
		mod = mod * Color(1.0 - 0.25 * fk, 1.0 - 0.08 * fk, 1.0 + 0.15 * fk)
	var hs := hero_scale()
	draw_set_transform(off, 0, Vector2(dir * sx, sy))
	draw_texture_rect(tex, Rect2(-HERO_ANCHOR * hs, HERO_CANVAS * hs), false, mod)
	draw_set_transform(Vector2.ZERO)
	var box := Rect2(-40, HERO_FEET - 100, 80, 100)
	if frozen > 0:
		_draw_ice_shell(box)
	if rooted > 0:
		_draw_roots(box)


## Aşama değişimi (3. ve 6. boss): zırh dönüşür; kısa güç pozu, ışık ve ad.
func stage_up() -> void:
	var st := hero_stage()
	var title: String = ["", "", "MÜHÜR NÖBETÇİSİ", "GÖK NÖBETÇİSİ"][st]
	show_pose("power", 110)
	main.fx.add_sprite(position, "fx_ring_gold" if st == 3 else "fx_ring_blue", 260, Color.WHITE, 40, 0.3)
	main.burst(position + Vector2(0, -40), 120, Color(1.0, 0.85, 0.45) if st == 3 else Color(0.6, 0.85, 1.0))
	main.float_text(position + Vector2(0, -120), title, Color(1.0, 0.88, 0.55))
	main.shake(12)
	Log.add("Arktan dönüştü: %s" % title.capitalize(), "level")


## Donma kabuğu: gövdeyi saran yarı saydam buz bloğu (yumuşak kenarlı, köşeli kristal yüzeyler).
func _draw_ice_shell(box: Rect2) -> void:
	var k := clampf(float(frozen) / 8.0, 0.0, 1.0)
	var c := box.get_center() + Vector2(0, box.size.y * 0.06)
	var w := box.size.x * 0.46
	var h := box.size.y * 0.56
	var pts := PackedVector2Array([c + Vector2(-w * 0.8, h), c + Vector2(-w, h * 0.1), c + Vector2(-w * 0.55, -h * 0.85),
		c + Vector2(0, -h), c + Vector2(w * 0.6, -h * 0.8), c + Vector2(w, 0), c + Vector2(w * 0.75, h)])
	draw_colored_polygon(pts, Color(0.62, 0.84, 1.0, 0.32 * k))
	var rim := pts.duplicate()
	rim.append(pts[0])
	draw_polyline(rim, Color(0.85, 0.95, 1.0, 0.75 * k), 1.6, true)
	draw_line(c + Vector2(-w * 0.55, -h * 0.85), c + Vector2(-w * 0.15, h * 0.4), Color(1, 1, 1, 0.35 * k), 1.2, true)
	draw_line(c + Vector2(w * 0.6, -h * 0.8), c + Vector2(w * 0.25, h * 0.2), Color(1, 1, 1, 0.3 * k), 1.0, true)


## Kök sarması: ayağın çevresinde boyalı kök halkası (yoksa kodla kıvrık kökler); bırakırken geri çekilir.
func _draw_roots(box: Rect2) -> void:
	var k := clampf(float(rooted) / 10.0, 0.0, 1.0) * clampf(float(ROOT - rooted + 6) / 6.0, 0.0, 1.0)
	var feet := Vector2(0, box.end.y - 6)
	var tex := Sprites.tex("fx_root_snare")
	if tex:
		var w := box.size.x * 1.25
		var h := w * tex.get_height() / tex.get_width()
		draw_texture_rect(tex, Rect2(feet.x - w / 2, feet.y - h * 0.72 * k, w, h * k), false, Color(1, 1, 1, k))
		return
	for i in 7:
		var ang := i * TAU / 7.0
		var base := feet + Vector2(cos(ang) * 22.0, sin(ang) * 8.0)
		var tip := feet + Vector2(cos(ang) * 8.0, -26.0 * k + sin(ang) * 4.0)
		var mid := (base + tip) * 0.5 + Vector2(sin(ang * 3.0) * 7.0, 0)
		var pts := PackedVector2Array([base, mid, tip])
		draw_polyline(pts, Color(0.16, 0.1, 0.06, k), 4.5, true)
		draw_polyline(pts, Color(0.45, 0.3, 0.18, k), 2.2, true)


## Kırağı yığınları başın üstünde küçük parlayan buz kristalleri; donunca kabuğun soğuk parıltısı.
func _paint_frost(g: GlowLayer) -> void:
	if not alive():
		return
	var size: float = 48.0 * ClassData.STYLES[style].draw_scale
	var t := Time.get_ticks_msec() / 1000.0
	if frozen > 0:
		var pulse := 0.8 + 0.2 * sin(t * 6.0)
		g.glow(Vector2(0, -2), size * 0.75, Color(0.45, 0.75, 1.0, 0.35 * pulse))
		g.glow(Vector2(-size * 0.15, -size * 0.3), size * 0.18, Color(0.9, 0.97, 1.0, 0.5))
		return
	if void_burn > 0:
		# Yokluk yanığı: gövdeyi yalayan mor-siyah alev dilleri.
		for i in 5:
			var q := fmod(t * 1.3 + i * 0.21, 1.0)
			var at := Vector2(sin(i * 2.3 + t * 2.0) * size * 0.22, size * 0.15 - q * size * 0.7)
			g.glow(at, 7.0 * (1.0 - q * 0.5), Color(0.62, 0.28, 1.0, 0.45 * (1.0 - q)))
	if crystal > 0:
		# Kristalleşme: omuzlarda mor kristal parıltıları.
		for k in crystal:
			var at := Vector2((k - (crystal - 1) * 0.5) * 14.0, -size * 0.45)
			g.glow(at, 7.0, Color(0.72, 0.32, 1.0, 0.6))
			g.glow(at, 2.5, Color(0.95, 0.85, 1.0, 0.9))
	if warp > 0:
		# Çarpıklık: gövdenin çevresinde kırılan camgöbeği çizgiler.
		var wa := minf(1.0, warp / 15.0)
		for k in 5:
			var a0 := k * TAU / 5.0 + t * 2.5
			var p0 := Vector2.from_angle(a0) * size * 0.4 + Vector2(0, -size * 0.35)
			var p1 := Vector2.from_angle(a0 + 0.5) * size * 0.55 + Vector2(0, -size * 0.35)
			g.streak(PackedVector2Array([p0, p1]), 1.2, Color(0.5, 0.95, 1.0, 0.6 * wa))
	if heavy > 0:
		# Ağırlık: ayağın altında dönen altın yerçekimi rünü.
		var ha := minf(1.0, heavy / 15.0)
		g.draw_set_transform(Vector2(0, size * 0.42), -t * 1.2, Vector2(1, 0.42))
		g.ring(Vector2.ZERO, 20.0, 1.6, Color(1.0, 0.82, 0.35, 0.7 * ha))
		for k in 4:
			g.glow(Vector2.from_angle(k * TAU / 4.0) * 20.0, 3.0, Color(1.0, 0.9, 0.55, 0.8 * ha))
		g.draw_set_transform(Vector2.ZERO)
	if blood_mark > 0:
		# Kan işareti: başın üstünde dönen kırmızı mühür.
		var a := minf(1.0, blood_mark / 20.0)
		var c := Vector2(0, -size * 0.85)
		g.draw_set_transform(c, t * 1.5, Vector2(1, 0.5))
		g.ring(Vector2.ZERO, 14.0, 1.6, Color(1.0, 0.2, 0.2, 0.75 * a))
		for k in 6:
			g.glow(Vector2.from_angle(k * TAU / 6.0) * 14.0, 3.0, Color(1.0, 0.4, 0.3, 0.8 * a))
		g.draw_set_transform(Vector2.ZERO)
		g.glow(c, 18.0, Color(1.0, 0.15, 0.15, 0.25 * a))
	for i in frost:
		var at := Vector2((i - (frost - 1) * 0.5) * 12.0, -size * 0.62 + sin(t * 3.0 + i) * 1.5)
		g.glow(at, 9.0, Color(0.45, 0.78, 1.0, 0.55))
		g.draw_set_transform(at, 0.0, Vector2(0.55, 1.0))
		g.glow(Vector2.ZERO, 4.5, Color(0.92, 0.98, 1.0, 0.9))
		g.draw_set_transform(Vector2.ZERO)


## Kuşanılan zırhın nadirliği: gövdenin arkasında soluk bir hale. Sıradan eşyada yok.
func _paint_armor_glow(g: GlowLayer) -> void:
	var r: String = equipment.get("armor", {}).get("rarity", "common")
	if r == "common" or not alive():
		return
	var size: float = 48.0 * ClassData.STYLES[style].draw_scale
	var t := Time.get_ticks_msec() / 1000.0
	var c := ItemData.fx_color(r)
	var hover := sin(t * 1000.0 / 480.0) * 3.5 if style == "mage" else 0.0
	var a := (0.62 if r == "mythic" else 0.5) * (0.85 + 0.15 * sin(t * 2.2))
	var at := Vector2(0, hover - size * 0.02)
	g.draw_set_transform(at, 0, Vector2(0.62, 1.0))
	g.glow(Vector2.ZERO, size * 0.7, Color(c, a))
	g.glow(Vector2.ZERO, size * 0.4, Color(c, a * 0.6))
	g.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Silahın nadirliği: yay / kılıç / asa başında hafifçe nabız atan parıltı. Sıradan eşyada yok.
func _paint_weapon_glow(g: GlowLayer) -> void:
	var r: String = equipment.get("weapon", {}).get("rarity", "common")
	if r == "common" or not alive():
		return
	var size: float = 48.0 * ClassData.STYLES[style].draw_scale
	var t := Time.get_ticks_msec() / 1000.0
	var hover := sin(t * 1000.0 / 480.0) * 3.5 if style == "mage" else 0.0
	# Sprite içindeki silah konumu (u, v: 0..1), sağa bakan karede.
	var uv: Vector2 = {"ranger": Vector2(0.45, 0.5), "warrior": Vector2(0.42, 0.6), "mage": Vector2(0.36, 0.15)}[style]
	var fs := -1.0 if facing_left else 1.0
	var at := Vector2((uv.x - 0.5) * size * fs, -size / 2 + hover + uv.y * size)
	var c := ItemData.fx_color(r)
	var pulse := 0.8 + 0.2 * sin(t * 3.0)
	var rad: float = size * (0.3 if style == "ranger" else 0.2)
	g.glow(at, rad, Color(c, 0.45 * pulse))
	if r in ["legendary", "mythic"]:
		g.sprite("fx_spark", at, Vector2.ONE * size * 0.32 * pulse, Color(c, 0.22 * pulse), t * 0.6)


func _draw_attack_fx() -> void:
	match phase:
		"windup":
			draw_arc(Vector2.ZERO, 30, aim - 1.0, aim + 1.0, 32, Color(1, 1, 1, 0.15), 2, true)
		"swing":
			var k := 1.0 - phase_timer / 8.0
			var a0 := aim - 1.0
			var a1 := a0 + 2.0 * k
			if Sprites.tex("fx_slash_w"):
				# Boyalı yay: dışbükey yüzü nişan yönüne bakar, rengi silahın nadirliği.
				var tint := ItemData.fx_color(equipment.weapon.get("rarity", "common"))
				# Kılıç izinin karelerdeki yeri (840x560 tuvalde ~120 px önde, ayaktan ~240 px yukarıda), boya göre.
				var hs := hero_scale() if hero_key() != "" else HERO_SCALE
				var s := 120.0 * (0.85 + 0.3 * k) * hs / HERO_SCALE
				draw_set_transform(Vector2.from_angle(aim) * 120.0 * hs + Vector2(0, HERO_FEET - 240.0 * hs), aim - PI * 0.75)
				Sprites.draw_flat(self, "fx_slash_w", Rect2(-s / 2, -s / 2, s, s), Color(tint, 0.95 * (1.0 - k * 0.5)))
				draw_set_transform(Vector2.ZERO)
			else:
				draw_arc(Vector2.ZERO, 64, a0, a1, 40, Color(0.3, 0.9, 1.0, 0.18), 22, true)
				draw_arc(Vector2.ZERO, 62, a0, a1, 40, Color(0.85, 0.95, 1.0, 0.85), 9, true)
				draw_arc(Vector2.ZERO, 70, a0, a1, 40, Color(0.3, 0.9, 1.0, 0.5), 3, true)
		"draw":
			# Nişan çizgisi yayın ucundan.
			var hand := muzzle(aim) - position + Vector2(0, -muzzle_lift())
			var tip := hand + Vector2.from_angle(aim) * 34
			draw_line(hand, tip, Color(1, 0.9, 0.6, 0.25), 5, true)
			draw_line(hand, tip, Color(1, 0.9, 0.6, 0.7), 1.6, true)
		"charge":
			var r := lerpf(20, 48, 1.0 - phase_timer / 18.0)
			# Ayak altında rün halkası, avuçta toplanan ışık.
			draw_arc(Vector2(0, HERO_FEET - 4), r, 0, TAU, 64, Color(0.7, 0.4, 1.0, 0.8), 2, true)
			draw_arc(Vector2(0, HERO_FEET - 4), r * 0.7, 0, TAU, 6, Color(0.9, 0.6, 1.0, 0.6), 1.5, true)
			var palm := muzzle(aim) - position + Vector2(0, -muzzle_lift())
			draw_circle(palm, 3.0 + r * 0.12, Color(0.85, 0.7, 1.0, 0.55))
