class_name Enemy
extends Actor
## Normal düşman (entities.js:739-1468): 180 piksel içinde oyuncuyu kovalar, yoksa ara sıra devriye gezer,
## 32 piksel içinde temasla vurur ve zehir / yanık / yavaşlatma bulaştırır.
## Bölge 2 yetenekleri: Gölge Balçığı ileri atılır ve ölünce ikiye bölünür, Tarikat Müridi yaklaşılınca
## solup uzağa ışınlanır, Kristal Örümceği kısa bir çömelmeden sonra oyuncuya sıçrar.
## Bölge 3 yetenekleri: goblin sürüsünden biri vurulunca diğerleri gözleri sararak hızlanır; Şaman iyileştiren
## kemik totemi diker, zehir küresi atar, goblinsiz kalınca dumanla kaybolup kaçar; Bombacı uyarı daireli bomba
## atar ve yaklaşılınca geri seker; Kölebaşı mor parlayan zincirle oyuncuyu çeker, yere vurup şok dalgası
## yayar, yarı canın altında öfkelenir.
## Bölge 4 yetenekleri: Kor İmpi zikzak uçar, gözleri parlayınca (tell) düz çizgide atılır ve arkasında kısa
## yanan iz lekeleri bırakır; Lav Golemi'nin çatlakları ~0.8 sn parlar, yere vurur ve lav gölü bırakır, vurduktan
## sonra soğuyup sertleşir (gri taş, hasar yarıya iner); Kül Rahibi oyuncunun ayağının altına 1-3 rün dairesi
## çizer (~1 sn tell) ve daireden alev sütunu fışkırır; canı %30'un altına inince ufalanıp kül bulutuna dönüşür,
## kısa süre görünmez kalır ve yakında yeniden belirir.

var type := "slime"
var display_name := ""
var max_hp := 10
var hp := 10
var atk := 5
var speed := 1.0
var xp := 10
var gold := 3
var debuff := ""
var size := 48.0
var sprite_key := "slime"
var tint := Color.WHITE
var is_minion := false
var ranged := false
var draw_mul := 1.0
## Bölünmeden doğan küçük balçık: bir daha bölünmez.
var small := false

const SURGE_RANGE := 56.0
const BLINK_NEAR := 90.0
const BLINK_FADE := 24
const LEAP_CROUCH := 30
const LEAP_REST := 50
var surge := 0
var surge_dir := Vector2.ZERO
var surge_hit := false
var blink := 0
var blink_cd := 0
var leap_state := ""
var leap_t := 0
var leap_cd := 60
var leap_vel := Vector2.ZERO
var leap_len := 1
var leap_hit := false

const POISON_GLOW := Color(0.72, 1.0, 0.18)
const CHAIN_GLOW := Color(0.72, 0.3, 1.0)
const FRENZY := 120
const PLANT_TELL := 30
const TOTEM_LIFE := 720
const TOTEM_RANGE := 120.0
const VANISH := 180
const HOP := 14
const CHAIN_TELL := 42
const CHAIN_THROW := 12
const CHAIN_RANGE := 230.0
const SLAM_TELL := 40
## Goblin: bir sürü üyesi vurulunca kısa süre hızlanır (gözler sarı parlar).
var frenzy := 0
## Şaman: asa yere vurulurken (tell) geri sayım, kendi totemi, dumanla görünmez kaçış.
var plant := 0
var totem_cd := 90
var my_totem: Enemy
var vanish := 0
var vanish_cd := 0
## Totem: ömrü ve iyileştirme nabzı.
var totem_age := 0
var heal_t := 0
## Bombacı: yaklaşılınca geri sekme.
var hop := 0
var hop_cd := 0
var hop_dir := Vector2.ZERO
## Kölebaşı: zincir ("tell" → "throw" → "pull" ya da "back"), yere vuruş ve öfke.
var chain_state := ""
var chain_t := 0
var chain_cd := 90
var chain_dir := Vector2.RIGHT
var chain_len := 0.0
var slam := 0
var slam_cd := 120
var slam_dir := Vector2.RIGHT
var enraged := false
## Kor İmpi: atılma ("tell" → "dash" → "rest"), zikzak evresi.
const DIVE_TELL := 24
const DIVE := 14
const DIVE_REST := 30
const DIVE_RANGE := 170.0
const DIVE_SPEED := 6.5
var dive_state := ""
var dive_t := 0
var dive_cd := 60
var dive_dir := Vector2.RIGHT
var dive_hit := false
var zig := randf() * TAU
## Lav Golemi: yere vuruş tell'i (slam/slam_dir/slam_cd kölebaşıyla ortak) ve vuruş sonrası sertleşme.
const GOLEM_SLAM_TELL := 48
const GOLEM_SLAM_R := 72.0
const HARDEN := 150
const HARDEN_GREY := Color(0.5, 0.5, 0.54)
var harden := 0
## Kül Rahibi: kül bulutu (önce ufalanma tell'i, sonra görünmez bekleme); yalnızca bir kez.
const ASH_TELL := 60
const ASH_HIDE := 120
const RUNE_R := 34.0
var ash := 0
var ash_hidden := 0
var ash_used := false
## Buz Zombisi: donduran pençe (kolunu geri çeker, eli maviye döner; tell bitince pençeler).
const ICE_GLOW := Color(0.55, 0.85, 1.0)
const CLAW_TELL := 30
const CLAW_RANGE := 40.0
var claw := 0
var claw_dir := Vector2.RIGHT
## Buz Aynası Örümceği: ayna kabuk döngüsü (3 sn kapalı, 2 sn açık), kırık kabuk ve buz ağı tell'i.
const MIRROR_OFF := 180
const MIRROR_ON := 120
const MIRROR_GLINT := 24
const SHELL_BROKEN := 300
const WEB_TELL := 36
var mirror := randi() % MIRROR_OFF
var shell_broken := 0
var web := 0
var web_cd := 90
var web_target := Vector2.ZERO
## Buz Ayısı: hücum ("tell" kükreme → "run" → duvara çarparsa sersemleme), yere vuruş, buz zırhı plakaları.
const CHARGE_TELL := 48
const CHARGE_RUN := 60
const CHARGE_SPEED := 6.2
const DAZE := 60
const STOMP_TELL := 36
var charge_state := ""
var charge_t := 0
var charge_cd := 120
var charge_dir := Vector2.RIGHT
var charge_hit := false
var dazed := 0
var plates := true
## Bölge 6. Diken Tazısı: kuşatma yönü (oyuncunun hangi yanından dolanır); atılma dive_* ile ortak.
const THORN_GLOW := Color(0.72, 0.32, 1.0)
const HOLY := Color(1.0, 0.92, 0.66)
var flank := 1.0 if randf() < 0.5 else -1.0
## Tazının atılması impten uzun: 60-160 px'ten oyuncuya yetişsin.
const HOUND_DASH := 17
const HOUND_SPEED := 8.0
## Spor Mantarı: şapka şişme tell'i.
const PUFF_TELL := 48
var puff := 0
var puff_cd := 60
## Kök Muhafızı: kök tuzağı (asa yere saplanır), %50'de kök salma (yenilenir, 3 isabet koparır).
const ROOT_CAST := 30
var root_cast := 0
var root_cd := 120
var root_target := Vector2.ZERO
var anchored := false
var anchor_hits := 0
var anchor_used := false
## Diken Rahibesi: sarmaşık kalkanı (bir sonraki vuruşu emer; her düşmanda olabilir).
var vine_shield := false
var shield_cd := 200
## Bölge 7. Gölge Yürüyücü: portal adımı (oyuncunun arkasında portal açılır, kendi yerinde solar, portaldan çıkıp pençeler).
const VOID_GLOW := Color(0.62, 0.28, 1.0)
const BLOOD_GLOW := Color(1.0, 0.2, 0.18)
const STEP_TELL := 42
var step := 0
var step_cd := 90
var step_at := Vector2.ZERO
## Kan Yazıcısı: havaya kan mührü çizer (tell), sonra oyuncuya kan işareti.
const SCRIBE_TELL := 48
var scribe := 0
## Gargoyl: taş uykusu (uyandırılınca gözler yanar), pike dalışı (yerde büyüyen gölge), %30'da yeniden taşlaşma.
const WAKE_TELL := 30
const RESTONE := 180
var stone := false
var wake := 0
var gdive := 0
var gdive_cd := 60
var gdive_from := Vector2.ZERO
var gdive_to := Vector2.ZERO
var restone := 0
var restone_hits := 0
var restone_used := false
## Bölge 8. Konsey Bilgesi: ışık mızrakları (asa kaldırılır, sonra hat üzerinde 3 daire), %50'de 2 ayna kopyası.
const GOLD_GLOW := Color(1.0, 0.82, 0.35)
const SAGE_CAST := 30
const DECOY_LIFE := 600
var sage_cast := 0
var sage_target := Vector2.ZERO
var decoy := false
var decoy_age := 0
var decoys_made := false
## Rün Bekçisi: topuz kalkar (tell), oyuncunun altında yerçekimi rünü; önden gelen hasar kalkana çarpar.
const GRAV_CAST := 24
var gcast := 0
var gcast_cd := 60
## Gök Muhafızı: rüzgâr savuruşu (0.6 sn tell, koni) ve kanat çırpıp süzülme.
const GUST_TELL := 36
const GUST_LEN := 130.0
const GUST_HALF := 0.6
var gust := 0
var gust_cd := 60
var gust_dir := Vector2.RIGHT
var glide := 0
var glide_cd := 90
var glide_dir := Vector2.RIGHT
## Bölge 9. Yörünge Taşı: taşlar hızlanıp parlar (tell), sonra halka halinde fırlar.
const RIFT_CYAN := Color(0.45, 0.95, 1.0)
const RING_TELL := 48
var ring_t := 0
var ring_cd2 := 90
## Yokluk Gözü: bakış (RiftHazard) sürerken yerinde kalır; ilk isabette ayna parçalarına dağılıp yanda birleşir.
var gaze_t := 0
var scattered := false
## Boşluk Yiyici: yırtığa dalar (hedef alınamaz), zemin altında ilerler, oyuncunun altında yırtık açıp fırlar.
const SINK := 20
const SURFACED := 110
var burrow := ""
var burrow_t := 0
var burrow_cd := 120
var burrow_to := Vector2.ZERO
## Yansıma (bölge 9'da Zaman Yankısı): oyuncunun her atışını 0.4 sn sonra geri yapar.
var echo_seen := 0
var echo_queue: Array = []
## Bölge 10. Rün klonları. Kılıç: 0.45 sn rün parıltısı (tell), düz atılma; büyücü: küre yelpazesi;
## dev: levhayı yere vurur (tell), kristal hattı; %50'de 3 sn kristal kabuk.
const RUNE_GLOW := Color(0.72, 0.32, 1.0)
const SLAB_TELL := 42
const SHELL_TIME := 180
var slab := 0
var slab_cd := 80
var slab_dir := Vector2.RIGHT
var cshell := 0
var cshell_used := false
## Göz / el parıltısının son çizimdeki yeri (GlowLayer bunu kullanır).
var _eye := Vector2.ZERO
var _hand := Vector2.ZERO

var attack_cd_max := 90
var attack_cd := 60
var attack_anim := 0
var flash := 0
var knock := Vector2.ZERO
var stun := 0
var hit_stop := 0
var burned := 0
var poisoned := 0
var marked := 0
var patrol := Vector2.ZERO
var facing_left := false
var moving := false
var anim_timer := 0
var frame := 1


func setup(enemy_type: String, floor_number: int, player: Player) -> void:
	type = enemy_type
	var d: Dictionary = EnemyData.TYPES[type]
	var m := EnemyData.scale_for_floor(floor_number)
	display_name = d.name
	if type == "time_echo":
		max_hp = int(player.base.maxHp * 0.7)
		atk = int(player.base.atk * 0.8)
		tint = Color(0.5, 1.0, 1.0, 0.75)
	else:
		max_hp = int(d.hp * m)
		atk = int(d.atk * m)
	hp = max_hp
	speed = d.spd
	xp = int(d.xp * m)
	gold = int((randf() * d.gold[0] + d.gold[1]) * m)
	debuff = d.debuff
	attack_cd_max = d.cd
	size = d.size
	sprite_key = d.sprite
	ranged = d.get("ranged", false)
	draw_mul = d.get("draw", 1.0)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if type == "totem":
		max_hp = 2
		hp = 2
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = 0.9
		l.color = POISON_GLOW
		l.energy = 0.8
		l.position = Vector2(0, -26)
		add_child(l)
	if type in ["kor_impi", "lav_golemi", "ocak_nobetcisi"]:
		# Kor ve lavdan yapılmışlar: karanlıkta kendi turuncu ışıkları seçilsin.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = 0.7 if type == "kor_impi" else 1.1
		l.color = Color(1.0, 0.5, 0.18)
		l.energy = 0.6
		l.position = Vector2(0, -size * 0.6)
		add_child(l)
	if type == "gargoyl":
		stone = true
	if type in ["run_klon_kilic", "run_klon_buyucu", "run_klon_dev"]:
		# Rün klonları: mor rün ve kızıl Kalp çatlakları.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = 0.95
		l.color = RUNE_GLOW.lerp(Color(1.0, 0.75, 0.6), 0.35)
		l.energy = 0.55
		l.position = Vector2(0, -size * 0.6)
		add_child(l)
	if type in ["yorunge_tasi", "yokluk_gozu", "bosluk_yiyici"]:
		# Camgöbeği yırtık ışığı: kara obsidyen zeminde seçilsinler.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = 0.9
		l.color = RIFT_CYAN.lerp(Color(0.8, 0.6, 1.0), 0.3)
		l.energy = 0.55
		l.position = Vector2(0, -size * 0.6)
		add_child(l)
	if type == "time_echo" and Game.zone() == 9:
		# Arktan'ın ayna camından yansıması: kendi sprite'ı, soğuk camgöbeği cam görünümü.
		sprite_key = Game.style
		tint = Color(0.62, 0.9, 1.0, 0.82)
		display_name = "YANSIMA"
		echo_seen = main.noise_frame
	if type in ["konsey_bilgesi", "run_bekcisi", "gok_muhafizi"]:
		# Altın rün kristali ışığı: mermer salonlarda gözler seçilsin.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = 0.9
		l.color = GOLD_GLOW.lerp(Color.WHITE, 0.3)
		l.energy = 0.45
		l.position = Vector2(0, -size * 0.7)
		add_child(l)
	if type in ["golge_yuruyucu", "kan_yazicisi", "gargoyl"]:
		# Yokluk alevi / kan ışığı: kara taş salonlarda seçilsin; soluk dolgu ışığı gövdeyi de aydınlatır.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = 0.95
		l.color = (BLOOD_GLOW if type == "kan_yazicisi" else VOID_GLOW).lerp(Color(1.0, 0.9, 0.85), 0.4)
		l.energy = 0.6
		l.position = Vector2(0, -size * 0.6)
		add_child(l)
	if type in ["diken_tazisi", "spor_mantari", "kok_muhafizi", "diken_rahibesi"]:
		# Mor zehir ışığı: yosunlu karanlık tapınakta göz ve benekler seçilsin.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		# Koyu kabuk-yosun bedenler karanlıkta kaybolmasın: mor ışığın yanında soluk sıcak dolgu ışığı.
		l.texture_scale = 0.8 if type == "diken_tazisi" else 1.05
		l.color = THORN_GLOW.lerp(Color(1.0, 0.9, 0.8), 0.45)
		l.energy = 0.6
		l.position = Vector2(0, -size * 0.6)
		add_child(l)
	if type in ["buz_zombisi", "buz_aynasi", "buz_ayisi"]:
		# Soğuk mavi göz ışığı: karanlık buz salonlarında seçilsinler.
		var l := PointLight2D.new()
		l.texture = Atmosphere.light_texture()
		l.texture_scale = 0.6 if type == "buz_zombisi" else 0.85
		l.color = ICE_GLOW
		l.energy = 0.45
		l.position = Vector2(0, -size * 0.6)
		add_child(l)
	if type in ["goblin", "goblin_saman", "goblin_bombaci", "kolebasi", "totem", "kor_impi", "lav_golemi", "kul_rahibi",
			"ocak_nobetcisi", "murekkep_hayaleti", "zincirli_arsivci", "ruhsuz_katip",
			"buz_zombisi", "buz_aynasi", "buz_ayisi", "diken_tazisi", "spor_mantari", "kok_muhafizi", "diken_rahibesi",
			"golge_yuruyucu", "kan_yazicisi", "gargoyl", "konsey_bilgesi", "run_bekcisi", "gok_muhafizi",
			"yorunge_tasi", "yokluk_gozu", "bosluk_yiyici", "run_klon_kilic", "run_klon_buyucu", "run_klon_dev"]:
		# Tell'ler karanlıkta seçilsin: toplamalı, ışıktan etkilenmeyen katman.
		add_child(GlowLayer.make(_paint_tells))


func tick() -> void:
	if flash > 0:
		flash -= 1
	if burned > 0:
		burned -= 1
	if poisoned > 0:
		poisoned -= 1
	if marked > 0:
		marked -= 1
	if attack_anim > 0:
		attack_anim -= 1
	if frenzy > 0:
		frenzy -= 1
	if harden > 0:
		harden -= 1
	if type == "buz_aynasi":
		mirror = (mirror + 1) % (MIRROR_OFF + MIRROR_ON)
		shell_broken = maxi(0, shell_broken - 1)
	if type == "totem":
		_totem_tick()
		queue_redraw()
		return
	if stun > 0 or hit_stop > 0:
		stun = maxi(0, stun - 1)
		hit_stop = maxi(0, hit_stop - 1)
		queue_redraw()
		return
	var p := main.player
	moving = false
	if blink_cd > 0:
		blink_cd -= 1
	if leap_cd > 0:
		leap_cd -= 1
	totem_cd = maxi(0, totem_cd - 1)
	vanish_cd = maxi(0, vanish_cd - 1)
	hop_cd = maxi(0, hop_cd - 1)
	chain_cd = maxi(0, chain_cd - 1)
	slam_cd = maxi(0, slam_cd - 1)
	dive_cd = maxi(0, dive_cd - 1)
	web_cd = maxi(0, web_cd - 1)
	charge_cd = maxi(0, charge_cd - 1)
	puff_cd = maxi(0, puff_cd - 1)
	root_cd = maxi(0, root_cd - 1)
	shield_cd = maxi(0, shield_cd - 1)
	step_cd = maxi(0, step_cd - 1)
	gdive_cd = maxi(0, gdive_cd - 1)
	gcast_cd = maxi(0, gcast_cd - 1)
	gust_cd = maxi(0, gust_cd - 1)
	glide_cd = maxi(0, glide_cd - 1)
	ring_cd2 = maxi(0, ring_cd2 - 1)
	burrow_cd = maxi(0, burrow_cd - 1)
	slab_cd = maxi(0, slab_cd - 1)
	if cshell > 0:
		cshell -= 1
	if _special(p):
		_animate()
		queue_redraw()
		return
	if knock.length() > 0.1:
		position = main.world.move_point(position, knock)
		knock *= 0.85
	else:
		knock = Vector2.ZERO
		var to := p.position - position
		var d := to.length()
		if d < 180.0 and p.alive():
			var v := to / maxf(d, 0.001) * speed * (1.55 if frenzy > 0 else 1.0)
			if type == "diken_tazisi" and d > 95.0:
				# Kuşatma: doğrudan değil, oyuncunun bir yanına doğru yay çizerek yaklaşır.
				var side := to.normalized().orthogonal() * flank
				v = (to / maxf(d, 0.001) + side * 0.9).normalized() * speed * (1.55 if frenzy > 0 else 1.0)
			if type in ["kor_impi", "murekkep_hayaleti"]:
				# Zikzak: kovalarken yönü iki yana salınır, okla vurması zorlaşır.
				v = v.rotated(sin(Engine.get_physics_frames() * 0.11 + zig) * 0.9)
			if ranged and d < 110.0:
				v = -v * 0.8
			if ranged and d < 150.0 and d >= 110.0:
				if absf(to.x) > 0.01:
					facing_left = to.x < 0
			elif d > 20.0:
				position = main.world.move_point(position, v)
				moving = true
			if absf(v.x) > 0.01:
				facing_left = v.x < 0
		else:
			if patrol == Vector2.ZERO and randf() < 0.015:
				patrol = Vector2.from_angle(randf() * TAU) * speed * 0.5
			if patrol != Vector2.ZERO:
				var np := main.world.move_point(position, patrol)
				if np == position:
					patrol = Vector2.ZERO
				else:
					position = np
					moving = true
					facing_left = patrol.x < 0
				if randf() < 0.01:
					patrol = Vector2.ZERO
	var pd := position.distance_to(p.position)
	if attack_cd > 0:
		attack_cd -= 1
	elif ranged and pd < 220.0 and p.alive():
		attack_cd = attack_cd_max
		attack_anim = 18
		if type == "goblin_bombaci":
			main.throw_bomb(self, p.position + Vector2(randf_range(-10, 10), randf_range(-8, 8)))
		elif type == "kul_rahibi":
			attack_anim = 30
			facing_left = p.position.x < position.x
			cast_runes(p.position)
		elif type == "diken_rahibesi":
			facing_left = p.position.x < position.x
			throw_seed(p.position + Vector2(randf_range(-12, 12), randf_range(-8, 8)))
		elif type == "ruhsuz_katip":
			# Keskin sayfa demeti: üç sayfa yelpaze gibi.
			facing_left = p.position.x < position.x
			var a0 := (p.position - position).angle()
			for i in 3:
				main.spawn_enemy_arrow(self, a0 + (i - 1) * 0.2)
		elif type == "run_klon_buyucu":
			facing_left = p.position.x < position.x
			rune_fan((p.position - position).angle(), 5, 0.22)
		else:
			main.spawn_enemy_arrow(self, (p.position - position).angle())
	elif type == "slime_shadow" and pd < SURGE_RANGE and p.alive():
		# Kısa ileri atılma: birkaç karede oyuncuya doğru akar, değerse bir kez vurur.
		attack_cd = attack_cd_max
		attack_anim = 18
		surge = 10
		surge_hit = false
		surge_dir = (p.position - position).normalized()
	elif not ranged and pd < 32.0 and p.alive():
		attack_cd = attack_cd_max
		attack_anim = 18
		if p.take_damage(atk, self):
			p.apply_debuff(debuff)
	_animate()
	queue_redraw()


func _animate() -> void:
	anim_timer += 1
	if anim_timer >= (11 if moving else 20) and knock == Vector2.ZERO:
		anim_timer = 0
		frame = 2 if frame == 1 else 1


## Türe özel hareketler. Bu kare normal kovalamanın yerine geçtiyse true döner.
func _special(p: Player) -> bool:
	var d := position.distance_to(p.position)
	match type:
		"slime_shadow":
			if surge > 0:
				surge -= 1
				position = main.world.move_point(position, surge_dir * 3.6)
				facing_left = surge_dir.x < 0
				if not surge_hit and position.distance_to(p.position) < 34.0 and p.alive():
					surge_hit = true
					if p.take_damage(atk, self):
						p.apply_debuff(debuff)
				return true
		"cultist":
			if blink > 0:
				blink -= 1
				if blink == 0:
					_blink_away(p)
				return true
			if blink_cd == 0 and d < BLINK_NEAR and p.alive() and knock == Vector2.ZERO:
				# Uyarı: mor dumanla solar, sonra 150-200 px öteye ışınlanır.
				blink = BLINK_FADE
				main.burst(position + Vector2(0, -20), 26, Color(0.62, 0.3, 1.0))
				return true
		"crystal_spider":
			return _leap(p, d)
		"goblin_saman":
			return _saman(p, d)
		"goblin_bombaci":
			return _bombaci(p, d)
		"kolebasi":
			return _kolebasi(p, d)
		"kor_impi":
			return _impi(p, d)
		"lav_golemi":
			return _golem(p, d)
		"kul_rahibi":
			return _rahip(p)
		"buz_zombisi":
			return _zombi(p, d)
		"buz_aynasi":
			return _ayna(p, d)
		"buz_ayisi":
			return _ayi(p, d)
		"diken_tazisi":
			return _tazi(p, d)
		"spor_mantari":
			return _mantar(p, d)
		"kok_muhafizi":
			return _muhafiz(p, d)
		"diken_rahibesi":
			return _rahibe(p, d)
		"golge_yuruyucu":
			return _yuruyucu(p, d)
		"kan_yazicisi":
			return _yazici(p, d)
		"gargoyl":
			return _gargoyl(p, d)
		"konsey_bilgesi":
			return _bilge(p, d)
		"run_bekcisi":
			return _bekci(p, d)
		"gok_muhafizi":
			return _muhafiz_gok(p, d)
		"yorunge_tasi":
			return _yorunge(p, d)
		"yokluk_gozu":
			return _goz(p, d)
		"bosluk_yiyici":
			return _yiyici(p, d)
		"time_echo":
			_echo_mirror(p)
		"run_klon_kilic":
			return _klon_kilic(p, d)
		"run_klon_dev":
			return _klon_dev(p, d)
		"murekkep_hayaleti":
			return _impi(p, d)
		"ocak_nobetcisi":
			return _golem(p, d)
		"zincirli_arsivci":
			return _arsivci(p, d)
	return false


## Zincirli Arşivci: 80 px içinde sırtındaki kitabı açar (0.7 sn, sayfalar mor parlar), yere vurur: küçük şok dalgası.
func _arsivci(p: Player, d: float) -> bool:
	if slam > 0:
		slam -= 1
		facing_left = slam_dir.x < 0
		if slam == 0:
			attack_anim = 18
			var hz := GoblinHazard.new()
			hz.setup("shock", position + slam_dir * 20.0, 90.0, atk)
			main._spawn(hz, hz.position)
			main.shake(8)
			main.burst(position + slam_dir * 20.0, 34, Color(0.75, 0.5, 1.0))
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if slam_cd == 0 and d < 80.0:
		slam = SLAM_TELL
		slam_cd = 200
		slam_dir = (p.position - position).normalized()
		return true
	return false


## Rün klonu (kılıç): 60-170 px'te kılıcı mor parlar (0.4 sn, yön kilitli), düz çizgide atılır; isabet kristalleşme.
func _klon_kilic(p: Player, d: float) -> bool:
	match dive_state:
		"tell":
			dive_t -= 1
			facing_left = dive_dir.x < 0
			if dive_t <= 0:
				dive_state = "dash"
				dive_t = HOUND_DASH
				dive_hit = false
				attack_anim = 18
			return true
		"dash":
			dive_t -= 1
			var np := main.world.move_point(position, dive_dir * HOUND_SPEED)
			var blocked := np == position
			position = np
			moving = true
			if not dive_hit and position.distance_to(p.position) < 34.0 and p.alive():
				dive_hit = true
				attack_cd = attack_cd_max
				if p.take_damage(atk, self):
					p.apply_debuff("crystal")
			if dive_t <= 0 or blocked:
				dive_state = "rest"
				dive_t = DIVE_REST
			return true
		"rest":
			dive_t -= 1
			if dive_t <= 0:
				dive_state = ""
				dive_cd = 150
			return true
	if dive_cd == 0 and d > 60.0 and d < 170.0 and p.alive() and knock == Vector2.ZERO:
		dive_state = "tell"
		dive_t = DIVE_TELL + 4
		dive_dir = (p.position - position).normalized()
		return true
	return false


## Rün küresi yelpazesi (klon büyücü, Kârun): n küre, aralarında spread radyan.
func rune_fan(ang: float, n: int, spread: float, speed2 := 3.4) -> void:
	attack_anim = 22
	for i in n:
		var a := ang + (i - (n - 1) * 0.5) * spread
		var hz := HeartHazard.new()
		hz.setup("orb", position + Vector2(size * (-0.5 if facing_left else 0.5), -size * 0.6), 8.0, atk)
		hz.vel = Vector2.from_angle(a) * speed2
		main._spawn(hz, hz.position)


## Rün klonu (dev): 220 px içinde levhasını kaldırır (0.7 sn), yere vurur; oyuncuya doğru kristal hattı fışkırır.
## Canı yarıya inince bir kez 3 sn kristal kabuğa bürünür (hasar %70 azalır).
func _klon_dev(p: Player, d: float) -> bool:
	if slab > 0:
		slab -= 1
		facing_left = slab_dir.x < 0
		if slab == 0:
			attack_anim = 18
			main.shake(8)
			var start := position + Vector2(0, 8) + slab_dir * 30.0
			var length := 0.0
			while length < 300.0 and main.world.is_walkable(start + slab_dir * (length + 14.0)):
				length += 14.0
			if length >= 40.0:
				var hz := HeartHazard.new()
				hz.setup_line(start, slab_dir, length, atk)
				main._spawn(hz, hz.position)
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if slab_cd == 0 and d < 220.0:
		slab = SLAB_TELL
		slab_cd = 210
		slab_dir = (p.position + Vector2(0, 14) - position).normalized()
		return true
	return false


## Yörünge Taşı: 260 px içinde taşları hızlanıp parlar (0.8 sn tell), sonra halka halinde dışa fırlar ve geri döner.
func _yorunge(p: Player, d: float) -> bool:
	if ring_t > 0:
		ring_t -= 1
		if ring_t == 0:
			attack_anim = 22
			var hz := RiftHazard.new()
			hz.reach = 230.0
			hz.count = 10
			var g0 := (p.position - position).angle() + PI * 0.5 + randf_range(-0.6, 0.6)
			hz.gaps = [g0, g0 + PI]
			hz.setup("orbit", position, 8.0, atk)
			hz.follow = self
			main._spawn(hz, hz.position)
		return true
	if ring_cd2 == 0 and d < 260.0 and p.alive() and knock == Vector2.ZERO:
		ring_t = RING_TELL
		ring_cd2 = 240
		return true
	return false


## Yokluk Gözü: 340 px içinde bakış hattını kilitler (0.9 sn tell, hat yavaşça izler), sonra kısa çarpıtıcı ışın.
func _goz(p: Player, d: float) -> bool:
	if gaze_t > 0:
		gaze_t -= 1
		facing_left = p.position.x < position.x
		if gaze_t == RiftHazard.GAZE_FIRE:
			attack_anim = RiftHazard.GAZE_FIRE
		return true
	if attack_cd == 0 and d < 340.0 and p.alive() and knock == Vector2.ZERO:
		attack_cd = attack_cd_max
		gaze_t = RiftHazard.GAZE_TELL + RiftHazard.GAZE_FIRE
		var hz := RiftHazard.new()
		hz.muzzle = Vector2(0, -size * 0.75)
		hz.setup("gaze", position, 8.0, atk)
		hz.follow = self
		hz.ang = (p.position + Vector2(0, -20) - (position + hz.muzzle)).angle()
		main._spawn(hz, hz.position)
		return true
	return false


## Boşluk Yiyici: 320 px içinde yırtığa dalar (0.3 sn), zemin altında oyuncuya doğru ilerler (hedef alınamaz),
## oyuncunun altında yırtık açar (0.8 sn tell) ve fırlayıp ısırır; sonra 2 sn yüzeyde savunmasız kalır.
func _yiyici(p: Player, d: float) -> bool:
	match burrow:
		"sink":
			burrow_t -= 1
			if burrow_t <= 0:
				burrow = "under"
			return true
		"under":
			var to := burrow_to - position
			if to.length() > 6.0:
				position = main.world.move_point(position, to.normalized() * minf(5.0, to.length()))
				if Engine.get_physics_frames() % 6 == 0:
					main.burst(position + Vector2(0, 6), 12, RIFT_CYAN)
			if to.length() <= 6.0 or burrow_t <= -120:
				burrow = "rise"
				burrow_t = RiftHazard.RIFT_TELL
				var hz := RiftHazard.new()
				hz.setup("rift", position + Vector2(0, 8), 46.0, atk)
				main._spawn(hz, hz.position)
			burrow_t -= 1
			return true
		"rise":
			burrow_t -= 1
			if burrow_t <= 0:
				burrow = "up"
				burrow_t = SURFACED
				attack_anim = 20
				facing_left = p.position.x < position.x
			return true
		"up":
			burrow_t -= 1
			if burrow_t <= 0:
				burrow = ""
			return burrow_t > SURFACED - 30
	if burrow_cd == 0 and d < 320.0 and d > 40.0 and p.alive() and knock == Vector2.ZERO:
		burrow = "sink"
		burrow_t = SINK
		burrow_cd = 300
		burrow_to = p.position
		main.burst(position + Vector2(0, 4), 30, RIFT_CYAN)
		return true
	return false


## Yansıma: oyuncu ateş ettiğinde (ses) 0.4 sn sonra aynı atışı oyuncuya geri yapar.
func _echo_mirror(p: Player) -> void:
	if Game.zone() != 9 or not p.alive():
		return
	if main.noise_frame > echo_seen:
		echo_seen = main.noise_frame
		echo_queue.append(24)
	for i in range(echo_queue.size() - 1, -1, -1):
		echo_queue[i] -= 1
		if echo_queue[i] <= 0:
			echo_queue.remove_at(i)
			attack_anim = 14
			facing_left = p.position.x < position.x
			main.spawn_enemy_arrow(self, (p.position - position).angle())


## Konsey Bilgesi: 320 px içinde asasını kaldırır (0.5 sn), sonra oyuncuya doğru bir hat üzerinde art arda 3 altın
## daire düşer (her biri ~1 sn tell), dairelere ışık mızrağı iner. Kopyaların mızrakları soluk ve hasarsızdır.
func _bilge(p: Player, d: float) -> bool:
	if decoy:
		decoy_age += 1
		if decoy_age >= DECOY_LIFE:
			_dispel()
			return true
	if sage_cast > 0:
		sage_cast -= 1
		facing_left = p.position.x < position.x
		if sage_cast == 0:
			attack_anim = 22
			var dir := (sage_target - position).normalized()
			for i in 3:
				var at := sage_target + dir * (i - 1) * 62.0
				if not main.world.is_walkable(at):
					continue
				var hz := SkyHazard.new()
				hz.fake = decoy
				hz.setup("lance", at + Vector2(0, 14), 34.0, 0 if decoy else atk)
				hz.t = -i * 10
				main._spawn(hz, hz.position)
		return true
	if attack_cd == 0 and d < 320.0 and p.alive() and knock == Vector2.ZERO:
		sage_cast = SAGE_CAST
		attack_cd = attack_cd_max
		sage_target = p.position
		return true
	return false


## Ayna kopyası tek vuruşta altın tozuna dağılır (ödül yok).
func _dispel() -> void:
	main.burst(position + Vector2(0, -30), 36, GOLD_GLOW)
	main.float_text(position + Vector2(0, -size * 1.2), "YANILSAMA", GOLD_GLOW.lightened(0.3))
	remove()


func _make_decoys() -> void:
	decoys_made = true
	main.float_text(position + Vector2(0, -size * 1.6), "AYNA KOPYALARI", GOLD_GLOW.lightened(0.3))
	for side in [-1.0, 1.0]:
		var at := position + Vector2(side * 70.0, randf_range(-20, 20))
		if not main.world.circle_free(at, 14):
			at = position + Vector2(0, side * 60.0)
		var e := main.spawn_enemy("konsey_bilgesi", at)
		if e:
			e.decoy = true
			e.decoys_made = true
			e.is_minion = true
			e.max_hp = 1
			e.hp = 1
			e.xp = 0
			e.gold = 0
			e.attack_cd = randi_range(20, 60)
			main.burst(at + Vector2(0, -30), 34, GOLD_GLOW)
	# Gerçek bilge de yer değiştirir: hangisinin gerçek olduğu karışsın.
	var swap := position + Vector2(0, randf_range(-40, 40))
	if main.world.circle_free(swap, 14):
		position = swap


## Rün Bekçisi: 260 px içinde topuzunu kaldırır (0.4 sn), oyuncunun altında yerçekimi rünü döner (0.9 sn), sonra bastırır.
func _bekci(p: Player, d: float) -> bool:
	if gcast > 0:
		gcast -= 1
		facing_left = p.position.x < position.x
		if gcast == 0:
			attack_anim = 18
			main.shake(4)
			var hz := SkyHazard.new()
			hz.setup("gravity", p.position + Vector2(0, 14), 46.0, atk)
			main._spawn(hz, hz.position)
		return true
	if gcast_cd == 0 and d < 260.0 and d > 50.0 and p.alive() and knock == Vector2.ZERO:
		gcast = GRAV_CAST
		gcast_cd = 230
		return true
	return false


## Gök Muhafızı: 120 px içinde teberini geri çeker, kanatlarını açar (0.6 sn tell, koni), savurur: hasar + geri itme.
## Oyuncu 220 px'ten uzaktaysa kanat çırpıp hızla süzülür.
func _muhafiz_gok(p: Player, d: float) -> bool:
	if gust > 0:
		gust -= 1
		facing_left = gust_dir.x < 0
		if gust == 0:
			attack_anim = 20
			attack_cd = attack_cd_max
			var rel := p.position - position
			if p.alive() and rel.length() < GUST_LEN + 12.0 and absf(angle_difference(gust_dir.angle(), rel.angle())) < GUST_HALF + 0.1:
				p.take_damage(atk, self)
				var push := gust_dir * 70.0
				p.position = main.world.move_circle(p.position, push, Player.RADIUS)
				main.float_text(p.position + Vector2(0, -60), "İTİLDİN", GOLD_GLOW.lightened(0.35))
			main.burst(position + gust_dir * 60.0 + Vector2(0, -20), 40, Color(0.9, 0.95, 1.0))
		return true
	if glide > 0:
		glide -= 1
		position = main.world.move_point(position, glide_dir * 6.0)
		moving = true
		facing_left = glide_dir.x < 0
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if gust_cd == 0 and d < GUST_LEN - 10.0:
		gust = GUST_TELL
		gust_cd = 200
		gust_dir = (p.position - position).normalized()
		return true
	if glide_cd == 0 and d > 220.0 and d < 420.0:
		glide = 16
		glide_cd = 200
		glide_dir = (p.position - position).normalized()
		main.burst(position + Vector2(0, -30), 26, Color(0.9, 0.95, 1.0))
		return true
	return false


## Gölge Yürüyücü: 70-260 px'te oyuncunun arkasında (kendisine göre karşı yanda) yerde portal açar (0.7 sn tell),
## kendi yerinde solar, portaldan çıkar ve pençeler (yokluk yanığı).
func _yuruyucu(p: Player, d: float) -> bool:
	if step > 0:
		step -= 1
		if step == 0:
			main.burst(position + Vector2(0, -30), 30, VOID_GLOW)
			position = step_at
			facing_left = p.position.x < position.x
			attack_anim = 18
			attack_cd = attack_cd_max
			main.burst(position + Vector2(0, -30), 36, VOID_GLOW)
			if p.alive() and position.distance_to(p.position) < 56.0:
				if p.take_damage(atk, self):
					p.apply_debuff("void")
		return true
	if step_cd == 0 and d > 70.0 and d < 260.0 and p.alive() and knock == Vector2.ZERO:
		var behind := p.position + (p.position - position).normalized() * 44.0
		if not main.world.circle_free(behind, 14):
			behind = p.position + (p.position - position).normalized().orthogonal() * 44.0
		if not main.world.circle_free(behind, 14):
			return false
		step = STEP_TELL
		step_cd = 230
		step_at = behind
		var hz := VoidHazard.new()
		hz.setup("portal", behind + Vector2(0, 10), 26.0, 0)
		hz.life = STEP_TELL + 16
		main._spawn(hz, hz.position)
		return true
	return false


## Kan Yazıcısı: 300 px içinde kalemle havaya kan mührü çizer (0.8 sn tell); bitince oyuncu 4 sn kan işareti alır.
func _yazici(p: Player, d: float) -> bool:
	if scribe > 0:
		scribe -= 1
		facing_left = p.position.x < position.x
		if scribe == 0:
			attack_anim = 22
			if p.alive() and position.distance_to(p.position) < 340.0:
				p.mark_blood()
				main.burst(p.position + Vector2(0, -70), 26, BLOOD_GLOW)
		return true
	if attack_cd == 0 and d < 300.0 and p.alive() and knock == Vector2.ZERO:
		scribe = SCRIBE_TELL
		attack_cd = attack_cd_max
		return true
	return false


## Gargoyl: taş uykusunda kıpırdamaz ve hasar almaz; oyuncu 140 px'e girince gözleri yanar (0.5 sn) ve uyanır.
## Uyanıkken 100-260 px'te havalanır, yerde gölgesi büyür (0.8 sn) ve gölgenin olduğu yere çakılır.
## Canı %30'un altına inince bir kez yeniden taşlaşıp 3 sn yenilenmeye çalışır; 3 isabet taşı kırar.
func _gargoyl(p: Player, d: float) -> bool:
	if stone:
		if wake > 0:
			wake -= 1
			if wake == 0:
				stone = false
				main.burst(position + Vector2(0, -30), 34, VOID_GLOW)
				main.float_text(position + Vector2(0, -size * 1.4), "UYANDI", VOID_GLOW.lightened(0.35))
				attack_cd = 40
				gdive_cd = 30
		elif d < 140.0 and p.alive():
			wake = WAKE_TELL
			facing_left = p.position.x < position.x
		return true
	if restone > 0:
		restone -= 1
		if Engine.get_physics_frames() % 60 == 0 and hp < max_hp:
			var amt := maxi(1, int(max_hp * 0.04))
			hp = mini(max_hp, hp + amt)
			main.float_text(position + Vector2(0, -size * 1.3), "+%d" % amt, Color(0.75, 0.75, 0.8))
		return true
	if gdive > 0:
		gdive -= 1
		var u := 1.0 - float(gdive) / VoidHazard.SHADOW_TELL
		position = gdive_from.lerp(gdive_to, u * u)
		facing_left = gdive_to.x < gdive_from.x
		attack_anim = maxi(attack_anim, 6)
		if gdive == 0:
			attack_cd = attack_cd_max
		return true
	if gdive_cd == 0 and d > 100.0 and d < 260.0 and p.alive() and knock == Vector2.ZERO:
		gdive = VoidHazard.SHADOW_TELL
		gdive_cd = 250
		gdive_from = position
		gdive_to = p.position + Vector2(0, 4)
		if not main.world.circle_free(gdive_to, 14):
			gdive_to = p.position
		var hz := VoidHazard.new()
		hz.setup("shadow", gdive_to + Vector2(0, 10), 46.0, atk)
		main._spawn(hz, hz.position)
		return true
	return false


## Havada mı (dalış ya da taşlaşma dışı)? Dalışta mermiler değmez.
func airborne() -> bool:
	return gdive > 6 or burrow in ["sink", "under", "rise"]


## Diken Tazısı: 60-160 px'te başını eğer, sırt dikenleri kabarıp mor parlar (0.4 sn tell; yön tell başında
## kilitlenir), sonra düz çizgide atılır; isabet zehir. Kor İmpi'nin atılma durumlarını kullanır.
func _tazi(p: Player, d: float) -> bool:
	match dive_state:
		"tell":
			dive_t -= 1
			facing_left = dive_dir.x < 0
			if dive_t <= 0:
				dive_state = "dash"
				dive_t = HOUND_DASH
				dive_hit = false
				attack_anim = 18
			return true
		"dash":
			dive_t -= 1
			var np := main.world.move_point(position, dive_dir * HOUND_SPEED)
			var blocked := np == position
			position = np
			moving = true
			facing_left = dive_dir.x < 0
			if not dive_hit and position.distance_to(p.position) < 32.0 and p.alive():
				dive_hit = true
				attack_cd = attack_cd_max
				if p.take_damage(atk, self):
					p.apply_debuff("poison")
			if dive_t <= 0 or blocked:
				dive_state = "rest"
				dive_t = DIVE_REST
			return true
		"rest":
			dive_t -= 1
			if dive_t <= 0:
				dive_state = ""
				dive_cd = 140
				flank = -flank
			return true
	if dive_cd == 0 and d > 60.0 and d < 160.0 and p.alive() and knock == Vector2.ZERO:
		dive_state = "tell"
		dive_t = DIVE_TELL
		dive_dir = (p.position - position).normalized()
		return true
	return false


## Spor Mantarı: 110 px içinde şapkası şişer, benekler parlar (0.8 sn tell), sonra çevresine spor bulutu salar.
func _mantar(p: Player, d: float) -> bool:
	if puff > 0:
		puff -= 1
		if puff == 0:
			attack_anim = 18
			spore_cloud(position + Vector2(0, 6), 74.0, false)
			puff_cd = 260
		return true
	if puff_cd == 0 and d < 110.0 and p.alive() and knock == Vector2.ZERO:
		puff = PUFF_TELL
		return true
	return false


## Spor bulutu bırakır (mantarın patlaması, ölüm patlaması).
func spore_cloud(at: Vector2, r: float, big: bool) -> void:
	var hz := ForestHazard.new()
	hz.setup("spores", at, r, 0)
	hz.hurts_enemies = big
	if big:
		hz.life = ForestHazard.SPORE_LIFE + 60
	main._spawn(hz, hz.position)
	main.burst(at + Vector2(0, -20), r * 0.6, THORN_GLOW)


## Kök Muhafızı: 90-300 px'te asasını yere saplar (0.5 sn), yerin altından oyuncunun durduğu yere kök kabarması
## ilerler (1 sn tell), orada kökler fışkırır. Canı yarıya inince bir kez yerinde kök salar ve yenilenir.
func _muhafiz(p: Player, d: float) -> bool:
	if anchored:
		# Kök salmış: hareket etmez, saniyede canının %3'ü kadar yenilenir; 3 isabet kökleri koparır.
		if Engine.get_physics_frames() % 60 == 0 and hp < max_hp:
			var amt := maxi(1, int(max_hp * 0.03))
			hp = mini(max_hp, hp + amt)
			main.float_text(position + Vector2(0, -size * 1.4), "+%d" % amt, Color(0.6, 0.9, 0.4))
		if root_cast > 0:
			root_cast -= 1
			if root_cast == 0:
				_cast_root()
		elif root_cd == 0 and d < 320.0 and p.alive():
			_start_root(p)
		facing_left = p.position.x < position.x
		return true
	if root_cast > 0:
		root_cast -= 1
		facing_left = root_target.x < position.x
		if root_cast == 0:
			_cast_root()
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if root_cd == 0 and d > 90.0 and d < 300.0:
		_start_root(p)
		return true
	return false


func _start_root(p: Player) -> void:
	root_cast = ROOT_CAST
	root_cd = 240
	root_target = p.position + Vector2(0, 14)


func _cast_root() -> void:
	attack_anim = 18
	var hz := ForestHazard.new()
	hz.setup("roots", root_target, 38.0, atk)
	hz.from = position + Vector2(0, 8) - hz.position
	main._spawn(hz, hz.position)
	main.shake(4)


## Diken Rahibesi: tohum atışı tick()'teki uzaktan saldırıda. Burada: yakındaki bir müttefike sarmaşık kalkanı örer.
func _rahibe(_p: Player, _d: float) -> bool:
	if shield_cd == 0:
		for e in main.enemies:
			if e != self and is_instance_valid(e) and not e.removed and not e.vine_shield and e.type != "totem" \
					and e.position.distance_to(position) < 220.0:
				e.vine_shield = true
				shield_cd = 420
				attack_anim = 18
				main.burst(e.position + Vector2(0, -e.size * 0.5), 34, THORN_GLOW)
				main.float_text(e.position + Vector2(0, -e.size * 1.3), "SARMAŞIK KALKANI", THORN_GLOW.lightened(0.35))
				return true
		shield_cd = 90
	return false


## Diken tohumu atar: hedefte yerde mor halka (1 sn), sonra kısa diken çemberi.
func throw_seed(target: Vector2) -> void:
	if not main.world.is_walkable(target):
		target = main.player.position
	var hz := ForestHazard.new()
	hz.setup("seed", target + Vector2(0, 14), 40.0, atk)
	hz.from = position + Vector2(size * (-0.5 if facing_left else 0.5), -size * 0.8) - hz.position
	main._spawn(hz, hz.position)


## Buz Zombisi: 40 px içinde kolunu geri çeker (0.5 sn, el maviye döner), sonra pençeler; isabet 1 kırağı.
## Normal temas saldırısı yerine geçer (attack_cd bekleme süresini korur).
func _zombi(p: Player, d: float) -> bool:
	if claw > 0:
		claw -= 1
		facing_left = claw_dir.x < 0
		if claw == 0:
			attack_anim = 18
			attack_cd = attack_cd_max
			var to := p.position - position
			if p.alive() and to.length() < CLAW_RANGE + 14.0 and to.normalized().dot(claw_dir) > 0.2:
				if p.take_damage(atk, self):
					p.apply_debuff("frost")
			main.burst(position + claw_dir * 26.0 + Vector2(0, -24), 16, ICE_GLOW)
		return true
	if attack_cd == 0 and d < CLAW_RANGE and p.alive() and knock == Vector2.ZERO:
		claw = CLAW_TELL
		claw_dir = (p.position - position).normalized()
		attack_cd = attack_cd_max
		return true
	return false


## Ayna kabuk açık mı (önden gelen ok / rün mermisi yansır)?
func shell_on() -> bool:
	return type == "buz_aynasi" and shell_broken == 0 and mirror >= MIRROR_OFF


## Mermi yansır mı: kabuk açık ve mermi önden (~60°) geliyor.
func mirrors(shot_dir: Vector2) -> bool:
	if not shell_on():
		return false
	var face := Vector2(-1.0 if facing_left else 1.0, 0.0)
	return (-shot_dir.normalized()).dot(face) > 0.5


## Delici Ok ya da kılıç kabuğu kırar: 5 sn yansıtamaz.
func crack_shell() -> void:
	if type != "buz_aynasi":
		return
	if shell_broken == 0:
		main.burst(position + Vector2(0, -30), 40, Color(0.9, 0.97, 1.0))
		main.float_text(position + Vector2(0, -70), "KABUK KIRILDI", Color(0.8, 0.94, 1.0))
	shell_broken = SHELL_BROKEN


## Buz Aynası Örümceği: oyuncuyla mesafe korur (duvar diplerinde bekler), 90-230 px'te karnını büzer
## (0.6 sn tell) ve oyuncunun durduğu yere ağ fırlatır; çok yakına gelinirse ısırır (normal saldırı).
func _ayna(p: Player, d: float) -> bool:
	if web > 0:
		web -= 1
		facing_left = web_target.x < position.x
		if web == 0:
			attack_anim = 18
			var hz := FrostHazard.new()
			hz.setup("web", web_target, 46.0, 0)
			hz.from = position + Vector2(0, -size * 0.5) - hz.center()
			main._spawn(hz, hz.position)
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if web_cd == 0 and d > 90.0 and d < 230.0:
		web = WEB_TELL
		web_cd = 240
		web_target = p.position + Vector2(0, 14)
		if not main.world.is_walkable(web_target):
			web_target = p.position
		return true
	if d > 110.0 and d < 200.0:
		# Pusuda: yerinde bekler, oyuncuya döner.
		facing_left = p.position.x < position.x
		return true
	return false


## Buz Ayısı: yakında yere vurur (buz halkası), 110-260 px'te arka ayakları üstüne kalkıp kükrer (0.8 sn tell;
## yön tell başında kilitlenir) ve düz çizgide hücum eder; duvara çarparsa 1 sn sersemler (çift hasar alır).
func _ayi(p: Player, d: float) -> bool:
	if dazed > 0:
		dazed -= 1
		return true
	match charge_state:
		"tell":
			charge_t -= 1
			facing_left = charge_dir.x < 0
			if charge_t <= 0:
				charge_state = "run"
				charge_t = CHARGE_RUN
				charge_hit = false
				attack_anim = 18
			return true
		"run":
			charge_t -= 1
			var np := main.world.move_point(position, charge_dir * CHARGE_SPEED * (1.25 if not plates else 1.0))
			var blocked := np.distance_to(position) < CHARGE_SPEED * 0.4
			position = np
			moving = true
			facing_left = charge_dir.x < 0
			attack_anim = maxi(attack_anim, 6)
			if not charge_hit and position.distance_to(p.position) < 40.0 and p.alive():
				charge_hit = true
				if p.take_damage(int(atk * 1.2), self):
					p.apply_debuff("frost")
					p.vel += charge_dir * 6.0
				main.shake(8)
			if blocked:
				charge_state = ""
				charge_cd = 240
				dazed = DAZE
				main.shake(12)
				main.burst(position + charge_dir * 30.0 + Vector2(0, -30), 40, Color(0.85, 0.95, 1.0))
				main.float_text(position + Vector2(0, -size * 1.6), "SERSEMLEDİ", Color(1.0, 0.95, 0.6))
			elif charge_t <= 0:
				charge_state = ""
				charge_cd = 240
				attack_cd = maxi(attack_cd, 30)
			return true
	if slam > 0:
		slam -= 1
		facing_left = slam_dir.x < 0
		if slam == 0:
			attack_anim = 18
			var hz := FrostHazard.new()
			hz.setup("ring", position + Vector2(0, 6), 84.0, int(atk * 0.7))
			main._spawn(hz, hz.position)
			main.shake(10)
			main.burst(position + Vector2(0, -6), 44, Color(0.8, 0.94, 1.0))
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if slam_cd == 0 and d < 70.0:
		slam = STOMP_TELL
		slam_cd = 200
		slam_dir = (p.position - position).normalized()
		return true
	if charge_cd == 0 and d > 110.0 and d < 260.0:
		charge_state = "tell"
		charge_t = CHARGE_TELL
		charge_dir = (p.position - position).normalized()
		return true
	return false


## Kor İmpi: 60-170 px'te kanatlarını toplar, gözleri beyaz-sarı parlar (0.4 sn tell; yön tell başında
## kilitlenir, yana kaçılabilir), sonra düz çizgide atılır; geçtiği yerde 1.5 sn yanan iz lekeleri kalır.
func _impi(p: Player, d: float) -> bool:
	match dive_state:
		"tell":
			dive_t -= 1
			facing_left = dive_dir.x < 0
			if dive_t <= 0:
				dive_state = "dash"
				dive_t = DIVE
				dive_hit = false
				attack_anim = 18
			return true
		"dash":
			dive_t -= 1
			var np := main.world.move_point(position, dive_dir * DIVE_SPEED)
			var blocked := np == position
			position = np
			facing_left = dive_dir.x < 0
			if dive_t % 3 == 0 and main.world.is_walkable(position):
				_drop_trail()
			if not dive_hit and position.distance_to(p.position) < 30.0 and p.alive():
				dive_hit = true
				attack_cd = attack_cd_max
				if p.take_damage(atk, self):
					p.apply_debuff(debuff)
			if dive_t <= 0 or blocked:
				dive_state = "rest"
				dive_t = DIVE_REST
			return true
		"rest":
			dive_t -= 1
			if dive_t <= 0:
				dive_state = ""
				dive_cd = 150
			return true
	if dive_cd == 0 and d > 60.0 and d < DIVE_RANGE and p.alive() and knock == Vector2.ZERO:
		dive_state = "tell"
		dive_t = DIVE_TELL
		dive_dir = (p.position - position).normalized()
		return true
	return false


func _drop_trail() -> void:
	if type == "murekkep_hayaleti":
		# Mürekkep izi yanmaz, yalnızca yavaşlatır (kaygan mürekkep).
		var ink := FrostHazard.new()
		ink.setup("patch", position + Vector2(0, 4), 16.0, 0)
		ink.modulate = Color(0.25, 0.15, 0.35)
		main._spawn(ink, ink.position)
		return
	var hz := FireHazard.new()
	hz.setup("trail", position + Vector2(0, 4), 18.0, maxi(1, atk / 4))
	main._spawn(hz, hz.position)


## Lav Golemi: 95 px içinde yumruklarını kaldırır, çatlakları giderek parlar (0.8 sn tell), yere vurur:
## önündeki daire hasar + yanık, yerde 3 sn lav gölü (yanık + yavaşlatma). Vuruştan sonra soğur: gri taş,
## "SERTLEŞTİ", 2.5 sn hasar yarıya iner.
func _golem(p: Player, d: float) -> bool:
	if slam > 0:
		slam -= 1
		facing_left = slam_dir.x < 0
		if slam == 0:
			_golem_impact(p)
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if slam_cd == 0 and d < 95.0:
		slam = GOLEM_SLAM_TELL
		slam_cd = 210
		slam_dir = (p.position - position).normalized()
		return true
	return false


func _golem_impact(p: Player) -> void:
	attack_anim = 18
	var at := position + slam_dir * 30.0
	if p.alive() and p.position.distance_to(at) < GOLEM_SLAM_R:
		if p.take_damage(atk, self):
			p.apply_debuff("burn")
	var hz := FireHazard.new()
	hz.setup("lava", at, 54.0, maxi(1, atk / 5))
	main._spawn(hz, hz.position)
	main.shake(12)
	main.burst(at + Vector2(0, -10), 50, Color(1.0, 0.5, 0.12))
	harden = HARDEN
	main.float_text(position + Vector2(0, -size * 1.6), "SERTLEŞTİ", Color(0.78, 0.78, 0.82))


## Kül Rahibi: oyuncunun ayağının altına rün daireleri çizer; ilki tam altında, diğerleri yakınında ve
## art arda (yüksek katlarda 2-3 daire). Her biri ~1 sn dolar, sonra alev sütunu fışkırır.
func cast_runes(target: Vector2, count := -1) -> void:
	var n := count if count > 0 else clampi(1 + (Game.floor_number - 31) / 3, 1, 3)
	for i in n:
		var at := target
		if i > 0:
			at = target + Vector2.from_angle(randf() * TAU) * randf_range(46, 70)
		if not main.world.is_walkable(at):
			continue
		var hz := FireHazard.new()
		hz.setup("rune", at, RUNE_R, atk)
		hz.delay = i * 14
		main._spawn(hz, hz.position)


## Kül bulutu: ufalanma tell'i bitince bulut patlar, rahip 2 sn görünmez (hedef alınamaz), sonra yakında belirir.
func _rahip(p: Player) -> bool:
	if ash > 0:
		ash -= 1
		if ash % 12 == 0:
			main.burst(position + Vector2(0, -30), 18, Color(0.35, 0.33, 0.3))
		if ash == 0:
			var hz := FireHazard.new()
			hz.setup("ash", position + Vector2(0, 6), 70.0, 0)
			main._spawn(hz, hz.position)
			main.burst(position + Vector2(0, -30), 44, Color(0.3, 0.28, 0.26))
			ash_hidden = ASH_HIDE
		return true
	if ash_hidden > 0:
		ash_hidden -= 1
		if ash_hidden == 0:
			_reappear(p)
		return true
	return false


func _reappear(p: Player) -> void:
	var best := position
	var best_d := -1.0
	for i in 16:
		var c := position + Vector2.from_angle(randf() * TAU) * randf_range(90, 160)
		if main.world.circle_free(c, 14):
			var pd := c.distance_to(p.position)
			if pd > best_d:
				best_d = pd
				best = c
	position = best
	main.burst(position + Vector2(0, -30), 34, Color(0.45, 0.4, 0.36))
	main.burst(position + Vector2(0, -30), 20, Color(1.0, 0.5, 0.15))
	attack_cd = maxi(attack_cd, 40)


## Görünmez (kül bulutundaki rahip): hedef alınamaz, vurulamaz.
func hidden() -> bool:
	return ash_hidden > 0


## Yakında (r px) şamandan başka goblin akrabası var mı?
func _kin_near(r: float) -> bool:
	for e in main.enemies:
		if e != self and is_instance_valid(e) and not e.removed and e.type in EnemyData.GOBLIN_KIN \
				and e.type != "goblin_saman" and e.position.distance_to(position) < r:
			return true
	return false


## Şaman: dumanla kaçış > totem dikme (asa yere vurulur, yeşil-sarı halka yayılır) > normal (küre atar).
func _saman(p: Player, d: float) -> bool:
	if vanish > 0:
		vanish -= 1
		var away := (position - p.position).normalized()
		var np := main.world.move_point(position, away * speed * 1.8)
		moving = np != position
		position = np
		facing_left = away.x < 0
		if vanish % 24 == 0:
			main.burst(position + Vector2(0, -18), 22, Color(0.55, 0.62, 0.42))
		return true
	if plant > 0:
		plant -= 1
		facing_left = p.position.x < position.x
		if plant == 0:
			_plant_totem()
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if vanish_cd == 0 and d < 240.0 and not _kin_near(420.0):
		# Yanında goblin kalmadı: duman bulutu (tell) ve görünmez kaçış.
		vanish = VANISH
		vanish_cd = 600
		main.burst(position + Vector2(0, -20), 44, Color(0.6, 0.68, 0.45))
		main.fx.add_sprite(position + Vector2(0, -22), "fx_burst_violet", 110.0, Color(0.7, 0.85, 0.5, 0.8), 26, 0.4)
		return true
	var has_totem := my_totem != null and is_instance_valid(my_totem) and not my_totem.removed
	if totem_cd == 0 and d < 260.0 and not has_totem and _kin_near(240.0):
		plant = PLANT_TELL
		totem_cd = 480
		return true
	return false


func _plant_totem() -> void:
	var at := position + Vector2(-26.0 if facing_left else 26.0, 8)
	if not main.world.circle_free(at, 10):
		at = position + Vector2(0, 10)
	my_totem = main.spawn_enemy("totem", at)
	if my_totem:
		my_totem.is_minion = true
		main.fx.add_sprite(at, "fx_ring_gold", 2.2 * TOTEM_RANGE, Color(0.75, 1.0, 0.25), 26, 0.25)
	attack_cd = maxi(attack_cd, 30)


## Totem: hareket etmez; 45 karede bir yakınındaki goblinleri iyileştirir, süresi dolunca çöker.
func _totem_tick() -> void:
	totem_age += 1
	if totem_age >= TOTEM_LIFE:
		main.burst(position + Vector2(0, -20), 26, Color(0.75, 0.7, 0.55))
		remove()
		return
	heal_t += 1
	if heal_t < 45:
		return
	heal_t = 0
	var healed := false
	for e in main.enemies:
		if e == self or not is_instance_valid(e) or e.removed or not e.type in EnemyData.GOBLIN_KIN:
			continue
		if e.hp < e.max_hp and e.position.distance_to(position) < TOTEM_RANGE:
			var amt := maxi(1, int(e.max_hp * 0.06))
			e.hp = mini(e.max_hp, e.hp + amt)
			main.float_text(e.position + Vector2(0, -50), "+%d" % amt, POISON_GLOW)
			healed = true
	if healed:
		main.fx.add_sprite(position, "fx_ring_gold", 2.0 * TOTEM_RANGE, Color(0.7, 1.0, 0.25, 0.7), 20, 0.25)


## Bombacı: oyuncu 80 px'e girince geri seker (bomba atma tick() içindeki uzaktan saldırıda).
func _bombaci(p: Player, d: float) -> bool:
	if hop > 0:
		hop -= 1
		position = main.world.move_point(position, hop_dir * 4.4)
		return true
	if hop_cd == 0 and d < 80.0 and p.alive() and knock == Vector2.ZERO:
		hop = HOP
		hop_cd = 150
		hop_dir = (position - p.position).normalized()
		facing_left = hop_dir.x > 0
		return true
	return false


## Kölebaşı: zincir çekişi (0.7 sn mor parıltı tell, sonra düz çizgide savurur; değerse oyuncuyu çeker)
## ve yere vuruş (çatlak çizgisi tell, sonra küçük şok dalgası).
func _kolebasi(p: Player, d: float) -> bool:
	match chain_state:
		"tell":
			chain_t -= 1
			facing_left = chain_dir.x < 0
			if chain_t <= 0:
				chain_state = "throw"
				chain_t = CHAIN_THROW
				attack_anim = 18
			return true
		"throw":
			chain_t -= 1
			chain_len = CHAIN_RANGE * (1.0 - float(chain_t) / CHAIN_THROW)
			if chain_t <= 0:
				var rel := p.position - position
				var along := rel.dot(chain_dir)
				if p.alive() and along > 0.0 and along < CHAIN_RANGE + 12.0 and absf(rel.cross(chain_dir)) < 28.0:
					chain_state = "pull"
					chain_t = 20
					p.take_damage(int(atk * 0.5), self)
					main.float_text(p.position + Vector2(0, -60), "ÇEKİLDİN!", CHAIN_GLOW.lightened(0.3))
					main.shake(6)
					main.burst(p.position + Vector2(0, -30), 34, CHAIN_GLOW)
				else:
					chain_state = "back"
					chain_t = CHAIN_THROW
			return true
		"pull":
			chain_t -= 1
			attack_anim = maxi(attack_anim, 2)
			var to := position - p.position
			var dist := to.length()
			if dist > 50.0:
				p.position = main.world.move_circle(p.position, to / dist * minf(10.0, dist - 50.0), Player.RADIUS)
			chain_dir = (p.position - position).normalized()
			chain_len = p.position.distance_to(position)
			if chain_t <= 0:
				chain_state = ""
				attack_cd = mini(attack_cd, 20)
			return true
		"back":
			chain_t -= 1
			chain_len = CHAIN_RANGE * float(chain_t) / CHAIN_THROW
			if chain_t <= 0:
				chain_state = ""
			return true
	if slam > 0:
		slam -= 1
		facing_left = slam_dir.x < 0
		if slam == 0:
			attack_anim = 18
			var hz := GoblinHazard.new()
			hz.setup("shock", position + slam_dir * 20.0, 100.0, atk)
			main._spawn(hz, hz.position)
			main.shake(12)
			main.burst(position + slam_dir * 20.0, 40, Color(0.8, 0.55, 1.0))
		return true
	if not p.alive() or knock != Vector2.ZERO:
		return false
	if slam_cd == 0 and d < 78.0:
		slam = SLAM_TELL
		slam_cd = 210 if not enraged else 150
		slam_dir = (p.position - position).normalized()
		return true
	if chain_cd == 0 and d > 100.0 and d < CHAIN_RANGE - 10.0:
		chain_state = "tell"
		chain_t = CHAIN_TELL
		chain_cd = 260 if not enraged else 180
		chain_dir = (p.position - position).normalized()
		chain_len = 0.0
		return true
	return false


func _blink_away(p: Player) -> void:
	blink_cd = 240
	var best := Vector2.ZERO
	var best_d := -1.0
	for i in 14:
		var c := position + Vector2.from_angle(randf() * TAU) * randf_range(150, 200)
		if main.world.circle_free(c, 14) and main.world.is_walkable(c):
			var pd := c.distance_to(p.position)
			if pd > best_d:
				best_d = pd
				best = c
	if best_d < 0:
		blink_cd = 60
		return
	main.burst(position + Vector2(0, -20), 34, Color(0.55, 0.25, 0.95))
	position = best
	main.burst(position + Vector2(0, -20), 30, Color(0.7, 0.4, 1.0))
	attack_cd = maxi(attack_cd, 40)


## Örümcek: 120-220 px'te çömelir (0.5 sn, sırt kristalleri parlar), oyuncuya sıçrar, sonra dinlenir.
func _leap(p: Player, d: float) -> bool:
	match leap_state:
		"crouch":
			leap_t -= 1
			facing_left = p.position.x < position.x
			if leap_t <= 0:
				var to := p.position - position
				leap_len = clampi(int(to.length() / 11.0), 10, 20)
				leap_vel = to / leap_len
				leap_t = leap_len
				leap_hit = false
				leap_state = "air"
				attack_anim = 18
			return true
		"air":
			leap_t -= 1
			position = main.world.move_point(position, leap_vel)
			facing_left = leap_vel.x < 0
			if not leap_hit and position.distance_to(p.position) < 36.0 and p.alive():
				leap_hit = true
				attack_cd = attack_cd_max
				if p.take_damage(atk, self):
					p.apply_debuff(debuff)
			if leap_t <= 0:
				leap_state = "rest"
				leap_t = LEAP_REST
			return true
		"rest":
			leap_t -= 1
			if leap_t <= 0:
				leap_state = ""
				leap_cd = 150
			return true
	if leap_cd == 0 and d > 120.0 and d < 220.0 and p.alive() and knock == Vector2.ZERO:
		leap_state = "crouch"
		leap_t = LEAP_CROUCH
		return true
	return false


## Kristal Örümceği önden gelen mermiyi sektirir: mermi yönü bakışına ~60° içinde karşıdan geliyorsa.
func deflects(shot_dir: Vector2) -> bool:
	if type != "crystal_spider":
		return false
	var face := Vector2(-1.0 if facing_left else 1.0, 0.0)
	return (-shot_dir.normalized()).dot(face) > 0.5


## Hasar alır. Öldüyse true döner.
func take_damage(amount: int, knock_dir := Vector2.ZERO, knock_mult := 1.0) -> bool:
	if removed:
		return false
	if type == "totem":
		# Totem can yerine vuruş sayar: sıradan vuruş 1, ağır vuruş 2 (1-2 okla kırılır).
		hp -= 2 if amount >= 30 else 1
		flash = 10
		main.float_text(position + Vector2(0, -50), "ÇATIRDADI" if hp > 0 else "KIRILDI", Color(0.85, 0.8, 0.6))
		if hp <= 0:
			main.on_enemy_killed(self)
			return true
		return false
	if hidden():
		return false
	if decoy:
		_dispel()
		return true
	if cshell > 0:
		# Kristal kabuk: hasar %70 azalır.
		amount = maxi(1, int(amount * 0.3))
	if type == "yokluk_gozu" and not scattered and hp - amount > 0:
		# Ayna parçalarına dağılır, yanda yeniden birleşir (bir kez).
		scattered = true
		main.burst(position + Vector2(0, -30), 34, RIFT_CYAN)
		for _try in 8:
			var side := Vector2.from_angle(randf() * TAU) * 80.0
			if main.world.circle_free(position + side, 14):
				position += side
				break
		main.float_text(position + Vector2(0, -size * 1.2), "DAĞILDI", RIFT_CYAN.lightened(0.3))
	if type == "run_bekcisi" and knock_dir != Vector2.ZERO:
		var face := Vector2(-1.0 if facing_left else 1.0, 0.0)
		if knock_dir.normalized().dot(face) < -0.3:
			# Rünlü kalkan: önden gelen vuruş kalkana çarpar.
			amount = maxi(1, int(amount * 0.3))
			main.fx.add_sprite(position + Vector2(-size * 0.4 * face.x * -1.0, -size * 0.6), "fx_spark", 40.0, GOLD_GLOW, 10, 0.4)
	if stone:
		# Taş uykusu: hasar işlemez.
		flash = 4
		main.float_text(position + Vector2(0, -size * 0.9), "NÖBETTE", Color(0.7, 0.7, 0.75))
		if wake == 0:
			wake = WAKE_TELL
		return false
	if restone > 0:
		restone_hits += 1
		amount = int(amount * 1.5)
		if restone_hits >= 3:
			restone = 0
			main.burst(position + Vector2(0, -30), 50, Color(0.6, 0.6, 0.65))
			main.float_text(position + Vector2(0, -size * 1.5), "ZIRHI ÇATLADI", Color(0.85, 0.85, 0.9))
	if vine_shield:
		# Sarmaşık kalkanı vuruşu emer.
		vine_shield = false
		flash = 6
		main.burst(position + Vector2(0, -size * 0.5), 40, THORN_GLOW)
		main.float_text(position + Vector2(0, -size * 0.9), "EMDİ", THORN_GLOW.lightened(0.35))
		return false
	if anchored:
		anchor_hits += 1
		if anchor_hits >= 3:
			anchored = false
			main.burst(position + Vector2(0, -10), 50, Color(0.55, 0.4, 0.28))
			main.float_text(position + Vector2(0, -size * 1.6), "KÖKLERİ KOPTU", Color(0.85, 0.7, 0.5))
	if harden > 0:
		# Soğumuş zırh: hasar yarıya iner.
		amount = maxi(1, amount / 2)
	var armored := false
	if type == "buz_ayisi":
		if dazed > 0:
			# Duvara çarpıp sersemledi: buz zırhı açık, çift hasar.
			amount *= 2
		elif plates and knock_dir != Vector2.ZERO:
			var face := Vector2(-1.0 if facing_left else 1.0, 0.0)
			if knock_dir.normalized().dot(face) < -0.3:
				# Önden gelen vuruş buz zırhına çarpar: -%40.
				amount = maxi(1, int(amount * 0.6))
				armored = true
	hp -= amount
	flash = 10
	if knock_dir != Vector2.ZERO:
		knock = knock_dir.normalized() * 8.0 * knock_mult * (0.3 if type in ["kolebasi", "lav_golemi", "ocak_nobetcisi"] else 1.0)
	main.float_text(position + Vector2(0, -size * 0.6), str(amount), Color(0.75, 0.75, 0.8) if harden > 0 or armored else Color("ffffff"))
	if type == "run_klon_dev" and not cshell_used and hp > 0 and hp <= max_hp / 2:
		cshell_used = true
		cshell = SHELL_TIME
		main.burst(position + Vector2(0, -size * 0.6), 60, RUNE_GLOW)
		main.float_text(position + Vector2(0, -size * 1.6), "KRİSTAL KABUK", RUNE_GLOW.lightened(0.35))
	if type == "konsey_bilgesi" and not decoys_made and hp > 0 and hp <= max_hp / 2:
		_make_decoys()
	if type == "gargoyl" and not restone_used and hp > 0 and hp <= max_hp * 0.3:
		restone_used = true
		restone = RESTONE
		restone_hits = 0
		gdive = 0
		main.float_text(position + Vector2(0, -size * 1.5), "KASKATI KESİLDİ", Color(0.75, 0.75, 0.8))
	if type == "kok_muhafizi" and not anchor_used and hp > 0 and hp <= max_hp / 2:
		anchor_used = true
		anchored = true
		anchor_hits = 0
		root_cast = 0
		main.burst(position + Vector2(0, 4), 60, Color(0.5, 0.36, 0.22))
		main.float_text(position + Vector2(0, -size * 1.6), "KÖK SALDI", Color(0.7, 0.9, 0.45))
	if type == "buz_ayisi" and plates and hp > 0 and hp <= max_hp / 2:
		# Plakalar dökülür: daha hızlı ama savunmasız.
		plates = false
		speed *= 1.35
		main.burst(position + Vector2(0, -size * 0.8), 60, Color(0.85, 0.95, 1.0))
		main.float_text(position + Vector2(0, -size * 1.6), "ZIRH DÖKÜLDÜ", Color(0.8, 0.94, 1.0))
		main.shake(8)
	if type == "kul_rahibi" and not ash_used and hp > 0 and hp <= max_hp * 0.3:
		# Ufalanma (tell): bedeni gri-siyah dağılır, sonra kül bulutuna dönüşür.
		ash_used = true
		ash = ASH_TELL
		attack_anim = 0
	if type == "goblin" and hp > 0:
		# Sürü: biri vurulunca yakındaki diğer goblinler kısa süre hızlanır.
		for e in main.enemies:
			if e != self and is_instance_valid(e) and e.type == "goblin" and e.position.distance_to(position) < 300.0:
				e.frenzy = FRENZY
	if type == "kolebasi" and not enraged and hp > 0 and hp <= max_hp / 2:
		enraged = true
		speed *= 1.6
		attack_cd_max = int(attack_cd_max * 0.7)
		main.burst(position + Vector2(0, -30), 60, CHAIN_GLOW)
		main.float_text(position + Vector2(0, -80), "ÖFKE!", CHAIN_GLOW.lightened(0.35))
		main.shake(8)
	if burned > 0 and poisoned > 0:
		burned = 0
		poisoned = 0
		main.elemental_burst(self, int(amount * 1.5))
	if hp <= 0:
		main.on_enemy_killed(self)
		return true
	return false


func _draw() -> void:
	var box_size := size * 1.5
	var box := Rect2(-box_size / 2, -box_size / 2, box_size, box_size)
	if type == "totem":
		_draw_shadow(Vector2(0, 2), 16)
		var tm := Color(1.0, 0.6, 0.5) if flash > 0 else Color.WHITE
		if totem_age > TOTEM_LIFE - 60:
			tm.a = float(TOTEM_LIFE - totem_age) / 60.0
		Sprites.draw_grounded(self, "prop_z3_totem", 66, 4, tm)
		return
	if hidden():
		return
	_draw_shadow(Vector2(0, box_size * 0.45), size * 0.45)
	var mod := tint
	if flash > 0:
		mod = Color(1.0, 0.45, 0.45, tint.a)
	elif enraged:
		var ek := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 110.0)
		mod = mod * Color(1.0 + 0.25 * ek, 0.85, 1.0 + 0.45 * ek)
	elif chain_state == "tell":
		var ck := 1.0 - float(chain_t) / CHAIN_TELL
		mod = mod * Color(1.0 + 0.4 * ck, 1.0, 1.0 + 0.8 * ck)
	elif type in ["lav_golemi", "ocak_nobetcisi"] and slam > 0:
		# Yere vuruş tell'i: lav çatlakları giderek kızarır.
		var gk := 1.0 - float(slam) / GOLEM_SLAM_TELL
		mod = mod * Color(1.0 + 0.7 * gk, 1.0 + 0.3 * gk, 1.0)
	elif dive_state == "tell":
		var dk := 1.0 - float(dive_t) / DIVE_TELL
		mod = mod * Color(1.0 + 0.5 * dk, 1.0 + 0.4 * dk, 1.0 + 0.2 * dk)
	elif claw > 0:
		# Donduran pençe tell'i: beden soğuk maviye çalar.
		var ck := 1.0 - float(claw) / CLAW_TELL
		mod = mod * Color(1.0 - 0.2 * ck, 1.0 + 0.1 * ck, 1.0 + 0.5 * ck)
	elif dazed > 0:
		mod = mod * Color(1.1, 1.05, 0.9)
	elif stone or restone > 0:
		# Taş: gri; uyanırken gri azalır.
		var gk := 1.0 if wake == 0 else float(wake) / WAKE_TELL
		mod = mod * Color.WHITE.lerp(Color(0.55, 0.55, 0.6), gk)
	elif cshell > 0:
		mod = mod * Color(1.1, 0.85, 1.3)
	elif slab > 0:
		var sk := 1.0 - float(slab) / SLAB_TELL
		mod = mod * Color(1.0 + 0.25 * sk, 1.0, 1.0 + 0.4 * sk)
	elif burrow in ["sink", "under", "rise"]:
		# Yırtığa dalmış: zemin altında (görünmez); batarken solar.
		mod.a *= 0.0 if burrow != "sink" else float(burrow_t) / SINK
	elif ring_t > 0:
		var rk := 1.0 - float(ring_t) / RING_TELL
		mod = mod * Color(1.0, 1.0 + 0.3 * rk, 1.0 + 0.4 * rk)
	elif decoy:
		# Kopya: biraz daha soluk ve altına çalan (dikkatli bakan seçer).
		mod = mod * Color(1.05, 1.0, 0.85, 0.82)
	elif step > 0:
		# Portal adımı: yerinde solar.
		mod.a *= float(step) / STEP_TELL
	elif scribe > 0:
		var sk := 1.0 - float(scribe) / SCRIBE_TELL
		mod = mod * Color(1.0 + 0.3 * sk, 1.0, 1.0)
	elif puff > 0:
		# Şapka şişerken benekler mora çalar.
		var pk := 1.0 - float(puff) / PUFF_TELL
		mod = mod * Color(1.0 + 0.3 * pk, 1.0, 1.0 + 0.5 * pk)
	if type == "buz_ayisi" and not plates:
		# Plakaları dökülmüş: buz sönük, kürk öne çıkar.
		mod = mod * Color(1.0, 0.96, 0.92)
	if harden > 0:
		# Soğumuş, sertleşmiş zırh: gri taş (son kareleri yeniden kızarır).
		mod = mod * Color.WHITE.lerp(HARDEN_GREY, minf(1.0, harden / 20.0))
	if ash > 0:
		# Ufalanma: beden gri-siyaha döner ve solar.
		var ak := 1.0 - float(ash) / ASH_TELL
		mod = mod * Color.WHITE.lerp(Color(0.32, 0.3, 0.28), ak)
		mod.a *= 1.0 - 0.5 * ak
	var off := Vector2.ZERO
	var sc := 1.0
	var sq := 1.0
	var pd := position.distance_to(main.player.position)
	var windup := attack_cd < 16 and attack_cd > 0 and pd < (220.0 if ranged else SURGE_RANGE + 8.0)
	if leap_state == "crouch":
		# Çömelme: basılır, sırt kristalleri nabız gibi parlar.
		var k := 1.0 - float(leap_t) / LEAP_CROUCH
		sq = 1.0 - 0.16 * k
		mod = mod * Color(1.0 + 0.5 * k, 1.0 + 0.2 * k, 1.0 + 0.7 * k)
		off.x = sin(leap_t * 1.7) * 1.5
	elif leap_state == "air":
		off.y = -sin((1.0 - float(leap_t) / leap_len) * PI) * 16.0
	elif hop > 0:
		off.y = -sin((1.0 - float(hop) / HOP) * PI) * 12.0
	elif slam > 0:
		# Yere vuruş hazırlığı: doğrulup kalkar, sonra çöker.
		var k := 1.0 - float(slam) / (GOLEM_SLAM_TELL if type in ["lav_golemi", "ocak_nobetcisi"] else SLAM_TELL)
		sq = 1.0 + 0.08 * sin(k * PI * 0.5)
		off.y = -6.0 * k
	elif dive_state == "tell":
		# Kanatlarını toplar: basılır, titrer.
		var k := 1.0 - float(dive_t) / DIVE_TELL
		sq = 1.0 - 0.12 * k
		off.x = sin(dive_t * 2.1) * 1.5
	elif ash > 0:
		off.x = sin(ash * 1.9) * 1.5
		sq = 1.0 - 0.12 * (1.0 - float(ash) / ASH_TELL)
	elif claw > 0:
		# Kolunu geri çeker: hafif geriye yaslanır ve titrer.
		var k := 1.0 - float(claw) / CLAW_TELL
		off.x = (6.0 if claw_dir.x < 0 else -6.0) * k + sin(claw * 1.9) * 1.0
	elif web > 0:
		# Karnını büzer: kalkıp basılır.
		var k := 1.0 - float(web) / WEB_TELL
		sq = 1.0 + 0.08 * sin(k * PI) - 0.1 * k
		off.x = sin(web * 2.0) * 1.2
	elif charge_state == "tell":
		# Arka ayakları üstüne kalkmış, kükrerken titrer.
		off.x = sin(charge_t * 1.6) * 1.5
	elif dazed > 0:
		off.x = sin(dazed * 0.5) * 2.0
	elif gdive > 0:
		# Pike dalış: havalanır, gölgenin üstüne yay çizerek iner.
		var u := 1.0 - float(gdive) / VoidHazard.SHADOW_TELL
		off.y = -sin(u * PI) * 70.0
	elif wake > 0:
		off.x = sin(wake * 1.8) * 1.5
	elif gust > 0:
		var k := 1.0 - float(gust) / GUST_TELL
		off.x = (-5.0 if gust_dir.x > 0 else 5.0) * k
	elif puff > 0:
		# Şapka şişer: gövde kabarır, titrer.
		var k := 1.0 - float(puff) / PUFF_TELL
		sc = 1.0 + 0.12 * k
		off.x = sin(puff * 2.2) * 1.2 * k
	elif root_cast > 0:
		# Asayı kaldırıp yere saplar.
		var k := 1.0 - float(root_cast) / ROOT_CAST
		off.y = -4.0 * sin(k * PI)
	elif attack_anim > 0:
		var k := sin((18 - attack_anim) / 18.0 * PI)
		var dir := (main.player.position - position).normalized()
		off = dir * 8.0 * k
		sc = 1.0 + 0.14 * k
	elif windup:
		sc = 1.0 - 0.08 * (16 - attack_cd) / 16.0
	if type in ["yokluk_gozu", "yorunge_tasi"]:
		# Havada süzülür (gölge yerde kalır).
		off.y += -12.0 + sin(Time.get_ticks_msec() / 380.0 + zig) * 4.0
	if type == "konsey_bilgesi":
		# Havada süzülür (gölge yerde kalır).
		off.y += -8.0 + sin(Time.get_ticks_msec() / 420.0 + zig) * 3.0
	if type in ["kor_impi", "murekkep_hayaleti"] and dive_state != "dash":
		# Kanat çırparak havada süzülür (gölge yerde kalır).
		off.y += -12.0 + sin(Time.get_ticks_msec() / 160.0 + zig) * 4.0
	if blink > 0:
		mod.a *= float(blink) / BLINK_FADE
	if vanish > 0:
		mod.a *= 0.16 if vanish > 20 else 1.0 - 0.84 * vanish / 20.0
	var key := "%s_idle%d" % [sprite_key, frame]
	var show_attack := attack_anim > 0 or windup or leap_state == "air" or surge > 0 or plant > 0 \
			or chain_state in ["throw", "pull"] or charge_state != "" or (puff > 0 and puff < PUFF_TELL / 3) \
			or (root_cast > 0 and root_cast < ROOT_CAST / 2) or gdive > 0 or (scribe > 0 and scribe < SCRIBE_TELL / 2) \
			or (sage_cast > 0 and sage_cast < SAGE_CAST / 2) or (gcast > 0 and gcast < GRAV_CAST / 2) or (gust > 0 and gust < GUST_TELL / 3) \
			or (slab > 0 and slab < SLAB_TELL / 3) or (ring_t > 0 and ring_t < RING_TELL / 3) or (gaze_t > 0 and gaze_t <= RiftHazard.GAZE_FIRE) or burrow == "up" and burrow_t > SURFACED - 20
	if show_attack and leap_state != "rest" and Sprites.tex("%s_attack" % sprite_key):
		key = "%s_attack" % sprite_key
	elif moving and attack_anim == 0 and Sprites.tex("%s_walk1" % sprite_key):
		key = "%s_walk%d" % [sprite_key, frame]
	# Kare kutuya germe yerine oranı koru: yüksekliğe göre sığdır, ortala, ayak alt kenarda.
	var ds := sc * draw_mul
	var r := Rect2(box.position * ds + off, box.size * ds)
	r.position.y = box.end.y - r.size.y * sq + off.y
	r.size.y *= sq
	var b := Sprites.fit_box(key, r)
	if sq != 1.0:
		b.size.x /= sq
		b.position.x = r.get_center().x - b.size.x / 2
	Sprites.draw_actor(self, key, b, facing_left, moving, false, mod)
	# Göz (goblin: kafanın önü) ve zincirli el (kölebaşı) — GlowLayer bu noktalara parlar.
	var fx_x := func(u: float) -> float: return b.end.x - u * b.size.x if facing_left else b.position.x + u * b.size.x
	_eye = Vector2(fx_x.call(0.605), b.position.y + 0.29 * b.size.y)
	_hand = Vector2(fx_x.call(0.95 if key.ends_with("attack") else 0.78), b.position.y + (0.45 if key.ends_with("attack") else 0.66) * b.size.y)
	match type:
		"kor_impi":
			_eye = Vector2(fx_x.call(0.92 if key.ends_with("attack") else 0.73), b.position.y + (0.6 if key.ends_with("attack") else 0.5) * b.size.y)
		"lav_golemi", "ocak_nobetcisi":
			# Göğüs ortası: çatlak parıltısının merkezi.
			_eye = Vector2(fx_x.call(0.55), b.position.y + 0.48 * b.size.y)
		"diken_tazisi":
			# Göz: başın önü; _hand: sırt dikenlerinin ortası.
			_eye = Vector2(fx_x.call(0.86 if key.ends_with("attack") else 0.82), b.position.y + (0.6 if key.ends_with("attack") else 0.62) * b.size.y)
			_hand = Vector2(fx_x.call(0.45), b.position.y + 0.55 * b.size.y)
		"spor_mantari":
			# Şapkanın ortası (benekler).
			_eye = Vector2(fx_x.call(0.58), b.position.y + 0.38 * b.size.y)
		"kok_muhafizi":
			# Göğüsteki mor rün; asanın kristal ucu (saldırıda yere saplanan uç).
			_eye = Vector2(fx_x.call(0.4), b.position.y + 0.42 * b.size.y)
			_hand = Vector2(fx_x.call(0.75 if key.ends_with("attack") else 0.72), b.position.y + (0.88 if key.ends_with("attack") else 0.13) * b.size.y)
		"run_klon_kilic":
			_eye = Vector2(fx_x.call(0.62), b.position.y + 0.18 * b.size.y)
			_hand = Vector2(fx_x.call(0.85), b.position.y + 0.6 * b.size.y)
		"run_klon_buyucu":
			_eye = Vector2(fx_x.call(0.55), b.position.y + 0.2 * b.size.y)
			_hand = Vector2(fx_x.call(0.3), b.position.y + 0.12 * b.size.y)
		"run_klon_dev":
			_eye = Vector2(fx_x.call(0.45), b.position.y + 0.2 * b.size.y)
			_hand = Vector2(fx_x.call(0.85), b.position.y + 0.55 * b.size.y)
		"yorunge_tasi":
			# Mor çekirdek.
			_eye = Vector2(fx_x.call(0.5), b.position.y + 0.5 * b.size.y)
		"yokluk_gozu":
			_eye = Vector2(fx_x.call(0.62), b.position.y + 0.5 * b.size.y)
		"bosluk_yiyici":
			_eye = Vector2(fx_x.call(0.85 if key.ends_with("attack") else 0.8), b.position.y + (0.25 if key.ends_with("attack") else 0.3) * b.size.y)
		"konsey_bilgesi":
			_eye = Vector2(fx_x.call(0.6), b.position.y + 0.2 * b.size.y)
			_hand = Vector2(fx_x.call(0.85 if key.ends_with("attack") else 0.8), b.position.y + (0.05 if key.ends_with("attack") else 0.15) * b.size.y)
		"run_bekcisi":
			_eye = Vector2(fx_x.call(0.55), b.position.y + 0.15 * b.size.y)
			_hand = Vector2(fx_x.call(0.85 if key.ends_with("attack") else 0.82), b.position.y + (0.8 if key.ends_with("attack") else 0.45) * b.size.y)
		"gok_muhafizi":
			_eye = Vector2(fx_x.call(0.6), b.position.y + 0.22 * b.size.y)
		"golge_yuruyucu":
			_eye = Vector2(fx_x.call(0.7), b.position.y + 0.25 * b.size.y)
		"kan_yazicisi":
			# Kan damlayan tüy kalemin ucu.
			_hand = Vector2(fx_x.call(0.95 if key.ends_with("attack") else 0.82), b.position.y + (0.45 if key.ends_with("attack") else 0.32) * b.size.y)
		"gargoyl":
			_eye = Vector2(fx_x.call(0.84 if key.ends_with("attack") else 0.74), b.position.y + (0.42 if key.ends_with("attack") else 0.32) * b.size.y)
		"diken_rahibesi":
			# Elindeki dikenli tohum.
			_hand = Vector2(fx_x.call(0.95 if key.ends_with("attack") else 0.86), b.position.y + (0.38 if key.ends_with("attack") else 0.6) * b.size.y)
		"buz_zombisi":
			_eye = Vector2(fx_x.call(0.71), b.position.y + 0.37 * b.size.y)
			_hand = Vector2(fx_x.call(0.96 if key.ends_with("attack") else 0.8), b.position.y + (0.45 if key.ends_with("attack") else 0.7) * b.size.y)
		"buz_aynasi":
			# Göz yerine ayna kabuğun ortası (yansıma çizgisi burada gezinir).
			_eye = Vector2(fx_x.call(0.57), b.position.y + 0.5 * b.size.y)
			_hand = Vector2(b.size.x * 0.24, 0)
		"buz_ayisi":
			_eye = Vector2(fx_x.call(0.93 if key.ends_with("attack") else 0.95), b.position.y + (0.24 if key.ends_with("attack") else 0.58) * b.size.y)
		"kul_rahibi":
			# Asanın ucundaki tütsü feneri.
			_hand = Vector2(fx_x.call(0.95 if key.ends_with("attack") else 0.81), b.position.y + (0.45 if key.ends_with("attack") else 0.6) * b.size.y)
	if anchored:
		_draw_anchor_roots()
	if vine_shield:
		_draw_vine_shield(box_size)
	if chain_state in ["throw", "pull", "back"] and chain_len > 4.0:
		_draw_chain(_hand, _chain_span())
	if attack_anim > 0 and chain_state == "" and charge_state == "" and slam == 0 and type != "kul_rahibi":
		var a := (main.player.position - position).angle()
		var swing: Color = EnemyData.DEBUFF_COLORS.get(debuff, Color.WHITE)
		draw_arc(Vector2.ZERO, size * 0.8, a - 0.55, a + 0.55, 32, Color(swing, 0.25), 8.0, true)
		draw_arc(Vector2.ZERO, size * 0.8, a - 0.55, a + 0.55, 32, swing, 2.5, true)
	if type == "time_echo":
		draw_string(ThemeDB.fallback_font, Vector2(-40, -box_size / 2 - 4), "ZAMAN YANKISI", HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color("7ff"))
	if hp < max_hp:
		var y := -box_size / 2 - 8
		if draw_mul > 1.2:
			# Büyük çizilen türlerde can çubuğu başın üstünde kalsın.
			y = box.end.y - box_size * draw_mul * 0.85 - 8
		draw_rect(Rect2(-16, y, 32, 4), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-16, y, 32.0 * maxf(0, hp) / max_hp, 4), Color("ff3b30"))
	if marked > 0:
		draw_arc(Vector2.ZERO, size * 0.55, 0, TAU, 48, Color(1, 0.85, 0.2, 0.8), 1.5, true)


## Kök salmış Kök Muhafızı: ayağının çevresinden yere dalan kalın kökler.
func _draw_anchor_roots() -> void:
	var feet := Vector2(0, size * 0.7)
	for i in 6:
		var ang := zig + i * TAU / 6.0
		var tip := feet + Vector2(cos(ang) * size * 0.95, sin(ang) * size * 0.32)
		var mid := feet.lerp(tip, 0.5) + Vector2(0, -6.0 - 4.0 * sin(i * 2.1))
		var pts := PackedVector2Array([feet + Vector2(cos(ang) * 8.0, -4), mid, tip])
		draw_polyline(pts, Color(0.12, 0.08, 0.05, 0.95), 6.0, true)
		draw_polyline(pts, Color(0.42, 0.29, 0.18, 0.95), 3.0, true)


## Sarmaşık kalkanı: gövdeyi saran mor yapraklı halka (bir sonraki vuruşu emer).
func _draw_vine_shield(box_size: float) -> void:
	var c := Vector2(0, -box_size * 0.12)
	var r := box_size * 0.45
	var now := Time.get_ticks_msec() / 1000.0
	draw_set_transform(c, 0, Vector2(1, 0.75))
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(0.18, 0.28, 0.12, 0.85), 3.0, true)
	for i in 10:
		var a := i * TAU / 10.0 + now * 0.4
		var at := Vector2.from_angle(a) * r
		draw_set_transform(c + at * Vector2(1, 0.75), a + PI / 2, Vector2(1, 0.5))
		draw_circle(Vector2.ZERO, 5.0, Color(0.45, 0.22, 0.6, 0.9))
		draw_set_transform(c, 0, Vector2(1, 0.75))
	draw_set_transform(Vector2.ZERO)


## Elden zincir ucuna: uç, oyuncunun gövde yüksekliğinde (uzunluk ayaktan ölçülür, el önde ve yukarıda).
func _chain_span() -> Vector2:
	return chain_dir * chain_len + Vector2(0, -30) - _hand


## Zincir: boyalı halkalar (yüz / yan sırayla) elden hedefe dizilir, ucunda dikenli kanca.
## Fırlarken ve geri sarılırken dalgalanır, çekerken gergin durur. Doku yoksa kodla çizilen zincir.
const CHAIN_LINK_H := 21.0   # yüz halkanın ekrandaki yüksekliği
const CHAIN_HOOK_H := 42.0


func _chain_wave() -> float:
	if chain_state == "throw":
		return 7.0
	if chain_state == "back":
		return 12.0
	return 0.0


func _draw_chain(from: Vector2, span: Vector2) -> void:
	if not paint_chain(self, from, span, _chain_wave()):
		_draw_chain_code(from, span)


## Boyalı zinciri herhangi bir CanvasItem'a çizer (Kölebaşı ve IGNIS ortak). suffix: doku çeşidi
## ("" mor demir, "_fire" IGNIS'in kor zinciri). Doku yoksa false döner.
static func paint_chain(ci: CanvasItem, from: Vector2, span: Vector2, wave: float, suffix := "") -> bool:
	var face := Sprites.tex("fx_chain_link_face" + suffix)
	var side := Sprites.tex("fx_chain_link_side" + suffix)
	var hook := Sprites.tex("fx_chain_hook" + suffix)
	if not (face and side and hook):
		return false
	var length := span.length()
	if length < 2.0:
		return true
	var dir := span / length
	var perp := dir.orthogonal()
	var now := Time.get_ticks_msec() / 1000.0
	var s := CHAIN_LINK_H / face.get_height()
	var sz := [face.get_size() * s, side.get_size() * s]
	var hs := CHAIN_HOOK_H / hook.get_height()
	var hsz := hook.get_size() * hs
	# Halkalar kancanın halkasına kadar uzanır; her halka bir öncekinin %72'si kadar ilerler.
	var usable := length - hsz.x * 0.74
	var centers := []
	var d := 0.0
	var i := 0
	while d < usable - sz[i % 2].x * 0.35:
		centers.append([d + sz[i % 2].x * 0.5, i % 2])
		d += sz[i % 2].x * 0.72
		i += 1
	var point := func(dd: float) -> Vector2:
		var u := clampf(dd / length, 0.0, 1.0)
		return from + dir * dd + perp * (sin(u * PI) * wave * sin(now * 24.0 - u * 9.0))
	# Önce yan halkalar (arkada), sonra yüz halkalar.
	for pass_kind in [1, 0]:
		for c in centers:
			if c[1] != pass_kind:
				continue
			var a: Vector2 = point.call(c[0])
			var tangent: Vector2 = point.call(c[0] + 3.0) - point.call(c[0] - 3.0)
			var lsz: Vector2 = sz[pass_kind]
			ci.draw_set_transform(a, tangent.angle())
			ci.draw_texture_rect(face if pass_kind == 0 else side, Rect2(-lsz / 2, lsz), false)
	# Uçta kanca: ucu zincir yönünü gösterir, sivri ucu hedefin biraz ötesinde.
	var tip: Vector2 = point.call(length)
	var back: Vector2 = point.call(length - 10.0)
	ci.draw_set_transform(tip, (tip - back).angle())
	ci.draw_texture_rect(hook, Rect2(Vector2(-hsz.x * 0.86, -hsz.y / 2), hsz), false)
	ci.draw_set_transform(Vector2.ZERO)
	return true


## Doku bulunamazsa: kodla çizilen mor-demir halkalar ve kanca.
func _draw_chain_code(from: Vector2, span: Vector2) -> void:
	var length := span.length()
	if length < 2.0:
		return
	var dir := span / length
	var perp := dir.orthogonal()
	var ang := dir.angle()
	var now := Time.get_ticks_msec() / 1000.0
	var wave := _chain_wave()
	var n := maxi(2, int(length / 12.0))
	for i in n:
		var u := (float(i) + 0.5) / n
		var sag := sin(u * PI) * wave * sin(now * 24.0 - u * 9.0)
		var c := from + span * u + perp * sag
		if i % 2 == 0:
			# Yüzü dönük halka: koyu dış hat, mor demir, üstte açık parıltı.
			draw_set_transform(c, ang, Vector2(1.0, 0.62))
			draw_arc(Vector2.ZERO, 8.5, 0, TAU, 16, Color(0.08, 0.04, 0.12), 5.5)
			draw_arc(Vector2.ZERO, 8.5, 0, TAU, 16, Color(0.5, 0.26, 0.72), 3.2)
			draw_arc(Vector2.ZERO, 8.5, PI * 1.1, PI * 1.75, 6, Color(0.92, 0.78, 1.0), 1.4)
		else:
			# Yan dönük halka: kalın çubuk.
			draw_set_transform(c, ang)
			draw_line(Vector2(-8.5, 0), Vector2(8.5, 0), Color(0.08, 0.04, 0.12), 6.0)
			draw_line(Vector2(-8.5, 0), Vector2(8.5, 0), Color(0.56, 0.3, 0.8), 3.2)
			draw_line(Vector2(-6, -1.2), Vector2(5, -1.2), Color(0.92, 0.78, 1.0), 1.2)
	# Uçta dikenli kanca.
	var tip := from + span
	draw_set_transform(tip, ang)
	var hook := PackedVector2Array([Vector2(14, 0), Vector2(-2, -9), Vector2(2, 0), Vector2(-2, 9)])
	draw_colored_polygon(hook, Color(0.1, 0.05, 0.14))
	var inner := PackedVector2Array([Vector2(11, 0), Vector2(0, -6), Vector2(3, 0), Vector2(0, 6)])
	draw_colored_polygon(inner, Color(0.62, 0.32, 0.88))
	draw_arc(Vector2(-3, 0), 6.0, -2.2, 2.2, 10, Color(0.1, 0.05, 0.14), 3.0)
	draw_line(Vector2(2, 0), Vector2(13, 0), Color(0.95, 0.85, 1.0), 1.2)
	draw_set_transform(Vector2.ZERO)


## Tell'lerin parlayan kısmı (GlowLayer, toplamalı): sürü gözleri, totem halkası, şamanın asa halkası,
## zincirin mor parıltısı ve savrulacağı çizgi, yere vuruşun çatlakları, öfkeli kölebaşının damarları.
func _paint_tells(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	match type:
		"goblin":
			if frenzy > 0:
				var a := minf(1.0, frenzy / 20.0)
				var side := Vector2(-3.0 if facing_left else 3.0, 0)
				g.glow(_eye, 9.0, Color(1.0, 0.85, 0.1, 0.55 * a))
				g.glow(_eye + side, 3.5, Color(1.0, 1.0, 0.5, 0.9 * a))
				g.glow(_eye - side, 3.0, Color(1.0, 1.0, 0.5, 0.8 * a))
		"totem":
			var k := 0.5 + 0.5 * sin(now * 2.2)
			var fade := 1.0 if totem_age < TOTEM_LIFE - 60 else float(TOTEM_LIFE - totem_age) / 60.0
			g.glow(Vector2(0, -50), 14.0 + 4.0 * k, Color(0.75, 1.0, 0.2, 0.45 * fade))
			g.draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.42))
			g.ring(Vector2.ZERO, TOTEM_RANGE, 2.0, Color(0.6, 1.0, 0.15, (0.18 + 0.14 * k) * fade))
			g.ring(Vector2.ZERO, TOTEM_RANGE * (1.0 - fmod(now * 0.6, 1.0)), 1.5, Color(0.7, 1.0, 0.3, 0.2 * fade))
			g.draw_set_transform(Vector2.ZERO)
		"goblin_saman":
			if plant > 0:
				var k := 1.0 - float(plant) / PLANT_TELL
				g.draw_set_transform(Vector2(0, size * 0.65), 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, 14.0 + 90.0 * k, 2.5, Color(0.7, 1.0, 0.2, 0.9 * (1.0 - k * 0.5)))
				g.ring(Vector2.ZERO, 8.0 + 50.0 * k, 1.5, Color(0.95, 1.0, 0.5, 0.6))
				g.draw_set_transform(Vector2.ZERO)
			if attack_anim > 0 or plant > 0 or (attack_cd < 16 and attack_cd > 0):
				g.glow(_eye + Vector2(-12.0 if facing_left else 12.0, -10), 10.0, Color(0.75, 1.0, 0.2, 0.6))
		"kolebasi":
			if enraged:
				var ek := 0.5 + 0.5 * sin(now * 6.0)
				g.glow(Vector2(0, -size * 0.55), size * 0.9, Color(0.55, 0.15, 0.9, 0.12 + 0.12 * ek))
			if chain_state == "tell":
				var k := 1.0 - float(chain_t) / CHAIN_TELL
				# Elde dönen zincir: mor halka büyür, kıvılcımlar elin çevresinde döner.
				g.glow(_hand, 12.0 + 16.0 * k, Color(0.7, 0.25, 1.0, 0.35 + 0.5 * k))
				for j in 5:
					var a := now * 9.0 + j * TAU / 5.0
					g.glow(_hand + Vector2.from_angle(a) * (10.0 + 6.0 * k), 4.0, Color(0.85, 0.55, 1.0, 0.5 + 0.4 * k))
				# Hedef çizgisi: lazer değil, soluk noktalar; sona doğru keskinleşir.
				var dots := 14
				for j in dots:
					var u := float(j + 1) / dots
					if u > 0.3 + 0.7 * k:
						break
					g.glow(_hand + chain_dir * CHAIN_RANGE * u, 3.0, Color(0.75, 0.4, 1.0, 0.15 + 0.4 * k))
			elif chain_state in ["throw", "pull", "back"]:
				# Halkaların mor parıltısı; çekerken parıltı oyuncudan kölebaşına doğru akar.
				# Parıltı halkalarla aynı dalgayı izler.
				var span := _chain_span()
				var perp := span.normalized().orthogonal()
				var wave := _chain_wave()
				var n := maxi(2, int(span.length() / 16.0))
				for j in n:
					var u := (float(j) + 0.5) / n
					var pulse := 0.0
					if chain_state == "pull":
						pulse = maxf(0.0, sin((u + now * 2.5) * TAU * 2.0))
					var c := _hand + span * u + perp * (sin(u * PI) * wave * sin(now * 24.0 - u * 9.0))
					g.glow(c, 10.0 + 5.0 * pulse, Color(0.65, 0.25, 1.0, 0.32 + 0.35 * pulse))
					g.glow(c, 4.0, Color(0.85, 0.55, 1.0, 0.25 + 0.3 * pulse))
				g.glow(_hand + span, 20.0, Color(0.75, 0.35, 1.0, 0.75))
			if slam > 0:
				_paint_cracks(g, 1.0 - float(slam) / SLAM_TELL, 20.0, 100.0)
		"kor_impi":
			if dive_state == "tell":
				var k := 1.0 - float(dive_t) / DIVE_TELL
				# Gözler beyaz-sarı parlar; atılacağı çizgi soluk kor noktalarıyla belirir.
				g.glow(_eye, 8.0 + 12.0 * k, Color(1.0, 0.85, 0.3, 0.35 + 0.5 * k))
				g.glow(_eye, 3.5, Color(1.0, 1.0, 0.85, 0.6 + 0.4 * k))
				var dots := 8
				for j in dots:
					var u := float(j + 1) / dots
					if u > 0.3 + 0.7 * k:
						break
					g.glow(Vector2(0, size * 0.75) + dive_dir * DIVE * DIVE_SPEED * u, 3.5, Color(1.0, 0.55, 0.15, 0.2 + 0.4 * k))
			elif dive_state == "dash":
				g.glow(_eye - dive_dir * 18.0, 22.0, Color(1.0, 0.5, 0.12, 0.45))
				g.glow(_eye, 7.0, Color(1.0, 0.95, 0.7, 0.8))
			else:
				g.glow(_eye, 4.0, Color(1.0, 0.7, 0.25, 0.45))
		"murekkep_hayaleti":
			g.glow(_eye, 4.0, Color(0.75, 0.45, 1.0, 0.5))
			if dive_state == "tell":
				var k := 1.0 - float(dive_t) / DIVE_TELL
				for j in 8:
					var u := float(j + 1) / 8
					if u > 0.3 + 0.7 * k:
						break
					g.glow(Vector2(0, size * 0.75) + dive_dir * DIVE * DIVE_SPEED * u, 3.5, Color(0.7, 0.4, 1.0, 0.2 + 0.4 * k))
		"zincirli_arsivci":
			if slam > 0:
				var k := 1.0 - float(slam) / SLAM_TELL
				g.glow(Vector2(0, -size * 0.9), 14.0 + 16.0 * k, Color(0.75, 0.45, 1.0, 0.3 + 0.5 * k))
				g.draw_set_transform(Vector2(0, size * 0.62), 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, 90.0 * k, 1.8, Color(0.8, 0.55, 1.0, 0.3 + 0.5 * k))
				g.draw_set_transform(Vector2.ZERO)
		"ruhsuz_katip":
			if attack_anim > 0 or (attack_cd < 16 and attack_cd > 0):
				g.glow(Vector2(0, -size * 0.5), 18.0, Color(0.85, 0.75, 1.0, 0.4))
		"lav_golemi", "ocak_nobetcisi":
			var bs := size * 1.5 * draw_mul / 162.0
			if slam > 0:
				var k := 1.0 - float(slam) / GOLEM_SLAM_TELL
				# Çatlaklar giderek parlar; sona doğru beyaz-sarı göbek. Yerde vuracağı yöne çatlak çizgileri.
				for o in [Vector2(0, 0), Vector2(-22, -18), Vector2(18, -24), Vector2(-14, 22), Vector2(24, 14), Vector2(-34, 4), Vector2(36, -6)]:
					g.glow(_eye + o * bs, (9.0 + 13.0 * k) * bs, Color(1.0, 0.5, 0.12, 0.2 + 0.5 * k))
				g.glow(_eye, (30.0 + 30.0 * k) * bs, Color(1.0, 0.45, 0.1, 0.15 + 0.25 * k))
				if k > 0.55:
					g.glow(_eye, 14.0 * bs, Color(1.0, 0.95, 0.7, (k - 0.55) * 1.6))
				_paint_cracks(g, k, 30.0, GOLEM_SLAM_R)
			elif harden == 0:
				var pk := 0.5 + 0.5 * sin(now * 2.0 + zig)
				g.glow(_eye, 18.0 * bs, Color(1.0, 0.45, 0.1, 0.12 + 0.08 * pk))
		"kul_rahibi":
			if ash > 0:
				var k := 1.0 - float(ash) / ASH_TELL
				for j in 6:
					var a := zig + j * 1.05 + now * 1.5
					g.glow(Vector2(cos(a) * 18.0, -size * 0.7 + sin(a * 1.3) * 26.0 - k * 20.0), 3.0, Color(1.0, 0.45, 0.12, 0.5 * (1.0 - k)))
			else:
				var cast := attack_anim > 0
				var fl := 0.85 + 0.15 * sin(now * 11.0 + zig)
				g.glow(_hand, (10.0 if not cast else 22.0) * fl, Color(1.0, 0.6, 0.2, 0.35 if not cast else 0.7))
				g.glow(_hand, 4.0, Color(1.0, 0.9, 0.6, 0.5))
		"diken_tazisi", "spor_mantari", "kok_muhafizi", "diken_rahibesi":
			_paint_forest(g, now)
		"golge_yuruyucu", "kan_yazicisi", "gargoyl":
			_paint_castle(g, now)
		"konsey_bilgesi", "run_bekcisi", "gok_muhafizi":
			_paint_sky(g, now)
		"yorunge_tasi", "yokluk_gozu", "bosluk_yiyici":
			_paint_rift(g, now)
		"run_klon_kilic", "run_klon_buyucu", "run_klon_dev":
			_paint_clone(g, now)
		"buz_zombisi":
			_paint_ice_eyes(g, 0.35)
			if claw > 0:
				# Pençe tell'i: geri çekilen el soğuk maviye döner, buz kıymıkları toplanır.
				var k := 1.0 - float(claw) / CLAW_TELL
				var hand := _hand - claw_dir * 10.0 * k
				g.glow(hand, 8.0 + 12.0 * k, Color(ICE_GLOW, 0.3 + 0.5 * k))
				g.glow(hand, 4.0, Color(0.9, 0.97, 1.0, 0.5 + 0.4 * k))
				for j in 4:
					var a := now * 7.0 + j * TAU / 4.0
					g.glow(hand + Vector2.from_angle(a) * (14.0 - 8.0 * k), 2.5, Color(0.9, 0.97, 1.0, 0.6 * k))
		"buz_aynasi":
			_paint_shell(g, now)
			if web > 0:
				# Ağ tell'i: karnın altında beyaz ağ yumağı büyür; hedefte soluk halka belirir.
				var k := 1.0 - float(web) / WEB_TELL
				var belly := Vector2(-14.0 if not facing_left else 14.0, -size * 0.35)
				g.glow(belly, 6.0 + 10.0 * k, Color(0.92, 0.97, 1.0, 0.35 + 0.45 * k))
				var tgt := web_target - position
				g.draw_set_transform(tgt, 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, 46.0 * (0.4 + 0.6 * k), 1.4, Color(ICE_GLOW, 0.25 + 0.4 * k))
				g.draw_set_transform(Vector2.ZERO)
		"buz_ayisi":
			_paint_ice_eyes(g, 0.4)
			if plates:
				var pk := 0.5 + 0.5 * sin(now * 1.6 + zig)
				g.glow(Vector2(0, -size * 0.9), size * 0.6, Color(ICE_GLOW, 0.06 + 0.05 * pk))
			if charge_state == "tell":
				# Kükreme: ağızdan buhar bulutları, hücum yönünde soluk buz noktaları.
				var k := 1.0 - float(charge_t) / CHARGE_TELL
				var mouth := _eye + Vector2(-16.0 if facing_left else 16.0, 10)
				for j in 4:
					var u := fmod(now * 1.4 + j * 0.25, 1.0)
					g.glow(mouth + Vector2((-1.0 if facing_left else 1.0) * 30.0 * u, -24.0 * u), 6.0 + 12.0 * u, Color(0.9, 0.96, 1.0, 0.35 * (1.0 - u)))
				var dots := 10
				for j in dots:
					var u := float(j + 1) / dots
					if u > 0.3 + 0.7 * k:
						break
					g.glow(Vector2(0, size * 0.6) + charge_dir * 240.0 * u, 3.5, Color(ICE_GLOW, 0.2 + 0.4 * k))
			elif charge_state == "run":
				g.glow(Vector2(0, -size * 0.6) - charge_dir * 20.0, size * 0.7, Color(ICE_GLOW, 0.18))
			if slam > 0:
				var k := 1.0 - float(slam) / STOMP_TELL
				g.draw_set_transform(Vector2(0, size * 0.62), 0, Vector2(1, 0.42))
				g.ring(Vector2.ZERO, 84.0 * k, 2.0, Color(0.9, 0.97, 1.0, 0.25 + 0.5 * k))
				g.glow(Vector2.ZERO, 40.0 * k, Color(ICE_GLOW, 0.2 * k))
				g.draw_set_transform(Vector2.ZERO)
			if dazed > 0:
				for j in 3:
					var a := now * 5.0 + j * TAU / 3.0
					g.glow(_eye + Vector2(cos(a) * 18.0, -26.0 + sin(a) * 6.0), 4.0, Color(1.0, 0.95, 0.6, 0.8))


## Bölge 6 parıltıları: mor göz / benek / damar; tell'lerde büyür.
func _paint_forest(g: GlowLayer, now: float) -> void:
	match type:
		"diken_tazisi":
			g.glow(_eye, 6.0, Color(THORN_GLOW, 0.45))
			g.glow(_eye, 2.2, Color(0.95, 0.8, 1.0, 0.8))
			if dive_state == "tell":
				var k := 1.0 - float(dive_t) / DIVE_TELL
				# Sırt dikenleri kabarıp mor parlar; atılacağı çizgi soluk noktalarla belirir.
				for j in 5:
					var u := float(j) / 4.0
					g.glow(_hand + Vector2(lerpf(-1.0, 1.0, u) * size * 0.45 * (-1.0 if facing_left else 1.0), -sin(u * PI) * 6.0), 7.0 + 6.0 * k, Color(THORN_GLOW, 0.3 + 0.45 * k))
				for j in 8:
					var u := float(j + 1) / 8
					if u > 0.3 + 0.7 * k:
						break
					g.glow(Vector2(0, size * 0.7) + dive_dir * HOUND_DASH * HOUND_SPEED * u, 3.5, Color(THORN_GLOW, 0.2 + 0.4 * k))
			elif dive_state == "dash":
				g.glow(_hand, 20.0, Color(THORN_GLOW, 0.35))
		"spor_mantari":
			var k := 0.0 if puff == 0 else 1.0 - float(puff) / PUFF_TELL
			var pk := 0.5 + 0.5 * sin(now * 2.0 + zig)
			for j in 6:
				var o := Vector2(cos(zig + j * 1.3) * size * 0.4, sin(zig * 2.0 + j) * size * 0.12)
				g.glow(_eye + o, 4.0 + 5.0 * k, Color(THORN_GLOW, 0.25 + 0.15 * pk + 0.5 * k))
			if puff > 0:
				g.glow(_eye, size * (0.6 + 0.5 * k), Color(THORN_GLOW, 0.12 + 0.25 * k))
		"kok_muhafizi":
			var pk := 0.5 + 0.5 * sin(now * 1.5 + zig)
			g.glow(_eye, size * 0.45, Color(THORN_GLOW, 0.08 + 0.06 * pk))
			if root_cast > 0:
				var k := 1.0 - float(root_cast) / ROOT_CAST
				g.glow(_hand, 10.0 + 14.0 * k, Color(THORN_GLOW, 0.3 + 0.5 * k))
			if anchored:
				g.draw_set_transform(Vector2(0, size * 0.7), 0, Vector2(1, 0.42))
				g.glow(Vector2.ZERO, size * 1.1, Color(0.55, 0.9, 0.35, 0.12 + 0.08 * pk))
				g.draw_set_transform(Vector2.ZERO)
		"diken_rahibesi":
			var cast := attack_anim > 0 or (attack_cd < 16 and attack_cd > 0)
			g.glow(_hand, 8.0 if not cast else 18.0, Color(THORN_GLOW, 0.3 if not cast else 0.7))
	if vine_shield:
		g.glow(Vector2(0, -size * 0.6), size * 0.9, Color(THORN_GLOW, 0.12))


## Bölge 7 parıltıları: yürüyücünün mor alevi, yazıcının kan mührü, gargoylün göz alevleri.
func _paint_castle(g: GlowLayer, now: float) -> void:
	match type:
		"golge_yuruyucu":
			var a := 1.0 if step == 0 else float(step) / STEP_TELL
			for j in 4:
				var q := fmod(now * 1.2 + j * 0.25 + zig, 1.0)
				g.glow(Vector2(sin(j * 2.1 + now) * size * 0.25, -size * (0.3 + 0.9 * q)), 9.0 * (1.0 - q * 0.5), Color(VOID_GLOW, 0.35 * a * (1.0 - q)))
		"kan_yazicisi":
			if scribe > 0:
				var k := 1.0 - float(scribe) / SCRIBE_TELL
				var c := _hand + Vector2(-14.0 if facing_left else 14.0, -10)
				g.draw_set_transform(c, now * 4.0, Vector2.ONE)
				g.ring(Vector2.ZERO, 6.0 + 12.0 * k, 1.6, Color(BLOOD_GLOW, 0.4 + 0.5 * k))
				for j in 5:
					g.glow(Vector2.from_angle(j * TAU / 5.0) * (6.0 + 12.0 * k), 3.0, Color(1.0, 0.5, 0.4, 0.5 + 0.4 * k))
				g.draw_set_transform(Vector2.ZERO)
				g.glow(c, 18.0 * k + 4.0, Color(BLOOD_GLOW, 0.25 * k))
			else:
				g.glow(_hand, 5.0, Color(BLOOD_GLOW, 0.35))
		"gargoyl":
			var on := 0.15 if stone and wake == 0 else (1.0 if not stone else 1.0 - float(wake) / WAKE_TELL)
			if restone > 0:
				on = 0.2
			g.glow(_eye, 7.0 + 6.0 * on, Color(VOID_GLOW, 0.2 + 0.5 * on))
			g.glow(_eye, 2.5, Color(0.95, 0.85, 1.0, 0.3 + 0.6 * on))


## Bölge 8 parıltıları: altın kristal gözler; bilgenin asa ucu, bekçinin topuzu, muhafızın rüzgâr konisi.
func _paint_sky(g: GlowLayer, now: float) -> void:
	var ga := 0.25 if decoy else 1.0
	g.glow(_eye, 6.0, Color(GOLD_GLOW, 0.5 * ga))
	g.glow(_eye, 2.2, Color(1.0, 0.97, 0.85, 0.8 * ga))
	match type:
		"konsey_bilgesi":
			var k := 0.0 if sage_cast == 0 else 1.0 - float(sage_cast) / SAGE_CAST
			g.glow(_hand, 8.0 + 16.0 * k, Color(GOLD_GLOW, (0.3 + 0.5 * k) * ga))
		"run_bekcisi":
			if gcast > 0:
				var k := 1.0 - float(gcast) / GRAV_CAST
				g.glow(_hand, 10.0 + 14.0 * k, Color(GOLD_GLOW, 0.3 + 0.5 * k))
		"gok_muhafizi":
			if gust > 0:
				var k := 1.0 - float(gust) / GUST_TELL
				var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
				var o := Vector2(0, size * 0.4)
				var a0 := gust_dir.angle()
				var edge := Color(0.9, 0.95, 1.0, (0.25 + 0.5 * k) * blink)
				g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 - GUST_HALF) * GUST_LEN]), 1.2, edge)
				g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 + GUST_HALF) * GUST_LEN]), 1.2, edge)
				var arc := PackedVector2Array()
				for i in 13:
					arc.append(o + Vector2.from_angle(a0 - GUST_HALF + GUST_HALF * 2.0 * i / 12.0) * GUST_LEN)
				g.streak(arc, 1.4, edge)
				for j in 6:
					var q := fmod(now * 1.8 + j / 6.0, 1.0)
					g.glow(o + Vector2.from_angle(a0 + sin(j * 1.7) * GUST_HALF * 0.8) * GUST_LEN * q, 5.0, Color(0.95, 0.97, 1.0, 0.35 * k * (1.0 - q)))


## Bölge 10 parıltıları: klonların boş parlayan gözleri, kılıcın tell'i, büyücünün asası, devin kabuğu.
func _paint_clone(g: GlowLayer, now: float) -> void:
	g.glow(_eye, 6.0, Color(RUNE_GLOW, 0.55))
	g.glow(_eye, 2.2, Color(0.95, 0.85, 1.0, 0.85))
	match type:
		"run_klon_kilic":
			if dive_state == "tell":
				var k := 1.0 - float(dive_t) / (DIVE_TELL + 4)
				g.glow(_hand, 10.0 + 14.0 * k, Color(RUNE_GLOW, 0.35 + 0.5 * k))
				for j in 8:
					var u := float(j + 1) / 8
					if u > 0.3 + 0.7 * k:
						break
					g.glow(Vector2(0, size * 0.7) + dive_dir * HOUND_DASH * HOUND_SPEED * u, 3.5, Color(RUNE_GLOW, 0.2 + 0.4 * k))
		"run_klon_buyucu":
			var cast := attack_anim > 0 or (attack_cd < 20 and attack_cd > 0)
			g.glow(_hand, 8.0 if not cast else 20.0, Color(1.0, 0.5, 0.25, 0.35 if not cast else 0.7))
		"run_klon_dev":
			if cshell > 0:
				g.glow(Vector2(0, -size * 0.7), size * 1.0, Color(RUNE_GLOW, 0.22 + 0.08 * sin(now * 6.0)))
			if slab > 0:
				var k := 1.0 - float(slab) / SLAB_TELL
				g.glow(_hand, 12.0 + 16.0 * k, Color(RUNE_GLOW, 0.3 + 0.5 * k))


## Bölge 9 parıltıları: taşın çekirdeği (tell'de hızlanan halka), gözün bebeği, yiyicinin zemin altındaki izi.
func _paint_rift(g: GlowLayer, now: float) -> void:
	match type:
		"yorunge_tasi":
			var k := 0.0 if ring_t == 0 else 1.0 - float(ring_t) / RING_TELL
			g.glow(_eye, 14.0 + 16.0 * k, Color(0.7, 0.4, 1.0, 0.35 + 0.4 * k))
			if ring_t > 0:
				for j in 8:
					var a := now * (3.0 + 12.0 * k) + j * TAU / 8.0
					g.glow(_eye + Vector2(cos(a), sin(a) * 0.6) * size * 0.9, 4.0, Color(RIFT_CYAN, 0.4 + 0.5 * k))
		"yokluk_gozu":
			g.glow(_eye, 6.0 + (8.0 if gaze_t > 0 else 0.0), Color(RIFT_CYAN, 0.6))
			g.glow(_eye, 2.5, Color(0.9, 1.0, 1.0, 0.9))
		"bosluk_yiyici":
			if burrow == "under":
				# Zemin altında ilerleyen camgöbeği yırtık izi.
				g.draw_set_transform(Vector2(0, 8), 0, Vector2(1, 0.42))
				g.glow(Vector2.ZERO, 26.0, Color(RIFT_CYAN, 0.45))
				g.ring(Vector2.ZERO, 18.0 + 4.0 * sin(now * 10.0), 1.4, Color(RIFT_CYAN, 0.7))
				g.draw_set_transform(Vector2.ZERO)
			elif burrow != "sink" and burrow != "rise":
				g.glow(_eye, 5.0, Color(RIFT_CYAN, 0.5))


## Buz düşmanlarının soluk mavi göz parıltısı.
func _paint_ice_eyes(g: GlowLayer, alpha: float) -> void:
	var side := Vector2(-3.0 if facing_left else 3.0, 0)
	g.glow(_eye, 7.0, Color(ICE_GLOW, alpha * 0.6))
	g.glow(_eye + side, 2.5, Color(0.9, 0.97, 1.0, alpha + 0.3))


## Ayna kabuk: açılmadan hemen önce ve açıkken sırt kabuğunun üstünde beyaz yansıma çizgisi gezinir;
## kırıkken soluk çatlak parıltısı.
func _paint_shell(g: GlowLayer, now: float) -> void:
	var back := _eye
	var w := maxf(_hand.x, 12.0)
	if shell_broken > 0:
		g.glow(back, w * 0.7, Color(0.6, 0.75, 0.9, 0.08))
		return
	var on := mirror >= MIRROR_OFF
	var pre := not on and mirror >= MIRROR_OFF - MIRROR_GLINT
	if not (on or pre):
		return
	var k := 1.0 if on else float(mirror - (MIRROR_OFF - MIRROR_GLINT)) / MIRROR_GLINT
	var fade := 1.0
	if on:
		fade = clampf(float(MIRROR_OFF + MIRROR_ON - mirror) / 12.0, 0.0, 1.0)
	g.glow(back, w * (0.8 + 0.2 * k), Color(0.75, 0.92, 1.0, (0.12 + 0.22 * k) * fade))
	# Gezinen yansıma: kabuğun bir ucundan öbürüne kayan eğik beyaz çizgi.
	var u := fmod(now * (1.6 if on else 2.4), 1.0)
	var x := lerpf(-w, w, u)
	var a := back + Vector2(x - 6.0, -w * 0.35)
	var b := back + Vector2(x + 6.0, w * 0.35)
	g.streak(PackedVector2Array([a, b]), 1.6, Color(1, 1, 1, (0.45 + 0.4 * k) * fade))
	g.glow(back + Vector2(x, 0), 6.0, Color(1, 1, 1, 0.5 * k * fade))


## Yere vuruş çatlakları: vuruş yönüne açılan dallı lav çizgileri, k ile uzar (kölebaşı ve lav golemi).
func _paint_cracks(g: GlowLayer, k: float, ahead: float, reach: float) -> void:
	var o := Vector2(0, size * 0.62) + slam_dir * ahead
	var rng := RandomNumberGenerator.new()
	for i in 6:
		rng.seed = get_instance_id() + i * 31
		var ang := slam_dir.angle() + (i - 2.5) * 0.55 + rng.randf_range(-0.2, 0.2)
		var pts := PackedVector2Array([o])
		var steps := 4
		for j in steps:
			var r := reach * k * float(j + 1) / steps
			pts.append(o + Vector2.from_angle(ang + rng.randf_range(-0.3, 0.3)) * Vector2(r, r * 0.42))
		# Yumuşak haleli kor çizgisi; uçta parlak nokta (sert sarı zikzak değil).
		g.streak(pts, 1.8, Color(1.0, 0.5, 0.15, 0.4 + 0.35 * k))
		g.draw_polyline(pts, Color(1.0, 0.9, 0.6, 0.45 * k), 0.7, true)
		g.glow(pts[pts.size() - 1], 6.0 + 6.0 * k, Color(1.0, 0.6, 0.2, 0.4 * k))
	g.glow(o, 20.0 + 30.0 * k, Color(1.0, 0.5, 0.15, 0.25 * k))


func _draw_shadow(at: Vector2, r: float) -> void:
	draw_set_transform(at, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
