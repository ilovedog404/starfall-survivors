extends Node


func _ready() -> void:
	print("SMOKE_TEST_START")
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("無法載入主場景")
		return

	var game = packed_scene.instantiate()
	get_tree().root.add_child(game)

	if game.level != 1 or game.scythe_level != 1:
		_fail("初始角色狀態不正確")
		return

	var starting_position: Vector2 = game.player_pos
	Input.action_press("move_right")
	game._update_player(0.5)
	Input.action_release("move_right")
	if game.player_pos.x <= starting_position.x:
		_fail("鍵盤移動沒有生效")
		return

	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(20.0, 0.0)
	var starting_hp: float = game.enemies[0]["hp"]
	game._fire_scythe_ring()
	if not game.enemies.is_empty() and float(game.enemies[0]["hp"]) >= starting_hp:
		_fail("星源鐮環沒有造成傷害")
		return

	game._gain_experience(100.0)
	if not game.choosing_upgrade or not game.upgrade_overlay.visible:
		_fail("升級三選一沒有開啟")
		return
	game._select_upgrade("needle")
	while game.pending_levels > 0:
		game._select_upgrade("health")
	if game.needle_level < 1:
		_fail("星針升級沒有套用")
		return

	get_tree().paused = false
	game._spawn_apostle()
	var boss_index := -1
	for index in game.enemies.size():
		if game.enemies[index]["boss"]:
			boss_index = index
			break
	if boss_index < 0:
		_fail("使徒沒有生成")
		return
	game._damage_enemy(boss_index, 999999.0)
	if not game.game_over or game.apostle_present:
		_fail("使徒討伐結算沒有觸發")
		return

	print("SMOKE_TEST_PASS: movement/combat/xp/upgrade/apostle/result")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("SMOKE_TEST_FAIL: " + message)
	get_tree().quit(1)

