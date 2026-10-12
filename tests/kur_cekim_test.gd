extends Node
## Boss/düşman kesim kurulumu görsel kontrolü (pencereli). user://kur_*.png kaydeder.
## godot --path . res://tests/kur_cekim_test.tscn

var main: Main


func _ready() -> void:
	Game.save_path = "user://test_kayit.cfg"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(30)
	main.screens.close()
	main.start_run("ranger")
	main.tutorial_step = -1
	main.player.god_mode = true
	await _wait(10)
	for f in [20, 50, 90, 100]:
		main.goto_floor(f)
		await _wait(40)
		if main.boss:
			_frame_near(main.boss.position)
			await _wait(30)
			_shot("kur_boss_kat_%03d" % f)
	# Kârun: kat 100 bossunu kaldırıp finali doğrudan çağır.
	if main.boss:
		main.boss.remove()
		main.boss = null
	main._spawn_karun()
	await _wait(60)
	_frame_near(main.boss.position)
	await _wait(30)
	_shot("kur_karun_kat_100")
	# Bölge 4 odası: düzeltilen trol + zombi yan yana.
	main.goto_floor(35)
	await _wait(40)
	var p: Vector2 = main.player.position
	main.spawn_enemy("troll", p + Vector2(150, -30))
	main.spawn_enemy("zombie", p + Vector2(150, 70))
	main.spawn_enemy("troll", p + Vector2(-160, 40))
	await _wait(20)
	_shot("kur_dusman_kat_035")
	get_tree().quit(0)


func _frame_near(at: Vector2) -> void:
	main.player.position = at + Vector2(-170, 30)
	main.camera.position = main.player.position


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame
		if main.state in ["upgrade", "story"]:
			main.screens.close()
		main.dialogue.reset()


func _shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("görüntü: ", name)
