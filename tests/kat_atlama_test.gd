extends Node
## Gizli kat atlama denemesi. Pencereli çalışırsa user://kat_*.png görüntüleri de alır.
## godot --path . res://tests/kat_atlama_test.tscn

var main: Main
var fails := 0


func _ready() -> void:
	DeathCinematic.enabled = false
	Game.save_path = "user://test_kayit.cfg"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(30)
	main.screens.close()
	main.start_run("ranger")
	main.tutorial_step = -1
	await _wait(10)
	var ev := InputEventKey.new()
	ev.keycode = KEY_K
	ev.pressed = true
	ev.ctrl_pressed = true
	ev.shift_pressed = true
	_check(main._secret_keys(ev), "Ctrl+Shift+K yakalandı")
	_check(main._jump_box.visible, "kutu açıldı")
	main._on_jump_submitted("37")
	await _wait(10)
	_check(Game.floor_number == 37, "37. kata gidildi")
	ev.keycode = KEY_G
	main._secret_keys(ev)
	_check(main.player.god_mode, "ölümsüzlük açıldı")
	for f in [2, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]:
		main.goto_floor(f)
		await _wait(40)
		_check(Game.floor_number == f and main.player.alive(), "kat %d" % f)
		if f % 10 == 0:
			_check(main.boss != null, "kat %d boss var" % f)
		if DisplayServer.get_name() != "headless":
			if f == 2 and main.enemies.size() > 0:
				main.player.position = main.enemies[0].position + Vector2(-110, 0)
				main.camera.position = main.player.position
				main.touch_move = Vector2.RIGHT
				await _wait(14)
				_shot("kat_02_yurume")
				main.touch_move = Vector2.ZERO
			elif main.boss:
				main.player.position = main.boss.position + Vector2(-170, 30)
				main.camera.position = main.player.position
				await _wait(30)
				_shot("kat_%03d" % f)
	main._on_jump_submitted("500")
	await _wait(5)
	_check(Game.floor_number == 100, "sınır 100")
	print("KAT ATLAMA: ", "TAMAM" if fails == 0 else "%d HATA" % fails)
	get_tree().quit(fails)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("HATA: ", what)


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame
		if main.state in ["upgrade", "story"]:
			main.screens.close()
		main.dialogue.reset()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("görüntü: ", name)
