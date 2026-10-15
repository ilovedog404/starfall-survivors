extends Node


func _ready() -> void:
	print("APOSTLE_PHASE_TEST_START")
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
	game._spawn_apostle()
	var boss_index := _boss_index(game)
	if boss_index < 0:
		_fail("使徒沒有生成")
		return

	game.hostile_projectiles.append({"pos": Vector2.ZERO, "velocity": Vector2.ZERO, "radius": 5.0, "damage": 1.0, "life": 2.0})
	game.enemies[boss_index]["hp"] = game.apostle_max_hp * 0.49
	game.apostle_hp = game.enemies[boss_index]["hp"]
	game._update_enemies(0.01)
	if int(game.enemies[boss_index].get("phase", 1)) != 2 or game.apostle_phase != 2:
		_fail("使徒半血後沒有進入第二階段")
		return
	if not game.hostile_projectiles.is_empty() or float(game.enemies[boss_index].get("phase_transition", 0.0)) <= 0.0:
		_fail("轉階段沒有清除舊彈幕或播放轉場")
		return
	game._update_enemies(1.2)
	boss_index = _boss_index(game)
	game.enemies[boss_index]["summon_cooldown"] = 999.0

	game.enemies[boss_index]["attack_cycle"] = 0
	game.enemies[boss_index]["attack_cooldown"] = 0.0
	game._update_enemies(0.01)
	if float(game.enemies[boss_index].get("fan_charge", 0.0)) <= 0.0 or not game.hostile_projectiles.is_empty():
		_fail("第二階段扇形彈幕沒有先進入預警")
		return
	game._update_enemies(0.75)
	if game.hostile_projectiles.size() != 7:
		_fail("扇形彈幕預警後沒有發射 7 枚彈體")
		return

	game.hostile_projectiles.clear()
	boss_index = _boss_index(game)
	game.enemies[boss_index]["attack_cycle"] = 1
	game.enemies[boss_index]["attack_cooldown"] = 0.0
	game._update_enemies(0.01)
	if float(game.enemies[boss_index].get("boss_dash_charge", 0.0)) <= 0.0:
		_fail("第二階段衝撞沒有蓄力預警")
		return
	game._update_enemies(0.75)
	var dash_start: Vector2 = game.enemies[boss_index]["pos"]
	game._update_enemies(0.2)
	if game.enemies[boss_index]["pos"].distance_to(dash_start) < 40.0:
		_fail("衝撞預警結束後使徒沒有高速位移")
		return

	boss_index = _boss_index(game)
	game.enemies[boss_index]["boss_dash_time"] = 0.0
	game.enemies[boss_index]["attack_cycle"] = 2
	game.enemies[boss_index]["attack_cooldown"] = 0.0
	game._update_enemies(0.01)
	if float(game.enemies[boss_index].get("hazard_charge", 0.0)) <= 0.0:
		_fail("地面危險區沒有鎖定與預警")
		return
	game._update_enemies(0.85)
	var hazard_positions: Array = []
	for effect in game.effects:
		if effect.get("kind", "") == "apostle_hazard":
			hazard_positions.append(effect["pos"])
	if hazard_positions.size() != 3:
		_fail("地面攻擊沒有生成三處危險區")
		return
	game.player_pos = hazard_positions[0]
	game.player_shield = 0.0
	game.player_invulnerable = 0.0
	var health_before: float = game.player_health
	game._update_effects(0.7)
	if game.player_health >= health_before:
		_fail("地面危險區啟動後沒有造成傷害")
		return

	game._update_interface(0.2)
	if not "第 2 階段" in game.boss_label.text:
		_fail("首領介面沒有顯示第二階段")
		return

	print("APOSTLE_PHASE_TEST_PASS: transition/fan/dash/ground-hazard/phase-hud")
	get_tree().quit(0)


func _boss_index(game) -> int:
	for index in game.enemies.size():
		if game.enemies[index]["boss"]:
			return index
	return -1


func _fail(message: String) -> void:
	push_error("APOSTLE_PHASE_TEST_FAIL: " + message)
	get_tree().quit(1)
