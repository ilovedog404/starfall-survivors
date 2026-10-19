extends Node


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("無法載入主場景")
		return

	var game = packed_scene.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.selected_character = "epathy"
	game._start_game()
	if not game.run_started or game._starter_weapon_name() != "疾風短刃":
		_fail("埃帕蒂角色資料或開戰流程失敗")
		return
	if game.player_armor != 3.0 or not is_equal_approx(game.close_damage_multiplier, 1.2):
		_fail("埃帕蒂被動沒有正確套用")
		return

	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(60.0, 0.0)
	var health_before := float(game.enemies[0]["hp"])
	game._fire_weapon("starter", 1)
	if game.enemies.is_empty() or float(game.enemies[0]["hp"]) >= health_before:
		_fail("埃帕蒂疾風短刃沒有造成傷害")
		return
	if game.effects.is_empty() or String(game.effects[-1]["kind"]) != "slash":
		_fail("埃帕蒂斬擊特效沒有建立")
		return

	for next_level in range(2, 9):
		game._apply_weapon_upgrade("starter")
	if game._weapon_level("starter") != 8:
		_fail("埃帕蒂起始武器無法升至 Lv.8")
		return

	print("EPATHY_MODULE_TEST_OK")
	game.queue_free()
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("EPATHY_MODULE_TEST_FAIL: " + message)
	get_tree().quit(1)
