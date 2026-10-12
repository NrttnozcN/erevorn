extends Node
## Eski oyunun ses efektleri (sound.js:758-826) ve menü / boss müzikleri.
## Dosyalar assets/sounds/ altında; eksik dosya sessizce atlanır.

const FILES := {
	"archer": "archer_attack_sound.wav", "mage": "mage_attack_sound.wav", "critical": "critical_damage_sound.wav",
	"gold": "gold_pick_sound.wav", "item": "item_pick_sound.wav", "rescue": "npc_kurtarma_sound.wav",
	"salvage": "salvage_sound_parcalama_.wav", "soulstone": "soulstones_craft_sound.wav", "forge": "forge_craft_sound.wav",
	"boss_victory": "boss_death_sound.mp3", "eq_bow": "bow_equipt_sound.mp3", "eq_staff": "staff_equip_sound.wav",
	"eq_armor": "armor_equetmant_sound.wav", "eq_helmet": "kask_equipt_sound.wav", "eq_necklace": "kolye_kusanma_sound.wav",
	"eq_earrings": "kupe_equip_sound.wav", "eq_shield": "kalkan_kusanma_sound.wav",
}
const VOLUME := {"gold": -3.0, "item": -2.0, "boss_victory": -1.0, "archer": -7.0, "mage": -7.0, "swing": -6.0, "critical": -5.0}
## Sık çalan vuruş sesleri: kısa, birkaç farklı tonda varyasyon (assets/sounds/sfx/); her çalışta biri seçilir,
## perde de hafif oynar. Böylece aynı ses üst üste binip kulak tırmalamaz.
const VARIANTS := {
	"archer": ["sfx/ok_1.wav", "sfx/ok_2.wav", "sfx/ok_3.wav"],
	"mage": ["sfx/buyu_1.wav", "sfx/buyu_2.wav", "sfx/buyu_3.wav"],
	"swing": ["sfx/kilic_1.wav", "sfx/kilic_2.wav", "sfx/kilic_3.wav"],
	"critical": ["sfx/kritik_1.wav", "sfx/kritik_2.wav"],
}
## Aynı sesin iki çalışı arasındaki en kısa süre (ms) ve aynı anda en fazla kaç kopyası.
const MIN_GAP := {"archer": 110, "mage": 140, "swing": 120, "critical": 180, "gold": 60, "item": 80}
const MAX_SAME := 2
const SETTINGS_PATH := "user://ayarlar.cfg"

## Ses ayarları (0–1): genel, efekt, müzik, konuşma. Duraklatma menüsünden değişir, kaydedilir.
var volume := 0.6
var sfx_volume := 0.8
var music_volume := 0.6
var voice_volume := 1.0
var muted := false
var _last := {}
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_key := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)


func _stream(file: String) -> AudioStream:
	if _streams.has(file):
		return _streams[file]
	var path := "res://assets/sounds/" + file
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_streams[file] = s
	return s


func play(key: String) -> void:
	if muted or not (FILES.has(key) or VARIANTS.has(key)):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(key, -100000)) < int(MIN_GAP.get(key, 0)):
		return
	var file: String = VARIANTS[key].pick_random() if VARIANTS.has(key) else FILES[key]
	var s := _stream(file)
	if s == null:
		return
	var same := 0
	for p in _players:
		if p.playing and p.get_meta("key", "") == key:
			same += 1
	if same >= MAX_SAME:
		return
	for p in _players:
		if not p.playing:
			_last[key] = now
			p.stream = s
			p.set_meta("key", key)
			p.volume_db = linear_to_db(maxf(volume * sfx_volume, 0.001)) + VOLUME.get(key, 0.0)
			p.pitch_scale = randf_range(0.94, 1.06) if VARIANTS.has(key) else 1.0
			p.play()
			return


func play_equip(item: Dictionary) -> void:
	match item.get("kind", ""):
		"bow": play("eq_bow")
		"staff": play("eq_staff")
		"shield": play("eq_shield")
		"helmet", "necklace", "earrings": play("eq_" + item.kind)
		_: play("eq_armor")


## "menu" ya da "boss"; boş anahtar müziği durdurur.
func music(key: String) -> void:
	if key == _music_key:
		return
	_music_key = key
	_music.stop()
	var file: String = {"menu": "iron_belltomb.mp3", "boss": "boss_figth_sound.mp3"}.get(key, "")
	if file == "" or muted:
		return
	var s := _stream(file)
	if s == null:
		return
	if s is AudioStreamMP3:
		(s as AudioStreamMP3).loop = true
	_music.stream = s
	_music.volume_db = music_db()
	_music.play()


func music_db() -> float:
	return linear_to_db(maxf(volume * music_volume * 0.6, 0.001))


func voice_db() -> float:
	return linear_to_db(maxf(volume * voice_volume, 0.001))


## Ayar değişince çalan müzik de anında güncellenir.
func set_level(which: String, v: float) -> void:
	set(which, clampf(v, 0.0, 1.0))
	_music.volume_db = music_db()
	save_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in ["volume", "sfx_volume", "music_volume", "voice_volume"]:
		cfg.set_value("ses", k, get(k))
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for k in ["volume", "sfx_volume", "music_volume", "voice_volume"]:
		set(k, float(cfg.get_value("ses", k, get(k))))


func set_muted(on: bool) -> void:
	muted = on
	if on:
		_music.stop()
	else:
		var k := _music_key
		_music_key = ""
		music(k)
