extends Node


func _ready() -> void:
	print("PERFORMANCE_TEST_START")
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

	var expected_experience := 0.0
	for index in 700:
		game._spawn_mutant("chaser")
		var enemy_index: int = game.enemies.size() - 1
		var elite := index % 10 == 0
		game.enemies[enemy_index]["elite"] = elite
		game.enemies[enemy_index]["hp"] = 1.0
		expected_experience += 8.0 if elite else 1.0
		game._damage_enemy(enemy_index, 10.0, "starter")

	game._enforce_runtime_limits()
	if game.gems.size() > game.MAX_GEMS:
		_fail("經驗碎片超過執行期上限")
		return
	if game.repair_cores.size() > game.MAX_REPAIR_CORES:
		_fail("修復核心超過執行期上限")
		return
	if game.effects.size() > game.MAX_EFFECTS:
		_fail("特效超過執行期上限")
		return

	var stored_experience := 0.0
	for gem in game.gems:
		stored_experience += float(gem["value"])
	if not is_equal_approx(stored_experience, expected_experience):
		_fail("合併碎片時遺失經驗值")
		return

	for index in game.MAX_ENEMIES:
		game._spawn_mutant("chaser")
	var count_before: int = game.enemies.size()
	game.spawn_timer = -1.0
	game._update_spawning(0.0)
	if game.enemies.size() != count_before:
		_fail("異變體數量上限失效")
		return

	for index in game.MAX_PLAYER_PROJECTILES + 20:
		game.projectiles.append({
			"pos": game.player_pos + Vector2(-520.0, float(index % 20) * 8.0),
			"velocity": Vector2.ZERO,
			"damage": 0.0,
			"source": "other",
			"radius": 4.0,
			"life": 5.0,
		})
	for index in game.MAX_HOSTILE_PROJECTILES + 20:
		game.hostile_projectiles.append({"pos": game.player_pos + Vector2(500.0, 0.0), "velocity": Vector2.ZERO, "radius": 5.0, "damage": 0.0, "life": 5.0})
	game._enforce_runtime_limits()
	if game.projectiles.size() > game.MAX_PLAYER_PROJECTILES or game.hostile_projectiles.size() > game.MAX_HOSTILE_PROJECTILES:
		_fail("投射物執行期上限失效")
		return
	if game._is_world_visible(game.player_pos + Vector2(5000.0, 0.0)):
		_fail("畫面外物件沒有被視野裁切")
		return

	game.projectiles = game.projectiles.slice(0, 40)
	var stress_start := Time.get_ticks_usec()
	for frame in 30:
		game._update_projectiles(1.0 / 60.0)
	var stress_milliseconds := float(Time.get_ticks_usec() - stress_start) / 1000.0
	if stress_milliseconds > 15000.0:
		_fail("大量敵人投射物碰撞測試逾時：%.1fms" % stress_milliseconds)
		return

	print("PERFORMANCE_TEST_PASS: enemies=%d gems=%d repair_cores=%d effects=%d projectiles=%d hostile=%d collision_stress=%.1fms xp=%.0f" % [
		game.enemies.size(), game.gems.size(), game.repair_cores.size(), game.effects.size(), game.projectiles.size(), game.hostile_projectiles.size(), stress_milliseconds, stored_experience,
	])
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("PERFORMANCE_TEST_FAIL: " + message)
	get_tree().quit(1)
