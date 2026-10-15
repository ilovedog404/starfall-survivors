extends Node


func _ready() -> void:
	print("ENEMY_TYPES_TEST_START")
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

	game.enemies.clear()
	game._spawn_mutant("guardian")
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(300.0, 0.0)
	game.enemies[0]["support_cooldown"] = 0.0
	game.enemies[1]["pos"] = game.enemies[0]["pos"] + Vector2(40.0, 0.0)
	game._update_enemies(0.1)
	if float(game.enemies[1].get("guarded_time", 0.0)) <= 0.0:
		_fail("護衛型沒有替附近異變體施加防護")
		return
	var guarded_hp_before: float = game.enemies[1]["hp"]
	game._damage_enemy(1, 10.0, "other")
	if absf((guarded_hp_before - float(game.enemies[1]["hp"])) - 6.5) > 0.01:
		_fail("護衛防護沒有降低承受傷害")
		return

	game.enemies.clear()
	game._spawn_mutant("splitter")
	game.enemies[0]["pos"] = Vector2(180.0, 120.0)
	game.enemies[0]["hp"] = 1.0
	game._damage_enemy(0, 5.0, "other")
	if game.enemies.size() != 2:
		_fail("分裂型死亡後沒有生成兩個小型異變體")
		return
	for child in game.enemies:
		if child["kind"] != "chaser" or float(child["radius"]) > 10.0:
			_fail("分裂生成物的類型或尺寸錯誤")
			return

	game.enemies.clear()
	game.effects.clear()
	game._spawn_mutant("contaminant")
	game.enemies[0]["pos"] = game.player_pos + Vector2(160.0, 0.0)
	game.enemies[0]["contamination_cooldown"] = 0.0
	game._update_enemies(0.1)
	var hazard_index := -1
	for effect_index in game.effects.size():
		if game.effects[effect_index].get("kind", "") == "contamination":
			hazard_index = effect_index
			break
	if hazard_index < 0:
		_fail("污染型沒有留下地面危險區")
		return
	game.player_pos = game.effects[hazard_index]["pos"]
	game.player_invulnerable = 0.0
	game.player_shield = 0.0
	var health_before: float = game.player_health
	game._update_effects(0.1)
	if game.player_health >= health_before:
		_fail("污染地面沒有對玩家造成傷害")
		return

	game.enemies.clear()
	game.effects.clear()
	game._spawn_mutant("chaser")
	var normal_speed: float = game.enemies[0]["speed"]
	game._spawn_mutant("chaser", true, "swift")
	if game.enemies[1]["elite_affix"] != "swift" or float(game.enemies[1]["speed"]) <= normal_speed * 1.4:
		_fail("迅捷精英詞綴沒有提高移動速度")
		return

	game.enemies.clear()
	game._spawn_mutant("chaser", true, "shielded")
	var shielded_hp: float = game.enemies[0]["hp"]
	var elite_shield_before: float = game.enemies[0]["elite_shield"]
	game._damage_enemy(0, 10.0, "other")
	if float(game.enemies[0]["hp"]) != shielded_hp or float(game.enemies[0]["elite_shield"]) >= elite_shield_before:
		_fail("護盾精英詞綴沒有先吸收傷害")
		return

	game.enemies.clear()
	game.effects.clear()
	game._spawn_mutant("chaser", true, "explosive")
	game.enemies[0]["pos"] = Vector2(220.0, -40.0)
	game.enemies[0]["hp"] = 1.0
	game._damage_enemy(0, 5.0, "other")
	var explosion_index := -1
	for effect_index in game.effects.size():
		if game.effects[effect_index].get("kind", "") == "elite_explosion":
			explosion_index = effect_index
			break
	if explosion_index < 0:
		_fail("爆裂精英死亡後沒有產生爆炸預警")
		return
	game.player_pos = game.effects[explosion_index]["pos"]
	game.player_invulnerable = 0.0
	game.player_shield = 0.0
	health_before = game.player_health
	game._update_effects(1.0)
	if game.player_health >= health_before:
		_fail("爆裂精英的延遲爆炸沒有造成傷害")
		return

	print("ENEMY_TYPES_TEST_PASS: guardian/splitter/contaminant and swift/shielded/explosive elites")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error("ENEMY_TYPES_TEST_FAIL: " + message)
	get_tree().quit(1)
