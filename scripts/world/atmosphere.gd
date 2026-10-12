class_name Atmosphere
extends Node2D
## Zindanın havası: karanlık sahne (CanvasModulate), duvarlara asılı titreyen meşaleler,
## duvarların düşürdüğü gölgeler, oda eşyaları (heykel, mangal, kemik, zincir, sancak)
## ve yerde süzülen sis. Her katta World.generate'ten sonra build() ile yeniden kurulur.

const AMBIENT := Color(0.12, 0.11, 0.17)
const TORCH_COLOR := Color(1.0, 0.6, 0.28)
## Bölgeye özel ortam rengi; listede olmayan bölge AMBIENT kullanır. Gölge Mağarası soğuk mor,
## Goblin Yurdu lağım zehrinden sarımsı yeşil, Alev Krallığı lavdan sıcak kor turuncusu (kızıl değil; zemin seçilsin).
## Donmuş Tundra soğuk ama okunur buz mavisi (zemin ve düşmanlar seçilsin).
const ZONE_AMBIENT := {2: Color(0.1, 0.085, 0.19), 3: Color(0.12, 0.14, 0.075), 4: Color(0.25, 0.16, 0.115),
	5: Color(0.17, 0.2, 0.27), 6: Color(0.25, 0.24, 0.22),
	7: Color(0.22, 0.19, 0.23), 8: Color(0.3, 0.31, 0.36), 9: Color(0.21, 0.2, 0.27),
	10: Color(0.26, 0.19, 0.18)}
const LAVA_COLOR := Color(1.0, 0.45, 0.12)
const CRYSTAL_COLOR := Color(0.74, 0.55, 1.0)
const POISON_COLOR := Color(0.7, 1.0, 0.2)
const FROST_COLOR := Color(0.55, 0.8, 1.0)
const SPORE_COLOR := Color(0.7, 0.35, 1.0)
const VOID_COLOR := Color(0.65, 0.3, 1.0)
const BLOOD_COLOR := Color(1.0, 0.25, 0.2)
const GOLD_COLOR := Color(1.0, 0.85, 0.5)
const RIFT_COLOR := Color(0.45, 0.95, 1.0)
const HEART_COLOR := Color(1.0, 0.45, 0.2)
const UNSHADED_MAT := preload("res://scripts/world/unshaded.tres")
## Boyalı alevlerin sprite içindeki yerleri (u, v: 0..1) ve büyüklüğü (px).
const FLAMES := {
	"prop_torch": [[Vector2(0.67, 0.22), 9.0]],
	"prop_brazier": [[Vector2(0.5, 0.2), 12.0]],
	"prop_candles": [[Vector2(0.37, 0.22), 4.0], [Vector2(0.13, 0.48), 3.0], [Vector2(0.6, 0.56), 3.0]],
	"prop_z3_pot": [[Vector2(0.47, 0.8), 8.0]],
	"prop_z4_brazier": [[Vector2(0.5, 0.48), 12.0]],
	"prop_z4_block": [[Vector2(0.3, 0.46), 7.0]],
	"prop_z4_anvil": [[Vector2(0.5, 0.1), 5.0]],
}

var world: World
var _modulate: CanvasModulate
var _lights: Array[PointLight2D] = []
var _light_base: Array[float] = []
var _light_slow: Array[bool] = []
## Bölgenin kendi eşya seti varsa önek ("prop_z2_"), yoksa boş: bölge 1 eşyaları kullanılır.
var _cave := ""
## Goblin Yurdu eşya seti (prop_z3_*) varsa önek, yoksa boş.
var _camp := ""
## Alev Krallığı eşya seti (prop_z4_*) varsa önek, yoksa boş.
var _forge := ""
## Donmuş Tundra eşya seti (prop_z5_*) varsa önek, yoksa boş. Anahtar "rune": "crystal" bölge 2'yi tetikler.
var _tundra := ""
## Orman Tapınağı eşya seti (prop_z6_*) varsa önek, yoksa boş. Anahtar "altar".
var _temple := ""
## Şeytan Kalesi eşya seti (prop_z7_*) varsa önek, yoksa boş. Anahtar "lectern".
var _castle := ""
## Gökyüzü Kalesi eşya seti (prop_z8_*) varsa önek, yoksa boş. Anahtar "scales".
var _sky := ""
## Yokluk Alemi eşya seti (prop_z9_*) varsa önek, yoksa boş. Anahtar "stairs".
var _void := ""
## Kara Taht eşya seti (prop_z10_*) varsa önek, yoksa boş. Anahtar "hoard".
var _throne := ""
## Ignis'in infaz kütüğü (kat 40); yoksa INF. Boss'un infaz zinciri oyuncuyu buraya çeker.
var exec_block := Vector2.INF
var _occluders: Node2D
var _mist: CPUParticles2D
static var _light_tex: GradientTexture2D
static var _soft_tex: GradientTexture2D
static var _spark_tex: GradientTexture2D
static var _puff_tex: GradientTexture2D


func _ready() -> void:
	_modulate = CanvasModulate.new()
	_modulate.color = AMBIENT
	add_child(_modulate)
	# Proje varsayılanı piksel (nearest) süzme; sis, kıvılcım ve parıltılar yumuşak süzülsün.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


static func light_texture() -> GradientTexture2D:
	if _light_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.55))
		_light_tex = GradientTexture2D.new()
		_light_tex.gradient = g
		_light_tex.fill = GradientTexture2D.FILL_RADIAL
		_light_tex.fill_from = Vector2(0.5, 0.5)
		_light_tex.fill_to = Vector2(1.0, 0.5)
		_light_tex.width = 256
		_light_tex.height = 256
	return _light_tex


static func soft_texture() -> GradientTexture2D:
	if _soft_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.5))
		g.set_color(1, Color(1, 1, 1, 0))
		_soft_tex = GradientTexture2D.new()
		_soft_tex.gradient = g
		_soft_tex.fill = GradientTexture2D.FILL_RADIAL
		_soft_tex.fill_from = Vector2(0.5, 0.5)
		_soft_tex.fill_to = Vector2(1.0, 0.5)
		_soft_tex.width = 64
		_soft_tex.height = 64
	return _soft_tex


## Kıvılcım / kor tanesi: beyaz-sıcak göbekli, yumuşak kenarlı yuvarlak (piksel kare değil). 32 px; parçacıkta ~0.15-0.3 ölçek.
static func spark_texture() -> GradientTexture2D:
	if _spark_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.18, Color(1, 1, 1, 0.85))
		g.add_point(0.45, Color(1, 1, 1, 0.3))
		_spark_tex = GradientTexture2D.new()
		_spark_tex.gradient = g
		_spark_tex.fill = GradientTexture2D.FILL_RADIAL
		_spark_tex.fill_from = Vector2(0.5, 0.5)
		_spark_tex.fill_to = Vector2(1.0, 0.5)
		_spark_tex.width = 32
		_spark_tex.height = 32
	return _spark_tex


## Duman / is yumağı: dolgun göbek, yumuşak sönen kenar (normal karışımla koyu leke çizmek için).
static func puff_texture() -> GradientTexture2D:
	if _puff_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.4, Color(1, 1, 1, 0.8))
		g.add_point(0.75, Color(1, 1, 1, 0.25))
		_puff_tex = GradientTexture2D.new()
		_puff_tex.gradient = g
		_puff_tex.fill = GradientTexture2D.FILL_RADIAL
		_puff_tex.fill_from = Vector2(0.5, 0.5)
		_puff_tex.fill_to = Vector2(1.0, 0.5)
		_puff_tex.width = 64
		_puff_tex.height = 64
	return _puff_tex


## Yumuşak kıvılcım parçacığı ayarı: yuvarlak dokulu, ömrü boyunca küçülen.
static func soften_sparks(em: CPUParticles2D, size_min: float, size_max: float) -> void:
	em.texture = spark_texture()
	em.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	em.scale_amount_min = size_min / 32.0
	em.scale_amount_max = size_max / 32.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(1, 0.35))
	em.scale_amount_curve = shrink


## Oyuncunun kırık kılıcından yayılan soğuk mavi ışık.
static func make_player_light() -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.texture_scale = 1.45
	l.color = Color(0.62, 0.78, 1.0)
	l.energy = 1.15
	l.shadow_enabled = true
	l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	l.shadow_filter_smooth = 3.0
	l.shadow_color = Color(0, 0, 0, 0.85)
	l.position = Vector2(0, -24)
	return l


func build(entities: Node2D) -> void:
	for c in get_children():
		if c != _modulate:
			c.queue_free()
	_lights.clear()
	_light_base.clear()
	_light_slow.clear()
	exec_block = Vector2.INF
	var pre := "prop_z%d_" % world.zone
	_cave = pre if Sprites.tex(pre + "crystal") != null else ""
	_camp = pre if Sprites.tex(pre + "totem") != null else ""
	_forge = pre if Sprites.tex(pre + "anvil") != null else ""
	_tundra = pre if Sprites.tex(pre + "rune") != null else ""
	_temple = pre if Sprites.tex(pre + "altar") != null else ""
	_castle = pre if Sprites.tex(pre + "lectern") != null else ""
	_sky = pre if Sprites.tex(pre + "scales") != null else ""
	_void = pre if Sprites.tex(pre + "stairs") != null else ""
	_throne = pre if Sprites.tex(pre + "hoard") != null else ""
	_modulate.color = ZONE_AMBIENT.get(world.zone, AMBIENT)
	_build_occluders()
	for i in world.rooms.size():
		_decorate_room(world.rooms[i], entities, i)
	if world.zone == 2 and Game.is_boss_floor():
		# Vaelen'in arenası biraz daha aydınlık: koyu boss koyu zeminde seçilsin.
		_modulate.color = _modulate.color.lightened(0.06)
		_add_light(world.boss_spawn, Color(0.78, 0.66, 1.0), 0.75, 3.2, false, true)
	if _camp != "" and Game.is_boss_floor():
		# Grak'thor'un arenası: ortada soluk zehir ışığı, boss seçilsin.
		_modulate.color = _modulate.color.lightened(0.05)
		_add_light(world.boss_spawn, Color(0.85, 1.0, 0.5), 0.7, 3.2, false, true)
	if _forge != "" and Game.is_boss_floor():
		# Ignis'in infaz sarayı: arena sıcak ışıkla aydınlanır, ortada yanan baltalı infaz kütüğü.
		_modulate.color = _modulate.color.lightened(0.04)
		_add_light(world.boss_spawn, Color(1.0, 0.62, 0.3), 0.7, 3.4, false, true)
		# Kütük boss'un doğduğu yerin sol önünde: dev gövdenin arkasında ya da boss çubuğunun altında kalmasın.
		var bp := world.boss_spawn + Vector2(-World.TILE * 3.0, World.TILE * 1.5)
		_standing_prop(entities, _forge + "block", bp, 70, false)
		_add_light(bp + Vector2(-10, -30), LAVA_COLOR, 1.3, 1.3)
		exec_block = bp
	if _throne != "" and Game.is_boss_floor():
		# Kalp'in odası: ortada kızıl-altın ışık havuzu.
		_modulate.color = _modulate.color.lightened(0.05)
		_add_light(world.boss_spawn, Color(1.0, 0.7, 0.5), 0.7, 3.6, false, true)
	if _void != "" and Game.is_boss_floor():
		# Nihil'in platformu: soğuk camgöbeği ve mor ışık havuzu.
		_modulate.color = _modulate.color.lightened(0.05)
		_add_light(world.boss_spawn, Color(0.7, 0.8, 1.0), 0.6, 3.4, false, true)
	if _sky != "" and Game.is_boss_floor():
		# Valerius'un yargı salonu: soluk altın-beyaz gün ışığı.
		_modulate.color = _modulate.color.lightened(0.04)
		_add_light(world.boss_spawn, Color(1.0, 0.95, 0.85), 0.55, 3.4, false, true)
	if _castle != "" and Game.is_boss_floor():
		# Malakor'un arenası: kuzeydeki yokluk portalının mor ışığı ve ortada soluk dolgu ışığı.
		_modulate.color = _modulate.color.lightened(0.05)
		_add_light(world.boss_spawn, Color(0.85, 0.75, 1.0), 0.6, 3.4, false, true)
	if _temple != "" and Game.is_boss_floor():
		# Lyra'nın arenası: Hayat Ağacı'nın çevresinde soluk mor-yeşil ışık havuzu (Kutsal Taşlar Main'de kurulur).
		_modulate.color = _modulate.color.lightened(0.05)
		_add_light(world.boss_spawn, Color(0.8, 0.7, 1.0), 0.7, 3.4, false, true)
	if _tundra != "" and Game.is_boss_floor():
		# Kral Alden'ın taht salonu: soğuk mavi ışık havuzu; kandiller (FrostHazard) Main'de kurulur.
		_modulate.color = _modulate.color.lightened(0.05)
		_add_light(world.boss_spawn, Color(0.7, 0.88, 1.0), 0.75, 3.4, false, true)
	_build_mist()


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for i in _lights.size():
		var l := _lights[i]
		if is_instance_valid(l):
			var k := sin(t * 9.0 + i * 1.7) * 0.06 + sin(t * 23.0 + i * 3.1) * 0.04
			if _light_slow[i]:
				# Kristaller titremez, yavaşça nefes alır.
				k = sin(t * 1.1 + i * 2.3) * 0.12
			l.energy = _light_base[i] * (1.0 + k)


## Ignis'in Hüküm fazı: arenadaki mangal ve meşale ışıkları alevlenir (enerji ve yarıçap büyür).
## Alevlenen ışıkların konumlarını döndürür (kıvılcım patlaması için).
func ignite_braziers(center: Vector2, radius: float, mult := 1.7) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in _lights.size():
		var l := _lights[i]
		if is_instance_valid(l) and l.color == TORCH_COLOR and l.position.distance_to(center) < radius:
			_light_base[i] *= mult
			l.texture_scale *= 1.3
			out.append(l.position)
	return out


# ── Gölge düşüren duvarlar ───────────────────────────────────────────

## Zemine komşu her duvar karosu bir gölge kutusu olur. Ön yüzü görünen (altı zemin olan)
## duvarlar hariç: onlar ışığı alır, yoksa meşale kendi duvarını karartırdı.
func _build_occluders() -> void:
	_occluders = Node2D.new()
	add_child(_occluders)
	var t := float(World.TILE)
	for y in world.height:
		for x in world.width:
			if world.get_tile(x, y) != World.WALL or is_face(x, y):
				continue
			var near := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
				if world.get_tile(x + d.x, y + d.y) != World.WALL:
					near = true
			if not near:
				continue
			var o := LightOccluder2D.new()
			var poly := OccluderPolygon2D.new()
			poly.polygon = PackedVector2Array([Vector2(0, 0), Vector2(t, 0), Vector2(t, t), Vector2(0, t)])
			o.occluder = poly
			o.position = Vector2(x, y) * t
			_occluders.add_child(o)


func is_face(x: int, y: int) -> bool:
	return world.get_tile(x, y) == World.WALL and world.get_tile(x, y + 1) != World.WALL


# ── Oda eşyaları ─────────────────────────────────────────────────────

func _decorate_room(r: Rect2i, entities: Node2D, index: int) -> void:
	if _cave != "":
		_decorate_cave(r, entities)
		return
	if _camp != "":
		_decorate_camp(r, entities)
		return
	if _forge != "":
		_decorate_forge(r, entities)
		return
	if _tundra != "":
		_decorate_tundra(r, entities)
		return
	if _temple != "":
		_decorate_temple(r, entities)
		return
	if _castle != "":
		_decorate_castle(r, entities)
		return
	if _sky != "":
		_decorate_sky(r, entities)
		return
	if _void != "":
		_decorate_void(r, entities)
		return
	if _throne != "":
		_decorate_throne(r, entities)
		return
	var t := float(World.TILE)
	var top := r.position.y - 1
	# Üst duvarın ön yüzüne meşaleler, aralarına sancak ya da zincir.
	var xs: Array[int] = []
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			xs.append(x)
		x += 3
	for i in xs.size():
		var p := Vector2(xs[i] * t + t / 2, top * t + t * 0.55)
		if i % 2 == 0:
			_wall_prop("prop_torch", p, 40)
			_add_light(p + Vector2(0, 30), TORCH_COLOR, 1.7, 1.5)
		else:
			_wall_prop("prop_banner" if randf() < 0.6 else "prop_chains", p, 44)
	# Köşelerde başsız muhafız heykelleri ve mangallar.
	var corners := [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y)]
	for c in corners:
		if randf() < 0.55:
			var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			if randf() < 0.6:
				_standing_prop(entities, "prop_statue", cp, 92, c.x != r.position.x)
			else:
				_standing_prop(entities, "prop_brazier", cp, 56, false)
				_add_light(cp + Vector2(0, -22), TORCH_COLOR, 1.6, 1.4)
	# Büyük salonlarda (boss arenası gibi) içeride dört mangal: ortada ışık havuzları oluşsun.
	if r.size.x >= 9 and r.size.y >= 9:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			var bp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			_standing_prop(entities, "prop_brazier", bp, 56, false)
			_add_light(bp + Vector2(0, -22), TORCH_COLOR, 1.6, 1.5)
	# Yerde kemik, moloz, mum.
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var key: String = ["prop_bones", "prop_rubble", "prop_bones", "prop_candles"].pick_random()
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if key == "prop_candles":
			_standing_prop(entities, key, pos, 30, false)
			_add_light(pos + Vector2(0, -12), Color(1.0, 0.75, 0.4), 0.7, 0.7, false)
		else:
			_floor_prop(key, pos, 40, randf() < 0.5)


## Mağara bölgesi: az meşale, çok kristal ışığı; heykel/mangal yerine kristal ve sarkıt,
## yerde kemik/mum yerine tarikat kalıntısı, maden arabası ve gölge kuyusu.
func _decorate_cave(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var p := Vector2(x * t + t / 2, top * t + t * 0.55)
			if slot % 4 == 0:
				_wall_prop("prop_torch", p, 40)
				_add_light(p + Vector2(0, 30), TORCH_COLOR, 1.3, 1.2)
			elif randf() < 0.55:
				_crystal(entities, Vector2(p.x + randf_range(-8, 8), r.position.y * t + t * 0.7), randf_range(30, 40), randf() < 0.5)
			elif randf() < 0.4:
				var bp := Vector2(p.x, r.position.y * t + t * 0.75)
				_standing_prop(entities, _cave + "beam", bp, 92, randf() < 0.5)
				_add_light(bp + Vector2(0, -50), CRYSTAL_COLOR, 0.8, 0.7, false, true)
			slot += 1
		x += 3
	# Köşelerde kristal kümeleri, kristal sütunlar ve sarkıtlar.
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if randf() < 0.6:
			var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			var roll := randf()
			if roll < 0.45:
				_crystal(entities, cp, 60, c.x != r.position.x)
			elif roll < 0.75:
				_standing_prop(entities, _cave + "spire", cp, 82, c.x != r.position.x)
				_add_light(cp + Vector2(0, -40), CRYSTAL_COLOR, 1.3, 1.25, true, true)
			else:
				_standing_prop(entities, _cave + "stalagmite", cp, 76, c.x != r.position.x)
	# Büyük salonlarda (boss arenası) mangal yerine dört kristal küme.
	if r.size.x >= 9 and r.size.y >= 9:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			_crystal(entities, Vector2(c.x * t + t / 2, c.y * t + t * 0.8), 66, c.x > r.position.x + 4)
	# Yerde tarikat kalıntısı, küçük kristaller, ara sıra maden arabası; odada en fazla bir gölge kuyusu.
	var well := r.size.x >= 6 and r.size.y >= 6 and randf() < 0.35
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if well:
			well = false
			_shadow_well(Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) * t + Vector2(t / 2, t / 2))
			continue
		var roll := randf()
		if roll < 0.45:
			_floor_prop(_cave + "cult", pos, 40, randf() < 0.5)
		elif roll < 0.8:
			_crystal(entities, pos, randf_range(24, 32), randf() < 0.5)
		elif roll < 0.92:
			_standing_prop(entities, _cave + "cart", pos, 52, randf() < 0.5)
		else:
			_floor_prop("prop_bones", pos, 36, randf() < 0.5)


## Goblin Yurdu: üst duvarda meşaleler arasında asılı esir kafesleri ve kemik totemleri; köşelerde çadır,
## kazık barikat, kafes; büyük salonlarda kaynayan kazanlar; yerde zehir gölü (sarı-yeşil ışık), Aetherium
## arabası ve kemikler.
func _decorate_camp(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var p := Vector2(x * t + t / 2, top * t + t * 0.55)
			var bp := Vector2(p.x + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_wall_prop("prop_torch", p, 40)
				_add_light(p + Vector2(0, 30), TORCH_COLOR, 1.5, 1.35)
			elif randf() < 0.5:
				_standing_prop(entities, _camp + "cage", bp, 84, randf() < 0.5)
			elif randf() < 0.6:
				_totem(entities, bp, 70, randf() < 0.5)
			slot += 1
		x += 3
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if randf() < 0.6:
			var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			var flip: bool = c.x != r.position.x
			var roll := randf()
			if roll < 0.3:
				_standing_prop(entities, _camp + "tent", cp + Vector2(-20.0 if flip else 20.0, 0), 66, flip)
			elif roll < 0.55:
				_standing_prop(entities, _camp + "barricade", cp, 52, flip)
			elif roll < 0.8:
				_standing_prop(entities, _camp + "cage", cp, 84, flip)
			else:
				_totem(entities, cp, 72, flip)
	if r.size.x >= 9 and r.size.y >= 9:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			var pp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			_standing_prop(entities, _camp + "pot", pp, 58, c.x > r.position.x + 4)
			_add_light(pp + Vector2(0, -10), TORCH_COLOR, 1.5, 1.4)
	var pool := r.size.x >= 6 and r.size.y >= 6 and randf() < 0.5
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if pool:
			pool = false
			_poison_pool(Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) * t + Vector2(t / 2, t / 2))
			continue
		var roll := randf()
		if roll < 0.4:
			_floor_prop("prop_bones", pos, 38, randf() < 0.5)
		elif roll < 0.6:
			_standing_prop(entities, _camp + "cart", pos, 50, randf() < 0.5)
			_add_light(pos + Vector2(0, -30), CRYSTAL_COLOR, 0.6, 0.5, false, true)
		elif roll < 0.8:
			_standing_prop(entities, _camp + "pot", pos, 50, randf() < 0.5)
			_add_light(pos + Vector2(0, -8), TORCH_COLOR, 1.2, 1.1, false)
		else:
			_floor_prop("prop_rubble", pos, 40, randf() < 0.5)


## Alev Krallığı: üst duvarda meşaleler arasında zincirli mangallar ve magma sütunları; köşelerde obsidyen
## sivri kaya, infaz kütüğü, örs, magma sütunu; büyük salonlarda dört zincirli mangal; yerde lav damarları
## (yalnızca süs, yolu kapatmaz), lav gölü, köz yığını ve yanık kemikler.
func _decorate_forge(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var p := Vector2(x * t + t / 2, top * t + t * 0.55)
			var bp := Vector2(p.x + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_wall_prop("prop_torch", p, 40)
				_add_light(p + Vector2(0, 30), TORCH_COLOR, 1.5, 1.35)
			elif randf() < 0.45:
				_standing_prop(entities, _forge + "brazier", bp, 74, randf() < 0.5)
				_add_light(bp + Vector2(0, -36), TORCH_COLOR, 1.4, 1.3)
			elif randf() < 0.5:
				_magma_pillar(entities, bp, 86, randf() < 0.5)
			slot += 1
		x += 3
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if randf() < 0.6:
			var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			var flip: bool = c.x != r.position.x
			var roll := randf()
			if roll < 0.3:
				_standing_prop(entities, _forge + "spire", cp, 82, flip)
				_add_light(cp + Vector2(0, -30), LAVA_COLOR, 0.6, 0.6, false)
			elif roll < 0.5:
				_standing_prop(entities, _forge + "block", cp, 60, flip)
			elif roll < 0.75:
				_standing_prop(entities, _forge + "anvil", cp, 58, flip)
				_add_light(cp + Vector2(0, -50), LAVA_COLOR, 0.7, 0.6, false)
			else:
				_magma_pillar(entities, cp, 84, flip)
	if r.size.x >= 9 and r.size.y >= 9:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			var pp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			_standing_prop(entities, _forge + "brazier", pp, 76, c.x > r.position.x + 4)
			_add_light(pp + Vector2(0, -36), TORCH_COLOR, 1.6, 1.5)
	# Lav damarları: odada 1-2 parlayan çatlak (yalnızca süs).
	for _n in randi_range(1, 2):
		var sp := Vector2(randf_range(r.position.x + 1, r.end.x - 1), randf_range(r.position.y + 1.5, r.end.y - 0.5)) * t
		_lava_seam(sp, randf_range(60, 130), randf() * TAU)
	var pool := r.size.x >= 6 and r.size.y >= 6 and randf() < 0.45
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if pool:
			pool = false
			_lava_pool(Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) * t + Vector2(t / 2, t / 2))
			continue
		var roll := randf()
		if roll < 0.35:
			_floor_prop(_forge + "bones", pos, 40, randf() < 0.5)
		elif roll < 0.65:
			_embers(pos)
		else:
			_floor_prop("prop_rubble", pos, 40, randf() < 0.5)


## Donmuş Tundra: üst duvarda meşaleler arasında kırağılı kütüphane rafları ve buz sütunları; köşelerde içinde
## donmuş insan silueti olan buz blokları, buz kristalleri, kırık sütun ve soğuk rün kandilleri; büyük salonlarda
## dört rün taşı (yavaş nefes alan mavi ışık); yerde donmuş göl, kar altında kılıçlı mezarlar ve moloz.
func _decorate_tundra(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var p := Vector2(x * t + t / 2, top * t + t * 0.55)
			var bp := Vector2(p.x + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_wall_prop("prop_torch", p, 40)
				_add_light(p + Vector2(0, 30), TORCH_COLOR, 1.2, 1.2)
			elif randf() < 0.45:
				_standing_prop(entities, _tundra + "shelf", bp, 70, randf() < 0.5)
			elif randf() < 0.55:
				_standing_prop(entities, _tundra + "pillar", bp, 92, randf() < 0.5)
			slot += 1
		x += 3
	var boss_room := Game.is_boss_floor() and r.has_point(Vector2i(world.boss_spawn / t))
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if boss_room or randf() > 0.6:
			continue
		var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
		var flip: bool = c.x != r.position.x
		var roll := randf()
		if roll < 0.3:
			_ice_glow_prop(entities, "frozen", cp, 82, flip, 0.55)
		elif roll < 0.55:
			_ice_glow_prop(entities, "ice", cp, 76, flip, 0.8)
		elif roll < 0.75:
			_standing_prop(entities, _tundra + "pillar", cp, 88, flip)
		else:
			_cold_lantern(entities, cp, flip)
	if r.size.x >= 9 and r.size.y >= 9:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			var rp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
			if boss_room:
				# Taht salonunun köşelerinde kandiller (Main kurar); rün taşları biraz içeride, yanlarda.
				rp += Vector2(t * 2.0 * (1.0 if c.x < r.get_center().x else -1.0), 0)
			_rune_stone(entities, rp, 70, c.x > r.position.x + 4)
	var pool := r.size.x >= 6 and r.size.y >= 6 and randf() < 0.45 and not boss_room
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if pool:
			pool = false
			_frozen_pool(Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) * t + Vector2(t / 2, t / 2))
			continue
		var roll := randf()
		if roll < 0.4:
			_standing_prop(entities, _tundra + "grave", pos, 46, randf() < 0.5)
		elif roll < 0.65:
			_ice_glow_prop(entities, "ice", pos, 44, randf() < 0.5, 0.45)
		else:
			_floor_prop("prop_rubble", pos, 38, randf() < 0.5)


## Orman Tapınağı: üst duvarda meşaleler arasında sarkan sarmaşık perdeleri ve kök sarılı sütunlar; köşelerde
## sarmaşıklı rahibe heykeli, kök yığını, dev mantar kümesi (mor ışık), sunak; yerde zehirli kutsal pınar ve kökler.
func _decorate_temple(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var p := Vector2(x * t + t / 2, top * t + t * 0.55)
			var bp := Vector2(p.x + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_wall_prop("prop_torch", p, 40)
				_add_light(p + Vector2(0, 30), TORCH_COLOR, 1.3, 1.25)
			elif randf() < 0.5:
				_wall_prop(_temple + "vine", p + Vector2(0, 14), 56)
			elif randf() < 0.55:
				_standing_prop(entities, _temple + "pillar", bp, 92, randf() < 0.5)
			slot += 1
		x += 3
	var boss_room := Game.is_boss_floor() and r.has_point(Vector2i(world.boss_spawn / t))
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if boss_room or randf() > 0.6:
			continue
		var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
		var flip: bool = c.x != r.position.x
		var roll := randf()
		if roll < 0.3:
			_standing_prop(entities, _temple + "statue", cp, 84, flip)
		elif roll < 0.55:
			_standing_prop(entities, _temple + "roots", cp, 70, flip)
		elif roll < 0.8:
			_shrooms(entities, cp, 74, flip)
		else:
			_standing_prop(entities, _temple + "altar", cp, 50, flip)
	if r.size.x >= 9 and r.size.y >= 9 and not boss_room:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			_shrooms(entities, Vector2(c.x * t + t / 2, c.y * t + t * 0.8), 66, c.x > r.position.x + 4)
	var pool := r.size.x >= 6 and r.size.y >= 6 and randf() < 0.45 and not boss_room
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if pool:
			pool = false
			_spring(Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) * t + Vector2(t / 2, t / 2))
			continue
		var roll := randf()
		if roll < 0.45:
			_standing_prop(entities, _temple + "roots", pos, 44, randf() < 0.5)
		elif roll < 0.7:
			_shrooms(entities, pos, 40, randf() < 0.5)
		else:
			_floor_prop("prop_rubble", pos, 38, randf() < 0.5)


## Şeytan Kalesi: üst duvarda meşaleler arasında iblis sancakları ve mor alevli mangallar; köşelerde işkence kafesi,
## zincirli sütun, kan yazılı isim kitabı, kafatası ve mum yığını; büyük salonlarda dört mor mangal; yerde küçük yokluk
## portalları (mor nabız) ve kafatasları.
func _decorate_castle(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var p := Vector2(x * t + t / 2, top * t + t * 0.55)
			var bp := Vector2(p.x + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_wall_prop("prop_torch", p, 40)
				_add_light(p + Vector2(0, 30), TORCH_COLOR, 1.25, 1.25)
			elif randf() < 0.5:
				_standing_prop(entities, _castle + "banner", bp, 88, randf() < 0.5)
			elif randf() < 0.6:
				_void_brazier(entities, bp, 78, randf() < 0.5)
			slot += 1
		x += 3
	var boss_room := Game.is_boss_floor() and r.has_point(Vector2i(world.boss_spawn / t))
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if boss_room or randf() > 0.6:
			continue
		var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
		var flip: bool = c.x != r.position.x
		var roll := randf()
		if roll < 0.25:
			_standing_prop(entities, _castle + "cage", cp, 86, flip)
		elif roll < 0.5:
			_standing_prop(entities, _castle + "pillar", cp, 90, flip)
		elif roll < 0.75:
			_standing_prop(entities, _castle + "lectern", cp, 62, flip)
			_add_light(cp + Vector2(0, -40), BLOOD_COLOR, 0.45, 0.6, false, true)
		else:
			_skulls(entities, cp, 50, flip)
	if r.size.x >= 9 and r.size.y >= 9 and not boss_room:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			_void_brazier(entities, Vector2(c.x * t + t / 2, c.y * t + t * 0.8), 80, c.x > r.position.x + 4)
	var portal := r.size.x >= 6 and r.size.y >= 6 and randf() < 0.4 and not boss_room
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if portal:
			portal = false
			_floor_portal(Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) * t + Vector2(t / 2, t / 2))
			continue
		if randf() < 0.55:
			_skulls(entities, pos, 34, randf() < 0.5)
		else:
			_floor_prop("prop_rubble", pos, 38, randf() < 0.5)


## Gökyüzü Kalesi: üst duvarda altın alevli mangallar ve rün sütunları; köşelerde bilge heykeli, yargıç kürsüsü,
## adalet terazisi, kanun tabletleri; büyük salonlarda dört altın mangal; yerde havada süzülen yerçekimi taşları ve
## bulut sisine gömülmüş kırık korkuluklar.
func _decorate_sky(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var p := Vector2(x * t + t / 2, top * t + t * 0.55)
			var bp := Vector2(p.x + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_gold_brazier(entities, bp, 70, randf() < 0.5)
			elif randf() < 0.6:
				_standing_prop(entities, _sky + "pillar", bp, 92, randf() < 0.5)
				_add_light(bp + Vector2(0, -50), GOLD_COLOR, 0.45, 0.6, false, true)
			slot += 1
		x += 3
	var boss_room := Game.is_boss_floor() and r.has_point(Vector2i(world.boss_spawn / t))
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if boss_room or randf() > 0.6:
			continue
		var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
		var flip: bool = c.x != r.position.x
		var roll := randf()
		if roll < 0.25:
			_standing_prop(entities, _sky + "statue", cp, 82, flip)
		elif roll < 0.5:
			_standing_prop(entities, _sky + "seat", cp, 80, flip)
		elif roll < 0.75:
			_standing_prop(entities, _sky + "scales", cp, 72, flip)
			_add_light(cp + Vector2(0, -50), GOLD_COLOR, 0.4, 0.5, false, true)
		else:
			_standing_prop(entities, _sky + "tablets", cp, 62, flip)
			_add_light(cp + Vector2(0, -40), GOLD_COLOR, 0.5, 0.6, false, true)
	if r.size.x >= 9 and r.size.y >= 9:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			_gold_brazier(entities, Vector2(c.x * t + t / 2, c.y * t + t * 0.8), 72, c.x > r.position.x + 4)
	for _n in randi_range(1, 3):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if boss_room:
			continue
		if randf() < 0.5:
			_standing_prop(entities, _sky + "gravstone", pos, 70, randf() < 0.5)
			_add_light(pos + Vector2(0, -6), GOLD_COLOR, 0.6, 0.6, false, true)
		else:
			_standing_prop(entities, _sky + "balustrade", pos, 48, randf() < 0.5)


## Yokluk Alemi: üst duvar boyunca havada asılı yırtıklar ve ayna parçaları; köşelerde bükülmüş kemer, ters dönmüş
## süzülen sütun, hiçbir yere çıkmayan merdiven, süzülen kayalar; yerde ayna kırıkları ve küçük boşluk havuzları.
func _decorate_void(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var bp := Vector2(x * t + t / 2 + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_rift_tear(entities, bp, 74)
			elif randf() < 0.6:
				_standing_prop(entities, _void + "mirror", bp, 86, randf() < 0.5)
				_add_light(bp + Vector2(0, -40), Color(0.75, 0.6, 1.0), 0.4, 0.6, false, true)
			slot += 1
		x += 3
	var boss_room := Game.is_boss_floor() and r.has_point(Vector2i(world.boss_spawn / t))
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if boss_room or randf() > 0.6:
			continue
		var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
		var flip: bool = c.x != r.position.x
		var roll := randf()
		if roll < 0.25:
			_standing_prop(entities, _void + "arch", cp, 86, flip)
		elif roll < 0.5:
			_standing_prop(entities, _void + "pillar", cp, 88, flip)
		elif roll < 0.75:
			_standing_prop(entities, _void + "stairs", cp, 80, flip)
		else:
			_standing_prop(entities, _void + "floatrocks", cp, 78, flip)
			_add_light(cp + Vector2(0, -10), RIFT_COLOR, 0.6, 0.6, false, true)
	if r.size.x >= 9 and r.size.y >= 9 and not boss_room:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.end.y - 3)]:
			_rift_tear(entities, Vector2(c.x * t + t / 2, c.y * t + t * 0.8), 70)
	var pool := r.size.x >= 6 and r.size.y >= 6 and randf() < 0.45 and not boss_room
	for _n in randi_range(2, 4):
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if pool:
			pool = false
			var pp := Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) * t + Vector2(t / 2, t / 2)
			var s := _sprite(_void + "pool", 58)
			if s:
				s.position = pp
				add_child(s)
				_add_light(pp, Color(0.6, 0.35, 1.0), 0.8, 1.0, false, true)
			continue
		_standing_prop(entities, _void + "shards", pos, 34, randf() < 0.5)


## Kara Taht: üst duvarda kızıl ateşli mangallar ve kristal taçlı sancaklar; köşelerde ejder sütunu, ejder kafatası,
## altın yığını, kristal kümesi; büyük salonlarda dört mangal; yerde kırık ejder yumurtaları ve mor kristaller.
func _decorate_throne(r: Rect2i, entities: Node2D) -> void:
	var t := float(World.TILE)
	var top := r.position.y - 1
	var slot := 0
	var x := r.position.x + 1
	while x < r.end.x - 1:
		if is_face(x, top):
			var bp := Vector2(x * t + t / 2 + randf_range(-6, 6), r.position.y * t + t * 0.75)
			if slot % 3 == 0:
				_heart_brazier(entities, bp, 74, randf() < 0.5)
			elif randf() < 0.6:
				_standing_prop(entities, _throne + "banner", bp, 88, randf() < 0.5)
			slot += 1
		x += 3
	var boss_room := Game.is_boss_floor() and r.has_point(Vector2i(world.boss_spawn / t))
	for c in [Vector2i(r.position.x, r.position.y), Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]:
		if boss_room or randf() > 0.6:
			continue
		var cp := Vector2(c.x * t + t / 2, c.y * t + t * 0.8)
		var flip: bool = c.x != r.position.x
		var roll := randf()
		if roll < 0.25:
			_standing_prop(entities, _throne + "pillar", cp, 92, flip)
			_add_light(cp + Vector2(0, -50), HEART_COLOR, 0.45, 0.6, false, true)
		elif roll < 0.5:
			_standing_prop(entities, _throne + "skull", cp, 70, flip)
		elif roll < 0.75:
			_standing_prop(entities, _throne + "hoard", cp, 56, flip)
			_add_light(cp + Vector2(0, -20), Color(1.0, 0.85, 0.45), 0.45, 0.55, false, true)
		else:
			_standing_prop(entities, _throne + "crystals", cp, 74, flip)
			_add_light(cp + Vector2(0, -36), Color(0.72, 0.32, 1.0), 0.7, 0.8, false, true)
	if r.size.x >= 9 and r.size.y >= 9:
		for c in [Vector2i(r.position.x + 2, r.position.y + 2), Vector2i(r.end.x - 3, r.position.y + 2),
				Vector2i(r.position.x + 2, r.end.y - 3), Vector2i(r.end.x - 3, r.end.y - 3)]:
			_heart_brazier(entities, Vector2(c.x * t + t / 2, c.y * t + t * 0.8), 72, c.x > r.position.x + 4)
	for _n in randi_range(1, 3):
		if boss_room:
			break
		var tp := Vector2(randi_range(r.position.x, r.end.x - 1), randi_range(r.position.y + 1, r.end.y - 1))
		var pos := tp * t + Vector2(randf_range(8, t - 8), randf_range(14, t - 4))
		if randf() < 0.5:
			_standing_prop(entities, _throne + "egg", pos, 46, randf() < 0.5)
			_add_light(pos + Vector2(0, -12), HEART_COLOR, 0.6, 0.55, false)
		else:
			_standing_prop(entities, _throne + "crystals", pos, 40, randf() < 0.5)
			_add_light(pos + Vector2(0, -18), Color(0.72, 0.32, 1.0), 0.5, 0.5, false, true)


## Kalp ateşli mangal: titreyen kızıl-altın ışık.
func _heart_brazier(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _throne + "brazier", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.85), HEART_COLOR, 1.2, 1.25)


## Havada asılı camgöbeği yırtık: yavaş nabız atan, titremeyen ışık.
func _rift_tear(entities: Node2D, pos: Vector2, h: float) -> void:
	_standing_prop(entities, _void + "tear", pos, h, false)
	_add_light(pos + Vector2(0, -h * 0.5), RIFT_COLOR, 0.9, 0.95, false, true)


## Altın-beyaz alevli mangal: sıcak, hafif titreyen ışık.
func _gold_brazier(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _sky + "brazier", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.85), GOLD_COLOR, 1.1, 1.2)


## Mor yokluk alevli demir mangal: titremeyen, yavaş nabız atan mor ışık.
func _void_brazier(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _castle + "brazier", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.8), VOID_COLOR, 1.1, 1.15, false, true)


## Kafatası ve mum yığını: mumların kırmızı-mor küçük ışığı.
func _skulls(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _castle + "skulls", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.6), Color(1.0, 0.45, 0.35), 0.6, 0.55, false)


## Yerde küçük yokluk portalı (boyalı ışın efektiyle aynı halka): yavaş nabız atan mor ışık, yolu kapatmaz.
func _floor_portal(pos: Vector2) -> void:
	var tex := Sprites.tex("fx_void_portal")
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.scale = Vector2.ONE * 70.0 / tex.get_width()
	s.position = pos
	add_child(s)
	var g := GlowLayer.make(_paint_portal.bind(randf() * TAU))
	g.position = pos
	add_child(g)
	_add_light(pos, VOID_COLOR, 0.9, 1.0, false, true)


func _paint_portal(g: GlowLayer, seed: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 1.7 + seed)
	g.draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.45))
	g.glow(Vector2.ZERO, 34.0 + 4.0 * k, Color(0.6, 0.25, 1.0, 0.14 + 0.1 * k))
	g.draw_set_transform(Vector2.ZERO)


## Dev mantar kümesi: beneklerinden soluk mor ışık (titremez, yavaş nefes alır).
func _shrooms(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _temple + "shroom", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.55), SPORE_COLOR, 0.55 + h / 160.0, 0.5 + h / 100.0, false, true)


## Zehirli kutsal pınar: yere yatık, mor nabız atan su (yolu kapatmaz).
func _spring(pos: Vector2) -> void:
	var s := _sprite(_temple + "pool", 62)
	if s == null:
		return
	s.position = pos
	add_child(s)
	var g := GlowLayer.make(_paint_spring.bind(randf() * TAU))
	g.position = pos
	add_child(g)
	_add_light(pos, SPORE_COLOR, 0.9, 1.1, false, true)


func _paint_spring(g: GlowLayer, seed: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 1.3 + seed)
	g.glow(Vector2(0, 4), 34.0 + 4.0 * k, Color(0.6, 0.3, 1.0, 0.12 + 0.1 * k))
	g.glow(Vector2(0, 2), 12.0, Color(0.85, 0.65, 1.0, 0.1 + 0.1 * k))


## Buz kristali / içinde donmuş insan olan buz bloğu: içinden soğuk, titremeyen mavi ışık.
func _ice_glow_prop(entities: Node2D, kind: String, pos: Vector2, h: float, flip: bool, energy: float) -> void:
	_standing_prop(entities, _tundra + kind, pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.45), FROST_COLOR, energy, 0.5 + h / 90.0, false, true)


## Süs kandili (boss kandilinden farklı, vurulamaz): asılı fenerde soğuk mavi alev.
func _cold_lantern(entities: Node2D, pos: Vector2, flip: bool) -> void:
	_standing_prop(entities, _tundra + "lantern", pos, 84, flip)
	var head := pos + Vector2((-12.0 if flip else 12.0), -84 * 0.56)
	_add_light(head, FROST_COLOR, 0.9, 0.9, false, true)
	var g := GlowLayer.make(_paint_cold_flame.bind(randf() * TAU))
	g.position = head
	add_child(g)


func _paint_cold_flame(g: GlowLayer, seed: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 1.4 + seed)
	g.glow(Vector2.ZERO, 16.0 + 3.0 * k, Color(FROST_COLOR, 0.28 + 0.1 * k))
	g.glow(Vector2.ZERO, 5.0, Color(0.9, 0.97, 1.0, 0.5))


## Rün taşı: oyulmuş rün halkası yavaşça mavi nefes alır.
func _rune_stone(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _tundra + "rune", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.5), FROST_COLOR, 0.9, 1.0, false, true)
	var g := GlowLayer.make(_paint_rune.bind(randf() * TAU, h))
	g.position = pos + Vector2(2, -h * 0.52)
	add_child(g)


func _paint_rune(g: GlowLayer, seed: float, h: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 1.1 + seed)
	g.glow(Vector2.ZERO, h * 0.32 + 4.0 * k, Color(FROST_COLOR, 0.12 + 0.12 * k))
	g.glow(Vector2.ZERO, h * 0.1, Color(0.85, 0.95, 1.0, 0.15 + 0.15 * k))


## Donmuş göl: yere yatık buz, çatlaklarında soğuk ışık nabzı (yolu kapatmaz).
func _frozen_pool(pos: Vector2) -> void:
	var s := _sprite(_tundra + "pool", 56)
	if s == null:
		return
	s.position = pos
	add_child(s)
	var g := GlowLayer.make(_paint_ice_pool.bind(randf() * TAU))
	g.position = pos
	add_child(g)
	_add_light(pos, FROST_COLOR, 0.9, 1.1, false, true)


func _paint_ice_pool(g: GlowLayer, seed: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 1.2 + seed)
	g.glow(Vector2(0, 2), 34.0 + 4.0 * k, Color(0.5, 0.8, 1.0, 0.1 + 0.1 * k))
	g.glow(Vector2(-6, 0), 12.0, Color(0.9, 0.97, 1.0, 0.08 + 0.1 * k))


## Magma sütunu: çatlaklarından lav akan bazalt; çatlak boyunca titreyen turuncu ışık.
func _magma_pillar(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _forge + "pillar", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.5), LAVA_COLOR, 1.0, 0.9, false)


## Köz yığını: yere yatık, nabız gibi parlayan közler ve yükselen kıvılcımlar.
func _embers(pos: Vector2) -> void:
	var s := _sprite(_forge + "embers", 26)
	if s == null:
		return
	s.position = pos
	s.flip_h = randf() < 0.5
	add_child(s)
	var g := GlowLayer.make(_paint_embers.bind(randf() * TAU))
	g.position = pos
	add_child(g)
	g.add_child(_spark_emitter(10.0, 4))
	_add_light(pos, LAVA_COLOR, 0.7, 0.6, false)


func _paint_embers(g: GlowLayer, seed: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 2.3 + seed)
	g.glow(Vector2(0, -2), 22.0 + 4.0 * k, Color(1.0, 0.4, 0.08, 0.14 + 0.12 * k))


## Lav gölü: yere yatık lav kanalı, titreyen parlak göbek ve sıcak ışık (yolu kapatmaz).
func _lava_pool(pos: Vector2) -> void:
	var s := _sprite(_forge + "lava", 58)
	if s == null:
		return
	s.position = pos
	add_child(s)
	var g := GlowLayer.make(_paint_lava.bind(randf() * TAU))
	g.position = pos
	add_child(g)
	g.add_child(_spark_emitter(22.0, 6))
	_add_light(pos, LAVA_COLOR, 1.5, 1.4, false)


func _paint_lava(g: GlowLayer, seed: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + seed
	var k := 0.82 + 0.1 * sin(t * 5.0) + 0.08 * sin(t * 13.0)
	g.glow(Vector2(0, 6), 46.0 * k, Color(1.0, 0.42, 0.08, 0.2))
	g.glow(Vector2(2, 8), 18.0, Color(1.0, 0.85, 0.4, 0.14 * k))


## Lav damarı: zeminde kırık bir çizgi; içi turuncu-sarı parlar, nabız gibi atar ve kendi ışığını verir.
func _lava_seam(pos: Vector2, length: float, ang: float) -> void:
	# Kırık bir yarık: yönü adım adım hafifçe sapan bir yürüyüş (zikzak karalama gibi durmasın).
	var pts := PackedVector2Array([Vector2.ZERO])
	var n := 8
	var a := ang
	for i in n:
		a += randf_range(-0.38, 0.38)
		pts.append(pts[i] + Vector2.from_angle(a) * Vector2(1, 0.55) * length / n)
	# Damarın uçları duvara taşmasın: yürünemeyen noktada kes.
	var keep := PackedVector2Array()
	for p in pts:
		if not world.is_walkable(pos + p):
			break
		keep.append(p)
	if keep.size() < 4:
		return
	var mid := keep[keep.size() / 2]
	var branch := PackedVector2Array([mid])
	var bang := ang + randf_range(0.8, 1.3) * (1.0 if randf() < 0.5 else -1.0)
	for i in 3:
		branch.append(branch[i] + Vector2.from_angle(bang + randf_range(-0.4, 0.4)) * Vector2(1, 0.55) * length * 0.1)
	var g := GlowLayer.make(_paint_seam.bind(keep, branch, randf() * TAU))
	g.position = pos
	add_child(g)
	_add_light(pos + mid, LAVA_COLOR, 0.8, 0.45 + length / 280.0, false)


## Damar ortada kalın, uçlara doğru incelir; lav akışı gibi yavaşça kayan parlak bir nabız taşır.
func _paint_seam(g: GlowLayer, pts: PackedVector2Array, branch: PackedVector2Array, seed: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + seed
	var k := 0.75 + 0.15 * sin(t * 2.4) + 0.1 * sin(t * 7.3)
	var n := pts.size()
	for i in n - 1:
		var u := (float(i) + 0.5) / (n - 1)
		var w := 0.3 + 0.7 * sin(u * PI)
		var flow := 0.5 + 0.5 * sin(u * 9.0 - t * 1.8)
		var m := (pts[i] + pts[i + 1]) / 2.0
		# Yumuşak kızıl hale, üstünde ince turuncu çatlak; parlak çizgi yerine sıcak bir yarık gibi okunur.
		g.glow(m, 20.0 * w + 6.0, Color(1.0, 0.35, 0.06, (0.22 + 0.12 * flow) * k))
		g.draw_line(pts[i], pts[i + 1], Color(1.0, 0.42, 0.08, (0.2 + 0.15 * flow) * k * w), 2.0 * w + 0.5, true)
		g.draw_line(pts[i], pts[i + 1], Color(1.0, 0.8, 0.4, (0.08 + 0.2 * flow) * k * w), 0.8, true)
	for i in branch.size() - 1:
		g.draw_line(branch[i], branch[i + 1], Color(1.0, 0.4, 0.08, 0.3 * k), 1.6 - i * 0.4, true)


## Yukarı süzülen kor kıvılcımları (lav, köz).
func _spark_emitter(r: float, n: int) -> CPUParticles2D:
	var em := CPUParticles2D.new()
	em.material = GlowLayer.additive()
	em.amount = n
	em.lifetime = 1.6
	em.randomness = 0.6
	em.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	em.emission_sphere_radius = r
	em.direction = Vector2(0, -1)
	em.spread = 30
	em.gravity = Vector2(0, -18)
	em.initial_velocity_min = 6
	em.initial_velocity_max = 18
	soften_sparks(em, 5.0, 10.0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.4, 0.95))
	ramp.set_color(1, Color(1.0, 0.25, 0.04, 0.0))
	em.color_ramp = ramp
	return em


## Kemik totemi (süs): tepesinde soluk zehir parıltısı.
func _totem(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _camp + "totem", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.7), POISON_COLOR, 0.55, 0.55, false, true)


## Zehir gölü: yere yatık, sarı-yeşil nabız atan parıltı ve yavaş nefes alan ışık.
func _poison_pool(pos: Vector2) -> void:
	var s := _sprite(_camp + "pool", 60)
	if s == null:
		return
	s.position = pos
	add_child(s)
	var g := GlowLayer.make(_paint_pool.bind(randf() * TAU))
	g.position = pos
	add_child(g)
	_add_light(pos, POISON_COLOR, 1.1, 1.2, false, true)


func _paint_pool(g: GlowLayer, seed: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 1.6 + seed)
	g.glow(Vector2(-6, 2), 30.0 + 5.0 * k, Color(0.6, 0.95, 0.1, 0.14 + 0.14 * k))
	g.glow(Vector2(-6, 0), 13.0, Color(0.9, 1.0, 0.4, 0.1 + 0.1 * k))


## Kristal küme ve altında yumuşak mor ışık (meşale gibi ama titremeden nefes alır).
func _crystal(entities: Node2D, pos: Vector2, h: float, flip: bool) -> void:
	_standing_prop(entities, _cave + "crystal", pos, h, flip)
	_add_light(pos + Vector2(0, -h * 0.45), CRYSTAL_COLOR, 0.7 + h / 60.0, 0.45 + h / 55.0, h >= 50, true)


## Gölge kuyusu: yere yatık, GlowLayer ile yavaş nabız atan mor parıltı.
func _shadow_well(pos: Vector2) -> void:
	var s := _sprite(_cave + "well", 52)
	if s == null:
		return
	s.position = pos
	add_child(s)
	var g := GlowLayer.make(_paint_well.bind(randf() * TAU))
	g.position = pos
	add_child(g)
	_add_light(pos, CRYSTAL_COLOR, 0.9, 0.9, false, true)


func _paint_well(g: GlowLayer, seed: float) -> void:
	var k := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 1.3 + seed)
	g.glow(Vector2(0, 4), 30.0 + 6.0 * k, Color(0.55, 0.3, 1.0, 0.16 + 0.18 * k))
	g.glow(Vector2(0, 2), 14.0, Color(0.8, 0.6, 1.0, 0.1 + 0.12 * k))


func _wall_prop(key: String, pos: Vector2, h: float) -> void:
	var s := _sprite(key, h)
	if s:
		s.position = pos
		add_child(s)
		_add_flames(s, key)


func _floor_prop(key: String, pos: Vector2, h: float, flip: bool) -> void:
	var s := _sprite(key, h)
	if s:
		s.position = pos
		s.flip_h = flip
		s.rotation = randf_range(-0.3, 0.3)
		add_child(s)


func _standing_prop(entities: Node2D, key: String, pos: Vector2, h: float, flip: bool) -> void:
	var s := _sprite(key, h)
	if s:
		s.flip_h = flip
		s.offset.y = -s.texture.get_height() / 2.0 + _bottom_pad(key)
		s.position = pos
		entities.add_child(s)
		_add_flames(s, key)


## Meşale / mangal / mum: boyalı alevin üstünde titreyen parıltı ve yükselen közler.
func _add_flames(s: Sprite2D, key: String) -> void:
	if not FLAMES.has(key):
		return
	var tw := float(s.texture.get_width())
	var th := float(s.texture.get_height())
	for f in FLAMES[key]:
		var uv: Vector2 = f[0]
		var r: float = f[1]
		var lp := Vector2((uv.x - 0.5) * tw * (-1.0 if s.flip_h else 1.0), (uv.y - 0.5) * th) + s.offset
		var seed := randf() * 10.0
		var g := GlowLayer.make(func(layer: GlowLayer): _paint_flame(layer, r, seed))
		g.position = lp
		g.scale = Vector2.ONE / s.scale
		s.add_child(g)
		var em := CPUParticles2D.new()
		em.material = GlowLayer.additive()
		em.amount = 3 if r < 6.0 else 6
		em.lifetime = 1.3
		em.randomness = 0.5
		em.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		em.emission_sphere_radius = r * 0.4
		em.direction = Vector2(0, -1)
		em.spread = 22
		em.gravity = Vector2(0, -14)
		em.initial_velocity_min = 8
		em.initial_velocity_max = 20
		soften_sparks(em, 4.0, 9.0)
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1.0, 0.85, 0.45, 0.9))
		ramp.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
		em.color_ramp = ramp
		em.position = Vector2(0, -r * 0.6)
		g.add_child(em)


func _paint_flame(g: GlowLayer, r: float, seed: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + seed
	var flick := 0.82 + 0.1 * sin(t * 13.0) + 0.08 * sin(t * 29.0 + 0.7)
	g.glow(Vector2(0, -r * 0.2), r * 2.6 * flick, Color(1.0, 0.55, 0.2, 0.24))
	g.sprite("fx_orb_w", Vector2(0, -r * 0.55), Vector2(r * 2.4 * flick, r * 1.1), Color(1.0, 0.62, 0.25, 0.22 * flick), -PI / 2 + sin(t * 3.0) * 0.12)
	g.glow(Vector2(0, -r * 0.1), r * 0.9, Color(1.0, 0.85, 0.5, 0.3 * flick))


func _bottom_pad(key: String) -> float:
	var t := Sprites.tex(key)
	return t.get_height() * (1.0 - Sprites.content_bottom(key)) if t else 0.0


func _sprite(key: String, h: float) -> Sprite2D:
	var tex := Sprites.tex(key)
	if tex == null:
		return null
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var used := Sprites.content_bottom(key) - Sprites.content_top(key)
	var sc := h / (tex.get_height() * maxf(used, 0.1))
	s.scale = Vector2(sc, sc)
	return s


func _add_light(pos: Vector2, color: Color, energy: float, scale: float, shadows := true, slow := false) -> void:
	var l := PointLight2D.new()
	l.texture = light_texture()
	l.texture_scale = scale
	l.color = color
	l.energy = energy
	l.position = pos
	l.shadow_enabled = shadows
	l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	l.shadow_filter_smooth = 2.0
	l.shadow_color = Color(0, 0, 0, 0.8)
	add_child(l)
	_lights.append(l)
	_light_base.append(energy)
	_light_slow.append(slow)


# ── Sis ──────────────────────────────────────────────────────────────

func _build_mist() -> void:
	_mist = CPUParticles2D.new()
	_mist.texture = soft_texture()
	_mist.material = UNSHADED_MAT
	_mist.amount = 60
	_mist.lifetime = 14.0
	_mist.preprocess = 14.0
	_mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var size := world.pixel_size()
	_mist.position = size / 2
	_mist.emission_rect_extents = size / 2
	_mist.direction = Vector2(1, -0.2)
	_mist.spread = 40
	_mist.gravity = Vector2.ZERO
	_mist.initial_velocity_min = 3
	_mist.initial_velocity_max = 9
	_mist.scale_amount_min = 3.0
	_mist.scale_amount_max = 6.0
	var ramp := Gradient.new()
	# Goblin Yurdu'nda sis lağım buharı gibi sarı-yeşil.
	var mc := Color(0.6, 0.75, 0.25) if _camp != "" else Color(0.55, 0.35, 0.9)
	if _forge != "":
		# Alev Krallığı'nda sis sıcak kehribar duman (kızıl perde gibi durmasın).
		mc = Color(0.78, 0.45, 0.24)
	if _tundra != "":
		# Donmuş Tundra'da yerde süzülen soluk beyaz-mavi kırağı sisi.
		mc = Color(0.75, 0.88, 1.0)
	if _temple != "":
		# Orman Tapınağı'nda yosun yeşiline çalan, mor sporlu nemli sis.
		mc = Color(0.55, 0.45, 0.7)
	if _castle != "":
		# Şeytan Kalesi'nde yerde sürünen koyu kan-mor duman.
		mc = Color(0.5, 0.25, 0.4)
	if _sky != "":
		# Gökyüzü Kalesi'nde zeminden geçen soluk beyaz bulut sisi.
		mc = Color(0.9, 0.93, 1.0)
	if _void != "":
		# Yokluk Alemi'nde mor-siyah boşluk dumanı.
		mc = Color(0.35, 0.2, 0.55)
	if _throne != "":
		# Kara Taht'ta Kalp'in sıcak kızıl dumanı.
		mc = Color(0.6, 0.25, 0.18)
	ramp.set_color(0, Color(mc, 0.0))
	ramp.set_color(1, Color(mc, 0.0))
	ramp.add_point(0.5, Color(mc, 0.1 if _camp != "" else (0.08 if _tundra != "" else 0.09)))
	_mist.color_ramp = ramp
	add_child(_mist)
	# Işıkta uçuşan toz zerreleri.
	var dust := CPUParticles2D.new()
	dust.amount = 140
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.position = size / 2
	dust.emission_rect_extents = size / 2
	dust.direction = Vector2(0.3, -1)
	dust.spread = 180
	dust.gravity = Vector2(0, -2)
	dust.initial_velocity_min = 2
	dust.initial_velocity_max = 7
	# Zerreler yumuşak yuvarlak (piksel kare değil).
	soften_sparks(dust, 3.0, 6.5)
	var dr := Gradient.new()
	var dc := Color(0.8, 0.75, 1.0) if _cave != "" else (Color(0.9, 1.0, 0.65) if _camp != "" else Color(1.0, 0.9, 0.75))
	if _forge != "":
		# Toz yerine havada yükselen közler: toplamalı, karanlıkta parlar.
		dc = Color(1.0, 0.55, 0.15)
		dust.material = GlowLayer.additive()
		dust.direction = Vector2(0.15, -1)
		dust.spread = 25
		dust.gravity = Vector2(0, -6)
		dust.initial_velocity_min = 8
		dust.initial_velocity_max = 20
		soften_sparks(dust, 5.0, 11.0)
	if _throne != "":
		# Kalp'ten yükselen kızıl-altın közler (toplamalı).
		dc = Color(1.0, 0.55, 0.25)
		dust.material = GlowLayer.additive()
		dust.amount = 150
		dust.direction = Vector2(0.1, -1)
		dust.spread = 30
		dust.gravity = Vector2(0, -6)
		dust.initial_velocity_min = 8
		dust.initial_velocity_max = 18
		soften_sparks(dust, 4.0, 9.0)
	if _void != "":
		# Yerçekimi yok: her yöne yavaşça süzülen camgöbeği kıvılcımlar.
		dc = Color(0.5, 0.95, 1.0)
		dust.material = GlowLayer.additive()
		dust.amount = 130
		dust.direction = Vector2(1, 0)
		dust.spread = 180
		dust.gravity = Vector2.ZERO
		dust.initial_velocity_min = 3
		dust.initial_velocity_max = 9
		soften_sparks(dust, 3.0, 7.0)
	if _sky != "":
		# Güneşte süzülen altın toz zerreleri (toplamalı, yavaş).
		dc = Color(1.0, 0.88, 0.55)
		dust.material = GlowLayer.additive()
		dust.amount = 120
		dust.direction = Vector2(0.3, -1)
		dust.spread = 90
		dust.gravity = Vector2(0, -1)
		dust.initial_velocity_min = 2
		dust.initial_velocity_max = 6
		soften_sparks(dust, 3.0, 7.0)
	if _castle != "":
		# Toz yerine yükselen mor yokluk kıvılcımları (toplamalı, karanlıkta parlar).
		dc = Color(0.75, 0.4, 1.0)
		dust.material = GlowLayer.additive()
		dust.amount = 150
		dust.direction = Vector2(0.1, -1)
		dust.spread = 30
		dust.gravity = Vector2(0, -5)
		dust.initial_velocity_min = 6
		dust.initial_velocity_max = 16
		soften_sparks(dust, 4.0, 9.0)
	if _temple != "":
		# Toz yerine havada yavaşça süzülüp yükselen mor sporlar (yumuşak, hafif parlak).
		dc = Color(0.78, 0.5, 1.0)
		dust.material = GlowLayer.additive()
		dust.amount = 180
		dust.direction = Vector2(0.2, -1)
		dust.spread = 60
		dust.gravity = Vector2(0, -3)
		dust.initial_velocity_min = 3
		dust.initial_velocity_max = 9
		soften_sparks(dust, 5.0, 11.0)
	if _tundra != "":
		# Toz yerine yavaşça yağan, salınan kar taneleri (yumuşak yuvarlak, hafif parlak).
		dc = Color(0.92, 0.97, 1.0)
		dust.material = GlowLayer.additive()
		dust.amount = 420
		dust.direction = Vector2(0.25, 1)
		dust.spread = 18
		dust.gravity = Vector2(0, 4)
		dust.initial_velocity_min = 10
		dust.initial_velocity_max = 22
		dust.tangential_accel_min = -4
		dust.tangential_accel_max = 4
		soften_sparks(dust, 6.0, 12.0)
	dr.set_color(0, Color(dc, 0.0))
	dr.set_color(1, Color(dc, 0.0))
	dr.add_point(0.3, Color(dc, 0.55))
	dust.color_ramp = dr
	add_child(dust)
