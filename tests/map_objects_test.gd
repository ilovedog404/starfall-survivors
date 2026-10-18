extends Node


func _ready() -> void:
	print("MAP_OBJECTS_TEST_START")
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		_fail("無法載入主場景")
		return
	var game = packed_scene.instantiate()
	get_tree().root.add_child(game)
	game.set_process(false)
	game._choose_character("epathy")
	game._start_game()

	var kinds: Dictionary = {}
	for cell_x in range(-3, 4):
		for cell_y in range(-3, 4):
			kinds[game._map_object_kind(cell_x, cell_y)] = true
	if not kinds.has("repair") or not kinds.has("supply") or not kinds.has("pylon"):
		_fail("地圖區塊沒有穩定分布三種互動物件")
		return

	game.player_health = 30.0
	game.player_shield = 0.0
	var repair := {"key": "test:repair", "kind": "repair", "pos": Vector2.ZERO}
	game._activate_map_object(repair)
	if game.player_health != 58.0 or game.player_shield != 12.0 or not game.activated_map_objects.has("test:repair"):
		_fail("星源修復站沒有回復生命與護盾")
		return
	var repaired_health: float = game.player_health
	game._activate_map_object(repair)
	if game.player_health != repaired_health:
		_fail("星源修復站可被重複使用")
		return

	var rerolls_before: int = game.rerolls_remaining
	var total_xp_before: float = game.experience + game.level * 1000.0
	game._activate_map_object({"key": "test:supply", "kind": "supply", "pos": Vector2(80.0, 0.0)})
	var total_xp_after: float = game.experience + game.level * 1000.0
	if game.rerolls_remaining != rerolls_before + 1 or total_xp_after <= total_xp_before:
		_fail("先遣補給箱沒有提供經驗與重骰")
		return

	game._start_game()
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = Vector2(80.0, 0.0)
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	game._spawn_mutant("chaser")
	game.enemies[1]["pos"] = Vector2(420.0, 0.0)
	game.enemies[1]["hp"] = 500.0
	game.enemies[1]["max_hp"] = 500.0
	game._activate_map_object({"key": "test:pylon", "kind": "pylon", "pos": Vector2.ZERO})
	if float(game.enemies[0]["hp"]) >= 500.0 or float(game.enemies[1]["hp"]) != 500.0:
		_fail("過載脈衝塔的範圍傷害不正確")
		return

	print("MAP_OBJECTS_TEST_PASS: repair/supply/pylon/one-use/deterministic-sectors")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("MAP_OBJECTS_TEST_FAIL: " + message)
	get_tree().quit(1)
