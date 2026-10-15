extends Node


func _ready() -> void:
	print("ARSENAL_TEST_START")
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

	var initial_ids := _upgrade_ids(game._available_upgrades())
	for weapon_id in ["drone", "gravity", "meteor"]:
		if not weapon_id in initial_ids:
			_fail("初始升級池缺少共通武器：%s" % weapon_id)
			return
		game.pending_levels = 1
		game._select_upgrade(weapon_id)
	if game.drone_level != 1 or game.gravity_level != 1 or game.meteor_level != 1:
		_fail("共通武器取得等級錯誤")
		return

	_spawn_test_enemy(game, Vector2(80.0, 0.0))
	game._fire_watch_drone()
	if game.projectiles.is_empty() or game.projectiles[0].get("kind", "") != "drone_bolt":
		_fail("守望無人機沒有發射專屬光彈")
		return
	game._update_projectiles(0.08)
	if float(game.damage_by_source["drone"]) <= 0.0:
		_fail("守望無人機沒有造成或記錄傷害")
		return

	game.enemies.clear()
	_spawn_test_enemy(game, Vector2(55.0, 0.0))
	_spawn_test_enemy(game, Vector2(105.0, 0.0))
	var outer_x_before: float = game.enemies[1]["pos"].x
	game._fire_gravity_singularity()
	if game.effects.is_empty() or game.effects[-1]["kind"] != "gravity" or float(game.enemies[1]["pos"].x) >= outer_x_before:
		_fail("重力奇點沒有牽引附近異變體")
		return
	if float(game.damage_by_source["gravity"]) <= 0.0:
		_fail("重力奇點沒有造成或記錄傷害")
		return

	game.effects.clear()
	game.enemies.clear()
	_spawn_test_enemy(game, Vector2(90.0, 0.0))
	game._fire_meteor_round()
	if game.effects.is_empty() or game.effects[-1]["kind"] != "meteor":
		_fail("隕炎彈沒有產生爆炸特效")
		return
	if float(game.damage_by_source["meteor"]) <= 0.0 or float(game.enemies[0]["burn_time"]) <= 0.0:
		_fail("隕炎彈沒有造成爆炸與燃燒")
		return

	game.enemies.clear()
	game.projectiles.clear()
	_spawn_test_enemy(game, Vector2(90.0, 0.0))
	game._fire_watch_drone()
	var drone_damage_before: float = game.projectiles[0]["damage"]
	game.projectiles.clear()
	game.pending_levels = 1
	game._select_upgrade("precision")
	game._fire_watch_drone()
	if float(game.projectiles[0]["damage"]) <= drone_damage_before:
		_fail("精密核心沒有提高投射武器傷害")
		return
	game.player_health = game.player_max_health - 20.0
	game.pending_levels = 1
	game._select_upgrade("recovery")
	var health_before_recovery: float = game.player_health
	game._update_passive_recovery(5.0)
	if game.player_health <= health_before_recovery:
		_fail("修復奈米機沒有持續回復生命")
		return

	game.needle_level = 5
	game.meta_levels["cooldown"] = 3
	game.evolution_cores_owned = 1
	if not game._try_consume_evolution_core() or not game.needle_evolved or game.evolution_cores_owned != 0:
		_fail("追星蜂群沒有統一使用進化核心流程")
		return

	game.needle_level = 1
	game.storm_level = 1
	if game._weapon_slot_count() != game.MAX_WEAPON_SLOTS or game._can_offer_common_weapon(0):
		_fail("六格武器持有上限沒有生效")
		return
	game.meta_levels = {"health": 1, "speed": 1, "pickup": 1, "armor": 1, "damage": 1, "cooldown": 1, "area": 0, "recovery": 0, "precision": 0}
	if game._passive_slot_count() != game.MAX_PASSIVE_SLOTS:
		_fail("六格能力持有數計算錯誤")
		return
	if "area" in _upgrade_ids(game._available_upgrades()):
		_fail("能力滿六格後仍出現未取得的廣域線圈")
		return
	if not "health" in _upgrade_ids(game._available_upgrades()):
		_fail("能力滿格後已持有能力無法繼續升級")
		return

	var old_drone_interval: float = game.drone_interval
	var old_gravity_interval: float = game.gravity_interval
	var old_meteor_interval: float = game.meteor_interval
	game.pending_levels = 1
	game._select_upgrade("cooldown")
	if game.drone_interval >= old_drone_interval or game.gravity_interval >= old_gravity_interval or game.meteor_interval >= old_meteor_interval:
		_fail("冷卻模組沒有影響新增共通武器")
		return
	var old_gravity_radius: float = game.gravity_radius
	var old_meteor_radius: float = game.meteor_radius
	game.meta_levels["area"] = 1
	game.pending_levels = 1
	game._select_upgrade("area")
	if game.gravity_radius <= old_gravity_radius or game.meteor_radius <= old_meteor_radius:
		_fail("廣域線圈沒有影響新增範圍武器")
		return
	game._update_build_text()
	for weapon_name in ["守望無人機", "重力奇點", "隕炎彈"]:
		if not weapon_name in game.build_text.text:
			_fail("建構面板缺少共通武器：%s" % weapon_name)
			return

	print("ARSENAL_TEST_PASS: drone/gravity/meteor/weapon-cap/passive-cap/cooldown/area/recovery/precision/build-panel")
	get_tree().quit(0)


func _upgrade_ids(options: Array) -> Array:
	var ids: Array = []
	for option in options:
		ids.append(option["id"])
	return ids


func _spawn_test_enemy(game, offset: Vector2) -> void:
	game._spawn_mutant("chaser")
	game.enemies[-1]["pos"] = game.player_pos + offset
	game.enemies[-1]["hp"] = 500.0
	game.enemies[-1]["max_hp"] = 500.0


func _fail(message: String) -> void:
	push_error("ARSENAL_TEST_FAIL: " + message)
	get_tree().quit(1)
