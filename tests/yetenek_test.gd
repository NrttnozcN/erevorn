extends Node
## Kahraman yetenekleri: F / V kilitleri, her tarzda hasar, seviye rütbesi, El Çabukluğu kartı, seviye büyümesi.

var fails := 0
var main: Main


func _ready() -> void:
	DeathCinematic.enabled = false
	Game.save_path = "user://test_kayit.cfg"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(20)
	for style in ["warrior", "ranger", "mage"]:
		main.screens.close()
		main.start_run(style)
		main.tutorial_step = -1
		await _wait(10)
		var p := main.player
		_check(not p.skills.f_unlocked() and not p.skills.v_unlocked(), "%s: F ve V başta kilitli" % style)
		var cd0 := p.skills.f_cd
		p.skills.use_f()
		_check(p.skills.f_cd == cd0, "%s: kilitli F çalışmaz" % style)
		Game.bosses_killed = 3
		_check(p.skills.f_unlocked() and p.skills.v_unlocked(), "%s: 3 bossdan sonra F ve V açık" % style)
		# Rütbe ve seviye büyümesi.
		var atk0 := p.total_atk()
		var r0 := p.skills.rank()
		for i in 10:
			p.gain_xp(p.next_xp)
			main.screens.close()
		_check(p.skills.rank() == r0 + 2, "%s: 10 seviyede rütbe I -> III (%d)" % [style, p.skills.rank()])
		_check(p.total_atk() >= atk0 + 20, "%s: seviyeyle saldırı arttı (%d -> %d)" % [style, atk0, p.total_atk()])
		# F hasar verir.
		var e := await _dummy(Vector2(90, 0))
		p.aim = 0.0
		p.skills.use_f()
		for i in 30:
			p.skills.tick()
			await get_tree().physics_frame
		_check(not is_instance_valid(e) or e.hp < e.max_hp, "%s: F hasar verdi" % style)
		# V hasar verir.
		var e2 := await _dummy(Vector2(70, 30))
		p.skills.use_v()
		_check(p.skills.v_left > 0, "%s: V etkin" % style)
		for i in 320:
			p.skills.tick()
			await get_tree().physics_frame
		_check(not is_instance_valid(e2) or e2.hp < e2.max_hp, "%s: V hasar verdi" % style)
		# El Çabukluğu kartı saldırı beklemesini kısaltır.
		p.phase = "idle"
		p.attack_cd = 0
		p._try_attack()
		var slow_cd := p.attack_cd
		p.apply_upgrade("atkspd")
		p.phase = "idle"
		p.attack_cd = 0
		p._try_attack()
		_check(p.attack_cd < slow_cd, "%s: El Çabukluğu saldırıyı hızlandırdı (%d -> %d)" % [style, slow_cd, p.attack_cd])
		Game.bosses_killed = 0
	print("YETENEK: " + ("TAMAM" if fails == 0 else "%d HATA" % fails))
	get_tree().quit(1 if fails > 0 else 0)


## Oyuncunun yanına dayanıklı bir hedef koyar.
func _dummy(off: Vector2) -> Enemy:
	for e in main.enemies:
		if is_instance_valid(e):
			e.remove()
	await _wait(2)
	main._cleanup()
	var e := main.spawn_enemy("skeleton", main.player.position + off)
	if e == null or not main.world.circle_free(e.position, 10):
		main.player.position = main.world.player_spawn
		e = main.spawn_enemy("skeleton", main.player.position + off)
	e.max_hp = 99999
	e.hp = 99999
	e.attack_cd = 9999
	e.speed = 0.0
	return e


func _check(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  HATA ") + what)
	if not ok:
		fails += 1


func _wait(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
		if main.state in ["upgrade", "story"]:
			main.screens.close()
		main.dialogue.reset()
