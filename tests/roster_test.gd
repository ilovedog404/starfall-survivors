extends Node


func _ready() -> void:
	print("ROSTER_TEST_START")
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("無法載入主場景")
		return

	var summaries: Array[String] = []
	var character_ids := ["epathy", "lucia", "claire", "rafari"]
	for character_index in character_ids.size():
		var character_id: String = character_ids[character_index]
		var game = packed_scene.instantiate()
		get_tree().root.add_child(game)
		game.set_process(false)
		game.rng.seed = 7100 + character_index
		game._choose_character(character_id)
		game._start_game()
		game.player_max_health = 5000.0
		game.player_health = game.player_max_health
		game.player_armor += 24.0
		game.damage_multiplier = 1.45

		var skill_uses := 0
		var delta := 1.0 / 30.0
		var steps := int(90.0 / delta)
		for step in steps:
			if game.game_over:
				_fail("%s 在 90 秒回歸測試中意外結束" % character_id)
				return
			if game.choosing_upgrade:
				var choices: Array = game._available_upgrades()
				if choices.is_empty():
					_fail("%s 的升級池意外耗盡" % character_id)
					return
				game._select_upgrade(choices[step % choices.size()]["id"])
			game.player_pos += Vector2.from_angle(float(step) * 0.017 + character_index) * 1.6
			game.camera.position = game.player_pos
			game.skill_cooldown_remaining = maxf(0.0, game.skill_cooldown_remaining - delta)
			if step % 210 == 0:
				game.skill_cooldown_remaining = 0.0
				if game._use_character_skill():
					skill_uses += 1
			game._update_spawning(delta)
			game._update_weapons(delta)
			game._update_projectiles(delta)
			game._update_enemy_statuses(delta)
			game._update_enemies(delta)
			game._update_hostile_projectiles(delta)
			game._update_gems(delta)
			game._update_repair_cores(delta)
			game._update_effects(delta)
			game._enforce_runtime_limits()

		if game.kills < 20:
			_fail("%s 的 90 秒擊殺數異常過低：%d" % [character_id, game.kills])
			return
		if float(game.damage_by_source["starter"]) <= 0.0:
			_fail("%s 的專屬起始武器沒有累積傷害" % character_id)
			return
		if skill_uses < 5:
			_fail("%s 的主動戰技無法持續施放" % character_id)
			return
		summaries.append("%s=%d kills/%d damage/%d skills" % [character_id, game.kills, int(game.total_damage_dealt), skill_uses])
		get_tree().paused = false
		game.queue_free()

	print("ROSTER_TEST_PASS: " + "; ".join(summaries))
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("ROSTER_TEST_FAIL: " + message)
	get_tree().quit(1)
