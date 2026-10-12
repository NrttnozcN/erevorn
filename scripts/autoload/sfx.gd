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
const VOLUME := {"gold": -3.0, "item": -2.0, "boss_victory": -1.0}

var volume := 0.6
var muted := false
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_key := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	if muted or not FILES.has(key):
		return
	var s := _stream(FILES[key])
	if s == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.volume_db = linear_to_db(volume) + VOLUME.get(key, 0.0)
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
	_music.volume_db = linear_to_db(volume * 0.6)
	_music.play()


func set_muted(on: bool) -> void:
	muted = on
	if on:
		_music.stop()
	else:
		var k := _music_key
		_music_key = ""
		music(k)
