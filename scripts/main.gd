class_name Main
extends Node2D
## Oyunun yöneticisi (eski GameEngine): kat kurulumu, nesne güncellemesi, etkileşim, ölüm,
## kamera, ışık ve ekranlar arası geçiş. Oyun mantığı 60 Hz fizik karesinde çalışır.

const BASE_ZOOM := 2.0
const COMBAT_ZOOM := 0.1
const HINT_FONT := preload("res://assets/fonts/Cinzel-Bold.ttf")
const LIGHT_SHADER := preload("res://scripts/world/light.gdshader")
## Bölgeye göre kenar kararmasının genişliği (1 = varsayılan). Alev Krallığı daha açık: koyu-kızıl kenar odayı yutmasın.
const ZONE_VIGNETTE := {4: 1.3}

var state := "start"
var world: World
var atmosphere: Atmosphere
var entities: Node2D
var fx: Fx
var camera: Camera2D
var dialogue: Dialogue
var hud: Hud
var screens: Screens
var light_rect: ColorRect
var fade_rect: ColorRect

var player: Player
var enemies: Array = []
var boss: Boss
var portal: Portal
var merchant: Merchant
var others: Array = []
## Bölge 5 boss arenasının soğun rün kandilleri (FrostHazard "lantern").
var lanterns: Array = []
## Oyuncunun son "ses"i (ok, büyü, kılıç savuruşu): Valerius'un Kör Adalet fazı bununla iz sürer.
var noise_pos := Vector2.INF
var noise_frame := 0

var touch_move := Vector2.ZERO
var touch_attack := false
var touch_q := false
var touch_r := false
var touch_aim := Vector2.ZERO
var aim_override := false

var combat_bonus := 0.0
var shake_amt := 0.0
var freeze := 0
## Boss ölüm sinematiği: ağır çekim, kamera odağı ve yakınlaşma payı (DeathCinematic yönetir).
var cine_slow := false
var cine_focus := Vector2.ZERO
var cine_zoom := 0.0
var crit_flash := 0
var respawn_timer := 0
var low_hp_timer := 0
var tutorial_step := -1
var tutorial_timer := 0
var _delayed: Array = []
var _jump_box: LineEdit


func _ready() -> void:
	world = World.new()
	add_child(world)
	atmosphere = Atmosphere.new()
	atmosphere.world = world
	add_child(atmosphere)
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	fx = Fx.new()
	fx.main = self
	fx.z_index = 50
	# Hasar yazıları karanlıktan etkilenmesin: dünyayla birlikte kayan ayrı bir katmanda.
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 2
	fx_layer.follow_viewport_enabled = true
	add_child(fx_layer)
	fx_layer.add_child(fx)
	camera = Camera2D.new()
	camera.zoom = Vector2(BASE_ZOOM, BASE_ZOOM)
	add_child(camera)
	dialogue = Dialogue.new()
	add_child(dialogue)

	var light_layer := CanvasLayer.new()
	light_layer.layer = 1
	add_child(light_layer)
	light_rect = ColorRect.new()
	light_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	light_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = LIGHT_SHADER
	light_rect.material = mat
	light_layer.add_child(light_rect)

	# Portal geçişi: inişte ekran soğuk bir mavi-beyaz parlamayla açılır.
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0, 0, 0, 0)
	fade_layer.add_child(fade_rect)

	hud = Hud.new()
	hud.main = self
	add_child(hud)
	screens = Screens.new()
	screens.main = self
	add_child(screens)
	screens.show_start()
	light_rect.visible = false


# ── Koşu ve kat kurulumu ─────────────────────────────────────────────

func start_run(style: String) -> void:
	screens.close()
	Sfx.music("")
	Game.new_run(style)
	dialogue.reset()
	Log.clear()
	_delayed.clear()
	if player:
		player.queue_free()
	player = Player.new()
	player.main = self
	player.setup(style)
	player.leveled_up.connect(_on_level_up)
	player.died.connect(_on_player_died)
	entities.add_child(player)
	player.add_child(Atmosphere.make_player_light())
	tutorial_step = -1 if Game.tutorial_done else 0
	tutorial_timer = 0
	Log.add("Zindan kapıları aralandı.")
	Log.add("%s: Arktan kırık kılıcını kavradı." % ClassData.STYLES[style].title, "level")
	_build_floor()
	state = "playing"
	light_rect.visible = true
	hud.visible = true
	Game.save_run(player)
	later(72, func(): dialogue.trigger("zone_entry", 1))
	later(150, _controls_hint)
	Log.add("Maceraya başlandı! Zindan Katı: 1")


## Koşu başında bir kez: gizli paneller ve iksir kısayolları hatırlatılır.
func _controls_hint() -> void:
	if hud.compact:
		hud.toast("TAB: AYRINTILI GÖRÜNÜM  |  1-2: İKSİR")


func _build_floor() -> void:
	for n in entities.get_children():
		if n != player:
			n.queue_free()
	enemies.clear()
	others.clear()
	lanterns.clear()
	noise_pos = Vector2.INF
	boss = null
	world.generate(Game.floor_number)
	atmosphere.build(entities)
	player.position = world.player_spawn
	player.vel = Vector2.ZERO
	camera.position = player.position
	camera.reset_smoothing()
	var f := Game.floor_number
	var boss_floor := Game.is_boss_floor()

	portal = _spawn(Portal.new(), world.portal_pos) as Portal
	for pos in world.chest_spawns:
		_spawn(Chest.new(), pos)
	var pool := EnemyData.pool_for_floor(f)
	for pos in world.enemy_spawns:
		var kind: String = pool.pick_random()
		spawn_enemy(kind, pos)
		if kind == "goblin" and Game.zone() == 3:
			# Goblin Yurdu: savaşçılar sürü halinde (2-3 birlikte) doğar.
			for _i in randi_range(1, 2):
				var gp: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(26, 44)
				spawn_enemy("goblin", gp if world.circle_free(gp, 12) else pos)
		if kind == "kor_impi" and Game.zone() == 4:
			# Alev Krallığı: kor impleri 2-3'ü birlikte doğar.
			for _i in randi_range(1, 2):
				var ip: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(26, 44)
				spawn_enemy("kor_impi", ip if world.circle_free(ip, 12) else pos)
		if kind == "yokluk_gozu" and Game.zone() == 9:
			# Yokluk Alemi: gözler ikişer süzülür.
			var ep: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(36, 56)
			spawn_enemy("yokluk_gozu", ep if world.circle_free(ep, 12) else pos)
		if kind == "golge_yuruyucu" and Game.zone() == 7:
			# Şeytan Kalesi: gölge yürüyücüler ikişer doğar.
			var wp: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(30, 50)
			spawn_enemy("golge_yuruyucu", wp if world.circle_free(wp, 12) else pos)
		if kind == "diken_tazisi" and Game.zone() == 6:
			# Orman Tapınağı: diken tazıları 2-3'lü sürü halinde doğar.
			for _i in randi_range(1, 2):
				var hp_: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(28, 46)
				spawn_enemy("diken_tazisi", hp_ if world.circle_free(hp_, 12) else pos)
		if kind == "buz_zombisi" and Game.zone() == 5:
			# Donmuş Tundra: buz zombileri 2-3'ü birlikte doğar.
			for _i in randi_range(1, 2):
				var zp: Vector2 = pos + Vector2.from_angle(randf() * TAU) * randf_range(28, 46)
				spawn_enemy("buz_zombisi", zp if world.circle_free(zp, 12) else pos)

	if not boss_floor and not world.enemy_spawns.is_empty():
		if Game.zone() == 9:
			var e := spawn_enemy("time_echo", world.enemy_spawns.pick_random() + Vector2(48, -48))
			if e:
				later(90, func(): dialogue.event("time_echo_spawn"))
		if randf() < 0.4:
			var sh := Shrine.new()
			sh.type = ["atk", "spd", "regen"].pick_random()
			_spawn(sh, world.enemy_spawns.pick_random() + Vector2(64, 64))
		if f > 1:
			for _i in randi_range(2, 4):
				var tp: Vector2 = world.enemy_spawns.pick_random() + Vector2(randf_range(-48, 48), randf_range(-48, 48))
				if world.is_walkable(tp):
					var tr := Trap.new()
					tr.type = ["spike", "fire"].pick_random()
					_spawn(tr, Vector2(floorf(tp.x / 32) * 32 + 16, floorf(tp.y / 32) * 32 + 16))
		if f >= 3 and f % 3 == 0 and not world.chest_spawns.is_empty():
			var lc := Chest.new()
			lc.locked = true
			var lp: Vector2 = world.chest_spawns[0] + Vector2(80, 0)
			_spawn(lc, lp if world.is_walkable(lp) else world.chest_spawns[0] + Vector2(0, 48))
		if f > 1 and world.enemy_spawns.size() > 1:
			for _i in (2 if randf() < 0.45 else 1):
				var cp: Vector2 = world.enemy_spawns.pick_random() + Vector2(randf_range(-50, 50), randf_range(-50, 50))
				if world.is_walkable(cp):
					var c := Captive.new()
					c.type = ["peasant", "soldier", "mage", "merchant"].pick_random()
					_spawn(c, cp)

	if Game.zone() == 10 and not boss_floor:
		# Kara Taht: büyük odaların yarısında bir Kalp Pınarı (vurunca kristali ve yanığı çözen altın ışık).
		for i in range(1, world.rooms.size()):
			var r: Rect2i = world.rooms[i]
			if r.size.x >= 6 and r.size.y >= 6 and randf() < 0.5:
				for _try in 8:
					var sp := (Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) + Vector2(0.5, 0.6)) * World.TILE
					if world.circle_free(sp, 22):
						spawn_spring(sp)
						break
	if Game.zone() == 6 and not boss_floor:
		# Orman Tapınağı: büyük odaların yarısında bir Kutsal Taş (vurunca zehri ve kökü çözen arınma ışığı).
		for i in range(1, world.rooms.size()):
			var r: Rect2i = world.rooms[i]
			if r.size.x >= 6 and r.size.y >= 6 and randf() < 0.5:
				for _try in 8:
					var sp := (Vector2(randi_range(r.position.x + 1, r.end.x - 2), randi_range(r.position.y + 2, r.end.y - 2)) + Vector2(0.5, 0.6)) * World.TILE
					if world.circle_free(sp, 22):
						spawn_stone(sp)
						break

	Game.assign_quest()
	merchant = Merchant.new()
	merchant.special = f % 5 == 0
	var mp: Vector2 = portal.position + Vector2(-52, 0)
	for o in [Vector2(-130, 10), Vector2(130, 10), Vector2(-110, 70), Vector2(110, 70), Vector2(0, 120), Vector2(-90, 0), Vector2(90, 0)]:
		if world.circle_free(portal.position + o, 18):
			mp = portal.position + o
			break
	_spawn(merchant, mp)

	if boss_floor:
		boss = Boss.new()
		boss.main = self
		boss.setup(f)
		boss.position = world.boss_spawn
		if boss.is_alden:
			# Buz tahtı arenanın kuzeyinde; dört köşede soğuk rün kandilleri.
			boss.position = world.boss_spawn + Vector2(0, -World.TILE * 3.5)
			for c in [Vector2(10.5, 4.6), Vector2(19.5, 4.6), Vector2(10.5, 14.4), Vector2(19.5, 14.4)]:
				spawn_lantern(c * World.TILE)
		if boss.is_nihil:
			boss.position = world.boss_spawn + Vector2(0, -World.TILE * 2.0)
		if boss.is_valerius:
			# Yargıç kürsüsü arenanın kuzeyinde, Valerius önünde.
			boss.position = world.boss_spawn + Vector2(0, -World.TILE * 2.5)
			atmosphere._standing_prop(entities, "prop_z8_dais", boss.position + Vector2(0, -60), 120, false)
			atmosphere._add_light(boss.position + Vector2(0, -130), Color(1.0, 0.85, 0.5), 0.7, 1.4, false, true)
		if boss.is_malakor:
			# Yokluk portalı arenanın kuzeyinde, Malakor önünde; dört köşede Kan Mühürü.
			boss.position = world.boss_spawn + Vector2(0, -World.TILE * 3.0)
			for c in [Vector2(10.5, 4.6), Vector2(19.5, 4.6), Vector2(10.5, 14.4), Vector2(19.5, 14.4)]:
				spawn_seal(c * World.TILE)
		if boss.is_lyra:
			# Hayat Ağacı arenanın kuzeyinde; dört köşede Kutsal Taş.
			boss.position = world.boss_spawn + Vector2(0, -World.TILE * 3.5)
			for c in [Vector2(10.5, 4.6), Vector2(19.5, 4.6), Vector2(10.5, 14.4), Vector2(19.5, 14.4)]:
				spawn_stone(c * World.TILE)
		entities.add_child(boss)
		if boss.is_malakor:
			boss.place_portal()
		hud.show_boss(true)
		Sfx.music("boss")
		Log.add("%s uyandı!" % boss.display_name, "death")
		later(42, func(): dialogue.trigger("boss_pre", Game.zone()))
	else:
		hud.show_boss(false)
		Sfx.music("")
	Game.changed.emit()


func _spawn(node: Actor, pos: Vector2) -> Actor:
	node.main = self
	node.position = pos
	entities.add_child(node)
	others.append(node)
	return node


func spawn_enemy(type: String, pos: Vector2) -> Enemy:
	if not world.is_walkable(pos):
		return null
	var e := Enemy.new()
	e.main = self
	e.setup(type, Game.floor_number, player)
	e.position = pos
	entities.add_child(e)
	enemies.append(e)
	return e


## Soğuk rün kandili ekler (bölge 5 boss arenası).
func spawn_lantern(pos: Vector2) -> FrostHazard:
	var l := FrostHazard.new()
	l.setup("lantern", pos, 26.0, 0)
	_spawn(l, l.position)
	lanterns.append(l)
	return l


## Kutsal Taş ekler (bölge 6): Main.lanterns listesinde durur, kandil gibi vurularak yakılır.
func spawn_stone(pos: Vector2) -> ForestHazard:
	var st := ForestHazard.new()
	st.setup("stone", pos, 26.0, 0)
	_spawn(st, st.position)
	lanterns.append(st)
	return st


## Kalp Pınarı ekler (bölge 10): Main.lanterns listesinde durur, vurularak akıtılır.
func spawn_spring(pos: Vector2) -> HeartHazard:
	var hs := HeartHazard.new()
	hs.setup("spring", pos, 26.0, 0)
	_spawn(hs, hs.position)
	lanterns.append(hs)
	return hs


## Kan Mühürü ekler (bölge 7 boss arenası): Main.lanterns listesinde durur, vuruşla kırılır.
func spawn_seal(pos: Vector2) -> VoidHazard:
	var sl := VoidHazard.new()
	sl.setup("seal", pos, 26.0, 0)
	_spawn(sl, sl.position)
	lanterns.append(sl)
	return sl


## Nokta (ok, büyü, kılıç ucu) bir kandile değdiyse kandili yakar; değdiyse true.
func hit_lanterns(at: Vector2, r: float) -> bool:
	var hit := false
	for l in lanterns:
		if is_instance_valid(l) and not l.removed and (at.distance_to(l.head()) < r + 20.0 or at.distance_to(l.center() + Vector2(0, -30)) < r + 12.0):
			l.light_up()
			hit = true
	return hit


func spawn_minions(b: Boss, count: int) -> void:
	for i in count:
		var pos := b.position + Vector2.from_angle(TAU * i / count + randf()) * randf_range(110, 150)
		var kinds: Array = ["slime_fire", "slime_shadow", "skeleton"]
		if Game.zone() <= 10:
			kinds = EnemyData.ZONE_POOLS[Game.zone() - 1]
		var e := spawn_enemy(kinds.pick_random(), pos)
		if e:
			var m := 1.0 + (b.phase - 1) * 0.3
			e.max_hp = int(e.max_hp * m)
			e.hp = e.max_hp
			e.atk = int(e.atk * m)
			e.speed *= m
			e.is_minion = true


## Kayıtlı koşuyu kaldığı katın başından sürdürür.
func continue_run() -> void:
	var saved := Game.saved_run()
	if saved.is_empty():
		return
	screens.close()
	Sfx.music("")
	Game.restore_run(saved.oyun)
	dialogue.reset()
	Log.clear()
	_delayed.clear()
	if player:
		player.queue_free()
	player = Player.new()
	player.main = self
	player.setup(Game.style)
	for k in Game.PLAYER_KEYS:
		if saved.oyuncu.has(k):
			player.set(k, saved.oyuncu[k])
	player.leveled_up.connect(_on_level_up)
	player.died.connect(_on_player_died)
	entities.add_child(player)
	player.add_child(Atmosphere.make_player_light())
	tutorial_step = -1
	_build_floor()
	state = "playing"
	light_rect.visible = true
	hud.visible = true
	hud.refresh()
	Log.add("Kaldığın yerden: Zindan Katı %d. %s" % [Game.floor_number, EnemyData.ZONE_NAMES[Game.zone() - 1]], "level")


func next_floor() -> void:
	Game.quest_event("floor_cleared")
	var old_zone := Game.zone()
	Game.floor_number += 1
	_build_floor()
	Game.save_run(player)
	shake(15)
	_portal_arrival()
	Log.add("Zindan Katı %d. %s" % [Game.floor_number, EnemyData.ZONE_NAMES[Game.zone() - 1]])
	for name in Game.check_achievements():
		hud.toast("BAŞARIM: " + name)
	var f := Game.floor_number
	if f % 10 == 0:
		later(36, func(): screens.show_story(f))
	if Game.zone() != old_zone:
		later(54, func(): dialogue.trigger("zone_entry", Game.zone()))
	else:
		dialogue.trigger("floor_specific", f, true)


# ── Kare döngüsü ─────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	_run_delayed()
	if state == "respawning":
		respawn_timer -= 1
		if respawn_timer <= 0:
			_respawn()
	if state == "playing" and freeze > 0:
		# Vuruş donması: darbe anında dünya birkaç kare durur, vuruş "tok" hissettirir.
		freeze -= 1
	elif state == "cinematic":
		# Ağır çekimde dünya üç karede bir ilerler; tablo ekrandayken tamamen durur.
		if cine_slow and Engine.get_physics_frames() % 3 == 0:
			for e in enemies.duplicate():
				if is_instance_valid(e) and not e.removed:
					e.tick()
			for o in others.duplicate():
				if is_instance_valid(o) and not o.removed:
					o.tick()
			_cleanup()
	elif state == "playing":
		dialogue.update(1000.0 / 60.0)
		player.tick()
		for e in enemies.duplicate():
			if is_instance_valid(e) and not e.removed:
				e.tick()
		if boss and is_instance_valid(boss) and not boss.removed:
			boss.tick()
		for o in others.duplicate():
			if is_instance_valid(o) and not o.removed:
				o.tick()
		_cleanup()
		_check_portal()
		_track_rooms()
		_hp_warnings()
		_tutorial()
		touch_q = false
		touch_r = false
	if player and state != "start":
		_update_camera()
		fx.tick()


func _cleanup() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.removed)
	others = others.filter(func(o): return is_instance_valid(o) and not o.removed)
	if boss and (not is_instance_valid(boss) or boss.removed):
		boss = null


func _check_portal() -> void:
	if portal.active:
		return
	var final_floor := Game.floor_number >= 100
	# Şamanın totemleri mührü tutmaz: geriye yalnız totem kaldıysa onlar da çöker.
	if not enemies.is_empty() and enemies.all(func(e): return e.type == "totem"):
		for e in enemies:
			burst(e.position + Vector2(0, -20), 26, Color(0.75, 0.7, 0.55))
			e.remove()
		enemies.clear()
	if enemies.is_empty() and boss == null and not final_floor:
		portal.active = true
		Log.add("Mühür kırıldı. Portal açıldı!", "level")


func _track_rooms() -> void:
	var i := world.room_index_at(player.position)
	if i >= 0:
		world.explored[i] = true


func _hp_warnings() -> void:
	low_hp_timer += 1
	if low_hp_timer < 300:
		return
	low_hp_timer = 0
	var ratio := float(player.hp) / player.max_hp()
	if ratio <= 0.12:
		dialogue.event("critical_hp", false)
	elif ratio <= 0.3:
		dialogue.event("low_hp", false)


func _tutorial() -> void:
	if tutorial_step < 0:
		return
	tutorial_timer += 1
	if tutorial_timer >= [300, 300, 300, 240, 240][tutorial_step]:
		tutorial_step += 1
		tutorial_timer = 0
		if tutorial_step >= 5:
			tutorial_step = -1
			Game.tutorial_done = true
			Game.save()


func _update_camera() -> void:
	var in_combat := false
	for e in targets():
		if e.position.distance_to(player.position) < 220.0:
			in_combat = true
			break
	combat_bonus += ((1.0 if in_combat else 0.0) - combat_bonus) * 0.035
	var crit := sin(crit_flash / 8.0 * PI) * 0.06 if crit_flash > 0 else 0.0
	if crit_flash > 0:
		crit_flash -= 1
	var z := BASE_ZOOM + COMBAT_ZOOM * combat_bonus + crit + cine_zoom
	camera.zoom = Vector2(z, z)
	var lerp_k: float = ClassData.STYLES[Game.style].camera_lerp
	var aim := player.position
	if cine_zoom > 0.0:
		aim = cine_focus + Vector2(0, -60)
		lerp_k = 0.08
	camera.position += (aim - camera.position) * lerp_k
	var half := get_viewport_rect().size / (2.0 * z)
	var size := world.pixel_size()
	camera.position.x = clampf(camera.position.x, half.x, maxf(half.x, size.x - half.x)) if size.x > half.x * 2 else size.x / 2
	camera.position.y = clampf(camera.position.y, half.y, maxf(half.y, size.y - half.y)) if size.y > half.y * 2 else size.y / 2
	if shake_amt > 0.1:
		camera.offset = Vector2(randf_range(-shake_amt, shake_amt), randf_range(-shake_amt, shake_amt)) * 0.5
		shake_amt *= 0.9
	else:
		shake_amt = 0
		camera.offset = Vector2.ZERO
	var mat := light_rect.material as ShaderMaterial
	var screen_pos := player.get_global_transform_with_canvas().origin
	mat.set_shader_parameter("center", screen_pos)
	mat.set_shader_parameter("rect_size", light_rect.size)
	# Asıl karanlığı Atmosphere'in ışıkları veriyor; bu katman artık yalnızca kenar kararması.
	var vg: float = ZONE_VIGNETTE.get(Game.zone(), 1.0)
	mat.set_shader_parameter("inner", 200.0 * z * vg)
	mat.set_shader_parameter("outer", 560.0 * z * vg)
	var zt: Array = EnemyData.ZONE_TINT[Game.zone() - 1]
	var tint: Color = zt[0]
	# Bölgenin kendi boyalı dokuları varsa renk zaten resimde; perdeyi bölge 1 kadar ince tut (çift renklenmesin).
	if world.has_zone_tiles():
		tint.a = minf(tint.a, EnemyData.ZONE_TINT[0][0].a)
	if zt[1]:
		tint.a *= 0.7 + 0.3 * sin(Time.get_ticks_msec() / 1200.0)
	mat.set_shader_parameter("tint", tint)


func _portal_arrival() -> void:
	var zc: Color = Portal.ZONE_COLORS[EnemyData.zone_of(Game.floor_number) - 1]
	fade_rect.color = Color(zc.lerp(Color.WHITE, 0.45), 1.0)
	var tw := create_tween()
	tw.tween_property(fade_rect, "color", Color(0.02, 0.03, 0.08, 0.85), 0.18)
	tw.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 0.9).set_ease(Tween.EASE_OUT)
	fx.add_burst(player.position, 90, zc)
	fx.add_burst(player.position, 50, Color(0.85, 0.95, 1.0))


func hit_freeze(frames: int) -> void:
	freeze = maxi(freeze, frames)


func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)
	if amount >= 8:
		crit_flash = 8


## Kareye bağlı gecikmeli iş (60 kare = 1 sn). Duraklatma ekranlarında da sayar.
func later(frames: int, fn: Callable) -> void:
	_delayed.append([frames, fn])


func _run_delayed() -> void:
	if _delayed.is_empty() or state == "start" or state == "cinematic":
		return
	var due: Array = []
	for d in _delayed:
		d[0] -= 1
		if d[0] <= 0:
			due.append(d)
	for d in due:
		_delayed.erase(d)
		# Sahibi silinmiş bir nesneye bağlı iş (ör. ölen bossun lambdası) sessizce düşer.
		if (d[1] as Callable).is_valid():
			d[1].call()


# ── Yardımcılar (nesnelerin çağırdığı) ───────────────────────────────

func targets() -> Array:
	# Kül bulutundaki rahip görünmez: hedef alınamaz.
	# Dalış halindeki gargoyl havada: hedef alınamaz. Gölge dalışındaki Malakor da öyle.
	var list: Array = enemies.filter(func(e): return is_instance_valid(e) and not e.removed and not e.hidden() and not e.airborne())
	if boss and is_instance_valid(boss) and not boss.removed and not boss.untargetable():
		list.append(boss)
	return list


func aim_point() -> Vector2:
	if aim_override:
		return player.position + touch_aim
	return get_global_mouse_position()


func mouse_in_world() -> bool:
	return hud.mouse_over_world()


func dialogue_open() -> bool:
	return dialogue.waiting_for_input()


func float_text(pos: Vector2, text: String, color: Color) -> void:
	fx.add_text(pos, text, color)


func burst(pos: Vector2, radius: float, color: Color) -> void:
	fx.add_burst(pos, radius, color)


func slash_effect(from: Vector2, to: Vector2) -> void:
	fx.add_slash(from, to)


func spawn_afterimage(p: Player) -> void:
	fx.add_afterimage(p)


func elemental_burst(src: Enemy, dmg: int) -> void:
	burst(src.position, 96, Color(0.8, 1.0, 0.3))
	for e in targets():
		if e != src and e.position.distance_to(src.position) < 96:
			e.take_damage(dmg)


## Oyuncu ses çıkardı (ateş etti / savurdu).
func make_noise(at: Vector2) -> void:
	noise_pos = at
	noise_frame = Engine.get_physics_frames()


func spawn_projectile(kind: String, pos: Vector2, angle: float, damage: int, crit: bool) -> void:
	make_noise(pos)
	var pr := Projectile.new()
	pr.main = self
	pr.position = pos
	entities.add_child(pr)
	pr.setup(kind, angle, damage, crit)
	others.append(pr)


func spawn_enemy_arrow(src: Enemy, angle: float) -> void:
	var a := EnemyArrow.new()
	var orb := src.type in ["cultist", "goblin_saman"]
	a.setup(angle, src.atk, src.debuff, orb)
	var at := src.position + Vector2(0, -src.size * 0.4)
	if orb:
		# Küre müridin uzattığı elinden çıkar.
		at = src.position + Vector2(src.size * (-0.45 if src.facing_left else 0.45), -src.size * 0.55)
	if src.type == "goblin_saman":
		# Şamanın yavaş lağım zehri küresi asasının kafatasından çıkar.
		a.tint = Color(0.72, 1.0, 0.18)
		a.speed = 2.3
		a.life = 150
		at = src.position + Vector2(src.size * (-0.6 if src.facing_left else 0.6), -src.size * 0.85)
	_spawn(a, at)


## Bombacı bombası: hedefte ~1 sn uyarı dairesi, sonra patlama ve kısa zehir gölü.
func throw_bomb(src: Enemy, target: Vector2) -> void:
	if not world.is_walkable(target):
		target = player.position
	var b := GoblinHazard.new()
	b.setup("bomb", target, 46.0, src.atk)
	b.from = src.position + Vector2(src.size * (-0.5 if src.facing_left else 0.5), -src.size * 0.7)
	_spawn(b, b.position)


func spawn_strike(kind: String, pos: Vector2, radius: float, damage: int, delay: int) -> void:
	var s := Strike.new()
	s.setup(kind, radius, damage, delay)
	_spawn(s, pos)
	s.z_index = 10


func draw_hint(ci: CanvasItem, offset: Vector2, text: String) -> void:
	var w := HINT_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var r := Rect2(offset.x - w / 2 - 10, offset.y - 15, w + 20, 21)
	ci.draw_rect(r, Color(0.04, 0.03, 0.05, 0.72))
	ci.draw_line(r.position + Vector2(6, 0), r.position + Vector2(r.size.x - 6, 0), Color(0.85, 0.66, 0.35, 0.55), 1)
	ci.draw_line(r.position + Vector2(6, r.size.y), r.end - Vector2(6, 0), Color(0.85, 0.66, 0.35, 0.55), 1)
	ci.draw_string_outline(HINT_FONT, Vector2(offset.x - w / 2, offset.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color(0, 0, 0, 0.8))
	ci.draw_string(HINT_FONT, Vector2(offset.x - w / 2, offset.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f2dcb0"))


func drop_item(pos: Vector2, item: Dictionary) -> void:
	var pk := Pickup.new()
	pk.setup_item(item)
	_spawn(pk, pos)


func drop_gold(pos: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	var pk := Pickup.new()
	pk.setup_gold(amount)
	_spawn(pk, pos)


func collect(pk: Pickup) -> void:
	if pk.gold > 0:
		Game.add_gold(pk.gold)
		Sfx.play("gold")
		Log.add("+%d altın" % pk.gold, "loot")
		float_text(player.position + Vector2(0, -60), "+%d" % pk.gold, Color("ffd700"))
		pk.remove()
		return
	if player.add_to_bag(pk.item):
		Sfx.play("item")
		Log.add("Alındı: %s" % pk.item.name, "loot")
		float_text(player.position + Vector2(0, -60), pk.item.name, ItemData.RARITY_COLORS.get(pk.item.rarity, Color.WHITE))
		pk.remove()
		hud.refresh_bag()
	else:
		pk.vel = (pk.position - player.position).normalized() * 3
		pk.lift_vel = 6
		pk.bounces = 1
		if Engine.get_physics_frames() % 60 == 0:
			hud.toast("ÇANTA DOLU!")


# ── Ölümler ──────────────────────────────────────────────────────────

func on_enemy_killed(e: Enemy) -> void:
	if e.removed:
		return
	if e.type == "totem":
		# Kırılan totem ödül vermez.
		burst(e.position + Vector2(0, -24), 34, Color(0.8, 0.95, 0.4))
		e.remove()
		return
	Game.kills += 1
	Log.add("%s yenildi." % e.display_name, "hit")
	if e.type.begins_with("slime"):
		Game.slime_kills += 1
	if Game.lifesteal_upgrade:
		player.heal(3)
	if player.weapon_kind() == "bow":
		player.bow_kills += 1
	else:
		player.sword_kills += 1
	_quest_event("kill")
	if Game.kills == 1:
		dialogue.event("first_kill")
	var f := Game.floor_number
	var luck: float = player.base.luck
	drop_gold(e.position, int(e.gold * (1.0 + luck / 140.0) * minf(1.15, 0.62 + f * 0.006)))
	var shard := 0.015 if f < 10 else (0.055 if f < 30 else (0.08 if f < 50 else 0.11))
	if randf() < shard:
		drop_item(e.position, ItemData.make("stone_shard_" + ItemData.STONES.pick_random()))
	# Altın anahtar her bölgedeki normal düşmanlardan düşebilir (yardımcılar hariç).
	if not e.is_minion and randf() < 0.03:
		drop_item(e.position, ItemData.make("gold_key"))
	var r := randf()
	if r < 0.10:
		drop_item(e.position, ItemData.make("potion_red"))
	elif r < 0.13:
		drop_item(e.position, ItemData.make("potion_blue"))
	elif r < 0.22:
		drop_item(e.position, ItemData.random_gear(f, luck))
	burst(e.position, 30, EnemyData.DEBUFF_COLORS.get(e.debuff, Color.WHITE))
	e.remove()
	if e.type == "slime_shadow" and not e.small:
		_split_slime(e)
	if e.type == "kor_impi":
		# Küçük kıvılcım patlaması (hasarsız, yalnızca görsel).
		burst(e.position + Vector2(0, -30), 40, Color(1.0, 0.62, 0.18))
		fx.add_sprite(e.position + Vector2(0, -30), "fx_spark", 70.0, Color(1.0, 0.8, 0.4, 0.9), 18, 0.3)
	if e.type == "diken_tazisi":
		# Yerde kısa süre kalan diken yığını.
		var th := ForestHazard.new()
		th.setup("thorns", e.position + Vector2(0, 6), 26.0, maxi(1, e.atk / 3))
		_spawn(th, th.position)
	if e.type == "spor_mantari":
		# Ölünce patlar: büyük spor bulutu, yakındaki düşmanları da zehirler.
		e.spore_cloud(e.position + Vector2(0, 6), 96.0, true)
	if e.type == "buz_zombisi":
		# Buz parçalarına ayrılır; yerde ~2 sn kaygan buz birikintisi kalır.
		burst(e.position + Vector2(0, -24), 36, Color(0.75, 0.92, 1.0))
		var ice := FrostHazard.new()
		ice.setup("patch", e.position + Vector2(0, 6), 34.0, 0)
		_spawn(ice, ice.position)
	if e.type == "goblin_bombaci":
		# Elindeki bomba yere düşer: 1 sn sonra patlar, oyuncuyu da goblinleri de yakar.
		var b := GoblinHazard.new()
		b.setup("bomb", e.position, 52.0, e.atk)
		b.hurts_enemies = true
		_spawn(b, b.position)
	player.gain_xp(e.xp)
	for n in Game.check_achievements():
		hud.toast("BAŞARIM: " + n)


## Gölge Balçığı ölünce iki küçük balçığa bölünür (yarım can, küçük boy; bir daha bölünmezler).
func _split_slime(e: Enemy) -> void:
	for sx in [-1.0, 1.0]:
		var pos := e.position + Vector2(sx * 16.0, randf_range(-6, 6))
		var c := spawn_enemy("slime_shadow", pos if world.is_walkable(pos) else e.position)
		if c == null:
			continue
		c.small = true
		c.is_minion = e.is_minion
		c.max_hp = maxi(1, int(e.max_hp * 0.5))
		c.hp = c.max_hp
		c.atk = maxi(1, int(e.atk * 0.6))
		c.xp = int(e.xp / 3.0)
		c.gold = 0
		c.size = e.size * 0.72
		c.draw_mul = e.draw_mul * 0.62
		c.speed = e.speed * 1.15
		c.attack_cd = 45
		c.knock = Vector2(sx * 5.0, 0)
		c.facing_left = sx < 0


func on_boss_killed(b: Boss) -> void:
	if b.removed:
		return
	shake(30)
	Sfx.music("")
	Sfx.play("boss_victory")
	Log.add("%s düştü!" % b.display_name, "death")
	Game.bosses_killed += 1
	_quest_event("boss_kill")
	var pos := b.position
	var c := Chest.new()
	_spawn(c, pos)
	for i in 5:
		drop_gold(pos + Vector2(randf_range(-30, 30), randf_range(-20, 20)), randi_range(15, 29))
	var weapon: String = {"warrior": "sword", "ranger": "bow", "mage": "staff"}[Game.style]
	drop_item(pos, ItemData.make(("%s_legendary" % weapon) if randf() < 0.5 else "armor_legendary"))
	b.remove()
	boss = null
	hud.show_boss(false)
	if Game.floor_number < 100:
		portal.active = true
	var was_karun := b.is_karun
	var after := func():
		if was_karun:
			later(60, func(): screens.show_ending_choice())
		elif Game.floor_number >= 100:
			later(48, _spawn_karun)
		else:
			dialogue.trigger("boss_post", Game.zone(), true)
			if Game.bosses_killed == 1:
				dialogue.event("first_boss_kill")
	var key := DeathCinematic.key_for(b, Game.zone()) if DeathCinematic.enabled else ""
	if key == "":
		after.call()
		return
	_start_cinematic(key, b, pos, after)


## Boss ölüm sinematiği: dünya ağır çekime girer, arayüz gizlenir; DeathCinematic tablo sahnesini oynatır.
func _start_cinematic(key: String, b: Boss, pos: Vector2, after: Callable) -> void:
	state = "cinematic"
	cine_slow = true
	cine_focus = pos
	hud.visible = false
	dialogue.stop_voices()
	var c := DeathCinematic.new()
	c.main = self
	c.key = key
	c.title = EnemyData.KARUN_NAME.get_slice(" — ", 0) if b.is_karun else b.display_name.get_slice(" — ", 0)
	c.focus = pos
	c.done = after
	add_child(c)


func end_cinematic() -> void:
	cine_slow = false
	cine_zoom = 0.0
	if state == "cinematic":
		state = "playing"
	hud.visible = true


func _spawn_karun() -> void:
	boss = Boss.new()
	boss.main = self
	boss.setup(100, true)
	boss.position = world.boss_spawn
	if boss.is_karun_final:
		# Kârun kuzeydeki Kara Taht'ından iner; arınıp uyuyan Gök Börü arenanın ortasında kalır.
		var throne := world.boss_spawn + Vector2(0, -World.TILE * 3.6)
		atmosphere._standing_prop(entities, "boss_karun_throne", throne + Vector2(0, -4), 200, false)
		atmosphere._add_light(throne + Vector2(0, -80), Color(1.0, 0.45, 0.2), 0.9, 1.6, false, true)
		boss.position = throne + Vector2(0, 50)
	entities.add_child(boss)
	hud.show_boss(true)
	Sfx.music("boss")
	shake(20)
	dialogue.event("karun_final_appears")


func _quest_event(kind: String) -> void:
	var reward := Game.quest_event(kind)
	if reward > 0:
		var key := Game.quest_gives_key()
		if key and not player.add_to_bag(ItemData.make("gold_key")):
			drop_item(player.position, ItemData.make("gold_key"))
		Log.add("Görev tamamlandı! +%d altın%s" % [reward, " + Altın Anahtar" if key else ""], "loot")
		hud.toast("GÖREV TAMAMLANDI! +%d ALTIN%s" % [reward, " + ALTIN ANAHTAR" if key else ""])
		hud.refresh()


func _on_level_up() -> void:
	Log.add("Seviye atladın! Seviye %d" % player.level, "level")
	if player.level == 5:
		dialogue.event("level_up_5")
	elif player.level == 10:
		dialogue.event("level_up_10")
	later(72, func(): dialogue.class_whisper(Game.style))
	screens.show_level_up()


func _on_player_died() -> void:
	Game.lives -= 1
	Log.add("Arktan düştü!", "death")
	shake(20)
	if Game.lives > 0:
		state = "respawning"
		respawn_timer = 90
	else:
		var stones := Game.soul_stone_reward()
		Game.soul_stones += stones
		Game.clear_run()
		Game.save()
		state = "gameover"
		screens.show_game_over(stones)
	Game.changed.emit()


func _respawn() -> void:
	player.position = world.player_spawn
	player.hp = player.max_hp()
	player.burn = 0
	player.poison = 0
	player.slow = 0
	player.frost = 0
	player.rooted = 0
	player.void_burn = 0
	player.blood_mark = 0
	player.heavy = 0
	player.warp = 0
	player.crystal = 0
	player.frozen = 0
	player.invincible = 120
	player.vel = Vector2.ZERO
	state = "playing"


# ── Etkileşim (E) ────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim_override = false
	if state != "playing":
		return
	if _secret_keys(event):
		return
	var advance: bool = event.is_action_pressed("interact") or event.is_action_pressed("confirm") or event.is_action_pressed("dash") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if advance and dialogue.waiting_for_input():
		dialogue.advance()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("bag"):
		screens.show_bag()
	elif event.is_action_pressed("potion_1") or event.is_action_pressed("potion_2"):
		var type := "potion_red" if event.is_action_pressed("potion_1") else "potion_blue"
		if player.potion_count(type) == 0:
			hud.toast("İKSİR YOK")
		elif not player.use_potion_type(type):
			hud.toast("CAN ZATEN DOLU")
		else:
			Sfx.play("item")
			hud.refresh()
	elif event.is_action_pressed("cancel"):
		screens.show_pause()


## Geliştirici kısayolları; arayüzde hiçbir yerde görünmez.
func _secret_keys(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.shift_pressed):
		return false
	match event.keycode:
		KEY_K:
			_open_jump_box()
		KEY_G:
			player.god_mode = not player.god_mode
			hud.toast("+" if player.god_mode else "-")
		_:
			return false
	get_viewport().set_input_as_handled()
	return true


func _open_jump_box() -> void:
	if _jump_box == null:
		var layer := CanvasLayer.new()
		layer.layer = 120
		add_child(layer)
		_jump_box = LineEdit.new()
		_jump_box.position = Vector2(560, 300)
		_jump_box.size = Vector2(160, 40)
		_jump_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_jump_box.max_length = 3
		_jump_box.add_theme_font_override("font", UiKit.TITLE)
		_jump_box.add_theme_font_size_override("font_size", 22)
		_jump_box.text_submitted.connect(_on_jump_submitted)
		_jump_box.focus_exited.connect(func(): _jump_box.visible = false)
		layer.add_child(_jump_box)
	_jump_box.text = ""
	_jump_box.visible = true
	_jump_box.grab_focus()


func _on_jump_submitted(text: String) -> void:
	_jump_box.visible = false
	_jump_box.release_focus()
	if text.is_valid_int():
		goto_floor(clampi(text.to_int(), 1, 100))


## Doğrudan kata ışınlanır; görev, başarım ve hikâye tetiklenmez.
func goto_floor(n: int) -> void:
	Game.floor_number = n
	_build_floor()
	_portal_arrival()
	Log.add("Zindan Katı %d. %s" % [n, EnemyData.ZONE_NAMES[Game.zone() - 1]])


func interact() -> void:
	var p := player.position
	# Portalın tam üstünde duran oyuncu iner: yakına düşmüş sandık / tutsak portalı engellemesin.
	if portal and portal.active and p.distance_to(portal.position) < 26:
		next_floor()
		return
	if merchant and p.distance_to(merchant.position) < 48:
		screens.show_shop()
		return
	# Toplanan / açılan nesneler aynı karede serbest kalmış olabilir.
	_cleanup()
	var opened := false
	for o in others:
		if o is Chest and not o.opened and p.distance_to(o.position) < 40:
			if _open_chest(o):
				opened = true
	if opened:
		return
	for o in others:
		if o is Shrine and not o.used and p.distance_to(o.position) < 44:
			o.used = true
			player.shrine_type = o.type
			player.shrine_left = 1800
			Log.add("%s kutsaması aldın (30 sn)" % Shrine.INFO[o.type][0], "level")
			hud.toast(Shrine.INFO[o.type][0])
	for o in others:
		if o is Captive and p.distance_to(o.position) < 52:
			_rescue(o)
			return
	if p.distance_to(portal.position) < 40:
		if portal.active:
			next_floor()
		else:
			hud.toast("PORTAL KAPALI — önce tüm düşmanları yen")


func _open_chest(c: Chest) -> bool:
	var f := Game.floor_number
	if c.locked:
		var key_index := -1
		for i in player.inventory.size():
			if player.inventory[i].type == "gold_key":
				key_index = i
		if key_index < 0:
			hud.toast("ALTIN ANAHTAR GEREKLİ")
			return false
		var k: Dictionary = player.inventory[key_index]
		k.count -= 1
		if k.count <= 0:
			player.inventory.remove_at(key_index)
		for _i in 2:
			var leg := f >= 15 and randf() < 0.45
			drop_item(c.position, ItemData.gear_roll(1.0 if leg else 0.0, 1.0))
		drop_gold(c.position, randi_range(25, 69))
	c.open_chest()
	for _i in randi_range(2, 3):
		var r := randf()
		if r < 0.48:
			drop_gold(c.position, int((randf() * 3 + 4) * (1 + (f - 1) * 0.1)))
		elif r < 0.74:
			drop_item(c.position, ItemData.make("potion_red" if randf() < 0.6 else "potion_blue"))
		elif f >= 10 and r < 0.82:
			drop_item(c.position, ItemData.make("stone_shard_" + ItemData.STONES.pick_random()))
		else:
			var leg := 0.0 if f < 10 else (0.015 if f < 25 else 0.035)
			var rare := 0.18 if f < 10 else (0.24 if f < 25 else 0.30)
			drop_item(c.position, ItemData.gear_roll(leg, rare))
	Log.add("Sandık açıldı.", "loot")
	_quest_event("chest")
	dialogue.event("first_chest")
	return true


func _rescue(c: Captive) -> void:
	var f := Game.floor_number
	var reward := ""
	var reward_color := UiKit.GOLD
	match c.type:
		"peasant":
			var g := int(20 + f * 2.5 + randf() * 30)
			Game.add_gold(g)
			Log.add("Köylü kurtarıldı: +%d altın" % g, "loot")
			reward = "+%d Altın" % g
		"soldier":
			var a := 1 + f / 25
			player.add_permanent("atk", a)
			Log.add("Asker kurtarıldı: kalıcı +%d hasar" % a, "level")
			reward = "Kalıcı +%d Hasar" % a
			reward_color = Color("ff9d5c")
		"mage":
			var h := 10 + (f / 8) * 5
			player.add_permanent("maxHp", h)
			player.heal(h)
			Log.add("Büyücü kurtarıldı: kalıcı +%d can" % h, "level")
			reward = "Kalıcı +%d Can" % h
			reward_color = Color("ff6b7a")
		"merchant":
			var g2 := int(45 + f * 4 + randf() * 50)
			Game.add_gold(g2)
			Log.add("Tüccar kurtarıldı: +%d altın" % g2, "loot")
			reward = "+%d Altın" % g2
	if reward != "":
		hud.toast("TUTSAK KURTARILDI: " + reward.to_upper())
		float_text(player.position + Vector2(0, -70), reward, reward_color)
	Sfx.play("rescue")
	Game.run_rescues += 1
	Game.lifetime_rescues += 1
	Game.save()
	var npc_type = c.type
	later(24, func(): dialogue.npc(npc_type))
	if Game.lifetime_rescues == 1:
		dialogue.event("first_npc_rescue")
	elif Game.lifetime_rescues == 5:
		dialogue.event("many_rescues")
	_quest_event("rescue")
	for n in Game.check_achievements():
		hud.toast("BAŞARIM: " + n)
	burst(c.position, 40, Color("ffd700"))
	c.remove()


# ── Sonlar ───────────────────────────────────────────────────────────

func resolve_ending(choice: String) -> void:
	# Tek sefer: ikinci tıklama yeniden ruh taşı vermesin, kaydetmesin.
	if state != "ending_choice":
		return
	state = "ending"
	Game.clear_run()
	var stones := 0
	match choice:
		"light": stones = 350 + int(Game.kills * 0.5) + Game.run_rescues * 20
		"iron": stones = 200 + int(Game.kills * 0.5)
		"dark": stones = 100 + int(Game.kills * 0.8)
	Game.soul_stones += stones
	Game.unlock("dungeon_conqueror")
	Game.save()
	screens.show_ending(choice, stones)
