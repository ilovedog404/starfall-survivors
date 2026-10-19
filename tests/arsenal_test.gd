extends Node


const EXPECTED_WEAPONS: Array[String] = [
	"starter", "needle", "rail_blade", "ion_axe", "return_disc",
	"orbit_blades", "meteor", "plasma_aura", "cryo_pool", "ricochet_ray",
]


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
	game.selected_character = "epathy"
	game._start_game()

	if game.WEAPON_BLUEPRINTS.size() != EXPECTED_WEAPONS.size():
		_fail("基礎武器數量不是 10 組")
		return
	for weapon_id in EXPECTED_WEAPONS:
		if not game.WEAPON_BLUEPRINTS.has(weapon_id):
			_fail("缺少武器定義：%s" % weapon_id)
			return
		if not game.weapon_stats.has(weapon_id) or not game.weapon_levels.has(weapon_id):
			_fail("武器未進入統一資料系統：%s" % weapon_id)
			return

	game._gm_unlock_all_weapons()
	for weapon_id in EXPECTED_WEAPONS:
		if game._weapon_level(weapon_id) < 1:
			_fail("GM 十武器測試未啟用：%s" % weapon_id)
			return

	# 1. 疾風短刃（鞭）：近距離扇形斬擊。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(72.0, 0.0))
	game._fire_weapon("starter", 1)
	if not _has_damage(game, "starter") or not _has_effect(game, "slash"):
		_fail("疾風短刃未造成近戰傷害或未產生斬擊")
		return

	# 2. 星針（魔法杖）：自動瞄準最近目標。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(180.0, 0.0))
	game._fire_weapon("needle", 1)
	if not _has_projectile(game, "needle"):
		_fail("星針未生成投射物")
		return

	# 3. 磁軌飛刃（飛刀）：朝最近目標高速射出。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(180.0, 0.0))
	game._fire_weapon("rail_blade", 1)
	if not _has_projectile(game, "rail_blade"):
		_fail("磁軌飛刃未生成投射物")
		return

	# 4. 離子戰斧（斧）：以較寬散射角投擲重型投射物。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(180.0, 0.0))
	game._fire_weapon("ion_axe", 1)
	if not _has_projectile(game, "ion_axe"):
		_fail("離子戰斧未生成投射物")
		return

	# 5. 折返星環（十字架）：飛出後折返回角色。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(180.0, 0.0))
	game._fire_weapon("return_disc", 1)
	if not _has_projectile(game, "return_disc") or not bool(game.projectiles[-1].get("returning", false)):
		_fail("折返星環未生成折返投射物")
		return

	# 6. 軌道刃陣（聖經）：傷害環帶中的敵人。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(72.0, 0.0))
	game._fire_weapon("orbit_blades", 1)
	if not _has_damage(game, "orbit_blades") or not _has_effect(game, "arsenal_orbit"):
		_fail("軌道刃陣未造成環帶傷害")
		return

	# 7. 隕炎彈（火杖）：鎖定敵群爆炸並附加燃燒。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(120.0, 0.0))
	game._fire_weapon("meteor", 1)
	if not _has_damage(game, "meteor") or not _has_effect(game, "meteor") or float(game.enemies[0]["burn_time"]) <= 0.0:
		_fail("隕炎彈未造成爆炸或燃燒")
		return

	# 8. 等離子場（大蒜）：週期傷害身旁敵人。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(60.0, 0.0))
	game._fire_weapon("plasma_aura", 1)
	if not _has_damage(game, "plasma_aura") or not _has_effect(game, "arsenal_aura"):
		_fail("等離子場未造成近身範圍傷害")
		return

	# 9. 冷媒污染區（聖水）：於敵人腳下生成持續傷害區。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(100.0, 0.0))
	game._fire_weapon("cryo_pool", 1)
	if not _has_effect(game, "arsenal_pool"):
		_fail("冷媒污染區未生成地面區域")
		return
	game._update_effects(0.05)
	if not _has_damage(game, "cryo_pool"):
		_fail("冷媒污染區未造成持續傷害")
		return

	# 10. 折射游標（符文追蹤器）：在多個目標間連鎖。
	_reset_combat(game)
	_spawn_test_enemy(game, Vector2(90.0, 0.0))
	_spawn_test_enemy(game, Vector2(145.0, 35.0))
	game._fire_weapon("ricochet_ray", 1)
	if not _has_damage(game, "ricochet_ray") or not _has_effect(game, "arsenal_chain"):
		_fail("折射游標未造成連鎖傷害")
		return

	print("ARSENAL_TEST_PASS: ten unified weapons, GM unlock, projectiles, fields and damage")
	get_tree().quit(0)


func _reset_combat(game) -> void:
	game.enemies.clear()
	game.projectiles.clear()
	game.effects.clear()
	game.damage_by_source.clear()
	game.total_damage_dealt = 0.0


func _spawn_test_enemy(game, offset: Vector2) -> void:
	var enemy: Dictionary = game._new_enemy("chaser", game.player_pos + offset, 10000.0, 0.0, 18.0)
	game.enemies.append(enemy)


func _has_projectile(game, weapon_id: String) -> bool:
	for projectile in game.projectiles:
		if String(projectile.get("source", projectile.get("weapon_id", ""))) == weapon_id:
			return true
	return false


func _has_effect(game, kind: String) -> bool:
	for effect in game.effects:
		if String(effect.get("kind", "")) == kind:
			return true
	return false


func _has_damage(game, weapon_id: String) -> bool:
	return float(game.damage_by_source.get(weapon_id, 0.0)) > 0.0


func _fail(message: String) -> void:
	push_error("ARSENAL_TEST_FAIL: " + message)
	get_tree().quit(1)
