extends Node
## Koşu durumu (kat, altın, can hakkı, görev...) ve kalıcı kayıt (ruh taşları, başarımlar).

signal changed

const SAVE_PATH := "user://erevorn.cfg"
const ACHIEVEMENTS := {
	"first_boss": "İlk Zafer", "explorer": "Zindan Kaşifi", "dungeon_conqueror": "Zindan Fatihi",
	"slime_slayer": "Balçık Katili", "millionaire": "Milyarder", "rescuer_hero": "Büyük Kurtarıcı",
	"centurion": "100 Öldürme",
}

var save_path := SAVE_PATH

# Koşu
var style := "warrior"
var floor_number := 1
var gold := 0
var lives := 3
var max_lives := 3
var kills := 0
var run_rescues := 0
var training_purchases := 0
var barter := false
var lifesteal_upgrade := false
var bosses_killed := 0
var quests_completed := 0
var quest := {}
var hit_this_floor := false
var triggered := {}
## 60. katta Lyra kurtulunca Sera'nın ruhu Arktan'a bağlanır (koşu boyunca).
var sera_bound := false

# Kalıcı
var soul_stones := 0
var meta := {"atk": 0, "def": 0, "hp": 0, "crit": 0, "life": 0}
var achievements := {}
var slime_kills := 0
var lifetime_rescues := 0
var tutorial_done := false


func _ready() -> void:
	_register_input()
	load_save()


func new_run(chosen_style: String) -> void:
	style = chosen_style
	floor_number = 1
	gold = 0
	max_lives = mini(5, 3 + int(meta.life))
	lives = max_lives
	kills = 0
	run_rescues = 0
	training_purchases = 0
	barter = false
	lifesteal_upgrade = false
	bosses_killed = 0
	quests_completed = 0
	quest = {}
	hit_this_floor = false
	triggered = {}
	sera_bound = false
	changed.emit()


func zone() -> int:
	return EnemyData.zone_of(floor_number)


func is_boss_floor() -> bool:
	return floor_number % 10 == 0


func add_gold(amount: int) -> void:
	gold += amount
	if gold >= 1000:
		unlock("millionaire")
	changed.emit()


func unlock(key: String) -> bool:
	if achievements.get(key, false):
		return false
	achievements[key] = true
	save()
	return true


## Başarımları kontrol eder; yeni açılanların adlarını döndürür.
func check_achievements() -> Array:
	var fresh: Array = []
	var rules := {
		"first_boss": floor_number > 10, "explorer": floor_number >= 50, "dungeon_conqueror": floor_number >= 100,
		"slime_slayer": slime_kills >= 100, "millionaire": gold >= 1000, "rescuer_hero": lifetime_rescues >= 10,
		"centurion": kills >= 100,
	}
	for k: String in rules:
		if rules[k] and unlock(k):
			fresh.append(ACHIEVEMENTS[k])
	return fresh


func title() -> String:
	if floor_number >= 100 or achievements.get("dungeon_conqueror", false): return "Zindan Fatihi"
	if floor_number >= 90: return "Efsane Kahraman"
	if floor_number >= 70: return "Kaos Lordu"
	if floor_number >= 50: return "Zindan Efendisi"
	if floor_number >= 30: return "Cesur Savaşçı"
	if floor_number >= 20 or kills >= 100: return "Efsanevi Katil"
	if floor_number >= 10: return "Zindan Avcısı"
	if floor_number >= 5: return "Cesur Kahraman"
	if lifetime_rescues >= 5: return "Büyük Kurtarıcı"
	return ""


## Her kata bir görev (game.js:716-768).
func assign_quest() -> void:
	var target := 3 + floor_number / 15
	if is_boss_floor():
		quest = {"id": "hunter", "title": "BOSS AVCISI", "desc": "Muhafızı yen", "target": 1}
	else:
		quest = [
			{"id": "kill", "title": "AVCI", "desc": "%d düşman öldür" % target, "target": target},
			{"id": "nohit", "title": "GÖLGE", "desc": "Hasar almadan katı temizle", "target": 1},
			{"id": "potion", "title": "SİMYACI", "desc": "1 iksir kullan", "target": 1},
			{"id": "rescue", "title": "KURTARICI", "desc": "1 tutsak kurtar", "target": 1},
			{"id": "chest", "title": "HAZİNEDAR", "desc": "2 sandık aç", "target": 2},
		].pick_random()
	quest.progress = 0
	quest.done = false
	hit_this_floor = false


## Her 10. tamamlanan görev ayrıca bir Altın Anahtar verir.
func quest_gives_key() -> bool:
	return quests_completed > 0 and quests_completed % 10 == 0


## Görev ilerlemesi. Tamamlanınca ödül altınını döndürür (yoksa 0).
func quest_event(kind: String) -> int:
	if quest.is_empty() or quest.done:
		return 0
	var match_ok := false
	match quest.id:
		"kill": match_ok = kind == "kill"
		# Yalnızca katın bossu sayılır; bossun çağırdığı yardımcılar sayılmaz.
		"hunter": match_ok = kind == "boss_kill"
		"potion": match_ok = kind == "potion"
		"rescue": match_ok = kind == "rescue"
		"chest": match_ok = kind == "chest"
		"nohit": match_ok = kind == "floor_cleared" and not hit_this_floor
	if not match_ok:
		return 0
	quest.progress += 1
	if quest.progress >= quest.target:
		quest.done = true
		quests_completed += 1
		var reward := 30 + int(floor_number * 2.5)
		add_gold(reward)
		return reward
	changed.emit()
	return 0


func soul_stone_reward() -> int:
	return int(floor_number * 2 + kills * 0.1)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(save_path)  # yarım koşu kaydı ("kosu") korunur
	cfg.set_value("kalici", "ruh_tasi", soul_stones)
	cfg.set_value("kalici", "meta", meta)
	cfg.set_value("kalici", "basarimlar", achievements)
	cfg.set_value("kalici", "balcik", slime_kills)
	cfg.set_value("kalici", "kurtarma", lifetime_rescues)
	cfg.set_value("kalici", "egitim_tamam", tutorial_done)
	cfg.save(save_path)


## Yarım kalan koşu: her kata girişte yazılır, "DEVAM ET" o katın başından sürdürür.
const RUN_KEYS := ["style", "floor_number", "gold", "lives", "max_lives", "kills", "run_rescues", "training_purchases",
	"barter", "lifesteal_upgrade", "bosses_killed", "quests_completed", "quest", "triggered", "sera_bound"]
const PLAYER_KEYS := ["base", "hp", "level", "xp", "next_xp", "equipment", "inventory", "attack_cd_base", "dash_cd_max", "perm", "full_power"]


func save_run(p: Node) -> void:
	var cfg := ConfigFile.new()
	cfg.load(save_path)
	var run := {}
	for k in RUN_KEYS:
		run[k] = get(k)
	var pl := {}
	for k in PLAYER_KEYS:
		pl[k] = p.get(k)
	cfg.set_value("kosu", "oyun", run)
	cfg.set_value("kosu", "oyuncu", pl)
	cfg.save(save_path)


func has_run() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(save_path) == OK and cfg.has_section_key("kosu", "oyun")


func saved_run() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK or not cfg.has_section_key("kosu", "oyun"):
		return {}
	return {"oyun": cfg.get_value("kosu", "oyun", {}), "oyuncu": cfg.get_value("kosu", "oyuncu", {})}


## Koşuyu kayıttan geri yükler (oyuncu ayrıca main tarafında).
func restore_run(run: Dictionary) -> void:
	new_run(run.get("style", "warrior"))
	for k in RUN_KEYS:
		if run.has(k):
			set(k, run[k])
	changed.emit()


func clear_run() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	if cfg.has_section("kosu"):
		cfg.erase_section("kosu")
		cfg.save(save_path)


func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	soul_stones = cfg.get_value("kalici", "ruh_tasi", 0)
	meta.merge(cfg.get_value("kalici", "meta", {}), true)
	achievements = cfg.get_value("kalici", "basarimlar", {})
	slime_kills = cfg.get_value("kalici", "balcik", 0)
	lifetime_rescues = cfg.get_value("kalici", "kurtarma", 0)
	tutorial_done = cfg.get_value("kalici", "egitim_tamam", false)


func _register_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"dash": [KEY_SPACE], "interact": [KEY_E], "skill_q": [KEY_Q], "skill_r": [KEY_R], "skill_f": [KEY_F], "skill_t": [KEY_T],
		"bag": [KEY_I, KEY_B], "potion_1": [KEY_1, KEY_KP_1], "potion_2": [KEY_2, KEY_KP_2], "confirm": [KEY_ENTER, KEY_KP_ENTER], "cancel": [KEY_ESCAPE],
	}
	for action: String in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k: int in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", m)
