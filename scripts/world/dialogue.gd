class_name Dialogue
extends Node
## Konuşma kutusu (dialogue.js). Satırlar sırayla gelir; harf harf yazılır (26 ms/harf).
## "Elle" satırlar E / Enter / Boşluk / tıklama bekler, "otomatik" satırlar 2.4 sn sonra geçer.
## Eski sürümdeki dt*1000 hatası yüzünden yazı anında çıkıp kayboluyordu; burada amaçlanan süreler kullanılıyor.

const CHAR_MS := 26.0
const AUTO_MS := 2400.0

var speakers := {}
var data := {}
var queue: Array = []
var current := {}
var shown := 0.0
var hold := 0.0
var cooldown := {}
## Sera ve Kârun'un sesli replikleri: satırın "voice" kimliği assets/sounds/ses/ altında varsa çalar.
static var voice_dir := "res://assets/sounds/ses/"
var _voice: AudioStreamPlayer


func _ready() -> void:
	var f := FileAccess.open("res://data/dialogue.json", FileAccess.READ)
	var parsed: Dictionary = JSON.parse_string(f.get_as_text())
	speakers = parsed.SPEAKERS
	data = parsed.DIALOGUE_DATA
	_voice = AudioStreamPlayer.new()
	_voice.bus = "Master"
	add_child(_voice)
	_voice.finished.connect(func():
		if current.is_empty():
			_play_next_seq())


## Kimliğin ses dosyası (mp3, ogg ya da wav); yoksa null.
static func voice_stream(id: String) -> AudioStream:
	for ext in ["mp3", "ogg", "wav"]:
		var path: String = voice_dir + id + "." + ext
		if ResourceLoader.exists(path):
			return load(path)
	return null


## Konuşma kutusu dışındaki sesler (hikaye kartı, son ekranı): kimlikleri sırayla çalar; yoksa atlar.
var _seq: Array = []


func play_voices(ids: Array) -> void:
	_seq = ids.duplicate()
	_voice.stop()
	_play_next_seq()


func _play_next_seq() -> void:
	while not _seq.is_empty():
		var s := voice_stream(_seq.pop_front())
		if s and not Sfx.muted:
			_voice.stream = s
			_voice.volume_db = linear_to_db(maxf(Sfx.volume, 0.05))
			_voice.play()
			return


func stop_voices() -> void:
	_seq.clear()
	_voice.stop()


func is_open() -> bool:
	return not current.is_empty()


func waiting_for_input() -> bool:
	return is_open() and not current.auto


func reset() -> void:
	queue.clear()
	current = {}
	cooldown.clear()
	if _voice:
		_voice.stop()


## Bir kez tetiklenen konuşma: zone_entry, floor_specific, boss_pre, boss_post, npc_rescue.
func trigger(group: String, key, auto := false) -> void:
	var tag := "%s:%s" % [group, key]
	if Game.triggered.has(tag):
		return
	var lines = data.get(group, {}).get(str(key))
	if lines == null:
		return
	Game.triggered[tag] = true
	_enqueue(lines, auto)


## Olay satırları (ilk öldürme, düşük can...). Aynı olay 22 sn içinde tekrarlanmaz.
func event(key: String, once := true) -> void:
	var now := Time.get_ticks_msec()
	if cooldown.has(key) and now - cooldown[key] < 22000:
		return
	if once and Game.triggered.has("event:" + key):
		return
	var lines = data.events.get(key)
	if lines == null:
		return
	cooldown[key] = now
	Game.triggered["event:" + key] = true
	_enqueue(lines, true)


func class_whisper(style: String) -> void:
	var key := "level_up_" + style
	var now := Time.get_ticks_msec()
	if cooldown.has(key) and now - cooldown[key] < 8000:
		return
	cooldown[key] = now
	_enqueue([data.events[key].pick_random()], true)


func npc(type: String) -> void:
	var variants = data.npc_rescue.get(type)
	if variants == null:
		return
	var pick = variants[Game.lifetime_rescues % variants.size()] if variants[0] is Array else variants
	_enqueue(pick, false)


func _enqueue(lines: Array, auto: bool) -> void:
	for l in lines:
		queue.append({"speaker": l.speaker, "text": l.text, "auto": auto, "voice": l.get("voice", "")})
	if current.is_empty():
		_next()


func _next() -> void:
	current = queue.pop_front() if not queue.is_empty() else {}
	shown = 0.0
	hold = 0.0
	_voice.stop()
	if not current.is_empty() and current.get("voice", "") != "" and not Sfx.muted:
		var s := voice_stream(current.voice)
		if s:
			_voice.stream = s
			_voice.volume_db = linear_to_db(maxf(Sfx.volume, 0.05))
			_voice.play()


func update(delta_ms: float) -> void:
	if current.is_empty():
		return
	var length: int = current.text.length()
	if shown < length:
		shown = minf(length, shown + delta_ms / CHAR_MS)
	elif current.auto:
		# Sesli satır, ses bitene kadar ekranda kalır.
		if _voice.playing:
			return
		hold += delta_ms
		if hold >= AUTO_MS:
			_next()


## Oyuncu ilerletme tuşuna bastı: önce tüm metni gösterir, sonra sonraki satıra geçer.
func advance() -> void:
	if current.is_empty():
		return
	if shown < current.text.length():
		shown = current.text.length()
	else:
		_next()


func visible_text() -> String:
	return current.text.substr(0, int(shown)) if is_open() else ""


func speaker_info() -> Dictionary:
	return speakers.get(current.get("speaker", "NARRATOR"), speakers.NARRATOR)
