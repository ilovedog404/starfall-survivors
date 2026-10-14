extends Node


func _ready() -> void:
	print("SIMULATION_TEST_START")
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("無法載入主場景")
		return

	var game = packed_scene.instantiate()
	get_tree().root.add_child(game)
	game.set_process(false)
	game._choose_character("claire")
	game._start_game()
	game.player_max_health = 9999.0
	game.player_health = game.player_max_health
	game.player_armor = 50.0
	game.damage_multiplier = 2.0

	var delta := 1.0 / 30.0
	var steps := int(246.0 / delta)
	for step in steps:
		if game.game_over:
			_fail("使徒生成前遊戲意外結束")
			return
		if game.choosing_upgrade:
			var choices: Array = game._available_upgrades()
			if choices.is_empty():
				_fail("升級池意外耗盡")
				return
			game._select_upgrade(choices[0]["id"])
		game.player_pos += Vector2.from_angle(float(step) * 0.013) * 1.8
		game.camera.position = game.player_pos
		game.skill_cooldown_remaining = maxf(0.0, game.skill_cooldown_remaining - delta)
		if step % 240 == 0:
			game.skill_cooldown_remaining = 0.0
			game._use_character_skill()
		game._update_spawning(delta)
		game._update_weapons(delta)
		game._update_projectiles(delta)
		game._update_enemy_statuses(delta)
		game._update_enemies(delta)
		game._update_hostile_projectiles(delta)
		game._update_gems(delta)
		game._update_effects(delta)

	if not game.apostle_spawned or not game.apostle_present:
		_fail("完整局模擬沒有生成使徒")
		return
	var boss_index := -1
	for index in game.enemies.size():
		if game.enemies[index]["boss"]:
			boss_index = index
			break
	if boss_index < 0:
		_fail("使徒狀態與敵人列表不同步")
		return
	game._damage_enemy(boss_index, 999999.0)
	if not game.game_over or game.apostle_present:
		_fail("完整局模擬無法完成使徒結算")
		return

	print("SIMULATION_TEST_PASS: 246 seconds, %d kills, level %d" % [game.kills, game.level])
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("SIMULATION_TEST_FAIL: " + message)
	get_tree().quit(1)
