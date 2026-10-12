class_name Boss
extends Actor
## Bölge muhafızı (entities.js:4497-5076). Kovalar, temasla vurur, genişleyen bir şok halkası atar.
## %75 / %50 / %25 canda faz atlar: güçlenir, hızlanır ve yardımcı çağırır.
## Bölge 4 muhafızı IGNIS kendi saldırılarıyla oynar (aşağıda "IGNIS" bölümü): balta savuruşu + lav yarığı,
## infaz zinciri; %50'de Hüküm (2 Kül Rahibi, mangallar alevlenir), %20'de Son İnfaz (beyaz-sarı balta).
## Bölge 5 muhafızı KRAL ALDEN de kendi saldırılarıyla oynar (aşağıda "KRAL ALDEN" bölümü): tahta zincirli buz
## dikeni hattı ve donduran nefes; %50'de kar fırtınası (kandiller, düşen sarkıtlar), %20'de tahttan iner, buz hapsi.
## Bölge 6 muhafızı LYRA da kendi saldırılarıyla oynar ("LYRA" bölümü): Hayat Ağacı'na bağlı diken yağmuru ve kök hattı;
## %50'de Ağlayan Ağaç (sürüklenen spor bulutları, Kutsal Taşlar), %20'de ağaçtan kopar, diken çemberi.
## Bölge 7 muhafızı MALAKOR ("MALAKOR" bölümü): çekiç darbesi ve portal ışınları; %50'de kan paktı (Kan Mühürleri
## kırılana dek hasar kalkanı) ve gölge dalışı; %20'de portal çöker, yokluk çekimi ve alev halkası.
## Bölge 8 muhafızı VALERİUS ("VALERİUS" bölümü): dönen ışık kılıcı ve hüküm sütunları; %50'de Kör Adalet (oyuncuyu
## sesinden bulur, atışın geldiği yere atılır); %20'de Hatırlayış (duraksama anları) ve son hüküm (dönen ışık hatları).

const PHASE_COLORS := [Color("ff3b30"), Color("ff8c00"), Color("b026ff"), Color("ff2d78")]
const AURA_COLORS := [Color("4466ff"), Color("aa33ff"), Color("ff4422"), Color("ff0000")]

var zone := 1
var display_name := ""
var sprite_key := "boss_z1"
var is_karun := false
var max_hp := 500
var hp := 500
var base_atk := 20
var atk := 20
var base_speed := 0.75
var speed := 0.75
var phase := 1
var slam_cd_max := 180
var slam_cd := 120
var slam_r := -1.0
var slam_hit := false
var second_slam := -1
var melee_cd := 120
var lunge := 0
var flash := 0
var facing_left := false
var anim_timer := 0
var frame := 1
var box := Vector2(96, 96)
## Bölge renginde arka ışık: koyu boss koyu zeminde kaybolmasın (silüet halesi + yumuşak ışık).
var zone_color := Color.WHITE
## Silüet halesinin gücü (Lyra'da yumuşak: koyu yosunlu zeminde parlak hale sert duruyordu).
var rim_k := 1.0
var _rim: Rim
var _last_key := ""
var _last_box := Rect2()
const RIM_SHADER := preload("res://scripts/world/rim.gdshader")

# ── IGNIS ──
## Kareler 640x440 tuvalde, çizme ortası (320, 384) — konsept/oyun/bolge4/ignis/kur_ignis.py.
const IG_CANVAS := Vector2(640, 440)
const IG_ANCHOR := Vector2(320, 384)
const IG_SCALE := 0.4            # dünya pikseli / doku pikseli: boyu okçunun ~2.3 katı
const IG_FEET := 30.0            # ayakların düğüme göre yüksekliği
const IG_HAND := Vector2(456, 162)   # zincir karesinde yumruk
const IG_FIRE := Color(1.0, 0.42, 0.1)
const IG_WHITE := Color(1.0, 0.9, 0.55)
const AXE_TELL := 60
const AXE_HIT := 30
const AXE_LEN := 200.0
const AXE_HALF := 0.38
const CRACK_LEN := 250.0
const IG_CHAIN_TELL := 48
const IG_CHAIN_THROW := 14
const IG_CHAIN_RANGE := 330.0
const IG_CHAIN_PULL := 70

var is_ignis := false
var ig_state := ""
var ig_t := 0
var axe_cd := 100
var ig_chain_cd := 220
var axe_dir := Vector2.RIGHT
var ig_chain_dir := Vector2.RIGHT
var ig_chain_len := 0.0
var ig_chain_target := Vector2.ZERO
var _priests: Array = []
var _ig_ground: GlowLayer
var _ig_front: GlowLayer
var _ig_flip := false
var _ig_hand := Vector2.ZERO

# ── KRAL ALDEN ──
## Kareler 420x470 tuvalde; tahtın (ayakta: çizmelerin) taban ortası (210, 456).
const AL_CANVAS := Vector2(420, 470)
const AL_ANCHOR := Vector2(210, 456)
const AL_SCALE := 0.44
const AL_MOUTH := Vector2(228, 182)
const AL_CHEST := Vector2(231, 240)
const AL_ICE := Color(0.55, 0.85, 1.0)
const AL_WHITE := Color(0.9, 0.97, 1.0)
const AL_SEAL := Color(0.72, 0.3, 1.0)
const SPIKE_POSE := 76          # dikenin tell'i (60) + fışkırma boyunca kılıç yerde
const BREATH_TELL := 60
const BREATH := 40
const BREATH_LEN := 230.0
const BREATH_HALF := 0.42
const PRISON_CAST := 30
const STORM_EVERY := 150
## Zincir menzili: faz 1'de tahtın dibi, faz 2'de bir zincir kopar ve menzil genişler.
const AL_REACH := [80.0, 120.0, 60.0]

var is_alden := false
var al_state := ""
var al_t := 0
var spike_cd := 90
var breath_cd := 200
var prison_cd := 120
var icicle_cd := 80
var storm_t := 0
var breath_dir := Vector2.RIGHT
var breath_hit := false
var throne_pos := Vector2.ZERO
var _al_flip := false
var _al_ground: GlowLayer
var _al_front: GlowLayer
var _storm: CanvasLayer
var _storm_rect: TextureRect

# ── LYRA ──
## Kareler 420x470 tuvalde; ağacın kök tabanının (ayakta: ayakların) ortası (210, 462). Yön ve taht yeri Alden'la ortak.
const LY_CANVAS := Vector2(420, 470)
const LY_ANCHOR := Vector2(210, 462)
const LY_SCALE := 0.5
const LY_PURPLE := Color(0.72, 0.32, 1.0)
const LY_REACH := 84.0
var is_lyra := false
var ly_state := ""
var ly_t := 0
var rain_cd := 80
var lroot_cd := 160
var ring_cd := 9999
var weep_t := 0
var _ly_ground: GlowLayer
var _ly_front: GlowLayer

# ── MALAKOR ──
const MK_CANVAS := Vector2(420, 470)
const MK_ANCHOR := Vector2(210, 462)
const MK_SCALE := 0.52
const MK_VOID := Color(0.62, 0.28, 1.0)
const MK_BLOOD := Color(1.0, 0.2, 0.18)
const MK_CONE := 190.0
const MK_HALF := 0.55
const MK_HOVER := 30
var is_malakor := false
var mk_state := ""
var mk_t := 0
var mk_dir := Vector2.RIGHT
var mk_target := Vector2.ZERO
var hammer_cd := 90
var beam_cd := 160
var dive_cd2 := 9999
var pull_cd := 9999
var _portal_sprite: Sprite2D

# ── VALERİUS ──
const VL_CANVAS := Vector2(420, 470)
const VL_ANCHOR := Vector2(210, 462)
const VL_SCALE := 0.5
const VL_GOLD := Color(1.0, 0.82, 0.35)
const VL_LISTEN := 30
const VL_DASH := 18
const VL_DASH_SPEED := 9.0
var is_valerius := false
var vl_state := ""
var vl_t := 0
var vl_dir := Vector2.RIGHT
var vl_target := Vector2.ZERO
var vl_hit := false
## Kör atılmanın süresi (kare): sesin geldiği yere kadar (en çok ~380 px).
var vl_dash_t := 18
var throw_cd := 90
var judge_cd := 160
var hesitate_cd := 9999
var sweep_cd := 9999
var noise_seen := 0
var wander := Vector2.ZERO
var wander_t := 0
var _vl_ground: GlowLayer
var _vl_front: GlowLayer

# ── BOŞLUK (iç ad: nihil) ──
const NH_CANVAS := Vector2(420, 470)
const NH_SCALE := 0.58
const NH_FLOAT := 120.0
const NH_VOID := Color(0.6, 0.3, 1.0)
const NH_CYAN := Color(0.45, 0.95, 1.0)
const NH_SAFE_MAX := 420.0
const NH_SAFE_MIN := 170.0
var is_nihil := false
var nh_state := ""
var nh_t := 0
var nh_gaze_cd := 90
var nh_storm_cd := 200
var nh_bind_cd := 9999
var nh_tear_cd := 9999
var nh_center := Vector2.ZERO
var nh_safe := NH_SAFE_MAX
var nh_out_t := 0
var _nh_ground: GlowLayer
var _nh_front: GlowLayer

# ── BÖLGE 1–3 MUHAFIZLARI ──
const MB_CANVAS := Vector2(420, 470)
const MB_ANCHOR := Vector2(210, 462)
const KD_BLUE := Color(0.5, 0.7, 1.0)
const DK_VIOLET := Color(0.7, 0.4, 1.0)
const KD_CONE := 190.0
const KD_HALF := 0.85
const KD_LEAP := 46
const KL_CHAIN := 300.0
var is_kardes := false
var is_dokuyucu := false
var is_kole := false
var mb_scale := 0.5
var mb_state := ""
var mb_t := 0
var mb_cds := {"sweep": 60, "leap": 150, "howl": 9999, "weave": 80, "split": 9999, "pool": 9999, "chain": 120, "slam": 60}
var mb_dir := Vector2.RIGHT
var mb_from := Vector2.ZERO
var mb_to := Vector2.ZERO
var mb_split := 0
var mb_copies: Array = []
var mb_pull := 0
var mb_double := false
var _mb_ground: GlowLayer
var _mb_front: GlowLayer

# ── GÖK BÖRÜ ve KÂRUN (kat 100) ──
const GB_CANVAS := Vector2(420, 470)
const GB_ANCHOR := Vector2(210, 462)
const GB_SCALE := 0.62
const GB_PURPLE := Color(0.72, 0.32, 1.0)
const KR_CANVAS := Vector2(420, 470)
const KR_ANCHOR := Vector2(210, 462)
const KR_SCALE := 0.5
const KR_PURPLE := Color(0.72, 0.32, 1.0)
var is_gokboru := false
var is_karun_final := false
var gb_state := ""
var gb_t := 0
var gb_dir := Vector2.RIGHT
var gb_hit := false
var gb_howl_cd := 120
var gb_lunge_cd := 60
var gb_breath_cd := 160
var gb_rage_cd := 9999
var kr_state := ""
var kr_t := 0
var kr_chain_cd := 90
var kr_orb_cd := 160
var kr_echo_cd := 9999
var kr_heart_cd := 9999
var kr_echo_i := 0
var _fn_ground: GlowLayer
var _fn_front: GlowLayer
var _mk_ground: GlowLayer
var _mk_front: GlowLayer


## Boss'un arkasında çizilen silüet: dokunun biraz büyütülmüş, bölge renginde düz kopyası.
class Rim extends Node2D:
	var boss: Boss

	func _draw() -> void:
		boss.draw_rim(self)


func setup(floor_number: int, karun := false) -> void:
	zone = EnemyData.zone_of(floor_number)
	var m := EnemyData.boss_scale(floor_number)
	max_hp = int(500 * m)
	base_atk = int(20 * m)
	is_karun = karun
	if karun:
		display_name = EnemyData.KARUN_NAME
		is_karun_final = Sprites.tex("boss_karun_kneel") != null
		sprite_key = "boss_karun"
		max_hp = int(max_hp * 1.4)
		base_atk = int(base_atk * 1.5)
		base_speed = 0.85
		box = Vector2(92, 140)
	else:
		display_name = EnemyData.BOSS_NAMES[zone - 1]
		sprite_key = "boss_z%d" % zone
		is_ignis = zone == 4 and Sprites.tex("boss_z4_raise") != null
		if is_ignis:
			base_speed = 0.7
			box = Vector2(110, 150)
		is_alden = zone == 5 and Sprites.tex("boss_z5_throne") != null
		is_lyra = zone == 6 and Sprites.tex("boss_z6_tree") != null
		is_malakor = zone == 7 and Sprites.tex("boss_z7_portal") != null
		is_valerius = zone == 8 and Sprites.tex("boss_z8_peace") != null
		is_nihil = zone == 9 and Sprites.tex("boss_z9_singular") != null
		is_kardes = zone == 1 and Sprites.tex("boss_z1_peace") != null
		is_dokuyucu = zone == 2 and Sprites.tex("boss_z2_peace") != null
		is_kole = zone == 3 and Sprites.tex("boss_z3_defeated") != null
		if is_kardes:
			base_speed = 0.75
			mb_scale = 0.5
			box = Vector2(110, 170)
		if is_dokuyucu:
			base_speed = 0.45
			mb_scale = 0.48
			box = Vector2(110, 170)
		if is_kole:
			base_speed = 0.6
			mb_scale = 0.5
			box = Vector2(130, 170)
		is_gokboru = zone == 10 and Sprites.tex("boss_z10_peace") != null
		if is_gokboru:
			base_speed = 0.8
			box = Vector2(170, 160)
		if is_nihil:
			base_speed = 0.0
			box = Vector2(150, 150)
		if is_valerius:
			base_speed = 0.6
			box = Vector2(110, 180)
		if is_malakor:
			base_speed = 0.55
			box = Vector2(130, 190)
		if is_lyra:
			base_speed = 0.0
			box = Vector2(130, 180)
		if is_alden:
			base_speed = 0.0
			box = Vector2(120, 170)
	hp = max_hp
	atk = base_atk
	speed = base_speed
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	zone_color = Portal.ZONE_COLORS[zone - 1]
	if is_gokboru:
		zone_color = Color(0.55, 0.7, 1.0)
		rim_k = 0.4
	if is_karun_final:
		zone_color = Color(0.7, 0.4, 1.0)
		rim_k = 0.45
	if is_nihil:
		zone_color = Color(0.5, 0.8, 1.0)
		rim_k = 0.35
	if is_valerius:
		zone_color = Color(1.0, 0.85, 0.5)
		rim_k = 0.45
	if is_malakor:
		zone_color = Color(0.6, 0.3, 0.8)
		rim_k = 0.5
	if is_lyra:
		# Yeşil bölge rengi yosunlu tapınakta sert bir hale yapıyordu: soluk mor-gri silüet.
		zone_color = Color(0.55, 0.45, 0.7)
		rim_k = 0.4
	_rim = Rim.new()
	_rim.boss = self
	_rim.show_behind_parent = true
	_rim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mat := ShaderMaterial.new()
	mat.shader = RIM_SHADER
	_rim.material = mat
	add_child(_rim)
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = 1.1 if not karun else 1.3
	l.color = zone_color
	# IGNIS kendi koru ile parlıyor; güçlü bölge ışığı zırhını kızıla boğmasın.
	l.energy = 0.9 if not is_ignis else 0.45
	if is_alden:
		l.color = AL_ICE
		l.energy = 0.6
	if is_lyra:
		l.color = LY_PURPLE
		l.energy = 0.28
	if is_gokboru:
		l.color = Color(0.6, 0.75, 1.0)
		l.energy = 0.5
	if is_karun_final:
		l.color = KR_PURPLE.lerp(Color.WHITE, 0.3)
		l.energy = 0.45
	if is_nihil:
		l.color = NH_CYAN.lerp(NH_VOID, 0.5)
		l.energy = 0.6
		l.position = Vector2(0, -NH_FLOAT)
	if is_valerius:
		l.color = VL_GOLD.lerp(Color.WHITE, 0.4)
		l.energy = 0.4
	if is_malakor:
		l.color = MK_VOID.lerp(Color.WHITE, 0.3)
		l.energy = 0.45
	l.position = Vector2(0, -box.y * 0.45)
	add_child(l)
	if is_ignis:
		# Yer tell'leri (koni, çizgi) gövdenin arkasında; zincir / el parıltısı önde. İkisi de toplamalı.
		_ig_ground = GlowLayer.make(_paint_ignis_ground, true)
		add_child(_ig_ground)
		_ig_front = GlowLayer.make(_paint_ignis_front)
		add_child(_ig_front)
	if is_kardes or is_dokuyucu or is_kole:
		_mb_ground = GlowLayer.make(_paint_early_ground, true)
		add_child(_mb_ground)
		_mb_front = GlowLayer.make(_paint_early_front)
		add_child(_mb_front)
		rim_k = 0.45
	if is_gokboru:
		_fn_ground = GlowLayer.make(_paint_gokboru_ground, true)
		add_child(_fn_ground)
		_fn_front = GlowLayer.make(_paint_gokboru_front)
		add_child(_fn_front)
	if is_karun_final:
		_fn_ground = GlowLayer.make(_paint_karun_ground, true)
		add_child(_fn_ground)
		_fn_front = GlowLayer.make(_paint_karun_front)
		add_child(_fn_front)
	if is_nihil:
		_nh_ground = GlowLayer.make(_paint_nihil_ground, true)
		add_child(_nh_ground)
		_nh_front = GlowLayer.make(_paint_nihil_front)
		add_child(_nh_front)
	if is_valerius:
		_vl_ground = GlowLayer.make(_paint_valerius_ground, true)
		add_child(_vl_ground)
		_vl_front = GlowLayer.make(_paint_valerius_front)
		add_child(_vl_front)
	if is_malakor:
		_mk_ground = GlowLayer.make(_paint_malakor_ground, true)
		add_child(_mk_ground)
		_mk_front = GlowLayer.make(_paint_malakor_front)
		add_child(_mk_front)
	if is_lyra:
		_ly_ground = GlowLayer.make(_paint_lyra_ground, true)
		add_child(_ly_ground)
		_ly_front = GlowLayer.make(_paint_lyra_front)
		add_child(_ly_front)
	if is_alden:
		_al_ground = GlowLayer.make(_paint_alden_ground, true)
		add_child(_al_ground)
		_al_front = GlowLayer.make(_paint_alden_front)
		add_child(_al_front)


## Hedef alınamaz mı (Malakor'un gölge dalışında havada)?
func untargetable() -> bool:
	return (is_malakor and untargetable_malakor()) or (is_dokuyucu and mb_state == "pool")


func tick() -> void:
	if is_ignis:
		_ignis_tick()
		return
	if is_alden:
		_alden_tick()
		return
	if is_lyra:
		_lyra_tick()
		return
	if is_malakor:
		_malakor_tick()
		return
	if is_valerius:
		_valerius_tick()
		return
	if is_nihil:
		_nihil_tick()
		return
	if is_kardes or is_dokuyucu or is_kole:
		_early_tick()
		return
	if is_gokboru:
		_gokboru_tick()
		return
	if is_karun_final:
		_karun_tick()
		return
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	var to := p.position - position
	var d := to.length()
	if d > 30.0 and p.alive():
		var v := to / d * speed
		var np := main.world.move_circle(position, v, 20.0)
		if np == position:
			np = main.world.move_point(position, v)
		position = np
		facing_left = v.x < 0
	if melee_cd > 0:
		melee_cd -= 1
	elif d < 40.0:
		melee_cd = 90
		lunge = 12
		p.take_damage(atk, self)
	if slam_cd > 0:
		slam_cd -= 1
	elif d < 160.0 and slam_r < 0:
		_start_slam()
	if slam_r >= 0:
		slam_r += 7.0
		if not slam_hit and not p.is_invincible():
			var pd := position.distance_to(p.position)
			if pd > slam_r - 18.0 and pd < slam_r:
				slam_hit = true
				p.take_damage(10 + (phase - 1) * 6, self)
				var push := (p.position - position).normalized() * 18.0
				p.position = main.world.move_circle(p.position, push, 16.0)
		if slam_r >= 150.0:
			slam_r = -1.0
	if second_slam > 0:
		second_slam -= 1
		if second_slam == 0 and slam_r < 0:
			_start_slam()
	anim_timer += 1
	if anim_timer >= 18:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


func _start_slam() -> void:
	slam_r = 10.0
	slam_hit = false
	slam_cd = slam_cd_max
	main.shake(10)
	if phase == 4 and second_slam <= 0:
		second_slam = 24


func take_damage(amount: int, _knock_dir := Vector2.ZERO, _knock_mult := 1.0) -> bool:
	if removed:
		return false
	if is_ignis and _priests_alive():
		# Hüküm: rahipler yaşadıkça zırh soğuk kalır, hasar yarıya iner.
		amount = maxi(1, amount / 2)
	if is_kardes and mb_state == "kneel":
		amount = int(amount * 1.5)
	if is_dokuyucu and mb_state == "pool":
		return false
	if is_nihil and nh_state == "bound":
		# Kârun'un zincirleri: savunmasız an.
		amount = int(amount * 1.5)
	if is_valerius and vl_state == "hesitate":
		# Hatırlayış: savunmasız an.
		amount = int(amount * 1.5)
	if is_malakor:
		if untargetable_malakor():
			return false
		# Kan paktı: sağlam mühür başına hasar azalır.
		amount = maxi(1, int(amount * mk_shield()))
	hp -= amount
	flash = 10
	main.float_text(position + Vector2(0, -box.y * 0.7), str(amount), Color("ffd700"))
	var ratio := float(hp) / max_hp
	if is_ignis:
		var ig_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		if hp > 0 and ig_phase > phase:
			_ignis_phase(ig_phase)
		if hp <= 0:
			main.on_boss_killed(self)
			return true
		return false
	if is_kardes or is_dokuyucu or is_kole:
		var e_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		while hp > 0 and e_phase > phase:
			_early_phase(phase + 1)
		if hp <= 0:
			_early_rest()
			main.on_boss_killed(self)
			return true
		return false
	if is_gokboru or is_karun_final:
		var f_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		while hp > 0 and f_phase > phase:
			if is_gokboru:
				_gokboru_phase(phase + 1)
			else:
				_karun_phase(phase + 1)
		if hp <= 0:
			if is_gokboru:
				_gokboru_rest()
			else:
				_karun_rest()
			main.on_boss_killed(self)
			return true
		return false
	if is_nihil:
		var nh_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		while hp > 0 and nh_phase > phase:
			_nihil_phase(phase + 1)
		if hp <= 0:
			main.float_text(position + Vector2(0, -220), "YIRTIK KAPANDI", NH_CYAN.lightened(0.3))
			_nihil_rest()
			main.on_boss_killed(self)
			return true
		return false
	if is_valerius:
		var vl_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		while hp > 0 and vl_phase > phase:
			_valerius_phase(phase + 1)
		if hp <= 0:
			main.float_text(position + Vector2(0, -200), "MASKE KIRILDI", VL_GOLD.lightened(0.3))
			_valerius_rest()
			main.on_boss_killed(self)
			return true
		return false
	if is_malakor:
		var mk_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		while hp > 0 and mk_phase > phase:
			_malakor_phase(phase + 1)
		if hp <= 0:
			main.float_text(position + Vector2(0, -200), "KOMUTAN DÜŞTÜ", MK_BLOOD.lightened(0.3))
			main.burst(position + Vector2(0, -60), 120, MK_VOID)
			_malakor_rest()
			main.on_boss_killed(self)
			return true
		return false
	if is_lyra:
		var ly_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		while hp > 0 and ly_phase > phase:
			_lyra_phase(phase + 1)
		if hp <= 0:
			if phase < 3:
				_leave_tree()
			main.float_text(position + Vector2(0, -190), "DİKENLER KURUDU", Color(1.0, 0.92, 0.66))
			main.burst(position + Vector2(0, -60), 120, LY_PURPLE)
			_lyra_rest()
			main.on_boss_killed(self)
			return true
		return false
	if is_alden:
		var al_phase := 3 if ratio <= 0.2 else (2 if ratio <= 0.5 else 1)
		while hp > 0 and al_phase > phase:
			_alden_phase(phase + 1)
		if hp <= 0:
			_end_storm()
			if phase < 3:
				_leave_throne()
			main.float_text(position + Vector2(0, -170), "LANET ÇÖZÜLDÜ", AL_WHITE)
			main.burst(position + Vector2(0, -60), 120, AL_WHITE)
			_rest_in_peace()
			main.on_boss_killed(self)
			return true
		return false
	var target_phase := 1
	if ratio <= 0.25:
		target_phase = 4
	elif ratio <= 0.5:
		target_phase = 3
	elif ratio <= 0.75:
		target_phase = 2
	if hp > 0 and target_phase > phase:
		_enter_phase(target_phase)
	if hp <= 0:
		main.on_boss_killed(self)
		return true
	return false


func _enter_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.25, 1.55, 2.0][n - 1])
	speed = base_speed + [0.0, 0.25, 0.55, 0.9][n - 1]
	slam_cd_max = [180, 144, 108, 72][n - 1]
	main.shake(16)
	Log.add("%s öfkeleniyor! (FAZ %d)" % [display_name.split(" — ")[0], n], "death")
	main.spawn_minions(self, [0, 0, 2, 3, 4][n])


func _draw() -> void:
	if is_ignis:
		_draw_ignis()
		return
	if is_alden:
		_draw_alden()
		return
	if is_lyra:
		_draw_lyra()
		return
	if is_malakor:
		_draw_malakor()
		return
	if is_valerius:
		_draw_valerius()
		return
	if is_nihil:
		_draw_nihil()
		return
	if is_kardes or is_dokuyucu or is_kole:
		_draw_early()
		return
	if is_gokboru:
		_draw_gokboru()
		return
	if is_karun_final:
		_draw_karun()
		return
	var draw_size := box * 1.8
	var t := Time.get_ticks_msec()
	var bob := sin(t / (950.0 if is_karun else 700.0)) * (1.2 if is_karun else 3.5)
	var breathe := 1.0 + sin(t / 300.0) * (0.008 if is_karun else 0.022)
	var sc := breathe
	if melee_cd < 90 * 0.28 and melee_cd > 0:
		sc += (0.08 if is_karun else 0.2) * (1.0 - melee_cd / (90 * 0.28))
	var key := "%s_idle%d" % [sprite_key, frame]
	var feet := draw_size.y / 2 - draw_size.y * (1.0 - Sprites.content_bottom(key))
	var aura: Color = AURA_COLORS[phase - 1]
	aura.a = 0.25 + 0.1 * sin(t / 200.0)
	# Doku kutuya oranı korunarak (yüksekliğe göre) oturur; görünen genişlik buna göre.
	var vis_w := Sprites.fit_box(key, Rect2(Vector2.ZERO, draw_size)).size.x
	var feet_x := Sprites.content_feet_x(key) * vis_w * (-1.0 if facing_left and not is_karun else 1.0)
	draw_set_transform(Vector2(feet_x, feet), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, vis_w * 0.32, aura)
	draw_set_transform(Vector2.ZERO)
	var off := Vector2.ZERO
	if lunge > 0:
		off = (main.player.position - position).normalized() * (lunge / 12.0) * 12.0
	var size := draw_size * sc
	var b := Sprites.fit_box(key, Rect2(Vector2(-size.x / 2, draw_size.y / 2 - size.y + bob) + off, size))
	var mod := Color(1.0 + phase * 0.12, 1.0 + phase * 0.12, 1.0 + phase * 0.12)
	if flash > 0:
		mod = Color(1.6, 0.6, 0.6)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, facing_left and not is_karun, false, false, mod)
	Sprites.draw_flat(self, "boss_crown", Rect2(-16, b.position.y + b.size.y * Sprites.content_top(key) - 30, 32, 32))
	if is_karun:
		draw_arc(Vector2(0, b.position.y + 30), 34, 0, TAU, 32, Color(0.7, 0.2, 1.0, 0.6), 3)
	if slam_r >= 0:
		draw_arc(Vector2.ZERO, slam_r, 0, TAU, 48, Color(1, 0.3, 0.2, 0.85), 5)
		draw_arc(Vector2.ZERO, maxf(1, slam_r - 18), 0, TAU, 48, Color(1, 0.6, 0.2, 0.35), 2)


## Rim düğümüne çizer: arkada yumuşak bölge renkli parıltı, üstüne 1-2 px taşan düz renk silüet.
func draw_rim(ci: CanvasItem) -> void:
	if _last_key == "":
		return
	var t := Time.get_ticks_msec()
	var pulse := 0.85 + 0.15 * sin(t / 420.0)
	var b := _last_box
	var glow := b.grow_individual(b.size.x * 0.05, -b.size.y * 0.05, b.size.x * 0.05, -b.size.y * 0.2)
	ci.draw_texture_rect(Atmosphere.soft_texture(), glow, false, Color(zone_color, 0.55 * pulse * rim_k))
	(ci.material as ShaderMaterial).set_shader_parameter("tint", Color(zone_color, 0.5 * pulse * rim_k))
	var flip := (facing_left and not is_karun) if not is_ignis else _ig_flip
	if is_alden or is_lyra or is_malakor or is_valerius or is_gokboru or is_karun_final or is_kardes or is_dokuyucu or is_kole:
		flip = _al_flip
	for o in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		Sprites.draw_actor(ci, _last_key, Rect2(b.position + o, b.size), flip, false, false)


# ── IGNIS — Alevin İnfazcısı (bölge 4) ───────────────────────────────

func _ig_feet() -> Vector2:
	return position + Vector2(0, IG_FEET)


## Dokudaki bir noktanın (tuval pikseli) düğüme göre yeri; sola bakarken aynalanır.
func _ig_local(px: Vector2) -> Vector2:
	var v := (px - IG_ANCHOR) * IG_SCALE
	return Vector2(-v.x if _ig_flip else v.x, IG_FEET + v.y)


func _priests_alive() -> bool:
	_priests = _priests.filter(func(e): return is_instance_valid(e) and not e.removed)
	return not _priests.is_empty()


func _ignis_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	if melee_cd > 0:
		melee_cd -= 1
	var to := p.position - position
	var d := to.length()
	match ig_state:
		"raise":
			# Balta başın üstünde: koni kızarır (tell), sonra savuruş.
			ig_t -= 1
			if ig_t <= 0:
				_axe_impact()
				ig_state = "swing"
				ig_t = AXE_HIT if phase < 3 else 20
		"swing":
			ig_t -= 1
			if ig_t <= 0:
				ig_state = ""
		"chain_tell":
			ig_t -= 1
			if ig_t <= 0:
				ig_state = "chain_throw"
				ig_t = IG_CHAIN_THROW
		"chain_throw":
			ig_t -= 1
			ig_chain_len = IG_CHAIN_RANGE * (1.0 - float(ig_t) / IG_CHAIN_THROW)
			if ig_t <= 0:
				var hand := position + _ig_local(IG_HAND)
				var rel := p.position - hand
				var along := rel.dot(ig_chain_dir)
				if p.alive() and along > 0.0 and along < IG_CHAIN_RANGE + 14.0 and absf(rel.cross(ig_chain_dir)) < 30.0:
					ig_state = "chain_pull"
					ig_t = IG_CHAIN_PULL
					ig_chain_target = _chain_target(p)
					main.float_text(p.position + Vector2(0, -60), "ZİNCİRLENDİN!", IG_FIRE.lightened(0.3))
					main.shake(7)
					main.burst(p.position + Vector2(0, -20), 36, IG_FIRE)
				else:
					ig_state = "chain_back"
					ig_t = IG_CHAIN_THROW
		"chain_pull":
			ig_t -= 1
			var hand := position + _ig_local(IG_HAND)
			var pull := ig_chain_target - p.position
			var pd := pull.length()
			if pd > 22.0:
				p.position = main.world.move_circle(p.position, pull / pd * minf(6.0, pd - 20.0), Player.RADIUS)
			ig_chain_dir = (p.position - hand).normalized()
			ig_chain_len = p.position.distance_to(hand)
			if pd <= 26.0 or ig_t <= 0:
				_chain_end(p)
		"chain_back":
			ig_t -= 1
			ig_chain_len = IG_CHAIN_RANGE * float(ig_t) / IG_CHAIN_THROW
			if ig_t <= 0:
				ig_state = ""
		_:
			if axe_cd > 0:
				axe_cd -= 1
			if ig_chain_cd > 0:
				ig_chain_cd -= 1
			# Ağır adımlarla yaklaşır.
			if d > 70.0 and p.alive():
				var v := to / d * speed
				var np := main.world.move_circle(position, v, 20.0)
				if np == position:
					np = main.world.move_point(position, v)
				position = np
			if absf(to.x) > 6.0:
				_ig_flip = to.x < 0
			if melee_cd == 0 and d < 46.0:
				melee_cd = 90
				lunge = 12
				p.take_damage(int(atk * 0.8), self)
			if p.alive():
				if axe_cd == 0 and d < 175.0:
					_start_axe(p)
				elif ig_chain_cd == 0 and d > 130.0 and d < IG_CHAIN_RANGE - 20.0:
					_start_chain(p)
	anim_timer += 1
	if anim_timer >= 26:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


func _start_axe(p: Player) -> void:
	ig_state = "raise"
	ig_t = AXE_TELL
	axe_cd = [150, 130, 100][phase - 1]
	axe_dir = (p.position + Vector2(0, 24) - _ig_feet()).normalized()
	_ig_flip = axe_dir.x < 0


func _start_chain(p: Player) -> void:
	ig_state = "chain_tell"
	ig_t = IG_CHAIN_TELL
	ig_chain_cd = [300, 260, 200][phase - 1]
	_ig_flip = p.position.x < position.x
	ig_chain_dir = (p.position - (position + _ig_local(IG_HAND))).normalized()
	ig_chain_len = 0.0


## Zincir oyuncuyu infaz kütüğüne çeker (arenada ve yakınsa), yoksa Ignis'in önüne.
func _chain_target(p: Player) -> Vector2:
	var blk: Vector2 = main.atmosphere.exec_block
	if blk != Vector2.INF and blk.distance_to(position) < 520.0:
		return blk + Vector2(26, 8)
	return position + (p.position - position).normalized() * 64.0


func _chain_end(p: Player) -> void:
	ig_state = "chain_back"
	ig_t = IG_CHAIN_THROW
	var blk: Vector2 = main.atmosphere.exec_block
	if blk != Vector2.INF and p.position.distance_to(blk) < 70.0:
		# Kütüğe yakalanan ağır hasar alır.
		p.take_damage(int(atk * 1.6), self)
		p.apply_debuff("burn")
		main.float_text(p.position + Vector2(0, -70), "İNFAZ!", IG_WHITE)
		main.burst(blk + Vector2(0, -24), 70, IG_FIRE)
		main.shake(12)
		main.hit_freeze(5)
	else:
		# Önüne çekildiyse balta hemen iner.
		axe_cd = mini(axe_cd, 10)


## Savuruş anı: ekran sarsılır, dünya bir an donar; konideki oyuncu yanar, önünde düz yer yarığı açılır.
func _axe_impact() -> void:
	var p := main.player
	var feet := _ig_feet()
	main.shake(16)
	main.hit_freeze(6)
	var rel := p.position + Vector2(0, 24) - feet
	if p.alive() and rel.length() < AXE_LEN + 10.0 and absf(angle_difference(axe_dir.angle(), rel.angle())) < AXE_HALF + 0.08:
		if p.take_damage(int(atk * 1.3), self):
			p.apply_debuff("burn")
	# Yarık duvara kadar uzanır.
	var start := feet + axe_dir * 26.0
	var length := 0.0
	while length < CRACK_LEN and main.world.is_walkable(start + axe_dir * (length + 10.0)):
		length += 10.0
	if length >= 30.0:
		var hz := FireHazard.new()
		hz.setup_crack(start, axe_dir, length, int(atk * 0.25), 300 if phase == 3 else FireHazard.CRACK_LIFE, phase == 3)
		main._spawn(hz, hz.position)
	if phase == 3:
		# Son İnfaz: savuruşun yayı boyunca yanan iz kalır.
		for a in [-0.5, -0.25, 0.0, 0.25, 0.5]:
			var tp := feet + axe_dir.rotated(a) * 74.0
			if main.world.is_walkable(tp):
				var tr := FireHazard.new()
				tr.setup("trail", tp, 18.0, int(atk * 0.2))
				main._spawn(tr, tr.position)


func _ignis_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.25, 1.5][n - 1])
	speed = base_speed + [0.0, 0.15, 0.35][n - 1]
	axe_cd = mini(axe_cd, 40)
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if n == 2:
		Log.add("%s hüküm veriyor! (FAZ 2)" % nm, "death")
		main.float_text(position + Vector2(0, -150), "HÜKÜM!", IG_FIRE.lightened(0.3))
		main.burst(position + Vector2(0, -40), 110, IG_FIRE)
		for side in [-1.0, 1.0]:
			var e: Enemy = null
			for tries in 6:
				var pos := position + Vector2(side * randf_range(110, 150), randf_range(-60, 60))
				e = main.spawn_enemy("kul_rahibi", pos)
				if e:
					break
			if e:
				e.is_minion = true
				_priests.append(e)
				main.burst(e.position, 46, IG_FIRE)
		for lp in main.atmosphere.ignite_braziers(position, 900.0):
			main.burst(lp + Vector2(0, 20), 40, IG_FIRE)
	else:
		Log.add("%s: SON İNFAZ! (FAZ 3)" % nm, "death")
		main.float_text(position + Vector2(0, -150), "SON İNFAZ!", IG_WHITE)
		main.burst(position + Vector2(0, -40), 130, IG_WHITE)
		main.hit_freeze(8)


func _ig_key() -> String:
	match ig_state:
		"raise": return "boss_z4_raise"
		"swing": return "boss_z4_swing"
		"chain_tell", "chain_throw", "chain_pull", "chain_back": return "boss_z4_chain"
	if phase >= 3:
		return "boss_z4_p3idle"
	return "boss_z4_idle%d" % frame


func _draw_ignis() -> void:
	var t := Time.get_ticks_msec()
	var feet := Vector2(0, IG_FEET)
	# Ayak altında yumuşak gölge.
	draw_set_transform(feet + Vector2(0, 2), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-78, -78, 156, 156), false, Color(0, 0, 0, 0.6))
	draw_set_transform(Vector2.ZERO)
	var key := _ig_key()
	var size := IG_CANVAS * IG_SCALE
	var bottom := IG_FEET + (IG_CANVAS.y - IG_ANCHOR.y) * IG_SCALE
	var off := Vector2.ZERO
	if lunge > 0:
		off = (main.player.position - position).normalized() * (lunge / 12.0) * 8.0
	if ig_state == "swing":
		var sk := clampf(float(ig_t - (AXE_HIT - 8)) / 8.0, 0.0, 1.0)
		off += axe_dir * 6.0 * sk
	var b := Rect2(Vector2(-size.x / 2, bottom - size.y) + off, size)
	var mod := Color.WHITE
	if ig_state == "raise":
		var k := 1.0 - float(ig_t) / AXE_TELL
		mod = Color(1.0 + 0.4 * k, 1.0 + 0.12 * k, 1.0)
	if _priests_alive():
		# Soğuk zırh: kor sönük, gri-mavi.
		mod = mod * Color(0.75, 0.8, 0.95)
	if flash > 0:
		mod = Color(1.6, 0.75, 0.6)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, _ig_flip, false, false, mod)
	var crown_y := bottom - size.y + size.y * Sprites.content_top("boss_z4_idle1")
	Sprites.draw_flat(self, "boss_crown", Rect2(-16, crown_y - 26 + sin(t / 500.0) * 2.0, 32, 32))
	if ig_state in ["chain_throw", "chain_pull", "chain_back"] and ig_chain_len > 4.0:
		var hand := _ig_local(IG_HAND)
		var tip := hand + ig_chain_dir * ig_chain_len
		Enemy.paint_chain(self, hand, tip - hand, _ig_chain_wave(), "_fire")


func _ig_chain_wave() -> float:
	if ig_state == "chain_throw":
		return 7.0
	if ig_state == "chain_back":
		return 12.0
	return 0.0


## Zemin tell'leri (toplamalı, gövdenin arkasında): balta konisi ve yarığın açılacağı çizgi, zincirin
## savrulacağı çizgi, ayak altındaki kor ışıması.
func _paint_ignis_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var feet := Vector2(0, IG_FEET)
	var hot := IG_WHITE if phase == 3 else IG_FIRE
	g.draw_set_transform(feet, 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 90.0, Color(hot, 0.16 + 0.04 * sin(now * 3.0)))
	g.draw_set_transform(Vector2.ZERO)
	if ig_state == "raise":
		var k := 1.0 - float(ig_t) / AXE_TELL
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
		var a0 := axe_dir.angle()
		var origin := feet + axe_dir * 14.0
		# Koni: yumuşak kırmızı dolgu (uçlara doğru söner) + içten dışa dolan daha parlak bant.
		_fan(g, origin, a0, AXE_HALF, AXE_LEN, Color(1.0, 0.1, 0.04, (0.16 + 0.22 * k) * blink), Color(1.0, 0.08, 0.03, 0.03))
		_fan(g, origin, a0, AXE_HALF * 0.85, AXE_LEN * k, Color(1.0, 0.25, 0.08, 0.22 * k), Color(1.0, 0.18, 0.05, 0.12 * k))
		var e0 := origin + Vector2.from_angle(a0 - AXE_HALF) * AXE_LEN
		var e1 := origin + Vector2.from_angle(a0 + AXE_HALF) * AXE_LEN
		var edge := Color(1.0, 0.22, 0.1, (0.35 + 0.5 * k) * blink)
		g.streak(PackedVector2Array([origin, e0]), 1.4, edge)
		g.streak(PackedVector2Array([origin, e1]), 1.4, edge)
		var arc := PackedVector2Array()
		for i in 17:
			arc.append(origin + Vector2.from_angle(a0 - AXE_HALF + AXE_HALF * 2.0 * i / 16.0) * AXE_LEN)
		g.streak(arc, 1.6, edge)
		# Yarığın açılacağı çizgi: soluk noktalar önden geriye dolar, sona doğru parlak çizgiye döner.
		var n := 18
		for j in n:
			var u := float(j + 1) / n
			if u > 0.25 + 0.75 * k:
				break
			g.glow(feet + axe_dir * (26.0 + CRACK_LEN * u), 4.0 + 3.0 * k, Color(1.0, 0.35, 0.1, 0.25 + 0.5 * k))
		if k > 0.7:
			g.streak(PackedVector2Array([feet + axe_dir * 26.0, feet + axe_dir * (26.0 + CRACK_LEN)]), 1.2, Color(1.0, 0.5, 0.2, (k - 0.7) * 2.2 * blink))
	elif ig_state == "chain_tell":
		# Zincirin savrulacağı çizgi: önden uca dolan parlak noktalar ve ince kor çizgi; uçta nabız gibi atan hedef.
		var k := 1.0 - float(ig_t) / IG_CHAIN_TELL
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 14.0 * k))
		var hand := _ig_local(IG_HAND)
		var reach := 0.3 + 0.7 * k
		var tip := hand + ig_chain_dir * IG_CHAIN_RANGE * reach
		g.streak(PackedVector2Array([hand, tip]), 1.6, Color(1.0, 0.55, 0.2, (0.25 + 0.45 * k) * blink))
		var dots := 16
		for j in dots:
			var u := float(j + 1) / dots
			if u > reach:
				break
			g.glow(hand + ig_chain_dir * IG_CHAIN_RANGE * u, 6.0, Color(1.0, 0.6, 0.2, (0.35 + 0.5 * k) * blink))
			g.glow(hand + ig_chain_dir * IG_CHAIN_RANGE * u, 2.5, Color(1.0, 0.92, 0.7, 0.8 * blink))
		var end := hand + ig_chain_dir * IG_CHAIN_RANGE
		g.draw_set_transform(end + Vector2(0, 30), 0, Vector2(1, 0.45))
		g.ring(Vector2.ZERO, 18.0 + 6.0 * (1.0 - k), 2.0, Color(1.0, 0.45, 0.12, (0.3 + 0.6 * k) * blink))
		g.draw_set_transform(Vector2.ZERO)


## Yumuşak dolgulu koni (köşe renkleri arası geçişli çokgen).
func _fan(g: GlowLayer, origin: Vector2, ang: float, half: float, r: float, c_in: Color, c_out: Color) -> void:
	if r < 4.0:
		return
	var pts := PackedVector2Array([origin])
	var cols := PackedColorArray([c_in])
	for i in 17:
		pts.append(origin + Vector2.from_angle(ang - half + half * 2.0 * i / 16.0) * r)
		cols.append(c_out)
	g.draw_polygon(pts, cols)


## Öndeki parıltılar (toplamalı): balta tell'inde baltanın ışıldaması, vuruş anının patlaması,
## zincir tell'inde elde dönen kor, zincirin akan parıltısı ve faz 3'ün beyaz-sarı baltası.
func _paint_ignis_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	match ig_state:
		"raise":
			var k := 1.0 - float(ig_t) / AXE_TELL
			var axe := _ig_local(Vector2(215, 80))
			g.glow(axe, 22.0 + 26.0 * k, Color(1.0, 0.4, 0.1, 0.25 + 0.45 * k))
			if k > 0.8:
				# Savuruştan hemen önce baltada parlama (son uyarı).
				g.sprite("fx_spark", axe, Vector2(54, 54) * (k - 0.6) * 2.5, Color(1.0, 0.85, 0.5, 0.9), now * 3.0)
		"swing":
			var u := 1.0 - float(ig_t) / (AXE_HIT if phase < 3 else 20)
			# Vuruş anı: yumuşak, büyüyüp sönen kor patlaması (sert halka değil).
			var hit := _ig_local(Vector2(470, 350))
			var a := clampf(1.0 - u * 1.3, 0.0, 1.0)
			var hc := IG_WHITE if phase == 3 else Color(1.0, 0.55, 0.15)
			g.draw_set_transform(hit, 0, Vector2(1, 0.6))
			g.glow(Vector2.ZERO, 60.0 + 70.0 * u, Color(hc, 0.55 * a))
			g.glow(Vector2.ZERO, 26.0 + 20.0 * u, Color(1.0, 0.95, 0.8, 0.85 * a))
			g.draw_set_transform(Vector2.ZERO)
			for j in 8:
				var sa := axe_dir.angle() + (j - 3.5) * 0.35
				var sd := 20.0 + 70.0 * u * (0.6 + 0.4 * fmod(j * 0.37, 1.0))
				g.glow(hit + Vector2.from_angle(sa) * sd + Vector2(0, -26.0 * u * (1.0 - u) * 4.0), 4.0, Color(1.0, 0.8, 0.4, 0.9 * a))
		"chain_tell":
			var k := 1.0 - float(ig_t) / IG_CHAIN_TELL
			# Yumruktaki zincir kızarır: büyüyen kor, beyaz göbek ve çevresinde dönen kıvılcımlar.
			var hand := _ig_local(IG_HAND)
			g.glow(hand, 18.0 + 30.0 * k, Color(1.0, 0.4, 0.08, 0.45 + 0.45 * k))
			g.glow(hand, 8.0 + 8.0 * k, Color(1.0, 0.93, 0.7, 0.5 + 0.4 * k))
			for j in 6:
				var a := now * 9.0 + j * TAU / 6.0
				g.glow(hand + Vector2.from_angle(a) * (12.0 + 10.0 * k), 4.5, Color(1.0, 0.8, 0.4, 0.6 + 0.4 * k))
		"chain_throw", "chain_pull", "chain_back":
			var hand := _ig_local(IG_HAND)
			var span := ig_chain_dir * ig_chain_len
			if span.length() < 4.0:
				return
			var perp := span.normalized().orthogonal()
			var wave := _ig_chain_wave()
			var n := maxi(2, int(span.length() / 16.0))
			for j in n:
				var u := (float(j) + 0.5) / n
				var pulse := 0.0
				if ig_state == "chain_pull":
					pulse = maxf(0.0, sin((u + now * 2.5) * TAU * 2.0))
				var c := hand + span * u + perp * (sin(u * PI) * wave * sin(now * 24.0 - u * 9.0))
				g.glow(c, 9.0 + 5.0 * pulse, Color(1.0, 0.38, 0.08, 0.3 + 0.35 * pulse))
			g.glow(hand + span, 16.0, Color(1.0, 0.55, 0.15, 0.6))
	if phase >= 3 and ig_state == "":
		# Son İnfaz: beyaz-sarı yanan balta, üstünden kıvılcımlar yükselir.
		var axe := _ig_local(Vector2(450, 300))
		var pulse := 0.8 + 0.2 * sin(now * 6.0)
		g.glow(axe, 46.0 * pulse, Color(1.0, 0.85, 0.4, 0.35))
		g.glow(axe, 20.0, Color(1.0, 0.97, 0.8, 0.35 * pulse))
		for j in 5:
			var sy := fmod(now * 0.9 + j * 0.21, 1.0)
			g.glow(axe + Vector2(sin(j * 2.3 + now) * 14.0, -10.0 - 50.0 * sy), 3.5, Color(1.0, 0.9, 0.55, 0.9 * (1.0 - sy)))


# ── KRAL ALDEN — Buzun Laneti (bölge 5) ──────────────────────────────

## Dokudaki bir noktanın (tuval pikseli) düğüme göre yeri; sola bakarken aynalanır.
func _al_local(px: Vector2) -> Vector2:
	var v := (px - AL_ANCHOR) * AL_SCALE
	return Vector2(-v.x if _al_flip else v.x, v.y)


func _alden_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	if melee_cd > 0:
		melee_cd -= 1
	if throne_pos == Vector2.ZERO:
		throne_pos = position
	var to := p.position - position
	var d := to.length()
	if phase >= 2:
		_storm_tick(p)
	match al_state:
		"spike":
			al_t -= 1
			if al_t <= 0:
				al_state = ""
		"breath_tell":
			al_t -= 1
			if al_t <= 0:
				al_state = "breath"
				al_t = BREATH
				breath_hit = false
				main.shake(6)
		"breath":
			al_t -= 1
			_breath_hit(p)
			if al_t <= 0:
				al_state = ""
		"prison":
			al_t -= 1
			if al_t <= 0:
				al_state = ""
		_:
			spike_cd = maxi(0, spike_cd - 1)
			breath_cd = maxi(0, breath_cd - 1)
			prison_cd = maxi(0, prison_cd - 1)
			if phase >= 3 and d > 60.0 and p.alive():
				# Son direniş: tahttan inmiş, oyuncuya yürür (tell süreleri aynı).
				var v := to / d * speed
				var np := main.world.move_circle(position, v, 20.0)
				if np == position:
					np = main.world.move_point(position, v)
				position = np
			if phase >= 3 and absf(to.x) > 6.0:
				_al_flip = to.x < 0
			if melee_cd == 0 and d < AL_REACH[phase - 1] and p.alive():
				# Zincir menzilinde: buz kılıcıyla savurur.
				melee_cd = 100
				lunge = 12
				if p.take_damage(int(atk * 0.8), self):
					p.apply_debuff("frost")
			if p.alive():
				if phase >= 3 and prison_cd == 0 and d < 320.0:
					_start_prison(p)
				elif breath_cd == 0 and d < BREATH_LEN + 40.0:
					_start_breath(p)
				elif spike_cd == 0 and d < 420.0:
					_start_spikes(p)
	anim_timer += 1
	if anim_timer >= 30:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


## Buz dikeni hattı: kılıcını yere saplar; yerde oyuncuya doğru mavi çizgi uzar (FrostHazard tell'i), sonra
## çizgi boyunca dikenler fışkırır. Faz 2'de iki, faz 3'te üç hat (yelpaze).
func _start_spikes(p: Player) -> void:
	al_state = "spike"
	al_t = SPIKE_POSE
	spike_cd = [170, 150, 130][phase - 1]
	var start := position + Vector2(0, 8)
	var base := (p.position + Vector2(0, 16) - start).normalized()
	var spread: Array = [[0.0], [-0.22, 0.22], [-0.35, 0.0, 0.35]][phase - 1]
	for a in spread:
		var dir := base.rotated(a)
		var from := start + dir * 34.0
		var length := 0.0
		while length < 380.0 and main.world.is_walkable(from + dir * (length + 12.0)):
			length += 12.0
		if length >= 40.0:
			var hz := FrostHazard.new()
			hz.setup_spikes(from, dir, length, int(atk * 0.9))
			main._spawn(hz, hz.position)


func _start_breath(p: Player) -> void:
	al_state = "breath_tell"
	al_t = BREATH_TELL
	breath_cd = [220, 190, 160][phase - 1]
	breath_dir = (p.position - _breath_origin()).normalized()


## Nefes konisinin yerdeki tepe noktası: ağzın hizasında, ayak düzleminde.
func _breath_origin() -> Vector2:
	return position + Vector2(_al_local(AL_MOUTH).x, 10)


## Nefes: konideki oyuncuya bir kez hasar + 2 kırağı; düşmüş sarkıt arada kalırsa nefesi keser.
func _breath_hit(p: Player) -> void:
	if breath_hit or not p.alive():
		return
	var o := _breath_origin()
	var rel := p.position - o
	if rel.length() > BREATH_LEN or absf(angle_difference(breath_dir.angle(), rel.angle())) > BREATH_HALF:
		return
	for h in main.others:
		if h is FrostHazard and is_instance_valid(h) and not h.removed and h.blocks(o, p.position):
			return
	breath_hit = true
	p.take_damage(int(atk * 0.6), self)
	p.add_frost(2, true)


func _start_prison(p: Player) -> void:
	al_state = "prison"
	al_t = PRISON_CAST
	prison_cd = 260
	_al_flip = p.position.x < position.x
	var hz := FrostHazard.new()
	hz.setup("prison", p.position + Vector2(0, 14), 62.0, int(atk * 0.7))
	main._spawn(hz, hz.position)
	main.float_text(p.position + Vector2(0, -70), "BUZ HAPSİ!", AL_WHITE)


## Kar fırtınası: yığınlar kendiliğinden yavaşça artar (yanan kandilin ışığında değilse); tavandan sarkıtlar düşer.
func _storm_tick(p: Player) -> void:
	storm_t += 1
	p.in_storm = 2
	if storm_t % STORM_EVERY == 0 and p.alive():
		var warm := false
		for l in main.lanterns:
			if is_instance_valid(l) and l.warms(p.position):
				warm = true
		if not warm:
			p.add_frost(1, false, true)
	icicle_cd -= 1
	if icicle_cd <= 0:
		icicle_cd = [0, 110, 90][phase - 1]
		# Biri oyuncunun yakınına, biri arenada rastgele.
		for i in 2:
			var at := p.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 50) + Vector2(0, 14)
			if i == 1:
				at = throne_pos + Vector2(randf_range(-240, 240), randf_range(60, 380))
			if main.world.circle_free(at, 16):
				var hz := FrostHazard.new()
				hz.setup("icicle", at, 34.0, int(atk * 0.6))
				main._spawn(hz, hz.position)
	if _storm_rect:
		var k := 0.82 + 0.1 * sin(storm_t / 40.0) + 0.08 * sin(storm_t / 13.0)
		_storm_rect.modulate.a = k * minf(1.0, storm_t / 60.0)


func _alden_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.45][n - 1])
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if n == 2:
		Log.add("%s zincirlerinden birini kopardı! (FAZ 2)" % nm, "death")
		main.float_text(position + Vector2(0, -190), "KAR FIRTINASI!", AL_WHITE)
		main.burst(position + Vector2(-40, -90), 90, AL_WHITE)
		icicle_cd = 60
		_start_storm()
		main.spawn_minions(self, 2)
	else:
		Log.add("%s tahttan iniyor! (FAZ 3)" % nm, "death")
		main.float_text(position + Vector2(0, -190), "SON DİRENİŞ!", AL_SEAL.lightened(0.4))
		main.burst(position + Vector2(0, -90), 120, AL_SEAL)
		main.hit_freeze(8)
		_leave_throne()
		prison_cd = 40
		main.spawn_minions(self, 2)


## Tahttan iner: boş taht arkada (kuzeyde) kalır, Alden bir adım öne çıkar.
func _leave_throne() -> void:
	if speed > 0.0:
		return
	if throne_pos == Vector2.ZERO:
		throne_pos = position
	main.atmosphere._standing_prop(main.entities, "boss_z5_throne", throne_pos + Vector2(0, -2), 390.0 * AL_SCALE, false)
	var fwd := throne_pos + Vector2(0, 46)
	position = fwd if main.world.circle_free(fwd, 20) else throne_pos
	speed = 0.95
	main.burst(throne_pos + Vector2(0, -80), 80, AL_WHITE)


## Ölüm: Alden'ın düştüğü yerde buz kırıntıları kalır; tahtta buz erir ve yalnızca yaşlı kral huzur içinde oturur.
func _rest_in_peace() -> void:
	if Sprites.tex("boss_z5_peace") == null:
		return
	var tp := throne_pos if throne_pos != Vector2.ZERO else position
	var r := AldenRest.new()
	r.died_at = position
	main._spawn(r, tp)
	# Faz 3'te kalan boş taht sprite'ı, aynı yere oturan erime / huzur kareleriyle değişir.
	var tt := Sprites.tex("boss_z5_throne")
	for c in main.entities.get_children():
		if c is Sprite2D and c.texture == tt:
			r.empty_throne = c


func _start_storm() -> void:
	if _storm:
		return
	_storm = CanvasLayer.new()
	_storm.layer = 3
	add_child(_storm)
	# Ekran kenarları beyazlaşır: ortası saydam, kenarları soluk beyaz-mavi yumuşak çerçeve.
	var g := Gradient.new()
	g.set_color(0, Color(0.85, 0.93, 1.0, 0.0))
	g.set_color(1, Color(0.85, 0.93, 1.0, 0.34))
	g.add_point(0.64, Color(0.85, 0.93, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 0.5)
	tex.width = 256
	tex.height = 256
	_storm_rect = TextureRect.new()
	_storm_rect.texture = tex
	_storm_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_storm_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_storm_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_storm_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_storm_rect.modulate.a = 0.0
	_storm.add_child(_storm_rect)
	# Ekranı yatay kesen rüzgârlı kar (yumuşak yuvarlak taneler).
	var vs := get_viewport().get_visible_rect().size
	var snow := CPUParticles2D.new()
	snow.amount = 220
	snow.lifetime = 2.6
	snow.preprocess = 2.6
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.position = Vector2(-40, vs.y * 0.5)
	snow.emission_rect_extents = Vector2(20, vs.y * 0.6)
	snow.direction = Vector2(1, 0.25)
	snow.spread = 12
	snow.gravity = Vector2(0, 30)
	snow.initial_velocity_min = vs.x * 0.35
	snow.initial_velocity_max = vs.x * 0.55
	Atmosphere.soften_sparks(snow, 5.0, 12.0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.15, Color(0.95, 0.98, 1.0, 0.75))
	ramp.add_point(0.8, Color(0.95, 0.98, 1.0, 0.55))
	snow.color_ramp = ramp
	_storm.add_child(snow)


func _end_storm() -> void:
	if _storm:
		_storm.queue_free()
		_storm = null
		_storm_rect = null


func _exit_tree() -> void:
	_end_storm()


func _al_key() -> String:
	if phase >= 3:
		return "boss_z5_p3cast" if al_state in ["spike", "prison", "breath_tell", "breath"] else "boss_z5_p3idle"
	# Faz 2'de bir bilek zinciri kopuk: o fazın kendi diken ve nefes pozları (yoksa faz 1'inkiler).
	var p2 := "p2" if phase == 2 and Sprites.tex("boss_z5_p2spike") != null else ""
	match al_state:
		"spike": return "boss_z5_%sspike" % p2
		"breath_tell", "breath": return "boss_z5_%sbreath" % p2
	if phase == 2:
		return "boss_z5_p2"
	return "boss_z5_idle%d" % frame


func _draw_alden() -> void:
	var t := Time.get_ticks_msec()
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	var sw := 92.0 if phase < 3 else 66.0
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-sw, -sw, sw * 2, sw * 2), false, Color(0, 0, 0, 0.55))
	draw_set_transform(Vector2.ZERO)
	var key := _al_key()
	var size := AL_CANVAS * AL_SCALE
	var off := Vector2.ZERO
	if lunge > 0:
		off = (main.player.position - position).normalized() * (lunge / 12.0) * 6.0
	if phase >= 3:
		off.y += sin(t / 600.0) * 1.5
	var b := Rect2(Vector2(-AL_ANCHOR.x * AL_SCALE, -AL_ANCHOR.y * AL_SCALE) + off, size)
	if _al_flip:
		b.position.x = -(AL_CANVAS.x - AL_ANCHOR.x) * AL_SCALE + off.x
	var mod := Color.WHITE
	if al_state == "breath_tell":
		var k := 1.0 - float(al_t) / BREATH_TELL
		mod = Color(1.0 + 0.15 * k, 1.0 + 0.25 * k, 1.0 + 0.4 * k)
	if flash > 0:
		mod = Color(1.5, 0.8, 0.8)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, _al_flip, false, false, mod)


## Zemin tell'leri (toplamalı, gövdenin arkasında): ayak altında soğuk ışıma, nefes konisi.
func _paint_alden_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	g.draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 100.0, Color(AL_ICE, 0.12 + 0.04 * sin(now * 2.0)))
	g.draw_set_transform(Vector2.ZERO)
	if al_state == "breath_tell":
		var k := 1.0 - float(al_t) / BREATH_TELL
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
		var o := _breath_origin() - position
		var a0 := breath_dir.angle()
		_fan(g, o, a0, BREATH_HALF, BREATH_LEN, Color(0.5, 0.8, 1.0, (0.1 + 0.2 * k) * blink), Color(0.5, 0.8, 1.0, 0.02))
		_fan(g, o, a0, BREATH_HALF * 0.8, BREATH_LEN * k, Color(0.85, 0.95, 1.0, 0.18 * k), Color(0.6, 0.85, 1.0, 0.1 * k))
		var edge := Color(0.75, 0.92, 1.0, (0.3 + 0.5 * k) * blink)
		g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 - BREATH_HALF) * BREATH_LEN]), 1.3, edge)
		g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 + BREATH_HALF) * BREATH_LEN]), 1.3, edge)
		var arc := PackedVector2Array()
		for i in 17:
			arc.append(o + Vector2.from_angle(a0 - BREATH_HALF + BREATH_HALF * 2.0 * i / 16.0) * BREATH_LEN)
		g.streak(arc, 1.5, edge)
	elif al_state == "breath":
		# Nefes: koni boyunca soğuk beyaz-mavi buhar örtüsü.
		var fade := clampf(float(al_t) / 10.0, 0.0, 1.0)
		var o := _breath_origin() - position
		_fan(g, o, breath_dir.angle(), BREATH_HALF, BREATH_LEN, Color(0.85, 0.95, 1.0, 0.42 * fade), Color(0.6, 0.85, 1.0, 0.1 * fade))


## Öndeki parıltılar: göğüsteki mor mühür (faz 3'te çatlak, titrek), nefes tell'inde ağız ve göğüs,
## nefes anında koni boyunca akan soğuk buhar, diken pozunda kılıç ucunun parlaması.
func _paint_alden_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var chest := _al_local(AL_CHEST)
	if phase >= 3:
		chest = _al_local(Vector2(222, 228))
	var sk := 0.5 + 0.5 * sin(now * 2.4)
	var seal_a := 0.3 + 0.15 * sk
	if phase >= 3:
		seal_a *= 0.6 + 0.4 * absf(sin(now * 17.0))
	g.glow(chest, 16.0 + 4.0 * sk, Color(AL_SEAL, seal_a))
	g.glow(chest, 5.0, Color(0.9, 0.75, 1.0, seal_a + 0.2))
	match al_state:
		"breath_tell":
			var k := 1.0 - float(al_t) / BREATH_TELL
			var mouth := _al_local(AL_MOUTH)
			g.glow(mouth, 10.0 + 18.0 * k, Color(AL_WHITE, 0.3 + 0.5 * k))
			g.glow(_al_local(AL_CHEST), 18.0 + 22.0 * k, Color(AL_ICE, 0.2 + 0.4 * k))
		"breath":
			var mouth := _al_local(AL_MOUTH)
			var o := _breath_origin() - position
			var fade := clampf(float(al_t) / 10.0, 0.0, 1.0)
			g.glow(mouth, 20.0, Color(AL_WHITE, 0.6 * fade))
			for j in 18:
				var q := fmod(now * 2.2 + j * 0.137, 1.0)
				var side := sin(j * 2.7) * BREATH_HALF * 0.85
				var at := o + Vector2.from_angle(breath_dir.angle() + side) * BREATH_LEN * q
				# Ağızdan yere inen buhar: başta ağız hizasında, ilerledikçe yere yaklaşır.
				at += Vector2(0, (mouth.y - o.y) * (1.0 - q) * (1.0 - q))
				g.glow(at, 12.0 + 26.0 * q, Color(0.85, 0.95, 1.0, 0.55 * (1.0 - q * 0.6) * fade))
		"spike":
			var k := clampf(float(al_t) / SPIKE_POSE, 0.0, 1.0)
			var tip := _al_local(Vector2(222, 440))
			if phase >= 3:
				tip = _al_local(Vector2(330, 120))
			g.glow(tip, 14.0 + 10.0 * k, Color(AL_ICE, 0.35 + 0.35 * k))
			g.glow(tip, 5.0, Color(AL_WHITE, 0.7))
		"prison":
			var hand := _al_local(Vector2(330, 120))
			g.glow(hand, 26.0, Color(AL_ICE, 0.5))


# ── LYRA — Dikenlerin Kraliçesi (bölge 6) ────────────────────────────

func _ly_local(px: Vector2) -> Vector2:
	var v := (px - LY_ANCHOR) * LY_SCALE
	return Vector2(-v.x if _al_flip else v.x, v.y)


func _lyra_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	if melee_cd > 0:
		melee_cd -= 1
	if throne_pos == Vector2.ZERO:
		throne_pos = position
	var to := p.position - position
	var d := to.length()
	if phase >= 2:
		_weep_tick()
	match ly_state:
		"rain", "rootcast", "ringcast":
			ly_t -= 1
			if ly_t <= 0:
				ly_state = ""
		_:
			rain_cd = maxi(0, rain_cd - 1)
			lroot_cd = maxi(0, lroot_cd - 1)
			ring_cd = maxi(0, ring_cd - 1)
			if phase >= 3 and d > 70.0 and p.alive():
				# Ağaçtan kopmuş: oyuncuya yürür.
				var v := to / d * speed
				var np := main.world.move_circle(position, v, 20.0)
				if np == position:
					np = main.world.move_point(position, v)
				position = np
			if phase >= 3 and absf(to.x) > 6.0:
				_al_flip = to.x < 0
			if melee_cd == 0 and d < LY_REACH and p.alive():
				# Dikenli sarmaşık kamçısı.
				melee_cd = 100
				lunge = 12
				if p.take_damage(int(atk * 0.8), self):
					p.apply_debuff("poison")
			if p.alive():
				if phase >= 3 and ring_cd == 0 and d < 300.0:
					_start_ring()
				elif rain_cd == 0 and d < 460.0:
					_start_rain(p)
				elif lroot_cd == 0 and d > 90.0 and d < 420.0:
					_start_lroot(p)
	anim_timer += 1
	if anim_timer >= 32:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


## Diken yağmuru: kollarını açar, oyuncunun çevresine 3 (faz 2+: 5) mor daire düşer; ~1 sn sonra dikenler iner.
func _start_rain(p: Player) -> void:
	ly_state = "rain"
	ly_t = 70
	rain_cd = [200, 170, 150][phase - 1]
	var n := 3 if phase == 1 else 5
	for i in n:
		var at := p.position + Vector2(0, 14)
		if i > 0:
			at += Vector2.from_angle(i * TAU / (n - 1) + randf() * 0.6) * randf_range(60, 95)
		if not main.world.is_walkable(at):
			continue
		var hz := ForestHazard.new()
		hz.setup("rain", at, 40.0, int(atk * 0.8))
		hz.t = -i * 6
		main._spawn(hz, hz.position)


## Kök hattı: elini köklere bastırır; yerin altından oyuncunun durduğu yere kök kabarması ilerler, orada kökler fışkırır.
func _start_lroot(p: Player) -> void:
	ly_state = "rootcast"
	ly_t = 60
	lroot_cd = [230, 200, 180][phase - 1]
	var hz := ForestHazard.new()
	hz.setup("roots", p.position + Vector2(0, 14), 46.0, atk)
	hz.from = position + Vector2(0, 6) - hz.position
	main._spawn(hz, hz.position)


## Diken çemberi (faz 3): çevresinden dışa yayılan diken halkası; boşluk oyuncunun yanında, rastgele bir yönde.
func _start_ring() -> void:
	ly_state = "ringcast"
	ly_t = 50
	ring_cd = 280
	var hz := ForestHazard.new()
	hz.reach = 300.0
	hz.gap = randf() * TAU
	hz.setup("ring", position + Vector2(0, 6), 8.0, int(atk * 0.8))
	main._spawn(hz, hz.position)
	main.shake(6)


## Ağlayan Ağaç (faz 2+): arenada yavaşça sürüklenen spor bulutları (en çok 4); Kutsal Taş ışığı onları dağıtır.
func _weep_tick() -> void:
	weep_t += 1
	if weep_t % 140 != 0:
		return
	var n := 0
	for h in main.others:
		if h is ForestHazard and is_instance_valid(h) and not h.removed and h.kind == "spores":
			n += 1
	if n >= 4:
		return
	for _try in 6:
		var at := throne_pos + Vector2(randf_range(-260, 260), randf_range(80, 420))
		if main.world.circle_free(at, 30):
			var hz := ForestHazard.new()
			hz.setup("spores", at, 70.0, 0)
			hz.life = 420
			hz.vel = Vector2.from_angle(randf() * TAU) * 0.35
			main._spawn(hz, hz.position)
			return


func _lyra_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.45][n - 1])
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if n == 2:
		Log.add("%s: Hayat Ağacı ağlıyor! (FAZ 2)" % nm, "death")
		main.float_text(position + Vector2(0, -200), "AĞLAYAN AĞAÇ!", LY_PURPLE.lightened(0.35))
		main.burst(position + Vector2(0, -90), 100, LY_PURPLE)
		weep_t = 100
		for side in [-1.0, 1.0]:
			var e := main.spawn_enemy("diken_tazisi", position + Vector2(side * 140.0, 120.0))
			if e:
				e.is_minion = true
	else:
		Log.add("%s ağaçtan koptu! (FAZ 3)" % nm, "death")
		main.float_text(position + Vector2(0, -200), "DİKEN ÇEMBERİ!", LY_PURPLE.lightened(0.35))
		main.burst(position + Vector2(0, -90), 120, LY_PURPLE)
		main.hit_freeze(8)
		_leave_tree()
		ring_cd = 60


## Ağaçtan kopar: yarık gövde arkada kalır, Lyra bir adım öne çıkar ve yürümeye başlar.
func _leave_tree() -> void:
	if speed > 0.0:
		return
	if throne_pos == Vector2.ZERO:
		throne_pos = position
	main.atmosphere._standing_prop(main.entities, "boss_z6_tree", throne_pos + Vector2(0, -2), 334.0 * LY_SCALE, false)
	var fwd := throne_pos + Vector2(0, 50)
	position = fwd if main.world.circle_free(fwd, 20) else throne_pos
	speed = 0.9
	main.burst(throne_pos + Vector2(0, -60), 70, Color(0.55, 0.4, 0.28))


## Ölüm: dikenler kurur, ağacın dibinde gerçek Lyra huzurla uzanır; Sera'nın ruhu Arktan'a bağlanır.
func _lyra_rest() -> void:
	if Sprites.tex("boss_z6_peace") == null:
		return
	var tp := throne_pos if throne_pos != Vector2.ZERO else position
	var r := LyraRest.new()
	r.died_at = position
	main._spawn(r, tp)
	var tt := Sprites.tex("boss_z6_tree")
	for c in main.entities.get_children():
		if c is Sprite2D and c.texture == tt:
			r.empty_tree = c


func _ly_key() -> String:
	if phase >= 3:
		return "boss_z6_p3cast" if ly_state != "" else "boss_z6_p3idle"
	match ly_state:
		"rain": return "boss_z6_rain"
		"rootcast": return "boss_z6_rootcast"
	if phase == 2:
		return "boss_z6_p2"
	return "boss_z6_idle%d" % frame


func _draw_lyra() -> void:
	var t := Time.get_ticks_msec()
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	var sw := 96.0 if phase < 3 else 60.0
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-sw, -sw, sw * 2, sw * 2), false, Color(0, 0, 0, 0.55))
	draw_set_transform(Vector2.ZERO)
	var key := _ly_key()
	var size := LY_CANVAS * LY_SCALE
	var off := Vector2.ZERO
	if lunge > 0:
		off = (main.player.position - position).normalized() * (lunge / 12.0) * 6.0
	if phase >= 3:
		off.y += sin(t / 600.0) * 1.5
	var b := Rect2(Vector2(-LY_ANCHOR.x * LY_SCALE, -LY_ANCHOR.y * LY_SCALE) + off, size)
	if _al_flip:
		b.position.x = -(LY_CANVAS.x - LY_ANCHOR.x) * LY_SCALE + off.x
	var mod := Color.WHITE
	if ly_state in ["rain", "rootcast"]:
		var k := 1.0 - float(ly_t) / (70.0 if ly_state == "rain" else 60.0)
		mod = Color(1.0 + 0.2 * k, 1.0, 1.0 + 0.35 * k)
	if flash > 0:
		mod = Color(1.5, 0.8, 0.8)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, _al_flip, false, false, mod)


## Zemin parıltısı: ayak altında mor zehir ışıması; faz 2'de ağacın dibinden sızan özsu.
func _paint_lyra_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	g.draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 110.0, Color(LY_PURPLE, 0.1 + 0.04 * sin(now * 1.6) + (0.08 if phase == 2 else 0.0)))
	g.draw_set_transform(Vector2.ZERO)


## Öndeki parıltılar: alnındaki mor mühür, yağmur tell'inde avuçlarda toplanan ışık, kök tell'inde elden köklere akan zehir.
func _paint_lyra_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var brow := _ly_local(Vector2(232, 120) if phase < 3 else Vector2(212, 128))
	var sk := 0.5 + 0.5 * sin(now * 2.2)
	g.glow(brow, 10.0 + 3.0 * sk, Color(LY_PURPLE, 0.3 + 0.15 * sk))
	g.glow(brow, 3.5, Color(0.95, 0.8, 1.0, 0.5))
	match ly_state:
		"rain":
			var k := 1.0 - float(ly_t) / 70.0
			for hp in [Vector2(118, 40), Vector2(320, 40)]:
				var at := _ly_local(hp)
				g.glow(at, 12.0 + 16.0 * k, Color(LY_PURPLE, 0.35 + 0.45 * k))
				g.glow(at, 5.0, Color(0.95, 0.85, 1.0, 0.7))
		"rootcast":
			var k := 1.0 - float(ly_t) / 60.0
			var hand := _ly_local(Vector2(270, 300))
			g.glow(hand, 14.0 + 14.0 * k, Color(LY_PURPLE, 0.35 + 0.4 * k))
			for j in 6:
				var a := j * TAU / 6.0 + now * 2.0
				g.glow(hand + Vector2(cos(a) * 30.0 * k, absf(sin(a)) * 24.0 * k), 4.0, Color(LY_PURPLE, 0.6 * k))
		"ringcast":
			g.glow(Vector2(0, -60), 40.0, Color(LY_PURPLE, 0.3))


# ── MALAKOR — Yokluğun Çekici (bölge 7) ──────────────────────────────

func _mk_local(px: Vector2) -> Vector2:
	var v := (px - MK_ANCHOR) * MK_SCALE
	return Vector2(-v.x if _al_flip else v.x, v.y)


func _malakor_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	if melee_cd > 0:
		melee_cd -= 1
	if throne_pos == Vector2.ZERO:
		throne_pos = position
	var to := p.position - position
	var d := to.length()
	match mk_state:
		"raise":
			mk_t -= 1
			if mk_t <= 0:
				_hammer_impact()
				mk_state = "smash"
				mk_t = 26
		"smash", "cast":
			mk_t -= 1
			if mk_t <= 0:
				mk_state = ""
		"lift":
			# Havalanır: hedef alınamaz; gölge yerde büyürken tepede bekler, sonra gölgenin üstüne çakılır.
			mk_t -= 1
			if mk_t == VoidHazard.SHADOW_TELL:
				# Tepede bekleme bitti: gölge yerde büyümeye başlar, tell bitince çakılır.
				var hz := VoidHazard.new()
				hz.setup("shadow", mk_target + Vector2(0, 10), 70.0, int(atk * 1.2))
				main._spawn(hz, hz.position)
			if mk_t <= 0:
				position = mk_target
				mk_state = "smash"
				mk_t = 26
				main.burst(position + Vector2(0, -20), 70, MK_VOID)
		"pull":
			mk_t -= 1
			# Yokluk çekimi: oyuncu Malakor'a doğru sürüklenir; atılırken çekim tutmaz.
			if p.alive() and p.dash_left == 0 and d > 50.0:
				p.position = main.world.move_circle(p.position, -to / d * minf(1.4, d - 50.0), Player.RADIUS)
			if mk_t <= 0:
				mk_state = ""
		_:
			hammer_cd = maxi(0, hammer_cd - 1)
			beam_cd = maxi(0, beam_cd - 1)
			dive_cd2 = maxi(0, dive_cd2 - 1)
			pull_cd = maxi(0, pull_cd - 1)
			if d > 90.0 and p.alive():
				var v := to / d * speed
				var np := main.world.move_circle(position, v, 20.0)
				if np == position:
					np = main.world.move_point(position, v)
				position = np
			if absf(to.x) > 6.0:
				_al_flip = to.x < 0
			if melee_cd == 0 and d < 70.0 and p.alive():
				melee_cd = 100
				lunge = 12
				if p.take_damage(int(atk * 0.8), self):
					p.apply_debuff("void")
			if p.alive():
				if phase >= 3 and pull_cd == 0 and d < 360.0:
					_start_pull()
				elif phase >= 2 and dive_cd2 == 0 and d > 140.0:
					_start_dive(p)
				elif hammer_cd == 0 and d < 200.0:
					_start_hammer(p)
				elif beam_cd == 0 and d < 480.0:
					_start_beams(p)
	anim_timer += 1
	if anim_timer >= 30:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


func _mk_feet() -> Vector2:
	return position + Vector2(0, 6)


## Çekiç darbesi: çekici kaldırır (1 sn tell, önünde koni kızarır), sonra vurur; önünde mor alevli yarık açılır.
func _start_hammer(p: Player) -> void:
	mk_state = "raise"
	mk_t = 60
	hammer_cd = [170, 150, 130][phase - 1]
	mk_dir = (p.position + Vector2(0, 14) - _mk_feet()).normalized()
	_al_flip = mk_dir.x < 0


func _hammer_impact() -> void:
	var p := main.player
	var feet := _mk_feet()
	main.shake(16)
	main.hit_freeze(5)
	var rel := p.position + Vector2(0, 14) - feet
	if p.alive() and rel.length() < MK_CONE + 10.0 and absf(angle_difference(mk_dir.angle(), rel.angle())) < MK_HALF + 0.08:
		if p.take_damage(int(atk * 1.3), self):
			p.apply_debuff("void")
	var start := feet + mk_dir * 30.0
	var length := 0.0
	while length < 280.0 and main.world.is_walkable(start + mk_dir * (length + 12.0)):
		length += 12.0
	if length >= 40.0:
		var hz := VoidHazard.new()
		hz.setup_line("crack", start, mk_dir, length, int(atk * 0.3))
		main._spawn(hz, hz.position)
	main.burst(feet + mk_dir * 40.0, 60, MK_VOID)


## Portal ışınları: oyuncunun çevresinde 2 (faz 2+: 3) küçük portal açılır, her biri oyuncunun durduğu yerden geçen
## bir hat boyunca mor alev ışını fışkırtır (1 sn çizgi tell).
func _start_beams(p: Player) -> void:
	mk_state = "cast"
	mk_t = 50
	beam_cd = [210, 180, 160][phase - 1]
	var n := 2 if phase == 1 else 3
	var base := randf() * TAU
	for i in n:
		var ang := base + i * TAU / n
		var from := p.position + Vector2(0, 14) + Vector2.from_angle(ang) * 170.0
		if not main.world.is_walkable(from):
			from = p.position + Vector2(0, 14) + Vector2.from_angle(ang) * 90.0
		var dir := (p.position + Vector2(0, 14) - from).normalized()
		var length := 0.0
		while length < 360.0 and main.world.is_walkable(from + dir * (length + 12.0)):
			length += 12.0
		if length >= 60.0:
			var hz := VoidHazard.new()
			hz.setup_line("beam", from, dir, length, int(atk * 0.9))
			main._spawn(hz, hz.position)


## Gölge dalışı (faz 2+): kanatlarını açıp havalanır; oyuncunun durduğu yerde gölge büyür (0.8 sn), sonra çakılır.
func _start_dive(p: Player) -> void:
	mk_state = "lift"
	mk_t = MK_HOVER + VoidHazard.SHADOW_TELL
	dive_cd2 = 330
	mk_target = p.position + Vector2(0, 4)
	if not main.world.circle_free(mk_target, 20):
		mk_target = p.position
	main.burst(position + Vector2(0, -40), 60, MK_VOID)


## Yokluk çekimi (faz 3): göğsündeki mühür girdap olur, oyuncuyu 2.5 sn kendine çeker (atılarak kurtulunur).
func _start_pull() -> void:
	mk_state = "pull"
	mk_t = 150
	pull_cd = 330
	main.float_text(position + Vector2(0, -200), "ZİNCİRLER!", MK_VOID.lightened(0.35))


func untargetable_malakor() -> bool:
	return mk_state == "lift"


## Kan paktı kalkanı (faz 2+): sağlam Kan Mühürü başına hasar azalır (4 mühür: %60 azalma, hepsi kırılınca yok).
func mk_shield() -> float:
	if phase < 2:
		return 1.0
	var intact := 0
	for l in main.lanterns:
		if l is VoidHazard and is_instance_valid(l) and l.intact():
			intact += 1
	return 1.0 - 0.15 * intact


func _malakor_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.45][n - 1])
	speed = base_speed + [0.0, 0.1, 0.25][n - 1]
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if n == 2:
		Log.add("%s mühürlerden güç alıyor! (FAZ 2)" % nm, "death")
		main.float_text(position + Vector2(0, -210), "VALEN MÜHRÜ!", MK_BLOOD.lightened(0.3))
		main.burst(position + Vector2(0, -80), 100, MK_BLOOD)
		dive_cd2 = 120
		for l in main.lanterns:
			if l is VoidHazard and is_instance_valid(l) and l.intact():
				main.burst(l.head(), 40, MK_BLOOD)
	else:
		Log.add("%s: zindan kapısı çöktü! (FAZ 3)" % nm, "death")
		main.float_text(position + Vector2(0, -210), "KAPI ÇÖKTÜ!", MK_VOID.lightened(0.35))
		main.burst(throne_pos + Vector2(0, -80), 120, MK_VOID)
		main.hit_freeze(8)
		pull_cd = 40
		if _portal_sprite:
			_portal_sprite.modulate = Color(0.55, 0.45, 0.6)
		var ring := VoidHazard.new()
		ring.setup("ring", position + Vector2(0, 6), 66.0, int(atk * 0.5))
		ring.follow = self
		main._spawn(ring, ring.position)


## Arenanın kuzeyindeki yokluk portalı (Malakor'un arkasında kalan kemer). Main boss kurulurken çağırır.
func place_portal() -> void:
	var tex := Sprites.tex("boss_z7_portal")
	if tex == null:
		return
	_portal_sprite = Sprite2D.new()
	_portal_sprite.texture = tex
	_portal_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_portal_sprite.scale = Vector2.ONE * MK_SCALE
	# Tuvalin çapası (taban ortası) düğümde olsun.
	_portal_sprite.offset = (Vector2(tex.get_size()) / 2.0 - MK_ANCHOR)
	_portal_sprite.position = position + Vector2(0, -46)
	main.entities.add_child(_portal_sprite)
	var l := PointLight2D.new()
	l.texture = Atmosphere.light_texture()
	l.texture_scale = 2.2
	l.color = MK_VOID
	l.energy = 0.9
	l.position = Vector2(0, -170)
	_portal_sprite.add_child(l)


## Ölüm: portal Malakor'u geri çeker; iblis portala sürüklenip yokluğa karışır, portal kapanır.
func _malakor_rest() -> void:
	var r := MalakorRest.new()
	r.died_at = position
	r.flip = _al_flip
	r.portal = _portal_sprite
	var at := _portal_sprite.position if _portal_sprite else position
	main._spawn(r, at)


func _mk_key() -> String:
	match mk_state:
		"raise": return "boss_z7_raise"
		"smash": return "boss_z7_smash"
		"cast": return "boss_z7_cast"
		"lift": return "boss_z7_fly"
		"pull": return "boss_z7_pull"
	return "boss_z7_idle%d" % frame


func _draw_malakor() -> void:
	var t := Time.get_ticks_msec()
	var lift := 0.0
	if mk_state == "lift":
		# Havalanma: ilk 24 karede yükselir; tepede bekler (gölge tell'i), son 8 karede çakılır.
		var total := MK_HOVER + VoidHazard.SHADOW_TELL
		var up := clampf(float(total - mk_t) / 24.0, 0.0, 1.0)
		var down := clampf(float(8 - mk_t) / 8.0, 0.0, 1.0) if mk_t < 8 else 0.0
		lift = 260.0 * up * (1.0 - down)
	var sh := 1.0 - clampf(lift / 260.0, 0.0, 0.8)
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-80 * sh, -80 * sh, 160 * sh, 160 * sh), false, Color(0, 0, 0, 0.55 * sh))
	draw_set_transform(Vector2.ZERO)
	var key := _mk_key()
	var size := MK_CANVAS * MK_SCALE
	var off := Vector2(0, -lift)
	if lunge > 0:
		off += (main.player.position - position).normalized() * (lunge / 12.0) * 6.0
	off.y += sin(t / 650.0) * 1.5
	var b := Rect2(Vector2(-MK_ANCHOR.x * MK_SCALE, -MK_ANCHOR.y * MK_SCALE) + off, size)
	if _al_flip:
		b.position.x = -(MK_CANVAS.x - MK_ANCHOR.x) * MK_SCALE + off.x
	var mod := Color.WHITE
	if mk_state == "raise":
		var k := 1.0 - float(mk_t) / 60.0
		mod = Color(1.0 + 0.2 * k, 1.0, 1.0 + 0.4 * k)
	if phase >= 2 and mk_shield() < 1.0:
		mod = mod * Color(1.12, 0.9, 0.9)
	if flash > 0:
		mod = Color(1.5, 0.8, 0.8)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, _al_flip, false, false, mod)


## Zemin tell'leri: ayak altında yokluk ışıması, çekiç konisi.
func _paint_malakor_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var feet := Vector2(0, 6)
	g.draw_set_transform(feet, 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 95.0, Color(MK_VOID, 0.12 + 0.04 * sin(now * 2.0)))
	g.draw_set_transform(Vector2.ZERO)
	if mk_state == "raise":
		var k := 1.0 - float(mk_t) / 60.0
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
		var a0 := mk_dir.angle()
		var o := feet + mk_dir * 14.0
		_fan(g, o, a0, MK_HALF, MK_CONE, Color(0.6, 0.2, 1.0, (0.12 + 0.22 * k) * blink), Color(0.5, 0.15, 0.9, 0.03))
		_fan(g, o, a0, MK_HALF * 0.85, MK_CONE * k, Color(0.8, 0.5, 1.0, 0.2 * k), Color(0.6, 0.25, 1.0, 0.1 * k))
		var edge := Color(0.8, 0.5, 1.0, (0.35 + 0.5 * k) * blink)
		g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 - MK_HALF) * MK_CONE]), 1.4, edge)
		g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 + MK_HALF) * MK_CONE]), 1.4, edge)
		var arc := PackedVector2Array()
		for i in 17:
			arc.append(o + Vector2.from_angle(a0 - MK_HALF + MK_HALF * 2.0 * i / 16.0) * MK_CONE)
		g.streak(arc, 1.6, edge)


## Öndeki parıltılar: göğüsteki kan paktı mührü, çekicin yokluk alevi, büyü elinde girdap, mühürlerden kalkan bağı, çekim girdabı.
func _paint_malakor_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if mk_state == "lift":
		return
	var chest := _mk_local(Vector2(222, 175))
	var sk := 0.5 + 0.5 * sin(now * 2.6)
	g.glow(chest, 12.0 + 4.0 * sk, Color(MK_BLOOD, 0.35 + 0.15 * sk))
	g.glow(chest, 4.0, Color(1.0, 0.75, 0.6, 0.6))
	match mk_state:
		"raise":
			var k := 1.0 - float(mk_t) / 60.0
			var head := _mk_local(Vector2(150, 30))
			g.glow(head, 18.0 + 22.0 * k, Color(MK_VOID, 0.35 + 0.45 * k))
		"cast":
			var hand := _mk_local(Vector2(345, 100))
			g.glow(hand, 22.0, Color(MK_VOID, 0.55))
			for j in 5:
				var a := now * 6.0 + j * TAU / 5.0
				g.glow(hand + Vector2.from_angle(a) * 16.0, 4.0, Color(0.85, 0.6, 1.0, 0.7))
		"pull":
			var k := 0.6 + 0.4 * sin(now * 5.0)
			g.glow(chest, 40.0 * k, Color(MK_VOID, 0.35))
			for j in 8:
				var q := fmod(now * 1.3 + j * 0.125, 1.0)
				var a := j * TAU / 8.0 + now
				g.glow(chest + Vector2.from_angle(a) * 110.0 * (1.0 - q), 5.0, Color(0.8, 0.5, 1.0, 0.6 * q))
	if phase >= 2:
		# Sağlam Kan Mühürlerinden Malakor'a akan kan bağı (kalkan).
		for l in main.lanterns:
			if l is VoidHazard and is_instance_valid(l) and l.intact():
				var from: Vector2 = l.head() - position
				var n := 12
				for j in n:
					var u := (float(j) + fmod(now * 0.8, 1.0)) / n
					g.glow(from.lerp(chest, u), 4.0, Color(MK_BLOOD, 0.35 * (1.0 - absf(u - 0.5))))
		if mk_shield() < 1.0:
			g.glow(Vector2(0, -90), 80.0, Color(MK_BLOOD, 0.08 + 0.06 * sk))


# ── VALERİUS — Kör Adalet (bölge 8) ──────────────────────────────────

func _vl_local(px: Vector2) -> Vector2:
	var v := (px - VL_ANCHOR) * VL_SCALE
	return Vector2(-v.x if _al_flip else v.x, v.y)


func _valerius_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	if melee_cd > 0:
		melee_cd -= 1
	if throne_pos == Vector2.ZERO:
		throne_pos = position
	var to := p.position - position
	var d := to.length()
	match vl_state:
		"throw", "cast":
			vl_t -= 1
			if vl_t <= 0:
				vl_state = ""
		"listen":
			# Kör: sesin geldiği yöne döner (yerde yön oku), sonra o noktaya atılır.
			vl_t -= 1
			_al_flip = vl_dir.x < 0
			if vl_t <= 0:
				vl_state = "dash"
				vl_t = vl_dash_t
				vl_hit = false
		"dash":
			vl_t -= 1
			var np := main.world.move_circle(position, vl_dir * VL_DASH_SPEED, 20.0)
			var blocked := np.distance_to(position) < VL_DASH_SPEED * 0.4
			position = np
			if not vl_hit and p.alive() and position.distance_to(p.position) < 46.0:
				vl_hit = true
				if p.take_damage(int(atk * 1.1), self):
					p.apply_debuff("heavy")
			if vl_t <= 0 or blocked:
				vl_state = ""
				noise_seen = main.noise_frame
		"hesitate":
			# Hatırlayış: eli yüzünde, diz çöker; bu sırada savunmasız (hasar +%50).
			vl_t -= 1
			if vl_t <= 0:
				vl_state = ""
		_:
			throw_cd = maxi(0, throw_cd - 1)
			judge_cd = maxi(0, judge_cd - 1)
			hesitate_cd = maxi(0, hesitate_cd - 1)
			sweep_cd = maxi(0, sweep_cd - 1)
			if phase == 2:
				_blind_tick(p)
			else:
				if d > 110.0 and p.alive():
					var v := to / d * speed
					var np := main.world.move_circle(position, v, 20.0)
					if np == position:
						np = main.world.move_point(position, v)
					position = np
				if absf(to.x) > 6.0:
					_al_flip = to.x < 0
				if melee_cd == 0 and d < 70.0 and p.alive():
					melee_cd = 100
					lunge = 12
					p.take_damage(int(atk * 0.8), self)
				if p.alive():
					if phase >= 3 and hesitate_cd == 0:
						_start_hesitate()
					elif phase >= 3 and sweep_cd == 0:
						_start_sweep()
					elif throw_cd == 0 and d > 80.0 and d < 380.0:
						_start_throw(p.position)
					elif judge_cd == 0 and d < 420.0:
						_start_judgment(p.position)
	anim_timer += 1
	if anim_timer >= 30:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


## Kör Adalet (faz 2): oyuncuyu göremez; oyuncu ateş ettiğinde / saldırdığında sesin geldiği yere döner ve atılır.
## Ses yoksa ağır adımlarla rastgele dolaşır; ara ara son sesin yerine hüküm sütunları çağırır.
func _blind_tick(_p: Player) -> void:
	if main.noise_frame > noise_seen and main.noise_pos != Vector2.INF:
		noise_seen = main.noise_frame
		vl_state = "listen"
		vl_t = VL_LISTEN
		vl_dir = (main.noise_pos - position).normalized()
		vl_target = main.noise_pos
		vl_dash_t = clampi(int(position.distance_to(main.noise_pos) / VL_DASH_SPEED) + 3, 8, 42)
		return
	wander_t -= 1
	if wander_t <= 0:
		wander_t = randi_range(80, 160)
		wander = Vector2.from_angle(randf() * TAU) * 0.45
	var np := main.world.move_circle(position, wander, 20.0)
	if np == position:
		wander = -wander
	position = np
	if absf(wander.x) > 0.05:
		_al_flip = wander.x < 0
	if judge_cd == 0 and main.noise_pos != Vector2.INF:
		_start_judgment(main.noise_pos)


## Dönen kılıç: çift uçlu ışık kılıcını fırlatır; kılıç düz hatta gidip geri döner (0.8 sn hat tell'i).
func _start_throw(target: Vector2) -> void:
	vl_state = "throw"
	vl_t = SkyHazard.BLADE_TELL
	throw_cd = [170, 150, 130][phase - 1]
	var from := position + Vector2(0, -6)
	var dir := (target - from).normalized()
	_al_flip = dir.x < 0
	var length := 0.0
	while length < 360.0 and main.world.is_walkable(from + dir * (length + 14.0)):
		length += 14.0
	if length >= 60.0:
		var hz := SkyHazard.new()
		hz.setup_line("blade", from, dir, length, int(atk * 0.9))
		main._spawn(hz, hz.position)


## Hüküm sütunları: hedefin üstünde artı (faz 3'te ek olarak çarpı) şeklinde altın çizgiler (1 sn tell), sonra ışık sütunları.
func _start_judgment(target: Vector2) -> void:
	vl_state = "cast"
	vl_t = 40
	judge_cd = [200, 200, 170][phase - 1]
	var c := target + Vector2(0, 14)
	var dirs: Array = [Vector2.RIGHT, Vector2.DOWN]
	if phase >= 3:
		dirs.append(Vector2(1, 1).normalized())
		dirs.append(Vector2(1, -1).normalized())
	for dir in dirs:
		var a: Vector2 = c - dir * 190.0
		var b: Vector2 = c + dir * 190.0
		var hz := SkyHazard.new()
		hz.setup_line("line", a, dir, 380.0, int(atk * 0.85))
		main._spawn(hz, hz.position)


## Hatırlayış (faz 3): eli titrer, yüzünü tutup diz çöker (1.5 sn); bu an savunmasızdır.
func _start_hesitate() -> void:
	vl_state = "hesitate"
	vl_t = 90
	hesitate_cd = 420
	main.float_text(position + Vector2(0, -190), "...Bu kan... seni tanıyorum.", Color(1.0, 0.95, 0.8))


## Son hüküm (faz 3): çevresinde yavaşça dönen iki ışık hattı.
func _start_sweep() -> void:
	sweep_cd = SkyHazard.SWEEP_TELL + SkyHazard.SWEEP_LIFE + 200
	var hz := SkyHazard.new()
	hz.setup("sweep", position + Vector2(0, 6), 8.0, int(atk * 0.7))
	hz.follow = self
	hz.ang = randf() * TAU
	main._spawn(hz, hz.position)
	main.float_text(position + Vector2(0, -200), "SON HÜKÜM", VL_GOLD.lightened(0.3))


func _valerius_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.45][n - 1])
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if n == 2:
		Log.add("%s'nın maskesindeki ışık söndü! (FAZ 2)" % nm, "death")
		main.float_text(position + Vector2(0, -210), "KÖR ADALET", VL_GOLD.lightened(0.3))
		main.burst(position + Vector2(0, -120), 70, VL_GOLD)
		noise_seen = main.noise_frame
		judge_cd = 240
	else:
		Log.add("%s duraksıyor... (FAZ 3)" % nm, "death")
		main.float_text(position + Vector2(0, -210), "HATIRLAYIŞ", Color(1.0, 0.95, 0.8))
		main.burst(position + Vector2(0, -120), 90, VL_GOLD)
		main.hit_freeze(8)
		vl_state = ""
		hesitate_cd = 120
		sweep_cd = 30


## Ölüm: kristaller kırılır, Valerius diz çöker; gerçek gözleriyle Arktan'ı tanır.
func _valerius_rest() -> void:
	var r := ValeriusRest.new()
	r.flip = _al_flip
	main._spawn(r, position)


func _vl_key() -> String:
	match vl_state:
		"throw": return "boss_z8_throw"
		"cast": return "boss_z8_cast"
		"listen": return "boss_z8_blind"
		"dash": return "boss_z8_dash"
		"hesitate": return "boss_z8_kneel"
	if phase == 2:
		return "boss_z8_blind"
	return "boss_z8_idle%d" % frame


func _draw_valerius() -> void:
	var t := Time.get_ticks_msec()
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-60, -60, 120, 120), false, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	var key := _vl_key()
	var size := VL_CANVAS * VL_SCALE
	var off := Vector2.ZERO
	if lunge > 0:
		off = (main.player.position - position).normalized() * (lunge / 12.0) * 6.0
	off.y += sin(t / 700.0) * 1.2
	var b := Rect2(Vector2(-VL_ANCHOR.x * VL_SCALE, -VL_ANCHOR.y * VL_SCALE) + off, size)
	if _al_flip:
		b.position.x = -(VL_CANVAS.x - VL_ANCHOR.x) * VL_SCALE + off.x
	var mod := Color.WHITE
	if vl_state == "hesitate":
		mod = Color(1.05, 1.0, 0.95)
	if flash > 0:
		mod = Color(1.5, 0.85, 0.75)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, _al_flip, false, false, mod)


## Zemin: ayak altında altın ışık; körken yön oku (atılacağı yön), atılma izi.
func _paint_valerius_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	g.draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 85.0, Color(VL_GOLD, 0.1 + 0.03 * sin(now * 2.0)))
	g.draw_set_transform(Vector2.ZERO)
	if vl_state == "listen":
		var k := 1.0 - float(vl_t) / VL_LISTEN
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
		var reach := vl_dash_t * VL_DASH_SPEED
		for j in 12:
			var u := float(j + 1) / 12
			if u > 0.3 + 0.7 * k:
				break
			g.glow(Vector2(0, 8) + vl_dir * reach * u, 4.0, Color(VL_GOLD, (0.25 + 0.5 * k) * blink))
		var tip := Vector2(0, 8) + vl_dir * reach
		var side := vl_dir.orthogonal() * 14.0
		g.streak(PackedVector2Array([tip - vl_dir * 20.0 + side, tip, tip - vl_dir * 20.0 - side]), 1.6, Color(VL_GOLD, (0.4 + 0.5 * k) * blink))
	elif vl_state == "dash":
		g.glow(Vector2(0, -60) - vl_dir * 30.0, 50.0, Color(VL_GOLD, 0.25))


## Öndeki parıltılar: altın göz kristalleri (körken sönük, faz 3'te çatlak titrek), atış elinde ışık, hüküm avuçları.
func _paint_valerius_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var eyes := _vl_local(Vector2(222, 68))
	var a := 0.65
	if phase == 2:
		a = 0.12
	elif phase >= 3:
		a = 0.3 + 0.3 * absf(sin(now * 13.0))
	if vl_state != "hesitate":
		# Demir maskenin göz yarıkları: iki ince altın ışık.
		for sx in [-5.0, 5.0]:
			g.glow(eyes + Vector2(sx, 0), 5.0, Color(VL_GOLD, a))
			g.glow(eyes + Vector2(sx, 0), 1.8, Color(1.0, 0.97, 0.85, a + 0.2))
	match vl_state:
		"throw":
			var hand := _vl_local(Vector2(330, 170))
			g.glow(hand, 20.0, Color(VL_GOLD, 0.6))
		"cast":
			for hp in [Vector2(150, 220), Vector2(290, 220)]:
				g.glow(_vl_local(hp), 16.0, Color(VL_GOLD, 0.55))
		"listen":
			var k := 1.0 - float(vl_t) / VL_LISTEN
			g.glow(_vl_local(Vector2(300, 110)), 10.0 + 10.0 * k, Color(1.0, 0.95, 0.85, 0.4))


# ── BOŞLUK — Kapının Ötesindeki İrade (bölge 9) ──────────────────────

func _nihil_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if throne_pos == Vector2.ZERO:
		throne_pos = position
	var to := p.position - position
	var d := to.length()
	if phase >= 3:
		_void_close_tick(p)
	match nh_state:
		"charge":
			nh_t -= 1
			if nh_t <= 0:
				nh_state = "fire"
				nh_t = RiftHazard.BEAM_FIRE
		"fire", "storm":
			nh_t -= 1
			if nh_t <= 0:
				nh_state = ""
		"bound":
			# Kârun'un zincirleri: hareketsiz ve savunmasız.
			nh_t -= 1
			if nh_t <= 0:
				nh_state = ""
				main.burst(position + Vector2(0, -NH_FLOAT), 60, NH_VOID)
		_:
			nh_gaze_cd = maxi(0, nh_gaze_cd - 1)
			nh_storm_cd = maxi(0, nh_storm_cd - 1)
			nh_bind_cd = maxi(0, nh_bind_cd - 1)
			nh_tear_cd = maxi(0, nh_tear_cd - 1)
			# Yavaşça süzülür, oyuncuya hafifçe yaklaşır.
			if d > 220.0 and p.alive():
				position = main.world.move_circle(position, to / d * 0.35, 30.0)
			if p.alive():
				if phase == 2 and nh_bind_cd == 0:
					_karun_bind()
				elif nh_gaze_cd == 0 and d < 560.0:
					_start_gaze(p)
				elif nh_storm_cd == 0:
					_start_storm_wave()
				elif phase == 2 and nh_tear_cd == 0:
					_open_tears(p)
	anim_timer += 1
	if anim_timer >= 26:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


## Bakış ışını: göz bebeği parlar (0.8 sn, hat kilitlenir), sonra 2.5 sn ışın oyuncuyu sınırlı hızla döndürerek izler.
func _start_gaze(p: Player) -> void:
	nh_state = "charge"
	nh_t = RiftHazard.BEAM_TELL
	nh_gaze_cd = [330, 300, 260][phase - 1]
	var hz := RiftHazard.new()
	hz.muzzle = Vector2(0, -NH_FLOAT)
	hz.setup("beam", position, 8.0, int(atk * 0.6))
	hz.follow = self
	hz.ang = (p.position - (position + hz.muzzle)).angle()
	main._spawn(hz, hz.position)


## Obsidyen parça fırtınası: çevresinden dışa genişleyen parça halkası (3 boşluklu); faz 2+'da art arda iki dalga.
func _start_storm_wave() -> void:
	nh_state = "storm"
	nh_t = 40
	nh_storm_cd = [260, 230, 200][phase - 1]
	for i in (1 if phase == 1 else 2):
		var hz := RiftHazard.new()
		hz.reach = 520.0
		var g0 := randf() * TAU
		hz.gaps = [g0, g0 + TAU / 3.0, g0 + TAU * 2.0 / 3.0]
		hz.setup("wave", position + Vector2(0, 6), 8.0, int(atk * 0.7))
		hz.t = -i * 40
		main._spawn(hz, hz.position)
	main.shake(6)


## Faz 2: oyuncunun çevresinde yutan yırtıklar açılır (her biri 10 sn).
func _open_tears(p: Player) -> void:
	nh_tear_cd = 420
	for i in 2:
		for _try in 6:
			var at := p.position + Vector2.from_angle(randf() * TAU) * randf_range(110, 200)
			if main.world.circle_free(at, 30):
				var hz := RiftHazard.new()
				hz.setup("tear", at + Vector2(0, 10), 44.0, int(atk * 0.4))
				main._spawn(hz, hz.position)
				break


## Faz 2: Kârun araya girer; mor zincirlerle Boşluk'u bağlar (3 sn hareketsiz, hasar +%50).
func _karun_bind() -> void:
	nh_state = "bound"
	nh_t = 180
	nh_bind_cd = 720
	main.float_text(main.player.position + Vector2(0, -90), "KÂRUN: \"Kalp'i ondan önce ben alacağım. Şimdi, torun!\"", Color(0.8, 0.55, 1.0))
	main.burst(position + Vector2(0, -NH_FLOAT), 80, Color(0.72, 0.3, 1.0))
	main.shake(10)


## Faz 3: boşluk arenanın kenarlarından içeri kapanır; güvenli daire küçülür, dışında kalan yokluk yanığı alır.
func _void_close_tick(p: Player) -> void:
	nh_safe = maxf(NH_SAFE_MIN, nh_safe - 0.25)
	if p.alive() and (p.position - nh_center).length() > nh_safe:
		nh_out_t += 1
		if nh_out_t % 45 == 1:
			if p.take_damage(int(atk * 0.35), self):
				p.apply_debuff("void")
	else:
		nh_out_t = 0


func _nihil_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.45][n - 1])
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if n == 2:
		Log.add("%s gerçekliği kırıyor! (FAZ 2)" % nm, "death")
		main.float_text(position + Vector2(0, -250), "GERÇEKLİK KIRILIYOR", NH_CYAN.lightened(0.3))
		main.burst(position + Vector2(0, -NH_FLOAT), 110, NH_CYAN)
		nh_bind_cd = 240
		nh_tear_cd = 60
		# Oyuncunun iki yansıması: geride bırakılan yoldaşların yankıları gibi atışları geri yapar.
		var made := 0
		for o in [Vector2(-150, 40), Vector2(150, 40), Vector2(0, 150), Vector2(0, -150), Vector2(-120, -100), Vector2(120, -100)]:
			if made >= 2:
				break
			var at: Vector2 = main.player.position + o
			if main.world.circle_free(at, 14):
				var e := main.spawn_enemy("time_echo", at)
				if e:
					e.is_minion = true
					made += 1
	else:
		Log.add("%s çöküyor: tekillik! (FAZ 3)" % nm, "death")
		main.float_text(position + Vector2(0, -250), "TEKİLLİK", NH_VOID.lightened(0.35))
		main.burst(position + Vector2(0, -NH_FLOAT), 130, NH_VOID)
		main.hit_freeze(8)
		nh_center = main.world.boss_spawn
		nh_safe = NH_SAFE_MAX


## Ölüm: göz obsidyen parçalarına dağılır, yırtık kapanır.
func _nihil_rest() -> void:
	main.fx.add_sprite(position + Vector2(0, -NH_FLOAT), "fx_rift_debris", 160.0, Color.WHITE, 40, 0.4)
	main.burst(position + Vector2(0, -NH_FLOAT), 140, NH_CYAN)
	# Boss bu sırada silinir; söz bossa değil main'e bağlı olsun.
	main.later(60, main.float_text.bind(main.player.position + Vector2(0, -90), "KÂRUN: \"...Onu durdurdun. Bu, aramızdaki hesabı değiştirmiyor.\"", Color(0.8, 0.55, 1.0)))


func _nh_key() -> String:
	match nh_state:
		"charge": return "boss_z9_charge"
		"fire": return "boss_z9_fire"
		"storm": return "boss_z9_storm"
		"bound": return "boss_z9_bound"
	if phase >= 3:
		return "boss_z9_singular" if frame == 1 else "boss_z9_idle2"
	return "boss_z9_idle%d" % frame


func _draw_nihil() -> void:
	var t := Time.get_ticks_msec()
	draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.3))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-90, -90, 180, 180), false, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO)
	var key := _nh_key()
	var s := NH_SCALE * (0.75 if phase >= 3 else 1.0)
	var size := NH_CANVAS * s
	var bob := sin(t / 900.0) * 6.0
	var c := Vector2(0, -NH_FLOAT + bob)
	var b := Rect2(c - size / 2.0, size)
	var mod := Color.WHITE
	if nh_state == "charge":
		var k := 1.0 - float(nh_t) / RiftHazard.BEAM_TELL
		mod = Color(1.0, 1.0 + 0.2 * k, 1.0 + 0.3 * k)
	if flash > 0:
		mod = Color(1.5, 0.85, 0.9)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, false, false, false, mod)


## Zemin: ayak altında mor-camgöbeği ışıma; faz 3'te küçülen güvenli dairenin kenarı (boşluk duvarı).
func _paint_nihil_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	g.draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 120.0, Color(NH_VOID, 0.12 + 0.04 * sin(now * 1.7)))
	g.draw_set_transform(Vector2.ZERO)
	if phase >= 3:
		var c := nh_center - position
		var n := 48
		for i in n:
			var a := i * TAU / n + now * 0.2
			var at := c + Vector2.from_angle(a) * nh_safe
			g.glow(at, 26.0, Color(NH_VOID, 0.3))
			g.glow(at, 8.0, Color(NH_CYAN, 0.35 + 0.15 * sin(now * 4.0 + i)))


## Öndeki parıltılar: göz bebeği; bağlıyken Kârun'un mor zincirleri dış kenardan göze uzanır.
func _paint_nihil_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var c := Vector2(0, -NH_FLOAT + sin(Time.get_ticks_msec() / 900.0) * 6.0)
	var k := 0.5 + 0.5 * sin(now * 2.0)
	g.glow(c, 24.0 + 6.0 * k, Color(NH_CYAN, 0.25))
	if nh_state == "bound":
		for j in 4:
			var from := c + Vector2.from_angle(j * TAU / 4.0 + 0.4) * 320.0
			var n := 16
			for i in n:
				var u := float(i) / n
				g.glow(from.lerp(c, u) + Vector2(0, sin(u * PI) * 20.0), 6.0, Color(0.72, 0.3, 1.0, 0.55))


# ── GÖK BÖRÜ — Kalbin Bekçisi (bölge 10, kat 100 ilk bölüm) ───────────

func _gb_local(px: Vector2) -> Vector2:
	var v := (px - GB_ANCHOR) * GB_SCALE
	return Vector2(-v.x if _al_flip else v.x, v.y)


func _gokboru_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	if melee_cd > 0:
		melee_cd -= 1
	var to := p.position - position
	var d := to.length()
	match gb_state:
		"howl":
			gb_t -= 1
			if gb_t <= 0:
				# Uluma dalgası: yıldız ışığı halkası (2 boşluk).
				var hz := RiftHazard.new()
				hz.reach = 420.0
				var g0 := randf() * TAU
				hz.gaps = [g0, g0 + PI]
				hz.setup("wave", position + Vector2(0, 6), 8.0, int(atk * 0.7))
				main._spawn(hz, hz.position)
				main.shake(8)
				gb_state = ""
		"lunge_tell":
			gb_t -= 1
			_al_flip = gb_dir.x < 0
			if gb_t <= 0:
				gb_state = "lunge"
				gb_t = 22
				gb_hit = false
		"lunge":
			gb_t -= 1
			var np := main.world.move_circle(position, gb_dir * 9.0, 26.0)
			var blocked := np.distance_to(position) < 3.0
			position = np
			if not gb_hit and p.alive() and position.distance_to(p.position) < 56.0:
				gb_hit = true
				if p.take_damage(int(atk * 1.2), self):
					p.apply_debuff("crystal")
			if gb_t <= 0 or blocked:
				gb_state = ""
		"breath":
			gb_t -= 1
			if gb_t == 20:
				# Yıldız nefesi: önündeki koniye kristal hatları (faz 2+: 3 hat).
				var n := 1 if phase == 1 else 3
				for i in n:
					var dir := gb_dir.rotated((i - (n - 1) * 0.5) * 0.35)
					var start := position + Vector2(0, 8) + dir * 50.0
					var length := 0.0
					while length < 340.0 and main.world.is_walkable(start + dir * (length + 14.0)):
						length += 14.0
					if length >= 40.0:
						var hz := HeartHazard.new()
						hz.setup_line(start, dir, length, int(atk * 0.9))
						hz.t = HeartHazard.LINE_TELL - 20
						main._spawn(hz, hz.position)
			if gb_t <= 0:
				gb_state = ""
		"rage":
			gb_t -= 1
			if gb_t <= 0:
				gb_state = ""
		_:
			gb_howl_cd = maxi(0, gb_howl_cd - 1)
			gb_lunge_cd = maxi(0, gb_lunge_cd - 1)
			gb_breath_cd = maxi(0, gb_breath_cd - 1)
			gb_rage_cd = maxi(0, gb_rage_cd - 1)
			if d > 120.0 and p.alive():
				var v := to / d * speed
				var np := main.world.move_circle(position, v, 26.0)
				if np == position:
					np = main.world.move_point(position, v)
				position = np
			if absf(to.x) > 6.0:
				_al_flip = to.x < 0
			if melee_cd == 0 and d < 80.0 and p.alive():
				melee_cd = 90
				lunge = 12
				if p.take_damage(int(atk * 0.8), self):
					p.apply_debuff("crystal")
			if p.alive():
				if phase >= 2 and gb_rage_cd == 0:
					_gb_rage(p)
				elif gb_lunge_cd == 0 and d > 140.0 and d < 380.0:
					gb_state = "lunge_tell"
					gb_t = 36
					gb_lunge_cd = [190, 160, 130][phase - 1]
					gb_dir = (p.position - position).normalized()
				elif gb_breath_cd == 0 and d < 320.0:
					gb_state = "breath"
					gb_t = 56
					gb_breath_cd = [210, 180, 150][phase - 1]
					gb_dir = (p.position + Vector2(0, 14) - position).normalized()
					_al_flip = gb_dir.x < 0
				elif gb_howl_cd == 0:
					gb_state = "howl"
					gb_t = 54
					gb_howl_cd = [280, 240, 200][phase - 1]
	anim_timer += 1
	if anim_timer >= 26:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


## Kristal öfkesi (faz 2+): sırtındaki kristaller parlar; çevresinde 5 kristal hattı yıldız gibi açılır, yerde Kalp közleri kalır.
func _gb_rage(p: Player) -> void:
	gb_state = "rage"
	gb_t = 60
	gb_rage_cd = 360 if phase == 2 else 280
	var base := (p.position - position).angle()
	for i in 5:
		var dir := Vector2.from_angle(base + i * TAU / 5.0)
		var start := position + Vector2(0, 8) + dir * 40.0
		var length := 0.0
		while length < 300.0 and main.world.is_walkable(start + dir * (length + 14.0)):
			length += 14.0
		if length >= 40.0:
			var hz := HeartHazard.new()
			hz.setup_line(start, dir, length, int(atk * 0.8))
			main._spawn(hz, hz.position)
	if phase >= 3:
		for i in 3:
			var at := p.position + Vector2.from_angle(randf() * TAU) * randf_range(60, 140)
			if main.world.circle_free(at, 20):
				var em := HeartHazard.new()
				em.setup("ember", at + Vector2(0, 10), 40.0, int(atk * 0.3))
				main._spawn(em, em.position)


func _gokboru_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.45][n - 1])
	speed = base_speed + [0.0, 0.2, 0.4][n - 1]
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if n == 2:
		Log.add("%s kristallerin acısıyla kudurdu! (FAZ 2)" % nm, "death")
		main.float_text(position + Vector2(0, -180), "KRİSTAL ÖFKESİ", GB_PURPLE.lightened(0.35))
		gb_rage_cd = 30
	else:
		Log.add("%s yaralı, Kalp kızıllaşıyor! (FAZ 3)" % nm, "death")
		main.float_text(position + Vector2(0, -180), "KALP KÖZLERİ", Color(1.0, 0.6, 0.3))
		main.hit_freeze(8)
		gb_rage_cd = 60


func _gb_key() -> String:
	match gb_state:
		"howl": return "boss_z10_howl"
		"lunge_tell", "lunge": return "boss_z10_lunge"
		"breath": return "boss_z10_breath"
		"rage": return "boss_z10_rage"
	if phase >= 3:
		return "boss_z10_wounded" if frame == 1 else "boss_z10_idle2"
	return "boss_z10_idle%d" % frame


func _draw_gokboru() -> void:
	var t := Time.get_ticks_msec()
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-110, -110, 220, 220), false, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	var key := _gb_key()
	var size := GB_CANVAS * GB_SCALE
	var off := Vector2.ZERO
	if lunge > 0:
		off = (main.player.position - position).normalized() * (lunge / 12.0) * 8.0
	if gb_state == "lunge_tell":
		off.x = sin(gb_t * 1.7) * 2.0
	var b := Rect2(Vector2(-GB_ANCHOR.x * GB_SCALE, -GB_ANCHOR.y * GB_SCALE) + off, size)
	if _al_flip:
		b.position.x = -(GB_CANVAS.x - GB_ANCHOR.x) * GB_SCALE + off.x
	var mod := Color.WHITE
	if flash > 0:
		mod = Color(1.5, 0.85, 0.9)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, _al_flip, false, false, mod)


func _paint_gokboru_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	g.draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 120.0, Color(0.5, 0.65, 1.0, 0.12 + 0.03 * sin(now * 2.0)))
	g.draw_set_transform(Vector2.ZERO)
	if gb_state == "lunge_tell":
		var k := 1.0 - float(gb_t) / 36.0
		var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
		for j in 12:
			var u := float(j + 1) / 12
			if u > 0.3 + 0.7 * k:
				break
			g.glow(Vector2(0, 8) + gb_dir * 198.0 * u, 4.0, Color(0.6, 0.8, 1.0, (0.3 + 0.5 * k) * blink))


func _paint_gokboru_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var amulet := _gb_local(Vector2(255, 310))
	g.glow(amulet, 12.0 + 3.0 * sin(now * 2.0), Color(1.0, 0.8, 0.4, 0.4))
	match gb_state:
		"howl":
			var k := 1.0 - float(gb_t) / 54.0
			g.glow(_gb_local(Vector2(300, 160)), 30.0 + 40.0 * k, Color(0.6, 0.8, 1.0, 0.3 + 0.4 * k))
		"breath":
			var k := clampf(1.0 - float(gb_t - 20) / 36.0, 0.0, 1.0)
			g.glow(_gb_local(Vector2(370, 250)), 12.0 + 18.0 * k, Color(0.85, 0.92, 1.0, 0.4 + 0.5 * k))
		"rage":
			g.glow(Vector2(0, -GB_ANCHOR.y * GB_SCALE * 0.6), 120.0, Color(GB_PURPLE, 0.25))


## Gök Börü'nün arınması: kristaller kırılır, kurt huzurla kıvrılıp uyur; ardından Kârun tahtından iner.
func _gokboru_rest() -> void:
	var r := WolfRest.new()
	r.flip = _al_flip
	main._spawn(r, position)


# ── KÂRUN — Son savaş (kat 100) ──────────────────────────────────────

func _kr_local(px: Vector2) -> Vector2:
	var v := (px - KR_ANCHOR) * KR_SCALE
	return Vector2(-v.x if _al_flip else v.x, v.y)


func _karun_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if melee_cd > 0:
		melee_cd -= 1
	var to := p.position - position
	var d := to.length()
	match kr_state:
		"chain":
			kr_t -= 1
			if kr_t == 24:
				# Zincirler: oyuncuya doğru üç zincir hattı; ortadaki değerse oyuncu Kârun'a çekilir.
				for i in 3:
					var dir := (p.position + Vector2(0, 14) - position).normalized().rotated((i - 1) * 0.28)
					var hz := VoidHazard.new()
					hz.setup_line("beam", position + Vector2(0, 8), dir, 420.0, int(atk * 0.8))
					hz.t = VoidHazard.BEAM_TELL - 24
					main._spawn(hz, hz.position)
			if kr_t <= 0:
				kr_state = ""
		"orbs", "echo", "heart":
			kr_t -= 1
			if kr_state == "orbs" and kr_t % 20 == 0 and kr_t > 0:
				_orb_ring(int(kr_t / 20))
			if kr_state == "heart" and kr_t % 30 == 0 and kr_t > 0:
				_heart_burst(p)
			if kr_t <= 0:
				kr_state = ""
		_:
			kr_chain_cd = maxi(0, kr_chain_cd - 1)
			kr_orb_cd = maxi(0, kr_orb_cd - 1)
			kr_echo_cd = maxi(0, kr_echo_cd - 1)
			kr_heart_cd = maxi(0, kr_heart_cd - 1)
			if d > 220.0 and p.alive():
				position = main.world.move_circle(position, to / d * 0.5, 22.0)
			elif d < 120.0 and p.alive():
				# Mesafe korur: yaklaşan oyuncudan geri süzülür.
				position = main.world.move_circle(position, -to / maxf(d, 1.0) * 0.7, 22.0)
			if absf(to.x) > 6.0:
				_al_flip = to.x < 0
			if p.alive():
				if phase >= 3 and kr_heart_cd == 0:
					_start_heart(p)
				elif phase >= 2 and kr_echo_cd == 0:
					_start_echoes(p)
				elif kr_chain_cd == 0 and d < 420.0:
					kr_state = "chain"
					kr_t = 60
					kr_chain_cd = [200, 180, 160][phase - 1]
				elif kr_orb_cd == 0:
					kr_state = "orbs"
					kr_t = 61
					kr_orb_cd = [220, 190, 170][phase - 1]
	anim_timer += 1
	if anim_timer >= 30:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


## Kristal küre halkası: çevresine 12 rün küresi dışa saçılır (her dalga biraz döner).
func _orb_ring(wave: int) -> void:
	for i in 12:
		var a := i * TAU / 12.0 + wave * 0.13
		var hz := HeartHazard.new()
		hz.setup("orb", position + Vector2(0, -60), 8.0, int(atk * 0.6))
		hz.vel = Vector2.from_angle(a) * 3.0
		main._spawn(hz, hz.position)


## Muhafızların yankıları (faz 2+): önceki muhafızların birer saldırısı arenada belirir.
func _start_echoes(p: Player) -> void:
	kr_state = "echo"
	kr_t = 70
	kr_echo_cd = 420
	var at := p.position + Vector2(0, 14)
	main.float_text(position + Vector2(0, -210), "MUHAFIZLARIN YANKILARI", KR_PURPLE.lightened(0.35))
	match kr_echo_i % 4:
		0:
			# Donmuş Han'ın buz dikeni hatları.
			for a in [-0.3, 0.3]:
				var dir := (at - position).normalized().rotated(a)
				var hz := FrostHazard.new()
				hz.setup_spikes(position + Vector2(0, 8) + dir * 40.0, dir, 360.0, int(atk * 0.8))
				main._spawn(hz, hz.position)
		1:
			# Lyra'nın diken yağmuru.
			for i in 5:
				var c := at + (Vector2.ZERO if i == 0 else Vector2.from_angle(i * TAU / 4.0) * 80.0)
				if main.world.is_walkable(c):
					var hz := ForestHazard.new()
					hz.setup("rain", c, 40.0, int(atk * 0.7))
					hz.t = -i * 6
					main._spawn(hz, hz.position)
		2:
			# Usta'nın hüküm sütunları.
			for dir in [Vector2.RIGHT, Vector2.DOWN]:
				var hz := SkyHazard.new()
				hz.setup_line("line", at - dir * 190.0, dir, 380.0, int(atk * 0.8))
				main._spawn(hz, hz.position)
		3:
			# Boşluk'un parça dalgası.
			var hz := RiftHazard.new()
			hz.reach = 480.0
			var g0 := randf() * TAU
			hz.gaps = [g0, g0 + TAU / 3.0, g0 + TAU * 2.0 / 3.0]
			hz.setup("wave", position + Vector2(0, 6), 8.0, int(atk * 0.6))
			main._spawn(hz, hz.position)
	kr_echo_i += 1


## Kalp'e uzanma (faz 3): yerden kızıl-altın kor sütunları; Sera'nın ışığı oyuncuyu korur.
func _start_heart(p: Player) -> void:
	kr_state = "heart"
	kr_t = 150
	kr_heart_cd = 420
	main.float_text(position + Vector2(0, -210), "KALBE UZANIYOR", Color(1.0, 0.6, 0.3))
	if not main.others.any(func(o): return o is HeartHazard and is_instance_valid(o) and not o.removed and o.kind == "sera"):
		# Sera'nın ruhu kılıçtan çıkar: yakında altın-beyaz koruyucu ışık.
		for _try in 10:
			var c := p.position + Vector2.from_angle(randf() * TAU) * randf_range(60, 140)
			if main.world.circle_free(c, 30):
				var s := HeartHazard.new()
				s.setup("sera", c + Vector2(0, 10), 70.0, 0)
				main._spawn(s, s.position)
				main.float_text(c + Vector2(0, -60), "SERA: \"Işığıma gel, evlat!\"", Color(1.0, 0.92, 0.7))
				break


func _heart_burst(p: Player) -> void:
	for i in 3:
		var at := p.position + Vector2.from_angle(randf() * TAU) * randf_range(0, 120)
		if main.world.is_walkable(at):
			var em := HeartHazard.new()
			em.setup("ember", at + Vector2(0, 10), 42.0, int(atk * 0.45))
			main._spawn(em, em.position)


func _karun_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.4][n - 1])
	flash = 16
	main.shake(16)
	if n == 2:
		Log.add("Kârun muhafızların yankılarını çağırıyor! (FAZ 2)", "death")
		main.float_text(position + Vector2(0, -230), "\"Dünya zaten ölüyor.\"", KR_PURPLE.lightened(0.35))
		kr_echo_cd = 30
	else:
		Log.add("Kârun Kalp'e uzanıyor! (FAZ 3)", "death")
		main.float_text(position + Vector2(0, -230), "\"Kanını vermeyeceksen, Kalp'i ben alırım!\"", Color(1.0, 0.6, 0.3))
		main.hit_freeze(8)
		kr_heart_cd = 30


func _kr_key() -> String:
	match kr_state:
		"chain": return "boss_karun_chain"
		"orbs": return "boss_karun_orbs"
		"echo": return "boss_karun_echo"
		"heart": return "boss_karun_heart"
	return "boss_karun_idle%d" % frame


func _draw_karun() -> void:
	var t := Time.get_ticks_msec()
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-70, -70, 140, 140), false, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	var key := _kr_key()
	var size := KR_CANVAS * KR_SCALE
	var off := Vector2(0, sin(t / 800.0) * 2.0)
	var b := Rect2(Vector2(-KR_ANCHOR.x * KR_SCALE, -KR_ANCHOR.y * KR_SCALE) + off, size)
	if _al_flip:
		b.position.x = -(KR_CANVAS.x - KR_ANCHOR.x) * KR_SCALE + off.x
	var mod := Color.WHITE
	if flash > 0:
		mod = Color(1.5, 0.85, 0.9)
	_last_key = key
	_last_box = b
	Sprites.draw_actor(self, key, b, _al_flip, false, false, mod)


func _paint_karun_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	g.draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 100.0, Color(KR_PURPLE, 0.12 + 0.04 * sin(now * 1.8)))
	if kr_state == "heart":
		g.glow(Vector2.ZERO, 160.0, Color(1.0, 0.45, 0.2, 0.18))
	g.draw_set_transform(Vector2.ZERO)


func _paint_karun_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var shard := _kr_local(Vector2(105, 60))
	g.glow(shard, 14.0 + 4.0 * sin(now * 3.0), Color(1.0, 0.45, 0.2, 0.5))
	var eyes := _kr_local(Vector2(215, 92))
	g.glow(eyes, 6.0, Color(KR_PURPLE, 0.6))
	if kr_state == "echo":
		g.glow(Vector2(0, -150), 140.0, Color(KR_PURPLE, 0.18))


## Kârun yenildi: diz çöker, tacı kırılır; karar ekranı açılır.
func _karun_rest() -> void:
	var r := KarunRest.new()
	r.flip = _al_flip
	main._spawn(r, position)


# ── BÖLGE 1–3 MUHAFIZLARI: KARDEŞ, GÖLGE DOKUYUCU, KÖLE EFENDİSİ ──────
## Ortak: kareler 420x470 tuvalde, çapa ayak tabanı (210, 462); mb_state / mb_t ile durum.

func _mb_local(px: Vector2) -> Vector2:
	var v := (px - MB_ANCHOR) * mb_scale
	return Vector2(-v.x if _al_flip else v.x, v.y)


func _mb_walk(p: Player, keep := 90.0) -> void:
	var to := p.position - position
	var d := to.length()
	if d > keep and p.alive() and speed > 0.0:
		var v := to / d * speed
		var np := main.world.move_circle(position, v, 22.0)
		if np == position:
			np = main.world.move_point(position, v)
		position = np
	if absf(to.x) > 6.0:
		_al_flip = to.x < 0


func _mb_cd(name: String) -> int:
	return mb_cds.get(name, 0)


func _mb_tick_cds() -> void:
	for k in mb_cds.keys():
		mb_cds[k] = maxi(0, mb_cds[k] - 1)


func _early_tick() -> void:
	var p := main.player
	if flash > 0:
		flash -= 1
	if lunge > 0:
		lunge -= 1
	if melee_cd > 0:
		melee_cd -= 1
	if mb_t > 0:
		mb_t -= 1
	if is_kardes:
		_kardes_tick(p)
	elif is_dokuyucu:
		_dokuyucu_tick(p)
	else:
		_kole_tick(p)
	anim_timer += 1
	if anim_timer >= 28:
		anim_timer = 0
		frame = 2 if frame == 1 else 1
	queue_redraw()
	_rim.queue_redraw()


## Yakın temas vuruşu (üç boss için ortak).
func _mb_melee(p: Player, reach: float, debuff := "") -> void:
	if melee_cd == 0 and p.alive() and position.distance_to(p.position) < reach:
		melee_cd = 90
		lunge = 12
		if p.take_damage(int(atk * 0.8), self) and debuff != "":
			p.apply_debuff(debuff)


# ── KARDEŞ (bölge 1) ──
## Kılıç savuruşu (geniş koni, 0.9 sn tell); sıçrama (yerde gölge); faz 2: mühür ulumasi (mavi halka);
## faz 3: diz çöker (savunmasız), geride bırakılan yoldaşları (Yitik Muhafızlar) çağırır.
func _kardes_tick(p: Player) -> void:
	var d := position.distance_to(p.position)
	match mb_state:
		"sweeptell":
			_al_flip = mb_dir.x < 0
			if mb_t == 0:
				_cone_hit(p, KD_CONE, KD_HALF, int(atk * 1.2), "slow")
				mb_state = "sweep"
				mb_t = 24
				main.shake(10)
			return
		"leap":
			var u := 1.0 - float(mb_t) / KD_LEAP
			position = mb_from.lerp(mb_to, u * u)
			if mb_t == 0:
				mb_state = ""
			return
		"sweep", "howl":
			if mb_t == 0:
				mb_state = ""
			return
		"kneel":
			if mb_t == 0:
				mb_state = ""
			return
	_mb_tick_cds()
	_mb_walk(p)
	_mb_melee(p, 70.0, "slow")
	if not p.alive():
		return
	if phase >= 2 and _mb_cd("howl") == 0:
		mb_state = "howl"
		mb_t = 50
		mb_cds["howl"] = 300
		var hz := RiftHazard.new()
		hz.debuff = "slow"
		hz.reach = 380.0
		var g0 := randf() * TAU
		hz.gaps = [g0, g0 + PI]
		hz.setup("wave", position + Vector2(0, 6), 8.0, int(atk * 0.7))
		main._spawn(hz, hz.position)
		main.shake(8)
	elif _mb_cd("leap") == 0 and d > 160.0 and d < 420.0:
		mb_state = "leap"
		mb_t = KD_LEAP
		mb_cds["leap"] = [260, 220, 180][phase - 1]
		mb_from = position
		mb_to = p.position + Vector2(0, 4)
		if not main.world.circle_free(mb_to, 20):
			mb_to = p.position
		var hz := VoidHazard.new()
		hz.debuff = ""
		hz.setup("shadow", mb_to + Vector2(0, 10), 70.0, int(atk * 1.1))
		main._spawn(hz, hz.position)
	elif _mb_cd("sweep") == 0 and d < KD_CONE:
		mb_state = "sweeptell"
		mb_t = 54
		mb_cds["sweep"] = [150, 130, 110][phase - 1]
		mb_dir = (p.position + Vector2(0, 14) - position).normalized()


## Koni isabeti (ayak düzleminde).
func _cone_hit(p: Player, r: float, half: float, dmg: int, debuff: String) -> void:
	var rel := p.position + Vector2(0, 14) - (position + Vector2(0, 6))
	if p.alive() and rel.length() < r + 10.0 and absf(angle_difference(mb_dir.angle(), rel.angle())) < half + 0.08:
		if p.take_damage(dmg, self) and debuff != "":
			p.apply_debuff(debuff)


# ── GÖLGE DOKUYUCU (bölge 2) ──
## İplik dokuma (eller arasında ağ, 0.8 sn tell, sonra 3 iplik hattı); faz 2: üçe bölünür (yalnızca biri gerçek);
## faz 3: gölge havuzuna batar, oyuncunun altından çıkar.
func _dokuyucu_tick(p: Player) -> void:
	var d := position.distance_to(p.position)
	if mb_split > 0:
		mb_split -= 1
	match mb_state:
		"weave":
			if mb_t == 0:
				for a in [-0.3, 0.0, 0.3]:
					var dir := (p.position + Vector2(0, 14) - position).normalized().rotated(a)
					var hz := VoidHazard.new()
					hz.debuff = "slow"
					hz.setup_line("beam", position + Vector2(0, 8), dir, 420.0, int(atk * 0.8))
					hz.t = VoidHazard.BEAM_TELL - 22
					main._spawn(hz, hz.position)
				mb_state = "threads"
				mb_t = 30
			return
		"threads", "split":
			if mb_t == 0:
				mb_state = ""
			return
		"pool":
			# Gölge havuzunda: hedef alınamaz, oyuncunun altına süzülür.
			var to := mb_to - position
			if to.length() > 6.0:
				position = main.world.move_point(position, to.normalized() * minf(4.0, to.length()))
			if mb_t == 0:
				var hz := RiftHazard.new()
				hz.debuff = "slow"
				hz.setup("rift", position + Vector2(0, 8), 54.0, int(atk * 1.1))
				main._spawn(hz, hz.position)
				mb_state = "rise"
				mb_t = RiftHazard.RIFT_TELL
			return
		"rise":
			if mb_t == 0:
				mb_state = ""
			return
	_mb_tick_cds()
	_mb_walk(p, 200.0)
	if not p.alive():
		return
	if phase >= 3 and _mb_cd("pool") == 0:
		mb_state = "pool"
		mb_t = 70
		mb_cds["pool"] = 320
		mb_to = p.position
		main.burst(position + Vector2(0, -20), 50, DK_VIOLET)
	elif phase >= 2 and _mb_cd("split") == 0:
		_dk_split()
	elif _mb_cd("weave") == 0 and d < 440.0:
		mb_state = "weave"
		mb_t = 48
		mb_cds["weave"] = [170, 150, 130][phase - 1]


## Üçe bölünme: Dokuyucu üç noktadan birine geçer, diğer ikisinde gölge kopyası durur (oklar kopyalardan geçer).
func _dk_split() -> void:
	mb_state = "split"
	mb_t = 40
	mb_cds["split"] = 480
	mb_split = 360
	var c := position
	var spots: Array = []
	for a in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
		var at: Vector2 = c + Vector2.from_angle(a + randf()) * 150.0
		spots.append(at if main.world.circle_free(at, 20) else c)
	spots.shuffle()
	position = spots[0]
	mb_copies = [spots[1], spots[2]]
	for s in spots:
		main.burst(s + Vector2(0, -40), 50, DK_VIOLET)


# ── KÖLE EFENDİSİ (bölge 3) ──
## Zincir (başın üstünde döner, 0.7 sn; değerse oyuncuyu çeker); yere vuruş (balta kalkar, şok dalgası);
## faz 2: öfke (hızlanır, 2 goblin çağırır); faz 3: art arda iki vuruş. Ölünce esirler serbest kalır.
func _kole_tick(p: Player) -> void:
	var d := position.distance_to(p.position)
	if mb_pull > 0:
		# Zincire yakalanan oyuncu efendisine sürüklenir (atılırken çekim tutmaz).
		mb_pull -= 1
		var to := position - p.position
		if to.length() > 60.0 and p.dash_left == 0:
			p.position = main.world.move_circle(p.position, to.normalized() * minf(9.0, to.length() - 60.0), Player.RADIUS)
	match mb_state:
		"chaintell":
			_al_flip = mb_dir.x < 0
			if mb_t == 0:
				mb_state = "chain"
				mb_t = 14
				var rel := p.position - position
				var along := rel.dot(mb_dir)
				if p.alive() and along > 0.0 and along < KL_CHAIN + 14.0 and absf(rel.cross(mb_dir)) < 30.0:
					p.take_damage(int(atk * 0.6), self)
					main.float_text(p.position + Vector2(0, -60), "ÇEKİLDİN!", Color(0.85, 0.6, 1.0))
					mb_pull = 30
			return
		"chain":
			if mb_t == 0:
				mb_state = ""
			return
		"slamtell":
			if mb_t == 0:
				var hz := GoblinHazard.new()
				hz.setup("shock", position + Vector2(0, 6), 130.0, int(atk * 1.1))
				main._spawn(hz, hz.position)
				main.shake(14)
				mb_state = "slam"
				mb_t = 26
				if phase >= 3 and not mb_double:
					mb_double = true
					mb_cds["slam"] = 0
			return
		"slam", "rage":
			if mb_t == 0:
				mb_state = ""
			return
	_mb_tick_cds()
	_mb_walk(p, 60.0)
	_mb_melee(p, 76.0, "slow")
	if not p.alive():
		return
	if _mb_cd("slam") == 0 and d < 120.0:
		mb_state = "slamtell"
		mb_t = 44
		mb_cds["slam"] = [190, 160, 130][phase - 1]
		if mb_double and phase >= 3:
			mb_double = false
			mb_cds["slam"] = 10 if randf() < 0.5 else mb_cds["slam"]
	elif _mb_cd("chain") == 0 and d > 110.0 and d < KL_CHAIN:
		mb_state = "chaintell"
		mb_t = 42
		mb_cds["chain"] = [230, 190, 160][phase - 1]
		mb_dir = (p.position - position).normalized()


func _early_phase(n: int) -> void:
	phase = n
	atk = int(base_atk * [1.0, 1.2, 1.45][n - 1])
	speed = base_speed + ([0.0, 0.15, 0.3][n - 1] if base_speed > 0.0 else 0.0)
	flash = 16
	main.shake(16)
	var nm := display_name.split(" — ")[0]
	if is_kardes:
		if n == 2:
			Log.add("%s mührünü uyandırdı! (FAZ 2)" % nm, "death")
			main.float_text(position + Vector2(0, -190), "KIRIK MÜHÜR ULUYOR", KD_BLUE.lightened(0.3))
			mb_cds["howl"] = 30
		else:
			Log.add("%s diz çöktü... yoldaşları geliyor! (FAZ 3)" % nm, "death")
			main.float_text(position + Vector2(0, -190), "\"Kapının önünde kalanlar... gelin!\"", KD_BLUE.lightened(0.3))
			mb_state = "kneel"
			mb_t = 80
			for kind in ["muhafiz_kalkan", "muhafiz_okcu"]:
				var e := main.spawn_enemy(kind, position + Vector2(randf_range(-150, 150), 120))
				if e:
					e.is_minion = true
	elif is_dokuyucu:
		if n == 2:
			Log.add("%s üçe bölündü! (FAZ 2)" % nm, "death")
			main.float_text(position + Vector2(0, -190), "GÖLGELER ÇOĞALIYOR", DK_VIOLET.lightened(0.3))
			mb_cds["split"] = 20
		else:
			Log.add("%s gölge havuzuna gömüldü! (FAZ 3)" % nm, "death")
			main.float_text(position + Vector2(0, -190), "GÖLGE HAVUZU", DK_VIOLET.lightened(0.3))
			mb_cds["pool"] = 30
	else:
		if n == 2:
			Log.add("%s öfkelendi! (FAZ 2)" % nm, "death")
			main.float_text(position + Vector2(0, -190), "ÖFKE!", Color(0.85, 0.55, 1.0))
			mb_state = "rage"
			mb_t = 50
			for i in 2:
				var e := main.spawn_enemy("goblin", position + Vector2(randf_range(-140, 140), 110))
				if e:
					e.is_minion = true
		else:
			Log.add("%s son gücüyle saldırıyor! (FAZ 3)" % nm, "death")
			main.float_text(position + Vector2(0, -190), "SON ÖFKE", Color(0.85, 0.55, 1.0))
			main.hit_freeze(8)


func _early_rest() -> void:
	var r := BossRest.new()
	r.flip = _al_flip
	r.scale_k = mb_scale
	if is_kardes:
		r.key = "boss_z1_peace"
		r.line = "\"Bizi kapının önünde bıraktınız... Ama sen döndün.\""
		r.line_color = Color(0.75, 0.85, 1.0)
	elif is_dokuyucu:
		r.key = "boss_z2_peace"
		r.line = "\"Kitaplarım... ustam onları yaktı.\""
		r.line_color = Color(0.85, 0.75, 1.0)
	else:
		r.key = "boss_z3_defeated"
		r.line = "Esirler serbest!"
		r.line_color = Color(1.0, 0.9, 0.5)
		r.light_color = Color(1.0, 0.8, 0.5)
		# Esirler zincirlerinden kurtulur: arenada iki tutsak belirir.
		for o in [Vector2(-110, 70), Vector2(110, 70)]:
			if main.world.circle_free(position + o, 14):
				var c := Captive.new()
				c.type = ["peasant", "soldier"].pick_random()
				main._spawn(c, position + o)
	main._spawn(r, position)


func _mb_key() -> String:
	var pre := "boss_z1_" if is_kardes else ("boss_z2_" if is_dokuyucu else "boss_z3_")
	match mb_state:
		"sweeptell", "sweep", "howl", "leap", "kneel": return pre + mb_state
		"weave", "threads", "split": return pre + mb_state
		"pool": return pre + "pool"
		"rise": return pre + "threads"
		"chaintell", "chain", "slamtell", "slam", "rage": return pre + mb_state
	return pre + "idle%d" % frame


func _draw_early() -> void:
	var t := Time.get_ticks_msec()
	var air := 0.0
	if mb_state == "leap":
		air = sin((1.0 - float(mb_t) / KD_LEAP) * PI) * 90.0
	draw_set_transform(Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_texture_rect(Atmosphere.puff_texture(), Rect2(-80, -80, 160, 160), false, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO)
	var key := _mb_key()
	var size := MB_CANVAS * mb_scale
	var off := Vector2(0, -air)
	if lunge > 0:
		off += (main.player.position - position).normalized() * (lunge / 12.0) * 6.0
	if is_dokuyucu:
		off.y += sin(t / 500.0) * 4.0 - 10.0
	var b := Rect2(Vector2(-MB_ANCHOR.x * mb_scale, -MB_ANCHOR.y * mb_scale) + off, size)
	if _al_flip:
		b.position.x = -(MB_CANVAS.x - MB_ANCHOR.x) * mb_scale + off.x
	var mod := Color.WHITE
	if flash > 0:
		mod = Color(1.5, 0.85, 0.85)
	_last_key = key
	_last_box = b
	if is_dokuyucu and mb_state == "pool":
		mod.a = 0.35
	Sprites.draw_actor(self, key, b, _al_flip, false, false, mod)
	if is_dokuyucu and mb_split > 0:
		# Gölge kopyaları: biraz daha soluk; dikkatli bakan seçer.
		for c in mb_copies:
			var cb := Rect2(b.position + (c - position), b.size)
			Sprites.draw_actor(self, key, cb, _al_flip, false, false, Color(0.85, 0.8, 1.0, 0.8))


func _paint_early_ground(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var col := KD_BLUE if is_kardes else (DK_VIOLET if is_dokuyucu else Color(0.85, 0.55, 1.0))
	g.draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.4))
	g.glow(Vector2.ZERO, 90.0, Color(col, 0.1 + 0.03 * sin(now * 2.0)))
	g.draw_set_transform(Vector2.ZERO)
	match mb_state:
		"sweeptell":
			var k := 1.0 - float(mb_t) / 54.0
			var blink := 0.75 + 0.25 * sin(now * (8.0 + 16.0 * k))
			var o := Vector2(0, 6)
			var a0 := mb_dir.angle()
			_fan(g, o, a0, KD_HALF, KD_CONE, Color(KD_BLUE, (0.12 + 0.22 * k) * blink), Color(KD_BLUE, 0.03))
			var edge := Color(0.7, 0.8, 1.0, (0.35 + 0.5 * k) * blink)
			g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 - KD_HALF) * KD_CONE]), 1.4, edge)
			g.streak(PackedVector2Array([o, o + Vector2.from_angle(a0 + KD_HALF) * KD_CONE]), 1.4, edge)
			var arc := PackedVector2Array()
			for i in 17:
				arc.append(o + Vector2.from_angle(a0 - KD_HALF + KD_HALF * 2.0 * i / 16.0) * KD_CONE)
			g.streak(arc, 1.6, edge)
		"chaintell":
			var k := 1.0 - float(mb_t) / 42.0
			var blink := 0.75 + 0.25 * sin(now * (8.0 + 14.0 * k))
			for j in 16:
				var u := float(j + 1) / 16
				if u > 0.3 + 0.7 * k:
					break
				g.glow(Vector2(0, -30) + mb_dir * KL_CHAIN * u, 4.0, Color(0.8, 0.5, 1.0, (0.3 + 0.5 * k) * blink))
		"slamtell":
			var k := 1.0 - float(mb_t) / 44.0
			g.draw_set_transform(Vector2(0, 6), 0, Vector2(1, 0.42))
			g.ring(Vector2.ZERO, 130.0 * k, 2.0, Color(0.9, 0.6, 1.0, 0.3 + 0.5 * k))
			g.draw_set_transform(Vector2.ZERO)


func _paint_early_front(g: GlowLayer) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if is_kardes:
		var seal := _mb_local(Vector2(215, 160))
		var k := 1.0 if mb_state == "howl" else 0.4 + 0.15 * sin(now * 2.0)
		g.glow(seal, 12.0 + 18.0 * k, Color(KD_BLUE, 0.3 + 0.3 * k))
	elif is_dokuyucu:
		if mb_state == "weave":
			var k := 1.0 - float(mb_t) / 48.0
			for hp in [Vector2(120, 170), Vector2(300, 170)]:
				g.glow(_mb_local(hp), 10.0 + 16.0 * k, Color(DK_VIOLET, 0.35 + 0.45 * k))
	else:
		if mb_pull > 0:
			var p := main.player
			var n := 14
			for j in n:
				var u := float(j) / n
				g.glow(Vector2(0, -40).lerp(p.position - position + Vector2(0, -20), u), 5.0, Color(0.8, 0.5, 1.0, 0.6))
