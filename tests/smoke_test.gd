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
	if not game.character_overlay.visible or game.run_started:
		_fail("角色選擇畫面沒有在啟動時顯示")
		return
	for character_id in ["epathy", "lucia", "claire", "rafari"]:
		game._choose_character(character_id)
		if game.selected_character != character_id:
			_fail("無法選擇角色：" + character_id)
			return
	game._choose_character("lucia")
	game._start_game()
	game._spawn_mutant("chaser")
	game.enemies[0]["hp"] = float(game.enemies[0]["max_hp"]) - 1.0
	if not game._use_character_skill() or float(game.enemies[0]["burn_time"]) <= 4.0:
		_fail("璐茜婭的全畫面引燃沒有套用")
		return

	game._show_character_select()
	game._choose_character("rafari")
	game._start_game()
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(40.0, 0.0)
	if not game._use_character_skill() or float(game.enemies[0]["slow_factor"]) != 0.0:
		_fail("菈法瑞的凍結沒有套用")
		return

	game._show_character_select()
	game._choose_character("claire")
	game._start_game()
	game.player_shield = 0.0
	if not game._use_character_skill() or game.player_shield <= 0.0:
		_fail("克萊兒的鐮環過載沒有回復護盾")
		return

	game._show_character_select()
	game._choose_character("epathy")
	game._start_game()
	if game.player_armor != 3.0 or game.close_damage_multiplier <= 1.0:
		_fail("埃帕蒂的初始被動沒有套用")
		return
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(40.0, 0.0)
	game.enemies[0]["hp"] = 200.0
	game.enemies[0]["max_hp"] = 200.0
	if not game._use_character_skill() or float(game.enemies[0]["hp"]) >= 200.0:
		_fail("埃帕蒂的環刃震退沒有造成傷害")
		return
	game._start_game()

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

	print("SMOKE_TEST_PASS: character-select/skills/status/movement/combat/xp/upgrade/apostle/result")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("SMOKE_TEST_FAIL: " + message)
	get_tree().quit(1)

