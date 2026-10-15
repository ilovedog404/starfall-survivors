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
	if not InputMap.action_has_event("build", _key_event(KEY_B)) or not InputMap.action_has_event("pause", _key_event(KEY_P)):
		_fail("瀏覽器替代鍵 B／P 沒有註冊")
		return
	if not game.character_overlay.visible or game.run_started:
		_fail("角色選擇畫面沒有在啟動時顯示")
		return
	for character_id in ["epathy", "lucia", "claire", "rafari"]:
		game._choose_character(character_id)
		if game.selected_character != character_id:
			_fail("無法選擇角色：" + character_id)
			return
		if not game._starter_weapon_name() in game.character_detail.text or not String(game.CHARACTERS[character_id]["skill_name"]) in game.character_detail.text:
			_fail("角色選擇頁沒有顯示專屬武器或戰技：" + character_id)
			return
	game._choose_character("lucia")
	game._start_game()
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(40.0, 0.0)
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	game._fire_scythe_ring()
	if float(game.enemies[0]["burn_time"]) <= 0.0 or game._starter_weapon_name() != "灼星法環" or game.effects[-1]["color"] != game._starter_ring_color():
		_fail("璐茜婭的灼星法環沒有附加燃燒")
		return
	game.enemies[0]["hp"] = float(game.enemies[0]["max_hp"]) - 1.0
	if not game._use_character_skill() or float(game.enemies[0]["burn_time"]) <= 4.0:
		_fail("璐茜婭的全畫面引燃沒有套用")
		return

	game._show_character_select()
	game._choose_character("rafari")
	game._start_game()
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(40.0, 0.0)
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	game._fire_scythe_ring()
	if float(game.enemies[0]["slow_factor"]) >= 1.0 or game._starter_weapon_name() != "零度環域":
		_fail("菈法瑞的零度環域沒有附加冰緩")
		return
	if not game._use_character_skill() or float(game.enemies[0]["slow_factor"]) != 0.0:
		_fail("菈法瑞的凍結沒有套用")
		return

	game._show_character_select()
	game._choose_character("claire")
	game._start_game()
	game.player_shield = 0.0
	game._fire_scythe_ring()
	if game.player_shield <= 0.0 or game._starter_weapon_name() != "星源鐮環":
		_fail("克萊兒的星源鐮環沒有回復護盾")
		return
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
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	var enemy_x_before: float = game.enemies[0]["pos"].x
	game._fire_scythe_ring()
	if float(game.enemies[0]["pos"].x) <= enemy_x_before or game._starter_weapon_name() != "近衛刀輪":
		_fail("埃帕蒂的近衛刀輪沒有擊退異變體")
		return
	game.enemies.clear()
	game._toggle_build_overlay()
	if not game.build_open or not game.build_overlay.visible or not "近衛刀輪" in game.build_text.text:
		_fail("當前建構面板沒有正確開啟")
		return
	game._toggle_build_overlay()
	if game.build_open or game.build_overlay.visible:
		_fail("當前建構面板沒有正確關閉")
		return
	game.manual_paused = true
	game.pause_overlay.visible = true
	get_tree().paused = true
	game._resume_game()
	if game.manual_paused or game.pause_overlay.visible or get_tree().paused:
		_fail("滑鼠暫停選單無法繼續戰鬥")
		return
	game._spawn_mutant("shooter")
	game.enemies[0]["pos"] = game.player_pos + Vector2(300.0, 0.0)
	game.enemies[0]["attack_cooldown"] = 0.0
	game._update_enemies(0.1)
	if float(game.enemies[0]["shot_charge"]) <= 0.0 or game.enemies[0]["shot_dir"] == Vector2.ZERO:
		_fail("遠程型異變體沒有進入射擊預警")
		return
	game._update_enemies(0.6)
	if game.hostile_projectiles.is_empty():
		_fail("遠程型異變體預警後沒有發射彈體")
		return
	game.enemies.clear()
	game.hostile_projectiles.clear()
	game._spawn_mutant("dasher")
	game.enemies[0]["pos"] = game.player_pos + Vector2(220.0, 0.0)
	game.enemies[0]["dash_cooldown"] = 0.0
	game._update_enemies(0.01)
	if float(game.enemies[0]["dash_charge"]) <= 0.0 or game.enemies[0]["dash_dir"] == Vector2.ZERO:
		_fail("奔襲型異變體沒有進入衝刺預警")
		return
	game._update_enemies(0.5)
	if float(game.enemies[0]["dash_time"]) <= 0.0:
		_fail("奔襲型異變體預警後沒有開始衝刺")
		return
	game.enemies.clear()
	game._spawn_mutant("tank")
	if float(game.enemies[0]["hp"]) < 90.0 or float(game.enemies[0]["radius"]) < 20.0:
		_fail("重裝型異變體數值不正確")
		return
	game.enemies.clear()
	game.game_time = 60.0
	game.wave_index = 0
	game._update_spawning(0.0)
	if game.wave_index != 1 or game.enemies.size() < 8:
		_fail("第一波異變體沒有正確生成")
		return
	var wave_elites := 0
	for enemy in game.enemies:
		if enemy["elite"]:
			wave_elites += 1
	if wave_elites < 1:
		_fail("定時波次沒有生成保證精英")
		return
	game._start_game()
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
	game.game_time = 30.0
	game.wave_index = 0
	game._update_interface(0.0)
	if not "下一波 00:30" in game.enemy_label.text or not "威脅 Lv.1" in game.enemy_label.text:
		_fail("下一波倒數或威脅等級顯示不正確")
		return
	game.game_time = 181.0
	game.wave_index = 3
	game._update_interface(0.0)
	if not "下一波 已完成" in game.enemy_label.text or not "威脅 Lv.4" in game.enemy_label.text:
		_fail("波次完成或後期威脅等級顯示不正確")
		return
	game.game_time = 0.0
	game.wave_index = 0

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
	if game.total_damage_dealt <= 0.0 or float(game.damage_by_source["starter"]) <= 0.0:
		_fail("造成傷害統計沒有累計")
		return
	game.player_invulnerable = 0.0
	game._take_player_damage(10.0)
	if game.total_damage_taken <= 0.0:
		_fail("承受傷害統計沒有累計")
		return
	game.enemies.clear()
	game.player_health = 50.0
	game._spawn_mutant("chaser")
	game.enemies[0]["elite"] = true
	game.enemies[0]["pos"] = game.player_pos
	game.enemies[0]["hp"] = 1.0
	game._damage_enemy(0, 10.0)
	if game.repair_cores.is_empty():
		_fail("精英異變體沒有掉落修復核心")
		return
	game._update_repair_cores(0.1)
	if game.player_health <= 50.0 or not game.repair_cores.is_empty():
		_fail("修復核心沒有正確回復生命")
		return

	game._gain_experience(100.0)
	if not game.choosing_upgrade or not game.upgrade_overlay.visible:
		_fail("升級三選一沒有開啟")
		return
	var rerolls_before: int = game.rerolls_remaining
	game._reroll_upgrades()
	if game.rerolls_remaining != rerolls_before - 1 or game.current_upgrade_choices.size() != 3:
		_fail("升級重抽沒有正確更新選項")
		return
	game._select_upgrade("needle")
	while game.pending_levels > 0:
		game._select_upgrade("health")
	if game.needle_level < 1:
		_fail("星針升級沒有套用")
		return
	game.scythe_level = 5
	game.meta_levels["armor"] = 3
	for option in game._available_upgrades():
		if option["id"] == "scythe_evolution":
			_fail("非克萊兒角色不應取得崩星護界進化")
			return
	game.selected_character = "claire"
	var evolution_found := false
	for option in game._available_upgrades():
		if option["id"] == "scythe_evolution":
			evolution_found = true
			break
	if not evolution_found:
		_fail("星源鐮環達成條件後沒有出現進化")
		return
	var old_radius: float = game.scythe_radius
	game.pending_levels = 1
	game._select_upgrade("scythe_evolution")
	if not game.scythe_evolved or game.scythe_radius <= old_radius:
		_fail("崩星護界進化沒有正確套用")
		return
	game.storm_level = 1
	game._spawn_mutant("chaser")
	game.enemies[-1]["pos"] = game.player_pos + Vector2(80.0, 0.0)
	var storm_target_hp: float = game.enemies[-1]["hp"]
	game._fire_pulse_storm()
	if not game.enemies.is_empty() and float(game.enemies[-1]["hp"]) >= storm_target_hp:
		_fail("脈衝雷暴沒有造成傷害")
		return
	if float(game.damage_by_source["storm"]) <= 0.0:
		_fail("脈衝雷暴傷害沒有列入來源統計")
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
	if not "傷害分布" in game.end_summary.text or not game._starter_weapon_name() in game.end_summary.text:
		_fail("結算畫面沒有顯示分來源傷害")
		return

	print("SMOKE_TEST_PASS: wave-countdown/guaranteed-wave-elites/browser-key-aliases/shooter-telegraph/dash-telegraph/damage-breakdown/character-selection/starter-visuals/skills/pause-menu/build/evolution/repair-core/enemy-types/waves/status/movement/combat/stats/xp/reroll/storm/apostle/result")
	get_tree().quit(0)


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	return event


func _fail(message: String) -> void:
	push_error("SMOKE_TEST_FAIL: " + message)
	get_tree().quit(1)

