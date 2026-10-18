extends Node


func _ready() -> void:
	print("EVOLUTION_TEST_START")
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("無法載入主場景")
		return

	var expected_names := {
		"epathy": "疾風環斬",
		"lucia": "全域燃燒脈衝",
		"claire": "超載鐮環",
		"rafari": "永凍領域",
	}
	for character_id in ["epathy", "lucia", "claire", "rafari"]:
		var game = packed_scene.instantiate()
		get_tree().root.add_child(game)
		game.set_process(false)
		game._choose_character(character_id)
		game._start_game()
		game.scythe_level = game._starter_max_level()
		var passive_id: String = game._starter_evolution_data()["passive_id"]
		game.meta_levels[passive_id] = game._starter_passive_required_level()
		game.evolution_cores_owned = 1
		var old_radius: float = game.scythe_radius
		var old_interval: float = game.scythe_interval
		if not game._try_consume_evolution_core():
			_fail("%s 達成條件後未消耗進化核心" % character_id)
			return
		if not game.scythe_evolved or game.evolution_cores_owned != 0:
			_fail("%s 的進化狀態或核心數量錯誤" % character_id)
			return
		if game._starter_evolution_name() != expected_names[character_id]:
			_fail("%s 的進化名稱錯誤" % character_id)
			return
		if game.scythe_radius <= old_radius or game.scythe_interval >= old_interval:
			_fail("%s 進化後沒有提高範圍並縮短間隔" % character_id)
			return

		game.effects.clear()
		game.enemies.clear()
		game.projectiles.clear()
		match character_id:
			"epathy":
				game.player_health = game.player_max_health - 10.0
				var health_before_slash: float = game.player_health
				_spawn_test_enemy(game, Vector2(90.0, 0.0))
				_spawn_test_enemy(game, Vector2(-90.0, 0.0))
				game._fire_scythe_ring()
				if game.enemies.size() != 2 or float(game.enemies[0]["hp"]) >= 500.0 or float(game.enemies[1]["hp"]) >= 500.0:
					_fail("疾風環斬沒有同時命中前後敵人")
					return
				var slash_effect_count := 0
				for effect in game.effects:
					if effect.get("kind", "") == "slash":
						slash_effect_count += 1
				if slash_effect_count != 2:
					_fail("疾風環斬沒有顯示雙向連斬")
					return
				if game.player_health <= health_before_slash:
					_fail("疾風環斬命中後沒有回復生命")
					return
			"lucia":
				_spawn_test_enemy(game, Vector2(120.0, 0.0))
				game._fire_scythe_ring()
				if game.projectiles.size() != 18:
					_fail("全域燃燒脈衝沒有射出 18 發進化霰彈")
					return
				if not game.projectiles[0].get("evolved", false) or float(game.projectiles[0]["burn_time"]) <= 2.4:
					_fail("全域燃燒脈衝沒有提高燃燒效果")
					return
			"claire":
				game.player_shield = 0.0
				_spawn_test_enemy(game, Vector2(80.0, 0.0))
				game._fire_scythe_ring()
				if game.player_shield <= 0.0 or game.effects.size() != 2:
					_fail("超載鐮環沒有產生雙重電圈並回復護盾")
					return
			"rafari":
				_spawn_test_enemy(game, Vector2(120.0, 0.0))
				_spawn_test_enemy(game, Vector2(-120.0, 0.0))
				_spawn_test_enemy(game, Vector2(0.0, 120.0))
				game._fire_scythe_ring()
				if game.effects.size() != 3:
					_fail("永凍領域沒有在三個目標腳下生成冰霜")
					return
				for enemy in game.enemies:
					if float(enemy["slow_factor"]) != 0.0 or float(enemy["slow_time"]) <= 0.0:
						_fail("永凍領域沒有凍結普通異變體")
						return
		get_tree().paused = false
		game.queue_free()

	print("EVOLUTION_TEST_PASS: epathy/lucia/claire/rafari core evolutions and evolved behaviors")
	get_tree().quit(0)


func _spawn_test_enemy(game, position: Vector2) -> void:
	game._spawn_mutant("chaser")
	game.enemies[-1]["pos"] = game.player_pos + position
	game.enemies[-1]["hp"] = 500.0
	game.enemies[-1]["max_hp"] = 500.0


func _fail(message: String) -> void:
	push_error("EVOLUTION_TEST_FAIL: " + message)
	get_tree().quit(1)
