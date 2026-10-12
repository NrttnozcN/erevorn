extends Node
## Sesli konuşma denemesi: deneme klasöründeki ses, kimliği eşleşen satır açılınca çalar ve satır sesten önce geçmez.
## godot --headless --path . res://tests/ses_test.tscn

var main: Main


func _ready() -> void:
	Game.save_path = "user://test_kayit.cfg"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.screens.close()
	main.start_run("ranger")
	main.tutorial_step = -1
	var fails := 0
	var d := main.dialogue
	Dialogue.voice_dir = "res://tests/ses_ornek/"
	d.reset()
	Game.triggered.clear()
	d.trigger("zone_entry", 6, true)
	_ok(d.is_open() and d.current.speaker == "NARRATOR", "bölge 6 girişi açıldı")
	d._next()
	_ok(d.current.get("voice", "") == "sera_zone_entry_6_2", "Sera satırının ses kimliği (%s)" % d.current.get("voice", ""))
	_ok(d._voice.playing, "ses çalıyor")
	d.shown = d.current.text.length()
	d.update(3000.0)
	_ok(d.is_open() and d.current.get("voice", "") == "sera_zone_entry_6_2", "ses sürerken satır geçmedi")
	d._next()
	_ok(not d._voice.playing, "dosyası olmayan satırda sessiz (Kârun)")
	Dialogue.voice_dir = "res://assets/sounds/ses/"
	print("SES TESTİ: ", "TAMAM" if fails == 0 else "HATA")
	get_tree().quit(0)


var _fails := 0
func _ok(c: bool, m: String) -> void:
	print(("  ok  " if c else "  HATA ") + m)
