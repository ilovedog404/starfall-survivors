extends RefCounted

# 埃帕蒂的角色資料與專屬武器邏輯。
# 主場景只負責通用戰鬥流程；這裡提供它會呼叫的角色介面。

var id := "epathy"

var data: Dictionary = {
	"name": "埃帕蒂",
	"role": "近戰／生存",
	"passive": "護甲 +3；近距離傷害提高 20%",
	"skill": "自動揮出近距離斬擊並擊退周圍異變體",
	"skill_name": "疾風短刃",
	"starter_weapon": "疾風短刃",
	"starter_trait": "朝最近目標自動轉向，揮出近距離扇形斬擊",
	"ring_color": Color(1.0, 0.38, 0.48),
	"color": Color(1.0, 0.48, 0.55),
}

var base_interval := 1.4
var max_level := 8
var passive_required_level := 1
var evolution: Dictionary = {
	"name": "疾風環斬",
	"passive_id": "armor",
	"passive_name": "強化裝甲",
}


func apply_passives(game) -> void:
	game.player_armor += 3.0
	game.close_damage_multiplier *= 1.2


func apply_evolution(_game, stats: Dictionary) -> void:
	stats["damage"] = float(stats["damage"]) + 14.0
	stats["radius"] = float(stats["radius"]) + 28.0
	stats["interval"] = float(stats["interval"]) * 0.88


func upgrade_description(_game, next_level: int) -> String:
	match next_level:
		2: return "追加反向第二斬，擴大近身清場覆蓋"
		3: return "基礎傷害 +5"
		4: return "基礎傷害 +5，斬擊範圍 +10%"
		5: return "基礎傷害 +5"
		6: return "基礎傷害 +5，斬擊範圍 +10%"
		7: return "基礎傷害 +5"
		8: return "基礎傷害 +5；可進行專屬進化"
	return "強化疾風短刃"


func apply_upgrade(game, next_level: int) -> void:
	var stats: Dictionary = game.weapon_stats["starter"]
	match next_level:
		2:
			stats["amount"] = int(stats["amount"]) + 1
		3, 5, 7, 8:
			stats["damage"] = float(stats["damage"]) + 5.0
		4, 6:
			stats["damage"] = float(stats["damage"]) + 5.0
			stats["radius"] = float(stats["radius"]) * 1.1


func fire(game) -> void:
	if game.enemies.is_empty():
		return

	var starter_level: int = game._weapon_level("starter")
	var stats: Dictionary = game.weapon_stats["starter"]
	var starter_damage := float(stats["damage"])
	var starter_evolved := bool(stats["evolved"])
	var radius := float(stats["radius"])
	var slash_angle: float = game._nearest_enemy_direction().angle()
	var half_arc: float = 1.25
	var slash_angles: Array[float] = [slash_angle]
	if starter_level >= 2 or starter_evolved:
		slash_angles.append(slash_angle + PI)

	var recovery_hits := 0
	for enemy_index in range(game.enemies.size() - 1, -1, -1):
		var enemy: Dictionary = game.enemies[enemy_index]
		var hit_radius: float = radius + float(enemy["radius"])
		if game.player_pos.distance_squared_to(enemy["pos"]) > hit_radius * hit_radius:
			continue

		var enemy_direction: Vector2 = game.player_pos.direction_to(enemy["pos"])
		var matched_slash: int = -1
		for slash_index in slash_angles.size():
			var angle_difference: float = absf(wrapf(enemy_direction.angle() - slash_angles[slash_index], -PI, PI))
			if angle_difference <= half_arc:
				matched_slash = slash_index
				break
		if matched_slash < 0:
			continue

		var push_direction: Vector2 = game.player_pos.direction_to(enemy["pos"])
		enemy["pos"] = Vector2(enemy["pos"]) + push_direction * (12.0 if bool(enemy["boss"]) else 34.0 + starter_level * 5.0)
		var secondary_multiplier: float = 1.0 if starter_evolved else 0.72
		var slash_damage: float = starter_damage * game.damage_multiplier * game.close_damage_multiplier
		if matched_slash > 0:
			slash_damage *= secondary_multiplier
		var critical: bool = starter_evolved and game.rng.randf() < 0.2
		if critical:
			slash_damage *= 2.0
			game._add_effect("epathy_critical", enemy["pos"], 0.34, 34.0, {"color": data["ring_color"]})
		game._damage_enemy(enemy_index, slash_damage, "starter")
		if starter_evolved:
			recovery_hits += 1

	for effect_index in slash_angles.size():
		game._add_effect("slash", game.player_pos, 0.42 if effect_index > 0 else 0.38, radius, {
			"angle": slash_angles[effect_index],
			"color": data["ring_color"],
		})
	if starter_evolved and recovery_hits > 0:
		game.player_health = minf(game.player_max_health, game.player_health + minf(4.0, recovery_hits * 0.35))


func draw_preview(game) -> void:
	var radius: float = float(game._weapon_stat("starter", "radius"))
	var preview_color: Color = Color(data["ring_color"], 0.18)
	var slash_angle: float = game._nearest_enemy_direction().angle()
	game.draw_arc(game.player_pos, radius, slash_angle - 1.25, slash_angle + 1.25, 40, preview_color, 3.0, true)
	if game._weapon_level("starter") >= 2 or game._weapon_is_evolved("starter"):
		game.draw_arc(game.player_pos, radius, slash_angle + PI - 1.25, slash_angle + PI + 1.25, 40, preview_color, 3.0, true)
