extends Node
## Ctrl+Shift+M (geliştirici tam güç): seviye 20, bütün yuvalarda Kızıl eşya, E / T açık, Gök Nöbetçisi zırhı.

var fails := 0

func _ready() -> void:
	DeathCinematic.enabled = false
	Game.save_path = "user://test_kayit.cfg"
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 20: await get_tree().physics_frame
	for style in ["warrior", "ranger", "mage"]:
		main.screens.close()
		main.start_run(style)
		for i in 5: await get_tree().physics_frame
		var p := main.player
		var a0 := p.total_atk()
		var ev := InputEventKey.new()
		ev.keycode = KEY_M; ev.pressed = true; ev.ctrl_pressed = true; ev.shift_pressed = true
		main._secret_keys(ev)
		var all_mythic := true
		for s in ItemData.SLOTS:
			if p.equipment[s].get("rarity", "") != "mythic": all_mythic = false
		var ok: bool = p.level == 20 and all_mythic and p.skills.f_unlocked() and p.skills.v_unlocked() and p.hero_stage() == 3 and p.total_atk() > a0 * 5
		if not ok:
			fails += 1
		print("  ok  " if ok else "  HATA ", style, ": seviye ", p.level, " rütbe ", p.skills.rank(), " saldırı ", a0, "->", p.total_atk(), " def ", p.total_def(), " can ", p.max_hp(), " kızıl:", all_mythic, " E/T:", p.skills.f_unlocked() and p.skills.v_unlocked(), " aşama:", p.hero_stage(), " silah:", p.equipment.weapon.name)
	print("TAM GÜÇ: " + ("TAMAM" if fails == 0 else "%d HATA" % fails))
	get_tree().quit(1 if fails > 0 else 0)
