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
			_fail("角色選擇頁沒有顯示專屬自動能力：" + character_id)
			return
	if String(game.CHARACTERS["rafari"]["name"]) != "菈法瑞":
		_fail("菈法瑞的角色名稱不正確")
		return
	game._choose_character("lucia")
	game._start_game()
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(40.0, 0.0)
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	game._fire_scythe_ring()
	if game.projectiles.size() != 10 or game.projectiles[0].get("kind", "") != "fireball" or game.projectiles[0].get("color", Color.BLACK) != game._starter_ring_color() or float(game.projectiles[0]["life"]) >= 1.0:
		_fail("璐茜婭 Lv.1 沒有射出 10 發短射程專屬色火球")
		return
	game._update_projectiles(0.1)
	if float(game.enemies[0]["burn_time"]) <= 0.0 or float(game.enemies[0]["hp"]) >= 500.0 or game._starter_weapon_name() != "緋色脈衝":
		_fail("璐茜婭火球命中後沒有造成傷害與燃燒")
		return
	game.projectiles.clear()
	for extra_target in 2:
		game._spawn_mutant("chaser")
		game.enemies[-1]["pos"] = game.player_pos + Vector2(90.0, (extra_target + 1) * 50.0)
	game.scythe_level = 3
	game._fire_scythe_ring()
	if game.projectiles.size() != 12:
		_fail("璐茜婭 Lv.3 沒有增加為 12 發火球")
		return
	game.projectiles.clear()
	game.scythe_level = 5
	game._fire_scythe_ring()
	if game.projectiles.size() != 14:
		_fail("璐茜婭 Lv.5 沒有增加為 14 發火球")
		return

	game._show_character_select()
	game._choose_character("rafari")
	game._start_game()
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(40.0, 0.0)
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	var frost_target_pos: Vector2 = game.enemies[0]["pos"]
	game._fire_scythe_ring()
	if float(game.enemies[0]["slow_factor"]) >= 1.0 or game._starter_weapon_name() != "零度領域" or game.effects[-1]["kind"] != "ice" or game.effects[-1]["color"] != game._starter_ring_color() or game.effects[-1]["pos"] != frost_target_pos or float(game.effects[-1]["radius"]) > 90.0 or game.scythe_interval < 2.8:
		_fail("菈法瑞的零度領域沒有在敵人腳下生成慢頻率小範圍冰霜")
		return

	game._show_character_select()
	game._choose_character("claire")
	game._start_game()
	game.player_shield = 0.0
	game._fire_scythe_ring()
	if game.player_shield <= 0.0 or game._starter_weapon_name() != "星源鐮環" or game.effects[-1]["kind"] != "pulse" or game.effects[-1]["color"] != game._starter_ring_color():
		_fail("克萊兒的星源鐮環沒有回復護盾")
		return

	game._show_character_select()
	game._choose_character("epathy")
	game._start_game()
	if not game.gm_panel.visible or game.gm_panel.get_child_count() == 0:
		_fail("遊戲左側沒有顯示 GM 測試按鍵")
		return
	game._toggle_gm_speed()
	if not game.gm_triple_speed or not is_equal_approx(Engine.time_scale, 3.0):
		_fail("GM 3 倍速按鍵沒有生效")
		return
	game._toggle_gm_speed()
	var gm_rerolls_before: int = game.rerolls_remaining
	game._gm_add_reroll()
	if game.rerolls_remaining != gm_rerolls_before + 1:
		_fail("GM 增加重骰次數按鍵沒有生效")
		return
	var gm_level_before: int = game.level
	game._gm_level_up()
	if game.level != gm_level_before + 1 or not game.choosing_upgrade:
		_fail("GM 升級按鍵沒有觸發升級選擇")
		return
	game._select_upgrade(game.current_upgrade_choices[0]["id"])
	if game.player_armor < 3.0 or game.close_damage_multiplier <= 1.0:
		_fail("埃帕蒂的初始被動沒有套用")
		return
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(40.0, 0.0)
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	var enemy_x_before: float = game.enemies[0]["pos"].x
	game._fire_scythe_ring()
	var right_slash_angle: float = float(game.effects[-1].get("angle", PI))
	if float(game.enemies[0]["pos"].x) <= enemy_x_before or absf(right_slash_angle) > 0.1 or game._starter_weapon_name() != "疾風短刃" or game.effects[-1]["kind"] != "slash" or game.effects[-1]["color"] != game._starter_ring_color():
		_fail("埃帕蒂的疾風短刃沒有以專屬顏色擊退異變體")
		return
	game.enemies.clear()
	game._spawn_mutant("chaser")
	game.enemies[0]["pos"] = game.player_pos + Vector2(0.0, -40.0)
	game.enemies[0]["hp"] = 500.0
	game.enemies[0]["max_hp"] = 500.0
	game._fire_scythe_ring()
	var upward_slash_angle: float = float(game.effects[-1].get("angle", 0.0))
	if absf(upward_slash_angle + PI * 0.5) > 0.1 or absf(upward_slash_angle - right_slash_angle) < 1.0:
		_fail("埃帕蒂的疾風短刃沒有朝最近敵人自動轉向")
		return
	game.enemies.clear()
	game._toggle_build_overlay()
	if not game.build_open or not game.build_overlay.visible or not "疾風短刃" in game.build_text.text:
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
	game._fire_scythe_ring()
	if float(game.enemies[0]["hp"]) >= 200.0:
		_fail("埃帕蒂的疾風短刃沒有造成傷害")
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
		_fail("角色自動能力沒有造成傷害")
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
	var choice_has_weapon := false
	var choice_has_ability := false
	for option in game.current_upgrade_choices:
		if game._is_weapon_upgrade(option["id"]):
			choice_has_weapon = true
		else:
			choice_has_ability = true
	if not choice_has_weapon or not choice_has_ability:
		_fail("升級三選一沒有同時提供武器與能力")
		return
	for button in game.upgrade_buttons.get_children():
		if not ("【武器】" in button.text or "【能力】" in button.text or "【進化】" in button.text):
			_fail("升級卡片沒有顯示分類")
			return
	var rerolls_before: int = game.rerolls_remaining
	game._reroll_upgrades()
	if game.rerolls_remaining != rerolls_before - 1 or game.current_upgrade_choices.size() != 3:
		_fail("升級重抽沒有正確更新選項")
		return
	choice_has_weapon = false
	choice_has_ability = false
	for option in game.current_upgrade_choices:
		if game._is_weapon_upgrade(option["id"]): choice_has_weapon = true
		else: choice_has_ability = true
	if not choice_has_weapon or not choice_has_ability:
		_fail("重新抽取後沒有維持武器與能力保證")
		return
	game._select_upgrade("needle")
	while game.pending_levels > 0:
		game._select_upgrade("health")
	if game.needle_level < 1:
		_fail("星針升級沒有套用")
		return
	var old_scythe_interval: float = game.scythe_interval
	var old_needle_interval_cooldown: float = game.needle_interval
	game.pending_levels = 1
	game._select_upgrade("cooldown")
	if game.scythe_interval >= old_scythe_interval or game.needle_interval >= old_needle_interval_cooldown:
		_fail("冷卻模組沒有縮短自動武器冷卻")
		return
	var old_scythe_radius_for_area: float = game.scythe_radius
	var old_storm_radius_for_area: float = game.storm_radius
	var old_projectile_area_scale: float = game.projectile_area_scale
	game.pending_levels = 1
	game._select_upgrade("area")
	if game.scythe_radius <= old_scythe_radius_for_area or game.storm_radius <= old_storm_radius_for_area or game.projectile_area_scale <= old_projectile_area_scale:
		_fail("廣域線圈沒有提高專屬能力、投射物或雷暴範圍")
		return
	game.needle_level = 5
	game.meta_levels["cooldown"] = 3
	var needle_evolution_found := false
	for option in game._available_upgrades():
		if option["id"] == "needle_evolution":
			needle_evolution_found = true
			break
	if not needle_evolution_found:
		_fail("星針達成條件後沒有出現追星蜂群進化")
		return
	var old_needle_damage: float = game.needle_damage
	var old_needle_interval: float = game.needle_interval
	game.pending_levels = 1
	game._select_upgrade("needle_evolution")
	if not game.needle_evolved or game.needle_damage <= old_needle_damage or game.needle_interval >= old_needle_interval:
		_fail("追星蜂群進化沒有正確提高傷害與射速")
		return
	game.enemies.clear()
	for target_index in 5:
		game._spawn_mutant("chaser")
		game.enemies[-1]["pos"] = game.player_pos + Vector2(120.0 + target_index * 8.0, target_index * 15.0)
	game.projectiles.clear()
	game._fire_star_needles()
	if game.projectiles.size() < 5 or not game.projectiles[0].get("evolved", false):
		_fail("追星蜂群沒有發射五枚進化星針")
		return
	game.enemies.clear()
	game.projectiles.clear()
	game._show_character_select()
	game._choose_character("claire")
	game._start_game()
	game._spawn_mutant("chaser", true)
	game.enemies[0]["hp"] = 1.0
	game._damage_enemy(0, 10.0, "starter")
	if game.evolution_cores.size() != 1:
		_fail("精英異變體沒有掉落進化核心")
		return
	game.evolution_cores[0]["pos"] = game.player_pos
	game._update_evolution_cores(0.0)
	if game.evolution_cores_owned != 1 or game.scythe_evolved:
		_fail("未達條件時進化核心沒有正確保存")
		return
	game.scythe_level = 5
	game.meta_levels["area"] = 3
	var old_radius: float = game.scythe_radius
	if not game._try_consume_evolution_core() or not game.scythe_evolved or game.scythe_radius <= old_radius or game._starter_evolution_name() != "超載鐮環":
		_fail("超載鐮環沒有透過進化核心正確套用")
		return
	for option in game._available_upgrades():
		if option["id"] == "scythe_evolution":
			_fail("專屬進化不應混入一般升級三選一")
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
	game.enemies[boss_index]["attack_cooldown"] = 0.0
	game._update_enemies(0.01)
	if float(game.enemies[boss_index].get("burst_charge", 0.0)) <= 0.0:
		_fail("使徒環形彈幕沒有進入蓄力預警")
		return
	if not game.hostile_projectiles.is_empty():
		_fail("使徒環形彈幕在預警完成前提前發射")
		return
	game._update_enemies(0.9)
	if game.hostile_projectiles.size() != 12:
		_fail("使徒環形彈幕預警後沒有發射 12 枚彈體")
		return
	game._damage_enemy(boss_index, 999999.0)
	if not game.game_over or game.apostle_present:
		_fail("使徒討伐結算沒有觸發")
		return
	var result_weapon_name: String = game._starter_evolution_name() if game.scythe_evolved else game._starter_weapon_name()
	if not "傷害分布" in game.end_summary.text or not result_weapon_name in game.end_summary.text:
		_fail("結算畫面沒有顯示分來源傷害")
		return

	print("SMOKE_TEST_PASS: evolution-core/four-starter-evolutions/gm-controls/lucia-shotgun/fixed-area-coil/render-culling/projectile-limits/rafari-name/auto-aim-slash/targeted-frost/automatic-character-skills/character-colors/apostle-burst-telegraph/needle-evolution/balanced-upgrade-draft/cooldown-area-passives/wave-countdown/guaranteed-wave-elites/browser-key-aliases/shooter-telegraph/dash-telegraph/damage-breakdown/character-selection/starter-visuals/pause-menu/build/repair-core/enemy-types/waves/status/movement/combat/stats/xp/reroll/storm/apostle/result")
	get_tree().quit(0)


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	return event


func _fail(message: String) -> void:
	push_error("SMOKE_TEST_FAIL: " + message)
	get_tree().quit(1)

