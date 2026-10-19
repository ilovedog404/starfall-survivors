extends Node2D

# 五分鐘垂直切片。戰鬥規則沿用既有原型，角色與異變體改用使用者提供的
# 透明 2D billboard 素材，場景與技能特效仍由 CanvasItem 即時繪製。

const EPATHY_TEXTURE: Texture2D = preload("res://assets/sprites/epathy_chibi_v1.png")
const ANUBARAK_TEXTURE: Texture2D = preload("res://assets/sprites/anubarak_chibi_v1.png")
const BATTLE_MUSIC: AudioStream = preload("res://assets/audio/seizon_no_kassen.wav")
const ENEMY_TEXTURES := {
	"chaser": preload("res://assets/sprites/wolf_mutant_chibi_v2.png"),
	"dasher": preload("res://assets/sprites/wolf_mutant_chibi_v2.png"),
	"shooter": preload("res://assets/sprites/robot_combat_chibi_v2.png"),
	"tank": preload("res://assets/sprites/beetle_crystal_chibi_v2.png"),
	"guardian": preload("res://assets/sprites/robot_combat_chibi_v2.png"),
	"splitter": preload("res://assets/sprites/beetle_crystal_chibi_v2.png"),
	"contaminant": preload("res://assets/sprites/wolf_mutant_chibi_v2.png"),
}
const PLAYABLE_CHARACTERS := ["epathy"]

const RUN_DURATION := 300.0
const APOSTLE_TIME := 240.0
const VIEW_SIZE := Vector2(1280.0, 720.0)
const MAX_ENEMIES := 650
const MAX_GEMS := 480
const MAX_REPAIR_CORES := 24
const MAX_EVOLUTION_CORES := 1
const MAX_ELITE_CHESTS := 8
const MAX_WEAPON_SLOTS := 6
const MAX_PASSIVE_SLOTS := 6
const MAX_EFFECTS := 220
const MAX_PLAYER_PROJECTILES := 220
const MAX_HOSTILE_PROJECTILES := 180
const LOW_DETAIL_ENEMY_COUNT := 220
const DRAW_MARGIN := 180.0
const MAP_OBJECT_RANGE := 76.0
const MAP_CHEST_COUNT := 4
const MAP_CHEST_DISTANCE := 2460.0
const MAP_CHEST_ANGLE_SHIFT := 0.647517
const WAVE_TIMES := [60.0, 120.0, 180.0]
const VERSION := "2.5D 改版開發版"
const SPAWN_MARGIN := 140.0
const RANDOM_ELITE_COOLDOWN := 22.0
const APOSTLE_ENRAGE_TEMPO := 1.4
const SEPARATION_CELL := 48.0
const SEPARATION_MAX_CHECKS := 10
const GAMEPLAY_EFFECT_KINDS := ["arsenal_pool", "contamination", "apostle_hazard", "elite_explosion"]
const GROUND_EFFECT_KINDS := ["arsenal_pool", "contamination", "apostle_hazard", "ice", "warning", "elite_explosion"]
const RECYCLE_DISTANCE := 1500.0
const ELITE_AFFIXES := ["swift", "shielded", "explosive"]
const PASSIVE_MAX_LEVEL := 5
const ENEMY_STATS := {
	"chaser": {"hp": 31.0, "speed": 76.0, "radius": 15.0},
	"dasher": {"hp": 24.0, "speed": 66.0, "radius": 13.0},
	"shooter": {"hp": 30.0, "speed": 58.0, "radius": 14.0},
	"tank": {"hp": 98.0, "speed": 42.0, "radius": 24.0},
	"guardian": {"hp": 74.0, "speed": 48.0, "radius": 21.0},
	"splitter": {"hp": 46.0, "speed": 64.0, "radius": 17.0},
	"contaminant": {"hp": 40.0, "speed": 54.0, "radius": 18.0},
}
const SPAWN_TABLE := [
	[165.0, 0.08, "guardian"],
	[135.0, 0.16, "splitter"],
	[105.0, 0.24, "contaminant"],
	[150.0, 0.34, "tank"],
	[90.0, 0.48, "shooter"],
	[35.0, 0.66, "dasher"],
]
const PASSIVE_BLUEPRINTS := {
	"health": {"name": "強化生命", "description": "最大生命 +15，並回復 15 生命"},
	"speed": {"name": "高速模組", "description": "移動速度提高 8%"},
	"pickup": {"name": "回收磁場", "description": "星源碎片拾取範圍 +25"},
	"armor": {"name": "強化裝甲", "description": "護甲 +1，降低每次受到的傷害"},
	"damage": {"name": "星源增幅", "description": "所有武器傷害提高 12%"},
	"cooldown": {"name": "冷卻模組", "description": "所有自動武器冷卻縮短 6%"},
	"area": {"name": "廣域線圈", "description": "範圍武器擴大，投射物尺寸 +8%"},
	"recovery": {"name": "修復奈米機", "description": "每秒回復 0.4 生命"},
	"precision": {"name": "精密核心", "description": "所有投射物傷害提高 12%"},
}
const CHARACTERS := {
	"epathy": {
		"name": "埃帕蒂",
		"role": "近戰／生存",
		"passive": "護甲 +3；近距離傷害提高 20%",
		"skill": "自動揮出近距離斬擊並擊退周圍異變體",
		"skill_name": "疾風短刃",
		"starter_weapon": "疾風短刃",
		"starter_trait": "近距離扇形斬擊並擊退",
		"ring_color": Color(1.0, 0.38, 0.48),
		"color": Color(1.0, 0.48, 0.55),
	},
	"lucia": {
		"name": "璐茜婭",
		"role": "法術／持續傷害",
		"passive": "燃燒持續時間 +30%",
		"skill": "自動向最近異變體發射短射程火球霰彈",
		"skill_name": "緋色脈衝",
		"starter_weapon": "緋色脈衝",
		"starter_trait": "一次射出 10 發短射程火球並附加燃燒",
		"ring_color": Color(1.0, 0.42, 0.16),
		"color": Color(0.92, 0.45, 1.0),
	},
	"claire": {
		"name": "克萊兒",
		"role": "新手／均衡",
		"passive": "初始武器：星源鐮環",
		"skill": "週期性範圍電圈，兼具傷害與短暫護盾",
		"skill_name": "星源鐮環",
		"starter_weapon": "星源鐮環",
		"starter_trait": "發動時回復護盾",
		"ring_color": Color(0.25, 0.9, 1.0),
		"color": Color(0.6, 0.92, 1.0),
	},
	"rafari": {
		"name": "菈法瑞",
		"role": "控場／冰霜",
		"passive": "減速效果提高",
		"skill": "定期在敵人腳下生成小範圍冰霜並凍緩敵人",
		"skill_name": "零度領域",
		"starter_weapon": "零度領域",
		"starter_trait": "鎖定敵人腳下的小範圍冰霜",
		"ring_color": Color(0.42, 0.62, 1.0),
		"color": Color(0.55, 0.72, 1.0),
	},
}

# 參照經典生存遊戲武器行為後重新命名、重新數值化的星隕武裝。
# 所有條目共用同一套資料驅動升級入口，後續批次只需擴充資料與攻擊型態。
const ARSENAL_BLUEPRINTS := {
	"rail_blade": {"name": "磁軌飛刃", "pattern": "aimed_pierce", "damage": 13.0, "interval": 1.0, "radius": 6.0, "speed": 760.0, "amount": 1, "description": "朝最近異變體高速連射並穿透目標"},
	"ion_axe": {"name": "離子戰斧", "pattern": "heavy_axes", "damage": 32.0, "interval": 2.4, "radius": 13.0, "speed": 330.0, "amount": 1, "description": "向周圍拋出緩慢但高傷害的重型戰斧"},
	"return_disc": {"name": "折返星環", "pattern": "returning_disc", "damage": 20.0, "interval": 1.85, "radius": 10.0, "speed": 470.0, "amount": 1, "description": "射出會轉向飛回角色的穿透星環"},
	"orbit_blades": {"name": "軌道刃陣", "pattern": "orbit", "damage": 13.0, "interval": 0.72, "radius": 92.0, "speed": 0.0, "amount": 3, "description": "旋轉刃陣持續切割近身目標"},
	"plasma_aura": {"name": "等離子場", "pattern": "aura", "damage": 8.0, "interval": 0.82, "radius": 108.0, "speed": 0.0, "amount": 1, "description": "週期傷害並削弱身旁異變體"},
	"cryo_pool": {"name": "冷媒污染區", "pattern": "target_area", "damage": 8.0, "interval": 3.0, "radius": 76.0, "speed": 0.0, "amount": 1, "description": "在敵群腳下留下持續傷害與減速區"},
	"ricochet_ray": {"name": "折射游標", "pattern": "chain", "damage": 17.0, "interval": 1.55, "radius": 7.0, "speed": 610.0, "amount": 2, "description": "在多個鄰近目標之間連鎖折射"},
}

var rng := RandomNumberGenerator.new()
var camera: Camera2D
var battle_music_player: AudioStreamPlayer

var player_pos := Vector2.ZERO
var player_speed := 255.0
var player_health := 110.0
var player_max_health := 110.0
var player_shield := 8.0
var player_max_shield := 24.0
var player_armor := 0.0
var player_invulnerable := 0.0
var pickup_radius := 115.0
var damage_multiplier := 1.0
var close_damage_multiplier := 1.0
var burn_duration_multiplier := 1.0
var slow_effect_multiplier := 1.0
var projectile_area_scale := 1.0
var projectile_damage_multiplier := 1.0
var recovery_per_second := 0.0
var selected_character := "epathy"
var run_started := false
var build_open := false
var total_damage_dealt := 0.0
var total_damage_taken := 0.0
var damage_by_source: Dictionary = {}

var game_time := 0.0
var spawn_timer := 0.0
var kills := 0
var game_over := false
var choosing_upgrade := false
var choosing_elite_reward := false
var manual_paused := false
var pending_levels := 0
var instruction_time := 10.0
var wave_index := 0
var hud_refresh_timer := 0.0
var gm_triple_speed := false
var active_map_objects: Array = []
var map_object_angle_offset := 0.0

var level := 1
var experience := 0.0
var experience_required := 12.0
var meta_levels: Dictionary = {}

var scythe_level := 1
var scythe_damage := 24.0
var scythe_radius := 132.0
var scythe_interval := 1.55
var scythe_timer := 0.25
var scythe_evolved := false

var needle_level := 0
var needle_damage := 17.0
var needle_interval := 0.72
var needle_timer := 0.2
var needle_evolved := false

var meteor_level := 0
var meteor_damage := 42.0
var meteor_radius := 70.0
var meteor_interval := 2.75
var meteor_timer := 1.35

var arsenal_levels: Dictionary = {}
var arsenal_timers: Dictionary = {}
var next_enemy_id := 0
var elite_spawn_cooldown := 0.0
var apostle_enraged := false
var cooldown_scale := 1.0
var arsenal_area_scale := 1.0

var enemies: Array = []
var projectiles: Array = []
var hostile_projectiles: Array = []
var gems: Array = []
var repair_cores: Array = []
var evolution_cores: Array = []
var evolution_cores_owned := 0
var elite_chests: Array = []
var pending_elite_rewards := 0
var effects: Array = []
var apostle_spawned := false
var apostle_present := false
var apostle_hp := 0.0
var apostle_max_hp := 0.0
var apostle_phase := 1

var canvas_layer: CanvasLayer
var ui_root: Control
var ui_theme: Theme
var time_label: Label
var stats_label: Label
var enemy_label: Label
var weapon_label: Label
var instruction_label: Label
var interaction_label: Label
var skill_label: Label
var pause_overlay: ColorRect
var xp_bar: ProgressBar
var boss_bar: ProgressBar
var boss_label: Label
var upgrade_overlay: ColorRect
var upgrade_title: Label
var upgrade_buttons: HBoxContainer
var reroll_button: Button
var current_upgrade_choices: Array = []
var rerolls_remaining := 1
var build_overlay: ColorRect
var build_text: Label
var end_overlay: ColorRect
var end_title: Label
var end_summary: Label
var character_overlay: ColorRect
var character_detail: Label
var character_buttons: Dictionary = {}
var character_portrait: TextureRect
var character_start_button: Button
var gm_panel: PanelContainer
var gm_speed_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_setup_battle_music()
	_ensure_input_map()
	_create_camera()
	_build_interface()
	_show_character_select()


func _setup_battle_music() -> void:
	battle_music_player = AudioStreamPlayer.new()
	battle_music_player.name = "BattleMusic"
	battle_music_player.stream = BATTLE_MUSIC
	battle_music_player.volume_db = -10.0
	battle_music_player.finished.connect(_on_battle_music_finished)
	add_child(battle_music_player)


func _start_battle_music() -> void:
	if battle_music_player.playing:
		battle_music_player.stop()
	battle_music_player.play()


func _stop_battle_music() -> void:
	if battle_music_player.playing:
		battle_music_player.stop()


func _on_battle_music_finished() -> void:
	if run_started and not game_over:
		battle_music_player.play()


func _process(delta: float) -> void:
	_handle_build_input()
	_handle_pause_input()
	_handle_upgrade_input()
	if get_tree().paused:
		queue_redraw()
		return
	if game_over or not run_started:
		return

	_update_player(delta)
	_update_map_objects()
	_update_passive_recovery(delta)
	_update_spawning(delta)
	_update_weapons(delta)
	_update_projectiles(delta)
	_update_enemy_statuses(delta)
	_update_enemies(delta)
	_apply_enemy_separation(delta)
	_update_hostile_projectiles(delta)
	_update_pickups(delta)
	_update_effects(delta)
	_enforce_runtime_limits()
	_update_interface(delta)
	queue_redraw()


func _ensure_input_map() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"pause": [KEY_ESCAPE, KEY_P],
		"upgrade_1": [KEY_1],
		"upgrade_2": [KEY_2],
		"upgrade_3": [KEY_3],
		"reroll": [KEY_R],
		"build": [KEY_TAB, KEY_B],
		"interact": [KEY_E],
	}
	for action_name in bindings:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for key_code in bindings[action_name]:
			var key_event := InputEventKey.new()
			key_event.keycode = key_code
			InputMap.action_add_event(action_name, key_event)


func _create_camera() -> void:
	camera = Camera2D.new()
	camera.name = "GameCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)
	camera.make_current()


func _apply_layout(control: Control, anchors: Vector4, offsets: Vector4) -> void:
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w


func _make_label(parent: Node, text: String, font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _make_button(parent: Node, text: String, min_size: Vector2, font_size: int, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button


func _make_hud_label(anchors: Vector4, offsets: Vector4, font_size: int, align: HorizontalAlignment) -> Label:
	var label := _make_label(ui_root, "", font_size, align)
	_apply_layout(label, anchors, offsets)
	return label


func _make_hud_bar(anchors: Vector4, offsets: Vector4) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	ui_root.add_child(bar)
	_apply_layout(bar, anchors, offsets)
	return bar


func _make_overlay(background: Color) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = background
	overlay.visible = false
	ui_root.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return overlay


func _add_panel_column(parent: Control, panel_size: Vector2, separation: int) -> VBoxContainer:
	var center := CenterContainer.new()
	parent.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = panel_size
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", separation)
	panel.add_child(column)
	return column


func _build_interface() -> void:
	ui_theme = Theme.new()
	ui_theme.default_font = load("res://assets/fonts/NotoSansTC-VF.ttf")
	ui_theme.default_font_size = 18
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "Interface"
	add_child(canvas_layer)
	ui_root = Control.new()
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = ui_theme
	canvas_layer.add_child(ui_root)
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	xp_bar = _make_hud_bar(Vector4(0.0, 0.0, 1.0, 0.0), Vector4(18.0, 14.0, -18.0, 32.0))
	boss_bar = _make_hud_bar(Vector4(0.25, 0.0, 0.75, 0.0), Vector4(0.0, 86.0, 0.0, 108.0))
	time_label = _make_hud_label(Vector4(0.5, 0.0, 0.5, 0.0), Vector4(-120.0, 40.0, 120.0, 78.0), 28, HORIZONTAL_ALIGNMENT_CENTER)
	stats_label = _make_hud_label(Vector4.ZERO, Vector4(20.0, 48.0, 340.0, 130.0), 18, HORIZONTAL_ALIGNMENT_LEFT)
	enemy_label = _make_hud_label(Vector4(1.0, 0.0, 1.0, 0.0), Vector4(-265.0, 48.0, -20.0, 128.0), 18, HORIZONTAL_ALIGNMENT_RIGHT)
	weapon_label = _make_hud_label(Vector4(0.0, 1.0, 0.0, 1.0), Vector4(20.0, -160.0, 520.0, -18.0), 17, HORIZONTAL_ALIGNMENT_LEFT)
	weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_label = _make_hud_label(Vector4(1.0, 1.0, 1.0, 1.0), Vector4(-480.0, -92.0, -20.0, -18.0), 17, HORIZONTAL_ALIGNMENT_RIGHT)
	instruction_label = _make_hud_label(Vector4(0.5, 1.0, 0.5, 1.0), Vector4(-360.0, -62.0, 360.0, -20.0), 20, HORIZONTAL_ALIGNMENT_CENTER)
	interaction_label = _make_hud_label(Vector4(0.5, 1.0, 0.5, 1.0), Vector4(-330.0, -108.0, 330.0, -68.0), 20, HORIZONTAL_ALIGNMENT_CENTER)
	interaction_label.add_theme_color_override("font_color", Color(0.66, 1.0, 0.82))
	boss_label = _make_hud_label(Vector4(0.25, 0.0, 0.75, 0.0), Vector4(0.0, 108.0, 0.0, 138.0), 18, HORIZONTAL_ALIGNMENT_CENTER)
	boss_label.text = "使徒｜阿努巴拉克"
	for node in [boss_bar, boss_label, interaction_label]:
		node.visible = false

	_build_gm_panel()
	_build_pause_overlay()
	_build_upgrade_overlay()
	_build_end_overlay()
	_build_loadout_overlay()
	_build_character_overlay()


func _build_gm_panel() -> void:
	gm_panel = PanelContainer.new()
	gm_panel.position = Vector2(16.0, 142.0)
	gm_panel.custom_minimum_size = Vector2(178.0, 174.0)
	gm_panel.visible = false
	ui_root.add_child(gm_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	gm_panel.add_child(column)
	_make_label(column, "GM 測試", 16)
	gm_speed_button = _make_button(column, "3 倍速：關", Vector2(160.0, 36.0), 16, _toggle_gm_speed)
	_make_button(column, "立即升級", Vector2(160.0, 36.0), 16, _gm_level_up)
	_make_button(column, "重骰次數 +1", Vector2(160.0, 36.0), 16, _gm_add_reroll)


func _build_pause_overlay() -> void:
	pause_overlay = _make_overlay(Color(0.008, 0.015, 0.045, 0.9))
	var column := _add_panel_column(pause_overlay, Vector2(480.0, 430.0), 20)
	_make_label(column, "已暫停", 38)
	_make_button(column, "繼續戰鬥", Vector2(280.0, 56.0), 21, _resume_game)
	_make_button(column, "重新開始本角色", Vector2(280.0, 54.0), 19, _start_game)
	_make_button(column, "返回角色選擇", Vector2(280.0, 54.0), 19, _show_character_select)
	_make_label(column, "按 Esc／P 也可繼續", 16)


func _build_upgrade_overlay() -> void:
	upgrade_overlay = _make_overlay(Color(0.01, 0.02, 0.06, 0.91))
	var column := _add_panel_column(upgrade_overlay, Vector2(1010.0, 350.0), 24)
	upgrade_title = _make_label(column, "", 30)
	upgrade_buttons = HBoxContainer.new()
	upgrade_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_buttons.add_theme_constant_override("separation", 18)
	column.add_child(upgrade_buttons)
	reroll_button = _make_button(column, "", Vector2(260.0, 46.0), 17, _reroll_upgrades)
	_make_label(column, "點擊卡片或按 1／2／3 選擇；R 可重抽", 16)


func _build_end_overlay() -> void:
	end_overlay = _make_overlay(Color(0.01, 0.015, 0.04, 0.94))
	var column := _add_panel_column(end_overlay, Vector2(560.0, 410.0), 22)
	end_title = _make_label(column, "", 42)
	end_summary = _make_label(column, "", 20)
	_make_button(column, "重新開始", Vector2(260.0, 58.0), 22, _start_game)
	_make_button(column, "返回角色選擇", Vector2(260.0, 50.0), 19, _show_character_select)
	_make_label(column, "%s｜非官方同人原型｜美術素材由使用者提供" % VERSION, 14)


func _build_loadout_overlay() -> void:
	build_overlay = _make_overlay(Color(0.01, 0.02, 0.06, 0.92))
	var column := _add_panel_column(build_overlay, Vector2(780.0, 640.0), 12)
	_make_label(column, "當前建構", 34)
	build_text = _make_label(column, "", 18, HORIZONTAL_ALIGNMENT_LEFT)
	build_text.custom_minimum_size = Vector2(690.0, 470.0)
	build_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	build_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_make_label(column, "按 B／Tab 或 Esc／P 返回戰鬥", 17)


func _build_character_overlay() -> void:
	character_overlay = _make_overlay(Color(0.035, 0.055, 0.055, 0.99))
	var column := _add_panel_column(character_overlay, Vector2(1100.0, 650.0), 12)
	_make_label(column, "星隕倖存者｜荒原先遣", 38)
	_make_label(column, "2.5D 改版測試｜埃帕蒂單角色垂直切片", 18)

	var content := HBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 34)
	column.add_child(content)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(400.0, 440.0)
	content.add_child(portrait_frame)
	character_portrait = TextureRect.new()
	character_portrait.texture = EPATHY_TEXTURE
	character_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	character_portrait.custom_minimum_size = Vector2(380.0, 420.0)
	character_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(character_portrait)

	var details := VBoxContainer.new()
	details.custom_minimum_size = Vector2(560.0, 440.0)
	details.alignment = BoxContainer.ALIGNMENT_CENTER
	details.add_theme_constant_override("separation", 16)
	content.add_child(details)
	for character_id in PLAYABLE_CHARACTERS:
		var data: Dictionary = CHARACTERS[character_id]
		character_buttons[character_id] = _make_button(details, "%s　｜　%s" % [data["name"], data["role"]], Vector2(520.0, 70.0), 22, _choose_character.bind(character_id))

	character_detail = _make_label(details, "", 18, HORIZONTAL_ALIGNMENT_LEFT)
	character_detail.custom_minimum_size = Vector2(520.0, 180.0)
	character_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	character_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var evolution_hint := _make_label(details, "二階進化｜暫以青綠星源光效與強化刀光呈現", 17, HORIZONTAL_ALIGNMENT_LEFT)
	evolution_hint.add_theme_color_override("font_color", Color(0.55, 1.0, 0.78))
	character_start_button = _make_button(details, "進入星蝕荒原", Vector2(360.0, 64.0), 24, _start_game)
	_make_label(column, "%s｜免費、非商業、非官方同人原型｜美術素材由使用者提供" % VERSION, 14)
	_choose_character(selected_character)


func _choose_character(character_id: String) -> void:
	if not CHARACTERS.has(character_id):
		return
	selected_character = character_id
	var data: Dictionary = CHARACTERS[selected_character]
	character_detail.text = "先遣角色｜%s\n\n被動｜%s\n自動武器｜%s\n%s\n\n%s" % [
		data["name"], data["passive"], data["starter_weapon"], data["starter_trait"], data["skill"],
	]
	for button_id in character_buttons:
		var button: Button = character_buttons[button_id]
		button.modulate = Color.WHITE if button_id == selected_character else Color(0.62, 0.66, 0.75)


func _show_character_select() -> void:
	_set_gm_speed(false)
	_stop_battle_music()
	get_tree().paused = true
	run_started = false
	game_over = false
	choosing_upgrade = false
	choosing_elite_reward = false
	manual_paused = false
	build_open = false
	for node in [upgrade_overlay, end_overlay, pause_overlay, build_overlay, gm_panel, interaction_label]:
		node.visible = false
	character_overlay.visible = true
	_choose_character(selected_character)
	character_start_button.grab_focus()
	queue_redraw()


func _start_game() -> void:
	_set_gm_speed(false)
	get_tree().paused = false
	run_started = true
	game_over = false
	choosing_upgrade = false
	choosing_elite_reward = false
	manual_paused = false
	build_open = false
	_start_battle_music()

	# 局內進度
	game_time = 0.0
	spawn_timer = 0.15
	wave_index = 0
	kills = 0
	level = 1
	experience = 0.0
	experience_required = 12.0
	pending_levels = 0
	pending_elite_rewards = 0
	rerolls_remaining = 1
	total_damage_dealt = 0.0
	total_damage_taken = 0.0
	damage_by_source.clear()
	current_upgrade_choices.clear()
	next_enemy_id = 0
	elite_spawn_cooldown = 0.0
	hud_refresh_timer = 0.0
	for passive_id in PASSIVE_BLUEPRINTS:
		meta_levels[passive_id] = 0

	# 玩家與角色被動
	player_pos = Vector2.ZERO
	player_speed = 255.0
	player_max_health = 110.0
	player_health = player_max_health
	player_max_shield = 24.0
	player_shield = 8.0
	player_armor = 3.0 if selected_character == "epathy" else 0.0
	player_invulnerable = 0.0
	pickup_radius = 115.0
	damage_multiplier = 1.0
	close_damage_multiplier = 1.2 if selected_character == "epathy" else 1.0
	burn_duration_multiplier = 1.3 if selected_character == "lucia" else 1.0
	slow_effect_multiplier = 1.35 if selected_character == "rafari" else 1.0
	projectile_area_scale = 1.0
	projectile_damage_multiplier = 1.0
	recovery_per_second = 0.0
	cooldown_scale = 1.0
	arsenal_area_scale = 1.0

	# 武器
	scythe_level = 1
	scythe_damage = 24.0
	scythe_radius = 132.0
	scythe_interval = {"epathy": 1.4, "lucia": 1.9, "rafari": 2.8}.get(selected_character, 1.55)
	scythe_timer = 0.25
	scythe_evolved = false
	needle_level = 0
	needle_damage = 17.0
	needle_interval = 0.72
	needle_timer = 0.2
	needle_evolved = false
	meteor_level = 0
	meteor_damage = 42.0
	meteor_radius = 70.0
	meteor_interval = 2.75
	meteor_timer = 1.35
	for weapon_id in ARSENAL_BLUEPRINTS:
		arsenal_levels[weapon_id] = 0
		arsenal_timers[weapon_id] = float(ARSENAL_BLUEPRINTS[weapon_id]["interval"]) * 0.45

	# 場上物件
	for list in [enemies, projectiles, hostile_projectiles, gems, repair_cores, evolution_cores, elite_chests, effects]:
		list.clear()
	evolution_cores_owned = 0
	apostle_spawned = false
	apostle_present = false
	apostle_enraged = false
	apostle_hp = 0.0
	apostle_max_hp = 0.0
	apostle_phase = 1
	_spawn_map_object_ring(rng.randf_range(-0.18, 0.18))

	# 介面
	camera.position = player_pos
	camera.reset_smoothing()
	for node in [character_overlay, build_overlay, upgrade_overlay, end_overlay, pause_overlay, boss_bar, boss_label]:
		node.visible = false
	gm_panel.visible = true
	_show_game_notice("WASD／方向鍵移動　E 互動　B／Tab 建構　Esc／P 暫停")
	instruction_time = 10.0
	_update_interface(0.0)
	queue_redraw()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _set_gm_speed(enabled: bool) -> void:
	gm_triple_speed = enabled
	Engine.time_scale = 3.0 if gm_triple_speed else 1.0
	if is_instance_valid(gm_speed_button):
		gm_speed_button.text = "3 倍速：開" if gm_triple_speed else "3 倍速：關"


func _toggle_gm_speed() -> void:
	if not run_started or game_over:
		return
	_set_gm_speed(not gm_triple_speed)
	_show_game_notice("GM：遊戲速度 ×%d" % (3 if gm_triple_speed else 1))


func _gm_level_up() -> void:
	if not run_started or game_over or manual_paused or build_open or choosing_elite_reward:
		return
	_gain_experience(maxf(0.0, experience_required - experience))
	_show_game_notice("GM：獲得 1 次升級")


func _gm_add_reroll() -> void:
	if not run_started or game_over:
		return
	rerolls_remaining += 1
	if choosing_upgrade:
		reroll_button.text = "[R] 重新抽取（剩餘 %d 次）" % rerolls_remaining
		reroll_button.disabled = false
	if build_open:
		_update_build_text()
	_show_game_notice("GM：重骰次數 +1（目前 %d）" % rerolls_remaining)


func _show_game_notice(message: String) -> void:
	instruction_label.text = message
	instruction_label.visible = true
	instruction_time = 2.0


func _handle_pause_input() -> void:
	if not Input.is_action_just_pressed("pause"):
		return
	if build_open:
		_toggle_build_overlay()
		return
	if choosing_upgrade or choosing_elite_reward or game_over or not run_started:
		return
	manual_paused = not manual_paused
	get_tree().paused = manual_paused
	pause_overlay.visible = manual_paused


func _resume_game() -> void:
	if not manual_paused:
		return
	manual_paused = false
	pause_overlay.visible = false
	get_tree().paused = false


func _handle_build_input() -> void:
	if Input.is_action_just_pressed("build"):
		_toggle_build_overlay()


func _toggle_build_overlay() -> void:
	if build_open:
		build_open = false
		build_overlay.visible = false
		get_tree().paused = false
		return
	if not run_started or choosing_upgrade or choosing_elite_reward or game_over or manual_paused:
		return
	build_open = true
	_update_build_text()
	build_overlay.visible = true
	get_tree().paused = true


func _update_build_text() -> void:
	var character_data: Dictionary = CHARACTERS[selected_character]
	var starter_text := "%s　已進化" % _starter_evolution_name() if scythe_evolved else "%s　Lv.%d / %d" % [_starter_weapon_name(), scythe_level, _starter_max_level()]
	var weapon_lines := PackedStringArray([
		"• " + starter_text,
		"• 星針　%s" % _weapon_level_text(needle_level),
		"• 隕炎彈　%s" % _weapon_level_text(meteor_level),
	])
	for weapon_id in ARSENAL_BLUEPRINTS:
		weapon_lines.append("• %s　%s" % [ARSENAL_BLUEPRINTS[weapon_id]["name"], _weapon_level_text(int(arsenal_levels.get(weapon_id, 0)))])
	var passive_cells := PackedStringArray()
	for passive_id in PASSIVE_BLUEPRINTS:
		passive_cells.append("• %s　Lv.%d / %d" % [PASSIVE_BLUEPRINTS[passive_id]["name"], int(meta_levels[passive_id]), PASSIVE_MAX_LEVEL])
	var passive_rows := PackedStringArray()
	for index in range(0, passive_cells.size(), 2):
		passive_rows.append("　　".join(passive_cells.slice(index, index + 2)))
	build_text.text = "\n".join(PackedStringArray([
		"%s｜%s" % [character_data["name"], character_data["role"]],
		String(character_data["passive"]),
		"",
		"武器 %d / %d" % [_weapon_slot_count(), MAX_WEAPON_SLOTS],
		"\n".join(weapon_lines),
		"",
		"能力 %d / %d" % [_passive_slot_count(), MAX_PASSIVE_SLOTS],
		"\n".join(passive_rows),
		"",
		_starter_evolution_requirement_text(),
		_needle_evolution_requirement_text(),
		"進化核心　%d（精英異變體掉落）" % evolution_cores_owned,
		"重抽剩餘　%d" % rerolls_remaining,
	]))


func _weapon_level_text(weapon_level: int) -> String:
	return "未取得" if weapon_level <= 0 else "Lv.%d / 8" % weapon_level


func _starter_weapon_name() -> String:
	return String(CHARACTERS[selected_character]["starter_weapon"])


func _starter_max_level() -> int:
	return 8 if selected_character == "epathy" else 5


func _starter_passive_required_level() -> int:
	# 疾風短刃沿用鞭系設計：滿級武器只需持有對應生存被動即可進化。
	return 1 if selected_character == "epathy" else 3


func _starter_ring_color() -> Color:
	return CHARACTERS[selected_character]["ring_color"]


func _weapon_slot_count() -> int:
	var count := 1
	for weapon_level in [needle_level, meteor_level]:
		if weapon_level > 0:
			count += 1
	for weapon_id in arsenal_levels:
		if int(arsenal_levels[weapon_id]) > 0:
			count += 1
	return count


func _passive_slot_count() -> int:
	var count := 0
	for passive_id in meta_levels:
		if int(meta_levels[passive_id]) > 0:
			count += 1
	return count


func _can_offer_common_weapon(current_level: int) -> bool:
	return current_level > 0 or _weapon_slot_count() < MAX_WEAPON_SLOTS


func _can_offer_passive(passive_id: String) -> bool:
	return int(meta_levels[passive_id]) > 0 or _passive_slot_count() < MAX_PASSIVE_SLOTS


func _starter_evolution_data() -> Dictionary:
	match selected_character:
		"epathy":
			return {"name": "疾風環斬", "passive_id": "armor", "passive_name": "強化裝甲"}
		"lucia":
			return {"name": "全域燃燒脈衝", "passive_id": "damage", "passive_name": "星源增幅"}
		"rafari":
			return {"name": "永凍領域", "passive_id": "cooldown", "passive_name": "冷卻模組"}
		_:
			return {"name": "超載鐮環", "passive_id": "area", "passive_name": "廣域線圈"}


func _starter_evolution_name() -> String:
	return String(_starter_evolution_data()["name"])


func _starter_evolution_requirement_text() -> String:
	if scythe_evolved:
		return "專屬進化：%s（完成）" % _starter_evolution_name()
	var data := _starter_evolution_data()
	var passive_id: String = data["passive_id"]
	var max_level := _starter_max_level()
	var passive_required_level := _starter_passive_required_level()
	var weapon_state := "完成" if scythe_level >= max_level else "%d / %d" % [scythe_level, max_level]
	var passive_state := "完成" if int(meta_levels[passive_id]) >= passive_required_level else "%d / %d" % [int(meta_levels[passive_id]), passive_required_level]
	var core_state := "已有" if evolution_cores_owned > 0 else "尚未取得"
	return "專屬進化：%s｜%s Lv.%d（%s）＋%s Lv.%d（%s）＋進化核心（%s）" % [
		data["name"], _starter_weapon_name(), max_level, weapon_state, data["passive_name"], passive_required_level, passive_state, core_state,
	]


func _can_evolve_starter() -> bool:
	if scythe_evolved or scythe_level < _starter_max_level() or evolution_cores_owned <= 0:
		return false
	var passive_id: String = _starter_evolution_data()["passive_id"]
	return int(meta_levels[passive_id]) >= _starter_passive_required_level()


func _can_evolve_needle() -> bool:
	return not needle_evolved and needle_level >= 8 and int(meta_levels["cooldown"]) >= 3 and evolution_cores_owned > 0


func _needle_evolution_requirement_text() -> String:
	if needle_evolved:
		return "共通進化：追星蜂群（完成）"
	var weapon_state := "完成" if needle_level >= 8 else "%d / 8" % needle_level
	var passive_state := "完成" if int(meta_levels["cooldown"]) >= 3 else "%d / 3" % int(meta_levels["cooldown"])
	var core_state := "已有" if evolution_cores_owned > 0 else "尚未取得"
	return "共通進化：追星蜂群｜星針 Lv.8（%s）＋冷卻模組 Lv.3（%s）＋進化核心（%s）" % [weapon_state, passive_state, core_state]


func _try_consume_evolution_core() -> bool:
	if _can_evolve_starter():
		evolution_cores_owned -= 1
		scythe_evolved = true
		match selected_character:
			"epathy":
				scythe_damage += 14.0
				scythe_radius += 28.0
				scythe_interval *= 0.88
			"lucia":
				scythe_damage += 8.0
				scythe_radius += 24.0
				scythe_interval *= 0.86
			"rafari":
				scythe_damage += 8.0
				scythe_radius += 20.0
				scythe_interval *= 0.88
			_:
				scythe_damage += 10.0
				scythe_radius += 36.0
				scythe_interval *= 0.82
				player_max_shield += 12.0
				player_shield = player_max_shield
		effects.append({"kind": "evolution", "pos": player_pos, "life": 1.15, "total": 1.15, "radius": scythe_radius, "color": _starter_ring_color()})
		_show_game_notice("進化完成：%s" % _starter_evolution_name())
		return true
	if _can_evolve_needle():
		evolution_cores_owned -= 1
		needle_evolved = true
		needle_damage += 12.0
		needle_interval *= 0.72
		effects.append({"kind": "evolution", "pos": player_pos, "life": 1.05, "total": 1.05, "radius": 150.0, "color": Color(0.92, 0.52, 1.0)})
		_show_game_notice("進化完成：追星蜂群")
		return true
	return false


func _handle_upgrade_input() -> void:
	if not choosing_upgrade and not choosing_elite_reward:
		return
	for index in mini(3, current_upgrade_choices.size()):
		if Input.is_action_just_pressed("upgrade_%d" % (index + 1)):
			if choosing_elite_reward:
				_select_elite_reward(current_upgrade_choices[index]["id"])
			else:
				_select_upgrade(current_upgrade_choices[index]["id"])
			return
	if choosing_upgrade and Input.is_action_just_pressed("reroll"):
		_reroll_upgrades()


func _update_player(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += movement * player_speed * delta
	camera.position = player_pos
	player_invulnerable = maxf(0.0, player_invulnerable - delta)


func _spawn_map_object_ring(angle_offset: float) -> void:
	active_map_objects.clear()
	interaction_label.visible = false
	map_object_angle_offset = wrapf(angle_offset, -PI, PI)
	for chest_index in MAP_CHEST_COUNT:
		var angle := map_object_angle_offset + TAU * float(chest_index) / float(MAP_CHEST_COUNT)
		var distance := MAP_CHEST_DISTANCE + rng.randf_range(-195.0, 255.0)
		active_map_objects.append({"pos": player_pos + Vector2.from_angle(angle) * distance, "angle": angle})


func _nearest_map_object() -> Dictionary:
	var best_distance_squared := INF
	var best: Dictionary = {}
	for map_object in active_map_objects:
		var distance_squared := player_pos.distance_squared_to(map_object["pos"])
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best = map_object.duplicate()
			best["distance_squared"] = distance_squared
	return best


func _update_map_objects() -> void:
	var nearest := _nearest_map_object()
	var in_range := not nearest.is_empty() and float(nearest["distance_squared"]) <= MAP_OBJECT_RANGE * MAP_OBJECT_RANGE
	interaction_label.visible = in_range
	if not in_range:
		return
	interaction_label.text = "[E] 開啟 先遣補給箱"
	if Input.is_action_just_pressed("interact"):
		_activate_map_object(nearest)


func _activate_map_object(map_object: Dictionary) -> void:
	rerolls_remaining += 1
	effects.append({"kind": "map_supply", "pos": map_object["pos"], "life": 1.0, "total": 1.0, "radius": 112.0})
	_show_game_notice("先遣補給箱｜獲得星源經驗、重骰 +1")
	_spawn_map_object_ring(float(map_object["angle"]) + MAP_CHEST_ANGLE_SHIFT + rng.randf_range(-0.11, 0.11))
	_gain_experience(16.0 + level * 1.5)


func _update_passive_recovery(delta: float) -> void:
	if recovery_per_second <= 0.0 or player_health >= player_max_health:
		return
	player_health = minf(player_max_health, player_health + recovery_per_second * delta)


func _use_epathy_skill() -> void:
	if enemies.is_empty():
		return
	var radius := scythe_radius
	var slash_direction := _nearest_enemy_direction()
	var slash_angle := slash_direction.angle()
	var half_arc := 1.25
	var slash_angles: Array[float] = [slash_angle]
	if scythe_level >= 2 or scythe_evolved:
		slash_angles.append(slash_angle + PI)
	var recovery_hits := 0
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		var hit_radius: float = radius + float(enemy["radius"])
		if player_pos.distance_squared_to(enemy["pos"]) > hit_radius * hit_radius:
			continue
		var enemy_direction: Vector2 = player_pos.direction_to(enemy["pos"])
		var matched_slash := -1
		for slash_index in slash_angles.size():
			var angle_difference := absf(wrapf(enemy_direction.angle() - slash_angles[slash_index], -PI, PI))
			if angle_difference <= half_arc:
				matched_slash = slash_index
				break
		if matched_slash < 0:
			continue
		var push_direction: Vector2 = player_pos.direction_to(enemy["pos"])
		enemy["pos"] += push_direction * (12.0 if enemy["boss"] else 34.0 + scythe_level * 5.0)
		enemies[index] = enemy
		var secondary_multiplier := 1.0 if scythe_evolved else 0.72
		var slash_damage := scythe_damage * damage_multiplier * close_damage_multiplier * (1.0 if matched_slash == 0 else secondary_multiplier)
		var critical := scythe_evolved and rng.randf() < 0.2
		if critical:
			slash_damage *= 2.0
			effects.append({"kind": "epathy_critical", "pos": enemy["pos"], "life": 0.34, "total": 0.34, "radius": 34.0, "color": _starter_ring_color()})
		_damage_enemy(index, slash_damage, "starter")
		if scythe_evolved:
			recovery_hits += 1
	for effect_index in slash_angles.size():
		effects.append({
			"kind": "slash",
			"pos": player_pos,
			"life": 0.42 if effect_index > 0 else 0.38,
			"total": 0.42 if effect_index > 0 else 0.38,
			"radius": radius,
			"angle": slash_angles[effect_index],
			"color": _starter_ring_color(),
		})
	if scythe_evolved and recovery_hits > 0:
		player_health = minf(player_max_health, player_health + minf(4.0, recovery_hits * 0.35))


func _use_lucia_skill() -> void:
	if enemies.is_empty():
		return
	var nearest := _nearest_enemy_indices(1)
	if nearest.is_empty():
		return
	var target_index: int = nearest[0]
	if target_index < 0 or target_index >= enemies.size():
		return
	var aim_direction := player_pos.direction_to(enemies[target_index]["pos"])
	var shot_count := 10 + (2 if scythe_level >= 3 else 0) + (2 if scythe_level >= 5 else 0) + (4 if scythe_evolved else 0)
	var spread := 0.92 + 0.05 * float(scythe_level - 1) + (0.18 if scythe_evolved else 0.0)
	var speed := 500.0
	var travel_distance := 270.0 + maxf(0.0, scythe_radius - 132.0) * 1.25
	for shot_index in shot_count:
		if projectiles.size() >= MAX_PLAYER_PROJECTILES:
			break
		var ratio := 0.5 if shot_count <= 1 else float(shot_index) / float(shot_count - 1)
		var direction := aim_direction.rotated(lerpf(-spread * 0.5, spread * 0.5, ratio))
		projectiles.append({
			"kind": "fireball",
			"pos": player_pos,
			"velocity": direction * speed,
			"damage": scythe_damage * (0.42 if scythe_evolved else 0.38) * damage_multiplier * projectile_damage_multiplier,
			"source": "starter",
			"radius": 8.0 * projectile_area_scale,
			"life": travel_distance / speed,
			"burn_time": (2.4 if scythe_evolved else 1.5) * burn_duration_multiplier,
			"burn_damage": scythe_damage * (0.11 if scythe_evolved else 0.08) * damage_multiplier * projectile_damage_multiplier,
			"color": _starter_ring_color(),
			"evolved": scythe_evolved,
		})


func _use_claire_skill() -> void:
	var radius := scythe_radius
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		var hit_radius: float = radius + float(enemy["radius"])
		if player_pos.distance_squared_to(enemy["pos"]) <= hit_radius * hit_radius:
			_damage_enemy(index, scythe_damage * damage_multiplier * (1.3 if scythe_evolved else 1.0), "starter")
	var shield_restore := 1.2 + scythe_level * 0.35 + (3.0 if scythe_evolved else 0.0)
	player_shield = minf(player_max_shield, player_shield + shield_restore)
	effects.append({"kind": "pulse", "pos": player_pos, "life": 0.55, "total": 0.55, "radius": radius, "color": _starter_ring_color()})
	if scythe_evolved:
		effects.append({"kind": "pulse", "pos": player_pos, "life": 0.72, "total": 0.72, "radius": radius * 0.72, "color": _starter_ring_color().lightened(0.32)})


func _use_rafari_skill() -> void:
	if enemies.is_empty():
		return
	var nearest := _nearest_enemy_indices(3 if scythe_evolved else 1)
	if nearest.is_empty():
		return
	var radius := minf(90.0, 58.0 + maxf(0.0, scythe_radius - 132.0) * 0.35)
	var target_positions: Array = []
	for target_index in nearest:
		if target_index >= 0 and target_index < enemies.size():
			target_positions.append(enemies[target_index]["pos"])
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		var hit_radius: float = radius + float(enemy["radius"])
		var inside_frost := false
		for target_pos in target_positions:
			if target_pos.distance_squared_to(enemy["pos"]) <= hit_radius * hit_radius:
				inside_frost = true
				break
		if not inside_frost:
			continue
		var base_slow_time := (2.4 if enemy["boss"] else 1.7) if scythe_evolved else ((1.8 if enemy["boss"] else 1.1) + scythe_level * 0.12)
		var frost_factor := 0.38 if enemy["boss"] and scythe_evolved else (0.52 if enemy["boss"] else (0.0 if scythe_evolved else 0.28))
		_apply_slow(enemy, base_slow_time * slow_effect_multiplier, frost_factor)
		_damage_enemy(index, scythe_damage * (0.88 if scythe_evolved else 0.72) * damage_multiplier, "starter")
	for target_pos in target_positions:
		effects.append({"kind": "ice", "pos": target_pos, "life": 0.92 if scythe_evolved else 0.72, "total": 0.92 if scythe_evolved else 0.72, "radius": radius, "color": _starter_ring_color()})


func _apply_slow(enemy: Dictionary, duration: float, factor: float) -> void:
	var remaining := float(enemy.get("slow_time", 0.0))
	var current_factor := float(enemy.get("slow_factor", 1.0))
	if remaining <= 0.0 or factor <= current_factor:
		enemy["slow_factor"] = factor
		enemy["slow_time"] = maxf(remaining, duration)
	elif remaining < duration:
		enemy["slow_factor"] = factor
		enemy["slow_time"] = duration


func _take_enemy_id() -> int:
	next_enemy_id += 1
	return next_enemy_id


func _offscreen_spawn_position() -> Vector2:
	var half := VIEW_SIZE * 0.5 + Vector2(SPAWN_MARGIN, SPAWN_MARGIN)
	var offset := Vector2.ZERO
	if rng.randf() < half.x / (half.x + half.y):
		offset = Vector2(rng.randf_range(-half.x, half.x), half.y * (1.0 if rng.randf() < 0.5 else -1.0))
	else:
		offset = Vector2(half.x * (1.0 if rng.randf() < 0.5 else -1.0), rng.randf_range(-half.y, half.y))
	return player_pos + offset


func _update_spawning(delta: float) -> void:
	game_time += delta
	elite_spawn_cooldown = maxf(0.0, elite_spawn_cooldown - delta)
	while wave_index < WAVE_TIMES.size() and game_time >= float(WAVE_TIMES[wave_index]):
		_trigger_wave(wave_index)
		wave_index += 1

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var interval := maxf(0.16, 0.72 - game_time * 0.0016)
		if enemies.size() < MAX_ENEMIES:
			var batch := 1 + int(game_time / 95.0)
			for index in batch:
				if _spawn_mutant().is_empty():
					break
			spawn_timer += interval
		else:
			spawn_timer = interval

	if game_time >= APOSTLE_TIME and not apostle_spawned:
		_spawn_apostle()

	if game_time >= RUN_DURATION and apostle_present and not apostle_enraged:
		apostle_enraged = true
		_show_game_notice("時限已到：使徒進入狂暴狀態！")


func _trigger_wave(index: int) -> void:
	var composition: Array
	match index:
		0: composition = ["dasher", "dasher", "dasher", "dasher", "dasher", "dasher", "dasher", "dasher"]
		1: composition = ["shooter", "shooter", "shooter", "contaminant", "contaminant", "splitter", "chaser", "chaser", "chaser", "chaser"]
		_: composition = ["tank", "tank", "guardian", "guardian", "splitter", "splitter", "contaminant", "dasher", "dasher", "dasher", "dasher"]
	for spawn_index in composition.size():
		if enemies.size() >= MAX_ENEMIES:
			break
		_spawn_mutant(composition[spawn_index], spawn_index == 0)
	instruction_label.text = "異變體波次 %d／%d 接近｜偵測到精英" % [index + 1, WAVE_TIMES.size()]
	instruction_label.visible = true
	instruction_time = 4.0
	effects.append({"kind": "warning", "pos": player_pos, "life": 1.1, "total": 1.1, "radius": 300.0})


func _roll_enemy_kind() -> String:
	var roll := rng.randf()
	for entry in SPAWN_TABLE:
		if game_time > float(entry[0]) and roll < float(entry[1]):
			return entry[2]
	return "chaser"


func _new_enemy(kind: String, spawn_pos: Vector2, hp: float, speed: float, radius: float) -> Dictionary:
	return {
		"id": _take_enemy_id(), "kind": kind, "pos": spawn_pos,
		"hp": hp, "max_hp": hp, "speed": speed, "radius": radius,
		"boss": false, "elite": false, "elite_affix": "", "elite_shield": 0.0,
		"flash": 0.0, "contact_cooldown": 0.0,
		"burn_time": 0.0, "burn_tick": 0.0, "burn_damage": 0.0,
		"slow_time": 0.0, "slow_factor": 1.0, "guarded_time": 0.0,
		"dash_cooldown": rng.randf_range(1.4, 3.2), "dash_time": 0.0, "dash_charge": 0.0, "dash_dir": Vector2.ZERO,
		"attack_cooldown": rng.randf_range(0.5, 2.2), "shot_charge": 0.0, "shot_dir": Vector2.ZERO,
		"support_cooldown": rng.randf_range(0.2, 0.8), "contamination_cooldown": rng.randf_range(0.8, 2.2),
	}


func _spawn_mutant(force_kind: String = "", force_elite: bool = false, force_affix: String = "", allow_random_elite: bool = true) -> Dictionary:
	if enemies.size() >= MAX_ENEMIES:
		return {}
	var kind := force_kind if not force_kind.is_empty() else _roll_enemy_kind()
	var stats: Dictionary = ENEMY_STATS.get(kind, ENEMY_STATS["chaser"])
	var hp := float(stats["hp"]) * (1.0 + game_time / 360.0)
	var speed := float(stats["speed"]) * (1.0 + game_time / 900.0)
	var radius := float(stats["radius"])
	var elite := force_elite
	if not elite and allow_random_elite and game_time > 50.0 and elite_spawn_cooldown <= 0.0 and rng.randf() < 0.025:
		elite = true
		elite_spawn_cooldown = RANDOM_ELITE_COOLDOWN
	var enemy := _new_enemy(kind, _offscreen_spawn_position(), hp, speed, radius)
	if elite:
		var affix: String = force_affix if force_affix in ELITE_AFFIXES else ELITE_AFFIXES[rng.randi_range(0, ELITE_AFFIXES.size() - 1)]
		hp *= 4.2
		enemy.merge({
			"elite": true, "elite_affix": affix, "hp": hp, "max_hp": hp,
			"radius": radius * 1.45,
			"speed": speed * 1.12 * (1.35 if affix == "swift" else 1.0),
			"elite_shield": hp * 0.34 if affix == "shielded" else 0.0,
		}, true)
	enemies.append(enemy)
	return enemy


func _spawn_apostle() -> void:
	apostle_spawned = true
	apostle_present = true
	apostle_max_hp = 4800.0
	apostle_hp = apostle_max_hp
	apostle_phase = 1
	var boss := _new_enemy("apostle", player_pos + Vector2(0.0, -650.0), apostle_max_hp, 48.0, 64.0)
	boss.merge({
		"boss": true, "elite": true, "dash_cooldown": 2.4, "attack_cooldown": 1.8,
		"phase": 1, "phase_transition": 0.0, "attack_cycle": 0,
		"burst_charge": 0.0, "burst_angle": 0.0, "fan_charge": 0.0, "fan_dir": Vector2.ZERO,
		"boss_dash_charge": 0.0, "boss_dash_time": 0.0, "boss_dash_dir": Vector2.ZERO,
		"hazard_charge": 0.0, "hazard_target": Vector2.ZERO, "summon_cooldown": 6.0,
	}, true)
	enemies.append(boss)
	boss_bar.visible = true
	boss_label.visible = true
	effects.append({"kind": "warning", "pos": player_pos, "life": 1.8, "total": 1.8, "radius": 420.0})
	_show_game_notice("警告：使徒降臨")
	instruction_time = 4.0


func _update_weapons(delta: float) -> void:
	scythe_timer -= delta
	if scythe_timer <= 0.0:
		_fire_scythe_ring()
		scythe_timer += scythe_interval * cooldown_scale
	if needle_level > 0:
		needle_timer -= delta
		if needle_timer <= 0.0:
			_fire_star_needles()
			needle_timer += needle_interval * cooldown_scale
	if meteor_level > 0:
		meteor_timer -= delta
		if meteor_timer <= 0.0:
			_fire_meteor_round()
			meteor_timer += meteor_interval * cooldown_scale
	for weapon_id in arsenal_levels:
		var weapon_level := int(arsenal_levels[weapon_id])
		if weapon_level <= 0:
			continue
		arsenal_timers[weapon_id] = float(arsenal_timers[weapon_id]) - delta
		if float(arsenal_timers[weapon_id]) <= 0.0:
			_fire_arsenal_weapon(weapon_id, weapon_level)
			var level_scale := pow(0.85, float(int(weapon_level >= 4) + int(weapon_level >= 7)))
			arsenal_timers[weapon_id] = float(ARSENAL_BLUEPRINTS[weapon_id]["interval"]) * level_scale * cooldown_scale


func _fire_arsenal_weapon(weapon_id: String, weapon_level: int) -> void:
	var blueprint: Dictionary = ARSENAL_BLUEPRINTS[weapon_id]
	var pattern: String = blueprint["pattern"]
	var damage_scale := 1.0 + (0.25 if weapon_level >= 2 else 0.0) + (0.3 if weapon_level >= 5 else 0.0) + (0.35 if weapon_level >= 8 else 0.0)
	var damage := float(blueprint["damage"]) * damage_scale * damage_multiplier
	var area_scale := 1.0 + (0.22 if weapon_level >= 3 else 0.0) + (0.25 if weapon_level >= 6 else 0.0)
	var radius := float(blueprint["radius"]) * area_scale
	var field_radius := radius * arsenal_area_scale
	var amount := int(blueprint["amount"]) + int(weapon_level >= 3) + int(weapon_level >= 6)
	match pattern:
		"aimed_pierce":
			var aim := _nearest_enemy_direction()
			for shot_index in amount:
				var spread := (float(shot_index) - float(amount - 1) * 0.5) * 0.09
				_spawn_arsenal_projectile(player_pos, aim.rotated(spread), float(blueprint["speed"]), damage, radius, 1.35, weapon_id, 1 + int(weapon_level >= 6))
		"heavy_axes":
			var phase := game_time * 0.55
			for shot_index in amount:
				var direction := Vector2.from_angle(phase + TAU * float(shot_index) / float(amount))
				_spawn_arsenal_projectile(player_pos, direction, float(blueprint["speed"]), damage, radius, 2.0, weapon_id, 1 + int(weapon_level >= 5))
		"returning_disc":
			var aim := _nearest_enemy_direction()
			for shot_index in amount:
				var spread := (float(shot_index) - float(amount - 1) * 0.5) * 0.32
				_spawn_arsenal_projectile(player_pos, aim.rotated(spread), float(blueprint["speed"]), damage, radius, 2.15, weapon_id, 4 + int(weapon_level >= 5) * 2, true)
		"orbit":
			for enemy_index in range(enemies.size() - 1, -1, -1):
				if enemy_index >= enemies.size():
					continue
				var enemy_radius := float(enemies[enemy_index]["radius"])
				var distance := player_pos.distance_to(enemies[enemy_index]["pos"])
				if distance >= field_radius * 0.55 - enemy_radius and distance <= field_radius + enemy_radius:
					_damage_enemy(enemy_index, damage, weapon_id)
			effects.append({"kind": "arsenal_orbit", "pos": player_pos, "life": 0.38, "total": 0.38, "radius": field_radius, "amount": amount})
		"aura":
			for enemy_index in range(enemies.size() - 1, -1, -1):
				if enemy_index >= enemies.size():
					continue
				var enemy: Dictionary = enemies[enemy_index]
				var hit_radius := field_radius + float(enemy["radius"])
				if player_pos.distance_squared_to(enemy["pos"]) > hit_radius * hit_radius:
					continue
				if weapon_level >= 6:
					_apply_slow(enemy, 0.55, 0.82 if enemy["boss"] else 0.68)
				_damage_enemy(enemy_index, damage, weapon_id)
			effects.append({"kind": "arsenal_aura", "pos": player_pos, "life": 0.42, "total": 0.42, "radius": field_radius})
		"target_area":
			for target_index in _nearest_enemy_indices(amount):
				if target_index < 0 or target_index >= enemies.size():
					continue
				var pool_life := 2.2 + weapon_level * 0.12
				effects.append({"kind": "arsenal_pool", "pos": enemies[target_index]["pos"], "life": pool_life, "total": pool_life, "radius": field_radius, "damage": damage, "damage_tick": 0.0, "slow_factor": 0.42 if weapon_level >= 5 else 0.56, "source": weapon_id})
		"chain":
			var target_indices := _nearest_enemy_indices(amount + 1)
			var chain_points: Array[Vector2] = [player_pos]
			for target_index in target_indices:
				if target_index >= 0 and target_index < enemies.size():
					chain_points.append(enemies[target_index]["pos"])
			target_indices.sort()
			target_indices.reverse()
			var chain_step := 0
			for target_index in target_indices:
				if target_index < 0 or target_index >= enemies.size():
					continue
				_damage_enemy(target_index, damage * pow(0.9, chain_step), weapon_id)
				chain_step += 1
			effects.append({"kind": "arsenal_chain", "pos": player_pos, "points": chain_points, "life": 0.28, "total": 0.28, "radius": radius})


func _spawn_arsenal_projectile(origin: Vector2, direction: Vector2, speed: float, damage: float, radius: float, lifetime: float, weapon_id: String, pierce_left: int = 0, returning: bool = false) -> void:
	if projectiles.size() >= MAX_PLAYER_PROJECTILES:
		return
	projectiles.append({
		"kind": "arsenal",
		"weapon_id": weapon_id,
		"pos": origin,
		"velocity": direction.normalized() * speed,
		"damage": damage * projectile_damage_multiplier,
		"source": weapon_id,
		"radius": radius * projectile_area_scale,
		"life": lifetime,
		"total_life": lifetime,
		"return_at": lifetime * 0.5,
		"returning": returning,
		"pierce_left": pierce_left,
		"hit_ids": [],
		"color": _arsenal_color(weapon_id),
	})


func _arsenal_color(weapon_id: String) -> Color:
	match weapon_id:
		"ion_axe": return Color(1.0, 0.45, 0.16)
		"return_disc": return Color(1.0, 0.85, 0.24)
		"ricochet_ray": return Color(0.42, 1.0, 0.72)
		_: return Color(0.35, 0.82, 1.0)


func _fire_scythe_ring() -> void:
	match selected_character:
		"epathy": _use_epathy_skill()
		"lucia": _use_lucia_skill()
		"claire": _use_claire_skill()
		"rafari": _use_rafari_skill()


func _fire_star_needles() -> void:
	if enemies.is_empty():
		return
	var shot_count := 1 + int(needle_level >= 3) + int(needle_level >= 5) + int(needle_level >= 8) + (2 if needle_evolved else 0)
	var targets := _nearest_enemy_indices(shot_count)
	for enemy_index in targets:
		if projectiles.size() >= MAX_PLAYER_PROJECTILES:
			break
		if enemy_index < 0 or enemy_index >= enemies.size():
			continue
		var target_pos: Vector2 = enemies[enemy_index]["pos"]
		var direction := player_pos.direction_to(target_pos)
		projectiles.append({
			"pos": player_pos,
			"velocity": direction * (660.0 + needle_level * 25.0 + (120.0 if needle_evolved else 0.0)),
			"damage": needle_damage * damage_multiplier * projectile_damage_multiplier,
			"source": "needle",
			"radius": (8.0 if needle_evolved else 6.0) * projectile_area_scale,
			"life": 1.5,
			"evolved": needle_evolved,
			"pierce_left": 2 if needle_evolved else (1 if needle_level >= 6 else 0),
			"hit_ids": [],
		})


func _fire_meteor_round() -> void:
	if enemies.is_empty():
		return
	var strike_count := 1 + (1 if meteor_level >= 3 else 0) + (1 if meteor_level >= 5 else 0) + (1 if meteor_level >= 8 else 0)
	var targets := _nearest_enemy_indices(strike_count)
	var strike_positions: Array = []
	for enemy_index in targets:
		if enemy_index >= 0 and enemy_index < enemies.size():
			strike_positions.append(enemies[enemy_index]["pos"])
	for enemy_index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[enemy_index]
		var inside_blast := false
		for position in strike_positions:
			var hit_radius: float = meteor_radius + float(enemy["radius"])
			if enemy["pos"].distance_squared_to(position) <= hit_radius * hit_radius:
				inside_blast = true
				break
		if not inside_blast:
			continue
		enemy["burn_time"] = maxf(float(enemy.get("burn_time", 0.0)), (1.5 + meteor_level * 0.18) * burn_duration_multiplier)
		enemy["burn_tick"] = 0.0
		enemy["burn_damage"] = maxf(float(enemy.get("burn_damage", 0.0)), meteor_damage * 0.1 * damage_multiplier)
		enemies[enemy_index] = enemy
		_damage_enemy(enemy_index, meteor_damage * damage_multiplier, "meteor")
	for position in strike_positions:
		effects.append({"kind": "meteor", "pos": position, "life": 0.68, "total": 0.68, "radius": meteor_radius})


func _nearest_enemy_indices(count: int) -> Array:
	if count <= 0 or enemies.is_empty():
		return []
	var result: Array = []
	var distances: Array = []
	for index in enemies.size():
		var distance: float = player_pos.distance_squared_to(enemies[index]["pos"])
		var insert_at := distances.size()
		for distance_index in distances.size():
			if distance < float(distances[distance_index]):
				insert_at = distance_index
				break
		if insert_at < count:
			distances.insert(insert_at, distance)
			result.insert(insert_at, index)
			if result.size() > count:
				result.pop_back()
				distances.pop_back()
	return result


func _nearest_enemy_direction() -> Vector2:
	var nearest := _nearest_enemy_indices(1)
	if nearest.is_empty():
		return Vector2.RIGHT
	var target_index: int = nearest[0]
	if target_index < 0 or target_index >= enemies.size():
		return Vector2.RIGHT
	return player_pos.direction_to(enemies[target_index]["pos"])


func _update_projectiles(delta: float) -> void:
	for projectile_index in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[projectile_index]
		if bool(projectile.get("returning", false)) and float(projectile.get("life", 0.0)) <= float(projectile.get("return_at", 0.0)):
			if not bool(projectile.get("has_returned", false)):
				projectile["has_returned"] = true
				projectile["hit_ids"] = []
			var return_speed: float = maxf(300.0, Vector2(projectile["velocity"]).length())
			projectile["velocity"] = Vector2(projectile["pos"]).direction_to(player_pos) * return_speed
			if Vector2(projectile["pos"]).distance_squared_to(player_pos) <= 625.0:
				projectiles.remove_at(projectile_index)
				continue
		projectile["pos"] = Vector2(projectile["pos"]) + Vector2(projectile["velocity"]) * delta
		projectile["life"] = float(projectile["life"]) - delta

		var consumed := false
		var hit_ids: Array = projectile.get("hit_ids", [])
		for enemy_index in range(enemies.size() - 1, -1, -1):
			if enemy_index >= enemies.size():
				continue
			var enemy: Dictionary = enemies[enemy_index]
			var collision_radius: float = float(projectile["radius"]) + float(enemy["radius"])
			var offset: Vector2 = Vector2(projectile["pos"]) - Vector2(enemy["pos"])
			if absf(offset.x) > collision_radius or absf(offset.y) > collision_radius:
				continue
			if offset.length_squared() > collision_radius * collision_radius:
				continue
			var enemy_id := int(enemy.get("id", -1))
			if hit_ids.has(enemy_id):
				continue
			if projectile.get("kind", "") == "fireball":
				enemy["burn_time"] = maxf(float(enemy.get("burn_time", 0.0)), float(projectile.get("burn_time", 0.0)))
				enemy["burn_tick"] = 0.0
				enemy["burn_damage"] = maxf(float(enemy.get("burn_damage", 0.0)), float(projectile.get("burn_damage", 0.0)))
			_damage_enemy(enemy_index, float(projectile["damage"]), String(projectile.get("source", "other")))
			if int(projectile.get("pierce_left", 0)) > 0:
				projectile["pierce_left"] = int(projectile["pierce_left"]) - 1
				hit_ids.append(enemy_id)
			else:
				consumed = true
				break
		projectile["hit_ids"] = hit_ids

		if consumed or float(projectile["life"]) <= 0.0:
			projectiles.remove_at(projectile_index)
		else:
			projectiles[projectile_index] = projectile


func _update_enemy_statuses(delta: float) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		if index >= enemies.size():
			continue
		var enemy = enemies[index]
		enemy["slow_time"] = maxf(0.0, float(enemy.get("slow_time", 0.0)) - delta)
		enemy["guarded_time"] = maxf(0.0, float(enemy.get("guarded_time", 0.0)) - delta)
		if float(enemy.get("burn_time", 0.0)) > 0.0:
			enemy["burn_time"] = maxf(0.0, float(enemy["burn_time"]) - delta)
			enemy["burn_tick"] = float(enemy.get("burn_tick", 0.0)) - delta
			if float(enemy["burn_tick"]) <= 0.0:
				enemy["burn_tick"] = 0.5
				var burn_damage: float = float(enemy.get("burn_damage", 0.0))
				var actual_burn_damage := minf(burn_damage, float(enemy["hp"]))
				_record_damage("burn", actual_burn_damage)
				enemy["hp"] = float(enemy["hp"]) - burn_damage
				enemy["flash"] = 0.08
				if enemy["boss"]:
					apostle_hp = maxf(0.0, float(enemy["hp"]))
		if float(enemy["hp"]) <= 0.0:
			enemies[index] = enemy
			_kill_enemy(index)
			continue
		enemies[index] = enemy


func _apply_enemy_separation(delta: float) -> void:
	if enemies.size() < 2:
		return
	var grid := {}
	for index in enemies.size():
		var pos: Vector2 = enemies[index]["pos"]
		var cell := Vector2i(floori(pos.x / SEPARATION_CELL), floori(pos.y / SEPARATION_CELL))
		if not grid.has(cell):
			grid[cell] = []
		grid[cell].append(index)

	for index in enemies.size():
		var enemy: Dictionary = enemies[index]
		if enemy["boss"] or float(enemy.get("dash_time", 0.0)) > 0.0:
			continue
		var pos: Vector2 = enemy["pos"]
		var radius := float(enemy["radius"])
		var cell := Vector2i(floori(pos.x / SEPARATION_CELL), floori(pos.y / SEPARATION_CELL))
		var push := Vector2.ZERO
		var checks := 0
		for offset_x in range(-1, 2):
			if checks >= SEPARATION_MAX_CHECKS:
				break
			for offset_y in range(-1, 2):
				if checks >= SEPARATION_MAX_CHECKS:
					break
				var neighbor_cell := cell + Vector2i(offset_x, offset_y)
				if not grid.has(neighbor_cell):
					continue
				for other_index in grid[neighbor_cell]:
					if other_index == index:
						continue
					checks += 1
					if checks > SEPARATION_MAX_CHECKS:
						break
					var other: Dictionary = enemies[other_index]
					var min_distance := radius + float(other["radius"])
					var offset: Vector2 = pos - Vector2(other["pos"])
					var distance_squared := offset.length_squared()
					if distance_squared >= min_distance * min_distance:
						continue
					if distance_squared < 0.01:
						offset = Vector2.from_angle(float(index) * 2.399)
						distance_squared = 1.0
					var distance := sqrt(distance_squared)
					push += offset / distance * (min_distance - distance)
		if push != Vector2.ZERO:
			enemy["pos"] = pos + (push * 0.5).limit_length(220.0 * delta)


func _update_enemies(delta: float) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		if index >= enemies.size():
			continue
		var enemy = enemies[index]
		enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
		enemy["contact_cooldown"] = maxf(0.0, float(enemy["contact_cooldown"]) - delta)
		var direction: Vector2 = enemy["pos"].direction_to(player_pos)
		var status_speed := float(enemy.get("slow_factor", 1.0)) if float(enemy.get("slow_time", 0.0)) > 0.0 else 1.0

		if enemy["boss"]:
			enemy = _update_apostle(enemy, delta * (APOSTLE_ENRAGE_TEMPO if apostle_enraged else 1.0), status_speed)
		elif enemy["kind"] == "guardian":
			enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
			enemy["support_cooldown"] = float(enemy.get("support_cooldown", 0.0)) - delta
			if float(enemy["support_cooldown"]) <= 0.0:
				for ally_index in enemies.size():
					if ally_index == index or bool(enemies[ally_index].get("boss", false)):
						continue
					if enemy["pos"].distance_squared_to(enemies[ally_index]["pos"]) <= 19600.0:
						var ally = enemies[ally_index]
						ally["guarded_time"] = maxf(float(ally.get("guarded_time", 0.0)), 1.1)
						enemies[ally_index] = ally
				enemy["support_cooldown"] = 0.75
		elif enemy["kind"] == "contaminant":
			var contaminant_distance: float = enemy["pos"].distance_squared_to(player_pos)
			if contaminant_distance > 48400.0:
				enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
			else:
				enemy["pos"] += direction.rotated(PI * 0.5) * float(enemy["speed"]) * 0.35 * status_speed * delta
			enemy["contamination_cooldown"] = float(enemy.get("contamination_cooldown", 0.0)) - delta
			if float(enemy["contamination_cooldown"]) <= 0.0:
				effects.append({"kind": "contamination", "pos": enemy["pos"], "life": 4.2, "total": 4.2, "radius": 58.0, "damage_tick": 0.0})
				enemy["contamination_cooldown"] = 3.4
		elif enemy["kind"] == "shooter":
			if float(enemy.get("shot_charge", 0.0)) > 0.0:
				enemy["shot_charge"] = float(enemy["shot_charge"]) - delta
				if float(enemy["shot_charge"]) <= 0.0:
					enemy["shot_charge"] = 0.0
					_fire_mutant_shot(enemy["pos"], enemy["shot_dir"])
					enemy["attack_cooldown"] = rng.randf_range(2.1, 2.8)
			else:
				var distance_squared: float = enemy["pos"].distance_squared_to(player_pos)
				if distance_squared > 136900.0:
					enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
				elif distance_squared < 60025.0:
					enemy["pos"] -= direction * float(enemy["speed"]) * status_speed * delta
				else:
					enemy["pos"] += direction.rotated(PI * 0.5) * float(enemy["speed"]) * 0.45 * status_speed * delta
				enemy["attack_cooldown"] = float(enemy["attack_cooldown"]) - delta
				if float(enemy["attack_cooldown"]) <= 0.0 and status_speed > 0.0:
					enemy["shot_dir"] = direction
					enemy["shot_charge"] = 0.52
		elif enemy["kind"] == "dasher":
			if float(enemy.get("dash_charge", 0.0)) > 0.0:
				enemy["dash_charge"] = float(enemy["dash_charge"]) - delta
				if float(enemy["dash_charge"]) <= 0.0:
					enemy["dash_charge"] = 0.0
					enemy["dash_time"] = 0.42
					enemy["dash_cooldown"] = rng.randf_range(2.4, 3.5)
			elif float(enemy["dash_time"]) > 0.0:
				enemy["dash_time"] = float(enemy["dash_time"]) - delta
				enemy["pos"] += enemy["dash_dir"] * float(enemy["speed"]) * 4.2 * status_speed * delta
			else:
				enemy["dash_cooldown"] = float(enemy["dash_cooldown"]) - delta
				enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
				if float(enemy["dash_cooldown"]) <= 0.0:
					enemy["dash_dir"] = direction
					enemy["dash_charge"] = 0.48
		else:
			enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta

		# 落後太遠的敵人傳送回畫面外圍，避免佔滿上限、前方生不出新怪。
		if not enemy["boss"] and Vector2(enemy["pos"]).distance_squared_to(player_pos) > RECYCLE_DISTANCE * RECYCLE_DISTANCE:
			enemy["pos"] = _offscreen_spawn_position()
			enemy["dash_time"] = 0.0
			enemy["dash_charge"] = 0.0

		var contact_radius: float = float(enemy["radius"]) + 18.0
		if enemy["pos"].distance_squared_to(player_pos) <= contact_radius * contact_radius and float(enemy["contact_cooldown"]) <= 0.0:
			var contact_damage := 22.0 if enemy["boss"] else (14.0 if enemy["kind"] == "tank" else (11.0 if enemy["elite"] else 7.0))
			_take_player_damage(contact_damage)
			enemy["contact_cooldown"] = 0.75
		enemies[index] = enemy


func _update_apostle(enemy: Dictionary, delta: float, status_speed: float) -> Dictionary:
	var hp_ratio: float = float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"]))
	if int(enemy.get("phase", 1)) == 1 and hp_ratio <= 0.5:
		enemy["phase"] = 2
		enemy["phase_transition"] = 1.15
		enemy["attack_cooldown"] = 0.75
		enemy["speed"] = float(enemy["speed"]) * 1.16
		enemy["summon_cooldown"] = 3.0
		apostle_phase = 2
		hostile_projectiles.clear()
		effects.append({"kind": "apostle_phase", "pos": enemy["pos"], "life": 1.15, "total": 1.15, "radius": 230.0})
		_show_game_notice("使徒進入第二階段：攻擊模式改變")

	if float(enemy.get("phase_transition", 0.0)) > 0.0:
		enemy["phase_transition"] = maxf(0.0, float(enemy["phase_transition"]) - delta)
		return enemy

	var direction: Vector2 = enemy["pos"].direction_to(player_pos)
	if float(enemy.get("boss_dash_time", 0.0)) > 0.0:
		enemy["boss_dash_time"] = maxf(0.0, float(enemy["boss_dash_time"]) - delta)
		enemy["pos"] += Vector2(enemy["boss_dash_dir"]) * float(enemy["speed"]) * 7.2 * status_speed * delta
		if float(enemy["boss_dash_time"]) <= 0.0:
			enemy["attack_cooldown"] = 1.35
	elif float(enemy.get("boss_dash_charge", 0.0)) > 0.0:
		enemy["boss_dash_charge"] = float(enemy["boss_dash_charge"]) - delta
		if float(enemy["boss_dash_charge"]) <= 0.0:
			enemy["boss_dash_charge"] = 0.0
			enemy["boss_dash_time"] = 0.48
	elif float(enemy.get("fan_charge", 0.0)) > 0.0:
		enemy["fan_charge"] = float(enemy["fan_charge"]) - delta
		if float(enemy["fan_charge"]) <= 0.0:
			enemy["fan_charge"] = 0.0
			_fire_apostle_fan(enemy["pos"], enemy["fan_dir"])
			enemy["attack_cooldown"] = 1.45
	elif float(enemy.get("hazard_charge", 0.0)) > 0.0:
		enemy["hazard_charge"] = float(enemy["hazard_charge"]) - delta
		if float(enemy["hazard_charge"]) <= 0.0:
			enemy["hazard_charge"] = 0.0
			_create_apostle_hazards(enemy["hazard_target"], enemy["pos"].direction_to(enemy["hazard_target"]))
			enemy["attack_cooldown"] = 1.5
	elif float(enemy.get("burst_charge", 0.0)) > 0.0:
		enemy["burst_charge"] = float(enemy["burst_charge"]) - delta
		if float(enemy["burst_charge"]) <= 0.0:
			enemy["burst_charge"] = 0.0
			_fire_apostle_burst(enemy["pos"], float(enemy.get("burst_angle", 0.0)))
			enemy["attack_cooldown"] = 2.35
	else:
		enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
		enemy["attack_cooldown"] = float(enemy["attack_cooldown"]) - delta
		if float(enemy["attack_cooldown"]) <= 0.0:
			if int(enemy.get("phase", 1)) == 1:
				enemy["burst_angle"] = game_time * 0.22
				enemy["burst_charge"] = 0.85
			else:
				var attack_cycle: int = int(enemy.get("attack_cycle", 0)) % 3
				enemy["attack_cycle"] = attack_cycle + 1
				match attack_cycle:
					0:
						enemy["fan_dir"] = direction
						enemy["fan_charge"] = 0.68
					1:
						enemy["boss_dash_dir"] = direction
						enemy["boss_dash_charge"] = 0.72
					_:
						enemy["hazard_target"] = player_pos
						enemy["hazard_charge"] = 0.78

	enemy["summon_cooldown"] = float(enemy["summon_cooldown"]) - delta
	if float(enemy["summon_cooldown"]) <= 0.0:
		var summon_count := 3 if int(enemy.get("phase", 1)) >= 2 else 5
		for summon_index in summon_count:
			_spawn_mutant("chaser" if summon_index % 2 == 0 else "dasher")
		enemy["summon_cooldown"] = 8.5 if int(enemy.get("phase", 1)) >= 2 else 7.0
	return enemy


func _fire_apostle_burst(origin: Vector2, angle_offset: float = 0.0) -> void:
	var projectile_count := 12
	for index in projectile_count:
		if hostile_projectiles.size() >= MAX_HOSTILE_PROJECTILES:
			break
		var angle := TAU * float(index) / float(projectile_count) + angle_offset
		hostile_projectiles.append({
			"pos": origin,
			"velocity": Vector2.from_angle(angle) * 185.0,
			"radius": 9.0,
			"damage": 10.0,
			"life": 6.0,
		})


func _fire_apostle_fan(origin: Vector2, locked_direction: Vector2) -> void:
	var base_direction := locked_direction.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = origin.direction_to(player_pos)
	for projectile_index in 7:
		if hostile_projectiles.size() >= MAX_HOSTILE_PROJECTILES:
			break
		var ratio := float(projectile_index) / 6.0
		var shot_direction := base_direction.rotated(lerpf(-0.62, 0.62, ratio))
		hostile_projectiles.append({
			"kind": "fan",
			"pos": origin,
			"velocity": shot_direction * 275.0,
			"radius": 10.0,
			"damage": 12.0,
			"life": 5.0,
		})


func _create_apostle_hazards(center: Vector2, cast_direction: Vector2) -> void:
	var perpendicular := cast_direction.normalized().rotated(PI * 0.5)
	if perpendicular == Vector2.ZERO:
		perpendicular = Vector2.UP
	for offset in [Vector2.ZERO, perpendicular * 112.0, perpendicular * -112.0]:
		effects.append({
			"kind": "apostle_hazard",
			"pos": center + offset,
			"life": 4.0,
			"total": 4.0,
			"radius": 76.0,
			"arm_time": 0.62,
			"damage_tick": 0.0,
		})


func _fire_mutant_shot(origin: Vector2, locked_direction: Vector2 = Vector2.ZERO) -> void:
	if hostile_projectiles.size() >= MAX_HOSTILE_PROJECTILES:
		return
	var direction := locked_direction.normalized()
	if direction == Vector2.ZERO:
		direction = origin.direction_to(player_pos)
	hostile_projectiles.append({
		"pos": origin,
		"velocity": direction * 255.0,
		"radius": 7.0,
		"damage": 8.0,
		"life": 5.0,
	})


func _update_hostile_projectiles(delta: float) -> void:
	for index in range(hostile_projectiles.size() - 1, -1, -1):
		var projectile = hostile_projectiles[index]
		projectile["pos"] += projectile["velocity"] * delta
		projectile["life"] -= delta
		if projectile["pos"].distance_to(player_pos) <= float(projectile["radius"]) + 17.0:
			_take_player_damage(float(projectile["damage"]))
			hostile_projectiles.remove_at(index)
		elif float(projectile["life"]) <= 0.0:
			hostile_projectiles.remove_at(index)
		else:
			hostile_projectiles[index] = projectile


func _record_damage(source: String, amount: float) -> void:
	if amount <= 0.0:
		return
	total_damage_dealt += amount
	damage_by_source[source] = float(damage_by_source.get(source, 0.0)) + amount


func _damage_source_name(source: String) -> String:
	if ARSENAL_BLUEPRINTS.has(source):
		return String(ARSENAL_BLUEPRINTS[source]["name"])
	match source:
		"starter": return _starter_evolution_name() if scythe_evolved else _starter_weapon_name()
		"needle": return "追星蜂群" if needle_evolved else "星針"
		"meteor": return "隕炎彈"
		"burn": return "燃燒"
	return "其他"


func _damage_breakdown_text() -> String:
	var entries: Array = []
	for source in damage_by_source:
		var amount := float(damage_by_source[source])
		if amount >= 1.0:
			entries.append({"name": _damage_source_name(String(source)), "amount": amount})
	if entries.is_empty():
		return "（尚無傷害紀錄）"
	entries.sort_custom(func(a, b): return float(a["amount"]) > float(b["amount"]))
	var total := maxf(1.0, total_damage_dealt)
	var lines: Array[String] = []
	for index in mini(6, entries.size()):
		var entry: Dictionary = entries[index]
		lines.append("%s　%d（%d%%）" % [entry["name"], int(entry["amount"]), roundi(float(entry["amount"]) / total * 100.0)])
	return "\n".join(lines)


func _damage_enemy(index: int, amount: float, source: String = "other") -> void:
	if index < 0 or index >= enemies.size() or amount <= 0.0:
		return
	var enemy: Dictionary = enemies[index]
	if float(enemy.get("guarded_time", 0.0)) > 0.0 and enemy.get("kind", "") != "guardian" and not bool(enemy.get("boss", false)):
		amount *= 0.65
	var elite_shield: float = float(enemy.get("elite_shield", 0.0))
	if elite_shield > 0.0:
		var shield_absorbed := minf(amount, elite_shield)
		enemy["elite_shield"] = elite_shield - shield_absorbed
		_record_damage(source, shield_absorbed)
		amount -= shield_absorbed
		enemy["flash"] = 0.08
		if float(enemy["elite_shield"]) <= 0.0:
			effects.append({"kind": "shield_break", "pos": enemy["pos"], "life": 0.35, "total": 0.35, "radius": float(enemy["radius"]) + 18.0})
		if amount <= 0.0:
			return
	_record_damage(source, minf(amount, float(enemy["hp"])))
	enemy["hp"] = float(enemy["hp"]) - amount
	enemy["flash"] = 0.08
	if enemy["boss"]:
		apostle_hp = maxf(0.0, float(enemy["hp"]))
	if float(enemy["hp"]) <= 0.0:
		_kill_enemy(index)


func _kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy = enemies[index]
	var was_boss: bool = enemy["boss"]
	var was_splitter: bool = enemy.get("kind", "") == "splitter"
	var was_explosive: bool = enemy.get("elite_affix", "") == "explosive"
	var split_position: Vector2 = enemy["pos"]
	var split_count := 3 if bool(enemy.get("elite", false)) else 2
	var gem_value := 8.0 if enemy["elite"] else 1.0
	if not was_boss:
		_drop_experience_gem(enemy["pos"], gem_value)
		if enemy["elite"]:
			_drop_repair_core(enemy["pos"])
			_drop_evolution_core(enemy["pos"])
			_drop_elite_chest(enemy["pos"])
	kills += 1
	effects.append({"kind": "burst", "pos": enemy["pos"], "life": 0.24, "total": 0.24, "radius": float(enemy["radius"]) * 2.2})
	enemies.remove_at(index)
	if was_explosive and not was_boss:
		effects.append({"kind": "elite_explosion", "pos": split_position, "life": 0.75, "total": 0.75, "radius": 104.0, "damage": 18.0})
	if was_splitter and not was_boss:
		_spawn_splitlings(split_position, split_count)
	if was_boss:
		apostle_present = false
		apostle_hp = 0.0
		_finish_game(true)


func _spawn_splitlings(origin: Vector2, count: int) -> void:
	for split_index in count:
		var child := _spawn_mutant("chaser", false, "", false)
		if child.is_empty():
			return
		child["pos"] = origin + Vector2.from_angle(TAU * float(split_index) / maxf(1.0, float(count))) * 18.0
		child["hp"] = minf(float(child["hp"]), 16.0)
		child["max_hp"] = float(child["hp"])
		child["radius"] = 10.0
		child["speed"] = maxf(float(child["speed"]), 92.0)


func _drop_experience_gem(position: Vector2, value: float) -> void:
	if gems.size() < MAX_GEMS:
		gems.append({"pos": position, "value": value})
		return
	var receiver = gems[gems.size() - 1]
	receiver["value"] = float(receiver["value"]) + value
	gems[gems.size() - 1] = receiver


func _drop_repair_core(position: Vector2) -> void:
	if repair_cores.size() < MAX_REPAIR_CORES:
		repair_cores.append({"pos": position, "heal": 24.0})
		return
	var receiver = repair_cores[repair_cores.size() - 1]
	receiver["heal"] = minf(72.0, float(receiver["heal"]) + 8.0)
	repair_cores[repair_cores.size() - 1] = receiver


func _drop_evolution_core(position: Vector2) -> void:
	if (scythe_evolved and needle_evolved) or evolution_cores_owned > 0:
		return
	if evolution_cores.size() >= MAX_EVOLUTION_CORES:
		return
	evolution_cores.append({"pos": position + Vector2(22.0, -8.0)})


func _drop_elite_chest(position: Vector2) -> void:
	if elite_chests.size() >= MAX_ELITE_CHESTS:
		pending_elite_rewards += 1
		return
	elite_chests.append({"pos": position + Vector2(-22.0, 8.0), "pulse": rng.randf_range(0.0, TAU)})


func _take_player_damage(amount: float) -> void:
	if player_invulnerable > 0.0 or game_over:
		return
	var final_amount := maxf(1.0, amount - player_armor)
	total_damage_taken += final_amount
	if player_shield > 0.0:
		var absorbed := minf(player_shield, final_amount)
		player_shield -= absorbed
		final_amount -= absorbed
	player_health -= final_amount
	player_invulnerable = 0.58
	effects.append({"kind": "hurt", "pos": player_pos, "life": 0.28, "total": 0.28, "radius": 54.0})
	if player_health <= 0.0:
		player_health = 0.0
		_finish_game(false)


func _magnet_pickup(item: Dictionary, magnet_range: float, base_pull: float, pull_gain: float, collect_radius: float, delta: float) -> bool:
	var item_pos: Vector2 = item["pos"]
	var distance := item_pos.distance_to(player_pos)
	if distance <= magnet_range:
		item_pos = item_pos.move_toward(player_pos, (base_pull + (magnet_range - distance) * pull_gain) * delta)
		item["pos"] = item_pos
	return item_pos.distance_squared_to(player_pos) <= collect_radius * collect_radius


func _update_pickups(delta: float) -> void:
	for index in range(gems.size() - 1, -1, -1):
		if _magnet_pickup(gems[index], pickup_radius * 2.0, 240.0, 3.0, 25.0, delta):
			var value := float(gems[index]["value"])
			gems.remove_at(index)
			_gain_experience(value)
	for index in range(repair_cores.size() - 1, -1, -1):
		if _magnet_pickup(repair_cores[index], pickup_radius * 1.5, 210.0, 3.2, 27.0, delta):
			var heal := float(repair_cores[index]["heal"])
			repair_cores.remove_at(index)
			_collect_repair_core(heal)
	for index in range(evolution_cores.size() - 1, -1, -1):
		if _magnet_pickup(evolution_cores[index], pickup_radius * 1.65, 225.0, 3.4, 27.0, delta):
			evolution_cores.remove_at(index)
			evolution_cores_owned = 1
			if not _try_consume_evolution_core():
				_show_game_notice("取得進化核心｜達成條件後自動進化")
	for index in range(elite_chests.size() - 1, -1, -1):
		var chest: Dictionary = elite_chests[index]
		chest["pulse"] = float(chest.get("pulse", 0.0)) + delta * 3.0
		if _magnet_pickup(chest, pickup_radius + 40.0, 180.0, 4.0, 32.0, delta):
			elite_chests.remove_at(index)
			pending_elite_rewards += 1
			effects.append({"kind": "elite_chest", "pos": player_pos, "life": 0.7, "total": 0.7, "radius": 92.0})
	if pending_elite_rewards > 0 and not choosing_upgrade and not choosing_elite_reward and not game_over:
		_show_elite_reward_choices()


func _collect_repair_core(heal: float) -> void:
	var restored := minf(heal, player_max_health - player_health)
	if restored > 0.0:
		player_health += restored
		_show_game_notice("修復核心：生命 +%d" % int(restored))
	else:
		player_shield = minf(player_max_shield, player_shield + 8.0)
		_show_game_notice("修復核心：護盾 +8")
	effects.append({"kind": "repair", "pos": player_pos, "life": 0.55, "total": 0.55, "radius": 72.0})


func _gain_experience(amount: float) -> void:
	if game_over or not run_started:
		return
	experience += amount
	while experience >= experience_required:
		experience -= experience_required
		level += 1
		experience_required = floorf(12.0 * pow(float(level), 1.28))
		pending_levels += 1
	if pending_levels > 0 and not choosing_upgrade and not choosing_elite_reward:
		_show_upgrade_choices()


func _show_choice_cards(title: String, options: Array, tag_of: Callable, on_pick: Callable) -> void:
	get_tree().paused = true
	upgrade_overlay.visible = true
	upgrade_title.text = title
	for child in upgrade_buttons.get_children():
		upgrade_buttons.remove_child(child)
		child.queue_free()
	current_upgrade_choices = options.slice(0, 3)
	for index in current_upgrade_choices.size():
		var option: Dictionary = current_upgrade_choices[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(285.0, 205.0)
		button.text = "[%d]【%s】%s\n\n%s" % [index + 1, tag_of.call(option), option["name"], option["description"]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(on_pick.bind(option["id"]))
		upgrade_buttons.add_child(button)


func _advance_choice_queue() -> void:
	if game_over:
		return
	if pending_levels > 0:
		_show_upgrade_choices()
	elif pending_elite_rewards > 0:
		_show_elite_reward_choices()
	else:
		choosing_upgrade = false
		choosing_elite_reward = false
		upgrade_overlay.visible = false
		get_tree().paused = false


func _upgrade_category(option: Dictionary) -> String:
	return "武器" if _is_weapon_upgrade(option["id"]) else "能力"


func _show_upgrade_choices() -> void:
	choosing_upgrade = true
	choosing_elite_reward = false
	_show_choice_cards("星源共鳴｜等級 %d" % level, _pick_upgrade_choices(_available_upgrades()), _upgrade_category, _select_upgrade)
	reroll_button.text = "[R] 重新抽取（剩餘 %d 次）" % rerolls_remaining
	reroll_button.disabled = rerolls_remaining <= 0


func _show_elite_reward_choices() -> void:
	if pending_elite_rewards <= 0:
		return
	choosing_upgrade = false
	choosing_elite_reward = true
	var candidates := _elite_reward_candidates()
	candidates.shuffle()
	_show_choice_cards("精英戰利品｜選擇一項特殊補給", candidates, func(_option): return "戰利品", _select_elite_reward)
	reroll_button.text = "精英戰利品不可重抽"
	reroll_button.disabled = true


func _elite_reward_candidates() -> Array:
	var result: Array = [
		{"id": "weapon_tuning", "name": "主武器精煉", "description": "%s傷害 +8、作用範圍 +5%%" % _starter_weapon_name()},
		{"id": "damage_boost", "name": "星源增幅器", "description": "本局所有傷害永久提高 10%"},
		{"id": "overclock", "name": "戰術超頻", "description": "所有自動武器冷卻縮短 8%"},
		{"id": "defense_cache", "name": "防衛補給", "description": "最大護盾 +12、護甲 +1，並恢復生命與護盾"},
		{"id": "salvage", "name": "先遣搜刮權限", "description": "重骰 +2、拾取範圍 +30"},
	]
	if evolution_cores_owned <= 0 and (not scythe_evolved or not needle_evolved):
		result.append({"id": "evolution_core", "name": "進化核心", "description": "取得 1 枚進化核心；達成條件時自動完成進化"})
	return result


func _select_elite_reward(reward_id: String) -> void:
	match reward_id:
		"weapon_tuning":
			scythe_damage += 8.0
			scythe_radius *= 1.05
		"damage_boost":
			damage_multiplier *= 1.1
		"overclock":
			cooldown_scale *= 0.92
		"defense_cache":
			player_max_shield += 12.0
			player_shield = player_max_shield
			player_armor += 1.0
			player_health = minf(player_max_health, player_health + 40.0)
		"salvage":
			rerolls_remaining += 2
			pickup_radius += 30.0
		"evolution_core":
			evolution_cores_owned = 1
			_try_consume_evolution_core()
	pending_elite_rewards = maxi(0, pending_elite_rewards - 1)
	_advance_choice_queue()


func _pick_upgrade_choices(candidates: Array) -> Array:
	var weapons: Array = []
	var abilities: Array = []
	for option in candidates:
		if _is_weapon_upgrade(option["id"]):
			weapons.append(option)
		else:
			abilities.append(option)
	weapons.shuffle()
	abilities.shuffle()

	var result: Array = []
	if not weapons.is_empty():
		result.append(weapons.pop_back())
	if not abilities.is_empty():
		result.append(abilities.pop_back())
	var remaining := weapons + abilities
	remaining.shuffle()
	while result.size() < 3 and not remaining.is_empty():
		result.append(remaining.pop_back())
	result.shuffle()
	return result


func _is_weapon_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in ["scythe", "needle", "meteor"] or upgrade_id.begins_with("arsenal:")


func _reroll_upgrades() -> void:
	if not choosing_upgrade or rerolls_remaining <= 0:
		return
	rerolls_remaining -= 1
	_show_upgrade_choices()


func _available_upgrades() -> Array:
	var result: Array = []
	if scythe_level < _starter_max_level():
		result.append({"id": "scythe", "name": "%s Lv.%d" % [_starter_weapon_name(), scythe_level + 1], "description": _scythe_upgrade_description(scythe_level + 1)})
	if needle_level < 8 and _can_offer_common_weapon(needle_level):
		result.append({"id": "needle", "name": "星針 Lv.%d" % (needle_level + 1), "description": _needle_upgrade_description(needle_level + 1)})
	if meteor_level < 8 and _can_offer_common_weapon(meteor_level):
		result.append({"id": "meteor", "name": "隕炎彈 Lv.%d" % (meteor_level + 1), "description": _meteor_upgrade_description(meteor_level + 1)})
	for weapon_id in ARSENAL_BLUEPRINTS:
		var arsenal_level := int(arsenal_levels.get(weapon_id, 0))
		if arsenal_level < 8 and _can_offer_common_weapon(arsenal_level):
			result.append({"id": "arsenal:%s" % weapon_id, "name": "%s Lv.%d" % [ARSENAL_BLUEPRINTS[weapon_id]["name"], arsenal_level + 1], "description": _arsenal_upgrade_description(weapon_id, arsenal_level + 1)})
	for passive_id in PASSIVE_BLUEPRINTS:
		var passive_level := int(meta_levels[passive_id])
		if passive_level < PASSIVE_MAX_LEVEL and _can_offer_passive(passive_id):
			result.append({"id": passive_id, "name": "%s Lv.%d" % [PASSIVE_BLUEPRINTS[passive_id]["name"], passive_level + 1], "description": PASSIVE_BLUEPRINTS[passive_id]["description"]})
	if result.is_empty():
		result = [
			{"id": "fallback_heal", "name": "星源修復", "description": "回復 30 生命與 10 護盾"},
			{"id": "fallback_power", "name": "星源餘燼", "description": "所有傷害永久提高 3%"},
			{"id": "fallback_reroll", "name": "備用重骰", "description": "重骰次數 +1"},
		]
	return result


func _scythe_upgrade_description(next_level: int) -> String:
	if selected_character == "epathy":
		match next_level:
			2: return "追加反向第二斬，擴大近身清場覆蓋"
			3: return "基礎傷害 +5"
			4: return "基礎傷害 +5，斬擊範圍 +10%"
			5: return "基礎傷害 +5"
			6: return "基礎傷害 +5，斬擊範圍 +10%"
			7: return "基礎傷害 +5"
			8: return "基礎傷害 +5；可進行專屬進化"
	if selected_character == "lucia":
		match next_level:
			2: return "火球傷害 +10"
			3: return "每次增加 2 顆火球，霰彈射程提高"
			4: return "火球發射間隔縮短 20%"
			5: return "再增加 2 顆火球，傷害 +14"
	if selected_character == "rafari":
		match next_level:
			2: return "冰霜傷害 +10"
			3: return "冰霜範圍小幅增加"
			4: return "冰霜生成間隔縮短 20%"
			5: return "提高冰霜傷害與凍緩時間"
	match next_level:
		2: return "%s傷害 +10" % _starter_weapon_name()
		3: return "%s作用範圍 +34" % _starter_weapon_name()
		4: return "攻擊間隔縮短 20%"
		5: return "%s能力強化" % _starter_weapon_name()
	return "強化%s" % _starter_weapon_name()


func _needle_upgrade_description(next_level: int) -> String:
	match next_level:
		1: return "取得武器：向最近異變體發射星針"
		2: return "星針傷害 +8"
		3: return "每次額外發射 1 枚星針"
		4: return "攻擊間隔縮短 20%"
		5: return "再增加 1 枚星針，傷害 +8"
		6: return "星針可額外穿透 1 個目標"
		7: return "攻擊間隔再縮短 15%"
		8: return "再增加 1 枚星針，傷害 +10"
	return "強化星針"


func _meteor_upgrade_description(next_level: int) -> String:
	match next_level:
		1: return "取得武器：轟擊敵人並留下燃燒"
		2: return "爆炸傷害 +16"
		3: return "每輪額外轟擊 1 個目標"
		4: return "發射間隔縮短 22%"
		5: return "再增加 1 個目標，爆炸範圍 +20"
		6: return "爆炸傷害 +18，燃燒時間延長"
		7: return "發射間隔再縮短 15%"
		8: return "再增加 1 個目標，爆炸範圍 +18"
	return "強化隕炎彈"


func _arsenal_upgrade_description(weapon_id: String, next_level: int) -> String:
	var blueprint: Dictionary = ARSENAL_BLUEPRINTS[weapon_id]
	if next_level == 1:
		return "取得武器：%s" % blueprint["description"]
	match weapon_id:
		"rail_blade":
			match next_level:
				2: return "飛刃傷害提高 25%"
				3: return "每輪額外發射 1 枚飛刃"
				4: return "發射間隔縮短 15%"
				5: return "飛刃傷害再提高 30%"
				6: return "再增加 1 枚飛刃，並額外穿透 1 個目標"
				7: return "發射間隔再縮短 15%"
				8: return "磁軌超載：傷害提高 35%"
		"ion_axe":
			match next_level:
				2: return "戰斧傷害提高 25%"
				3: return "每輪額外拋出 1 把戰斧，尺寸增大"
				4: return "拋射間隔縮短 15%"
				5: return "傷害提高 30%，額外穿透 1 個目標"
				6: return "再增加 1 把戰斧，尺寸再次增大"
				7: return "拋射間隔再縮短 15%"
				8: return "離子過載：傷害提高 35%"
		"return_disc":
			match next_level:
				2: return "星環傷害提高 25%"
				3: return "每輪額外發射 1 枚折返星環"
				4: return "發射間隔縮短 15%"
				5: return "傷害提高 30%，可穿透更多目標"
				6: return "再增加 1 枚星環並擴大尺寸"
				7: return "發射間隔再縮短 15%"
				8: return "雙程共振：傷害提高 35%"
		"orbit_blades":
			match next_level:
				2: return "刃陣傷害提高 25%"
				3: return "增加 1 枚軌道刃並擴大環繞半徑"
				4: return "切割間隔縮短 15%"
				5: return "刃陣傷害再提高 30%"
				6: return "再增加 1 枚軌道刃並擴大半徑"
				7: return "切割間隔再縮短 15%"
				8: return "軌道超載：傷害提高 35%"
		"plasma_aura":
			match next_level:
				2: return "等離子傷害提高 25%"
				3: return "放電範圍擴大 22%"
				4: return "放電間隔縮短 15%"
				5: return "等離子傷害再提高 30%"
				6: return "範圍再次擴大，命中附加短暫減速"
				7: return "放電間隔再縮短 15%"
				8: return "電漿飽和：傷害提高 35%"
		"cryo_pool":
			match next_level:
				2: return "冷媒每跳傷害提高 25%"
				3: return "每輪額外生成 1 處污染區並擴大範圍"
				4: return "生成間隔縮短 15%"
				5: return "傷害提高 30%，減速效果增強"
				6: return "再增加 1 處污染區並擴大範圍"
				7: return "生成間隔再縮短 15%"
				8: return "深度冷卻：傷害提高 35%"
		"ricochet_ray":
			match next_level:
				2: return "折射傷害提高 25%"
				3: return "每輪額外連鎖 1 個目標"
				4: return "折射間隔縮短 15%"
				5: return "折射傷害再提高 30%"
				6: return "再額外連鎖 1 個目標"
				7: return "折射間隔再縮短 15%"
				8: return "游標超頻：傷害提高 35%"
	match next_level:
		2: return "基礎傷害提高 25%"
		3: return "投射數量或作用範圍提高"
		4: return "攻擊冷卻縮短 15%"
		5: return "基礎傷害再提高 30%"
		6: return "投射數量或作用範圍再次提高"
		7: return "攻擊冷卻再縮短 15%"
		8: return "完成武器極限強化"
	return "強化%s" % blueprint["name"]


func _select_upgrade(upgrade_id: String) -> void:
	if upgrade_id.begins_with("arsenal:"):
		var weapon_id := upgrade_id.trim_prefix("arsenal:")
		arsenal_levels[weapon_id] = mini(8, int(arsenal_levels.get(weapon_id, 0)) + 1)
		arsenal_timers[weapon_id] = 0.05
	else:
		_apply_standard_upgrade(upgrade_id)
	_try_consume_evolution_core()
	pending_levels = maxi(0, pending_levels - 1)
	_advance_choice_queue()


func _apply_standard_upgrade(upgrade_id: String) -> void:
	if meta_levels.has(upgrade_id):
		meta_levels[upgrade_id] = int(meta_levels[upgrade_id]) + 1
	match upgrade_id:
		"scythe":
			scythe_level += 1
			if selected_character == "epathy":
				scythe_damage += 5.0 if scythe_level >= 3 else 0.0
				if scythe_level in [4, 6]:
					scythe_radius *= 1.1
			else:
				match scythe_level:
					2: scythe_damage += 10.0
					3: scythe_radius += 34.0
					4: scythe_interval *= 0.8
					5:
						scythe_damage += 14.0
						if selected_character == "claire":
							player_max_shield += 8.0
		"needle":
			needle_level += 1
			match needle_level:
				2, 5: needle_damage += 8.0
				4: needle_interval *= 0.8
				7: needle_interval *= 0.85
				8: needle_damage += 10.0
		"meteor":
			meteor_level += 1
			match meteor_level:
				2: meteor_damage += 16.0
				4: meteor_interval *= 0.78
				5: meteor_radius += 20.0
				6: meteor_damage += 18.0
				7: meteor_interval *= 0.85
				8: meteor_radius += 18.0
		"health":
			player_max_health += 15.0
			player_health = minf(player_max_health, player_health + 15.0)
		"speed": player_speed *= 1.08
		"pickup": pickup_radius += 25.0
		"armor": player_armor += 1.0
		"damage": damage_multiplier *= 1.12
		"cooldown": cooldown_scale *= 0.94
		"area":
			scythe_radius += 12.0
			meteor_radius += 8.0
			projectile_area_scale *= 1.08
			arsenal_area_scale *= 1.08
		"recovery":
			recovery_per_second += 0.4
			player_health = minf(player_max_health, player_health + 5.0)
		"precision": projectile_damage_multiplier *= 1.12
		"fallback_heal":
			player_health = minf(player_max_health, player_health + 30.0)
			player_shield = minf(player_max_shield, player_shield + 10.0)
		"fallback_power":
			damage_multiplier *= 1.03
		"fallback_reroll":
			rerolls_remaining += 1



func _update_effects(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		var effect = effects[index]
		effect["life"] = float(effect["life"]) - delta
		if effect.get("kind", "") == "arsenal_pool":
			effect["damage_tick"] = float(effect.get("damage_tick", 0.0)) - delta
			if float(effect["damage_tick"]) <= 0.0:
				var pool_source := String(effect.get("source", "other"))
				var pool_slow := float(effect.get("slow_factor", 0.56))
				for enemy_index in range(enemies.size() - 1, -1, -1):
					if enemy_index >= enemies.size():
						continue
					var enemy: Dictionary = enemies[enemy_index]
					var hit_radius := float(effect["radius"]) + float(enemy["radius"])
					if Vector2(effect["pos"]).distance_squared_to(enemy["pos"]) > hit_radius * hit_radius:
						continue
					_apply_slow(enemy, 0.72, maxf(0.35, pool_slow) if enemy["boss"] else pool_slow)
					_damage_enemy(enemy_index, float(effect.get("damage", 8.0)), pool_source)
				effect["damage_tick"] = 0.45
		elif effect.get("kind", "") == "contamination":
			effect["damage_tick"] = float(effect.get("damage_tick", 0.0)) - delta
			var hazard_radius: float = float(effect["radius"]) + 16.0
			if float(effect["damage_tick"]) <= 0.0 and player_pos.distance_squared_to(effect["pos"]) <= hazard_radius * hazard_radius:
				_take_player_damage(8.0)
				effect["damage_tick"] = 0.7
		elif effect.get("kind", "") == "apostle_hazard":
			effect["arm_time"] = maxf(0.0, float(effect.get("arm_time", 0.0)) - delta)
			if float(effect["arm_time"]) <= 0.0:
				effect["damage_tick"] = float(effect.get("damage_tick", 0.0)) - delta
				var apostle_hazard_radius: float = float(effect["radius"]) + 16.0
				if float(effect["damage_tick"]) <= 0.0 and player_pos.distance_squared_to(effect["pos"]) <= apostle_hazard_radius * apostle_hazard_radius:
					_take_player_damage(11.0)
					effect["damage_tick"] = 0.65
		elif effect.get("kind", "") == "elite_explosion" and float(effect["life"]) <= 0.0:
			var blast_radius: float = float(effect["radius"]) + 16.0
			if player_pos.distance_squared_to(effect["pos"]) <= blast_radius * blast_radius:
				_take_player_damage(float(effect.get("damage", 18.0)))
		if float(effect["life"]) <= 0.0:
			effects.remove_at(index)
		else:
			effects[index] = effect


func _trim_effects() -> void:
	if effects.size() <= MAX_EFFECTS:
		return
	var overflow := effects.size() - MAX_EFFECTS
	var kept: Array = []
	for effect in effects:
		if overflow > 0 and not GAMEPLAY_EFFECT_KINDS.has(effect.get("kind", "")):
			overflow -= 1
			continue
		kept.append(effect)
	effects = kept


func _enforce_runtime_limits() -> void:
	_trim_effects()
	if projectiles.size() > MAX_PLAYER_PROJECTILES:
		projectiles = projectiles.slice(projectiles.size() - MAX_PLAYER_PROJECTILES)
	if hostile_projectiles.size() > MAX_HOSTILE_PROJECTILES:
		hostile_projectiles = hostile_projectiles.slice(hostile_projectiles.size() - MAX_HOSTILE_PROJECTILES)
	if evolution_cores.size() > MAX_EVOLUTION_CORES:
		evolution_cores = evolution_cores.slice(evolution_cores.size() - MAX_EVOLUTION_CORES)
	if elite_chests.size() > MAX_ELITE_CHESTS:
		pending_elite_rewards += elite_chests.size() - MAX_ELITE_CHESTS
		elite_chests = elite_chests.slice(elite_chests.size() - MAX_ELITE_CHESTS)
	while gems.size() > MAX_GEMS:
		var overflow_gem = gems.pop_back()
		var gem_receiver = gems[gems.size() - 1]
		gem_receiver["value"] = float(gem_receiver["value"]) + float(overflow_gem["value"])
		gems[gems.size() - 1] = gem_receiver
	while repair_cores.size() > MAX_REPAIR_CORES:
		var overflow_core = repair_cores.pop_back()
		var core_receiver = repair_cores[repair_cores.size() - 1]
		core_receiver["heal"] = minf(72.0, float(core_receiver["heal"]) + float(overflow_core["heal"]))
		repair_cores[repair_cores.size() - 1] = core_receiver


func _update_interface(delta: float) -> void:
	if instruction_time > 0.0:
		instruction_time -= delta
		instruction_label.visible = true
	else:
		instruction_label.visible = false
	hud_refresh_timer -= delta
	if delta > 0.0 and hud_refresh_timer > 0.0:
		return
	hud_refresh_timer = 0.1
	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	time_label.text = "星蝕荒原　區域 1 / 1\n%02d:%02d" % [minutes, seconds]
	var character_name: String = CHARACTERS[selected_character]["name"]
	stats_label.text = "%s　Lv.%d\n生命 %d / %d　護盾 %d\n護甲 %d　擊殺 %d" % [
		character_name,
		level,
		ceili(player_health),
		ceili(player_max_health),
		ceili(player_shield),
		int(player_armor),
		kills,
	]
	var threat_level := mini(5, 1 + int(game_time / 60.0))
	var next_wave_text := "已完成" if wave_index >= WAVE_TIMES.size() else _format_countdown(maxf(0.0, float(WAVE_TIMES[wave_index]) - game_time))
	enemy_label.text = "異變體 %d　威脅 Lv.%d\n波次 %d / %d　下一波 %s\n使徒降臨 %s" % [
		enemies.size(),
		threat_level,
		wave_index,
		WAVE_TIMES.size(),
		next_wave_text,
		("戰鬥中" if apostle_spawned else _format_countdown(maxf(0.0, APOSTLE_TIME - game_time))),
	]
	weapon_label.text = "%s\n星針 %s｜隕炎彈 %s" % [
		("%s｜進化" % _starter_evolution_name() if scythe_evolved else "%s Lv.%d%s" % [_starter_weapon_name(), scythe_level, ("｜待核心" if scythe_level >= _starter_max_level() else "")]),
		("未取得" if needle_level == 0 else ("追星蜂群｜進化" if needle_evolved else "Lv.%d" % needle_level)),
		("未取得" if meteor_level == 0 else "Lv.%d" % meteor_level),
	]
	var active_arsenal: Array[String] = []
	for weapon_id in arsenal_levels:
		var arsenal_level := int(arsenal_levels[weapon_id])
		if arsenal_level > 0:
			active_arsenal.append("%s Lv.%d" % [ARSENAL_BLUEPRINTS[weapon_id]["name"], arsenal_level])
	if not active_arsenal.is_empty():
		weapon_label.text += "\n" + "｜".join(active_arsenal)
	var skill_name: String = _starter_evolution_name() if scythe_evolved else CHARACTERS[selected_character]["skill_name"]
	skill_label.text = "自動能力｜%s\n每 %.1f 秒發動" % [skill_name, scythe_interval * cooldown_scale]
	skill_label.modulate = _starter_ring_color()
	xp_bar.max_value = experience_required
	xp_bar.value = experience

	if apostle_present:
		boss_bar.max_value = apostle_max_hp
		boss_bar.value = apostle_hp
		boss_label.text = "使徒｜第 %d 階段%s" % [apostle_phase, "｜狂暴" if apostle_enraged else ""]
		boss_bar.visible = true
		boss_label.visible = true
	else:
		boss_bar.visible = false
		boss_label.visible = false

func _format_countdown(value: float) -> String:
	var total := maxi(0, ceili(value))
	return "%02d:%02d" % [total / 60, total % 60]


func _finish_game(victory: bool) -> void:
	if game_over:
		return
	game_over = true
	_stop_battle_music()
	interaction_label.visible = false
	_set_gm_speed(false)
	gm_panel.visible = false
	choosing_upgrade = false
	choosing_elite_reward = false
	upgrade_overlay.visible = false
	get_tree().paused = true
	end_overlay.visible = true
	end_title.text = "使徒討伐完成" if victory else "任務失敗"
	end_title.modulate = Color(0.45, 0.95, 1.0) if victory else Color(1.0, 0.4, 0.48)
	end_summary.text = "生存時間　%s\n擊殺數　%d　最終等級　%d\n造成傷害　%d　承受傷害　%d\n\n傷害分布（前 6 名）\n%s\n\n%s" % [
		_format_countdown(game_time),
		kills,
		level,
		int(total_damage_dealt),
		int(total_damage_taken),
		_damage_breakdown_text(),
		("方舟防線暫時安全。" if victory else "重新調整強化後再次出擊。"),
	]


func _draw() -> void:
	_draw_background()
	_draw_effect_layer(true)
	_draw_pickups()
	_draw_units_y_sorted()
	_draw_player_projectiles()
	_draw_hostile_projectiles()
	_draw_effect_layer(false)
	_draw_map_object_indicator()


func _draw_effect_layer(ground_layer: bool) -> void:
	for effect in effects:
		if GROUND_EFFECT_KINDS.has(effect.get("kind", "")) != ground_layer:
			continue
		if not _is_world_visible(effect["pos"], float(effect.get("radius", 0.0)) + 48.0):
			continue
		_draw_effect(effect)


func _draw_units_y_sorted() -> void:
	var visible_enemies: Array = []
	for enemy in enemies:
		if _is_world_visible(enemy["pos"], DRAW_MARGIN + float(enemy["radius"])):
			visible_enemies.append(enemy)
	visible_enemies.sort_custom(func(a, b): return Vector2(a["pos"]).y < Vector2(b["pos"]).y)
	var player_drawn := false
	for enemy in visible_enemies:
		if not player_drawn and Vector2(enemy["pos"]).y > player_pos.y:
			_draw_player()
			player_drawn = true
		_draw_enemy(enemy)
	if not player_drawn:
		_draw_player()


func _draw_pickups() -> void:
	for gem in gems:
		var gem_pos: Vector2 = gem["pos"]
		if not _is_world_visible(gem_pos, 24.0):
			continue
		var gem_size := 7.0 if float(gem["value"]) <= 1.0 else 11.0
		draw_colored_polygon(PackedVector2Array([
			gem_pos + Vector2(0.0, -gem_size),
			gem_pos + Vector2(gem_size * 0.72, 0.0),
			gem_pos + Vector2(0.0, gem_size),
			gem_pos + Vector2(-gem_size * 0.72, 0.0),
		]), Color(0.26, 0.95, 1.0))

	for core in repair_cores:
		var core_pos: Vector2 = core["pos"]
		if not _is_world_visible(core_pos, 32.0):
			continue
		draw_circle(core_pos, 13.0, Color(0.14, 0.95, 0.62, 0.22))
		draw_arc(core_pos, 12.0, 0.0, TAU, 24, Color(0.35, 1.0, 0.72), 3.0, true)
		draw_rect(Rect2(core_pos + Vector2(-3.0, -8.0), Vector2(6.0, 16.0)), Color(0.7, 1.0, 0.86))
		draw_rect(Rect2(core_pos + Vector2(-8.0, -3.0), Vector2(16.0, 6.0)), Color(0.7, 1.0, 0.86))

	for core in evolution_cores:
		var core_pos: Vector2 = core["pos"]
		if not _is_world_visible(core_pos, 36.0):
			continue
		var pulse := 1.0 + sin(game_time * 5.5) * 0.12
		var outer_points := PackedVector2Array()
		for point_index in 6:
			outer_points.append(core_pos + Vector2.from_angle(TAU * float(point_index) / 6.0) * 16.0 * pulse)
		draw_colored_polygon(outer_points, Color(1.0, 0.72, 0.18, 0.88))
		draw_arc(core_pos, 21.0 * pulse, 0.0, TAU, 28, Color(0.45, 0.95, 1.0, 0.78), 4.0, true)
		draw_circle(core_pos, 6.0, Color(0.96, 1.0, 0.78))

	for chest in elite_chests:
		var chest_pos: Vector2 = chest["pos"]
		if not _is_world_visible(chest_pos, 42.0):
			continue
		var chest_pulse := 1.0 + sin(float(chest.get("pulse", 0.0))) * 0.08
		draw_circle(chest_pos, 25.0 * chest_pulse, Color(1.0, 0.72, 0.16, 0.15))
		draw_rect(Rect2(chest_pos + Vector2(-17.0, -10.0) * chest_pulse, Vector2(34.0, 24.0) * chest_pulse), Color(0.18, 0.12, 0.28), true)
		draw_rect(Rect2(chest_pos + Vector2(-17.0, -10.0) * chest_pulse, Vector2(34.0, 24.0) * chest_pulse), Color(1.0, 0.72, 0.2), false, 4.0)
		draw_line(chest_pos + Vector2(-17.0, -2.0), chest_pos + Vector2(17.0, -2.0), Color(1.0, 0.9, 0.45), 4.0, true)
		draw_circle(chest_pos + Vector2(0.0, 4.0), 4.0, Color(0.48, 0.95, 1.0))


func _draw_player_projectiles() -> void:
	for projectile in projectiles:
		if not _is_world_visible(projectile["pos"], 48.0):
			continue
		var direction: Vector2 = Vector2(projectile["velocity"]).normalized()
		if projectile.get("kind", "") == "fireball":
			var fireball_color: Color = projectile.get("color", Color(1.0, 0.42, 0.16))
			draw_line(projectile["pos"] - direction * 18.0, projectile["pos"], Color(fireball_color, 0.48), 8.0, true)
			draw_circle(projectile["pos"], float(projectile["radius"]), fireball_color)
			draw_circle(projectile["pos"], float(projectile["radius"]) * 0.46, fireball_color.lightened(0.55))
		elif projectile.get("kind", "") == "arsenal":
			var arsenal_color: Color = projectile.get("color", Color(0.35, 0.82, 1.0))
			match projectile.get("weapon_id", ""):
				"ion_axe":
					var side := direction.rotated(PI * 0.5) * float(projectile["radius"])
					draw_colored_polygon(PackedVector2Array([projectile["pos"] + direction * 15.0, projectile["pos"] + side, projectile["pos"] - direction * 15.0, projectile["pos"] - side]), arsenal_color)
					draw_arc(projectile["pos"], float(projectile["radius"]) + 4.0, game_time * 7.0, game_time * 7.0 + 4.7, 16, Color(1.0, 0.82, 0.36, 0.8), 3.0, true)
				"return_disc":
					draw_arc(projectile["pos"], float(projectile["radius"]) + 5.0, game_time * 9.0, game_time * 9.0 + 5.2, 20, arsenal_color, 6.0, true)
					draw_circle(projectile["pos"], 3.0, Color(1.0, 1.0, 0.78))
				_:
					draw_line(projectile["pos"] - direction * 14.0, projectile["pos"] + direction * 7.0, Color(arsenal_color, 0.42), maxf(4.0, float(projectile["radius"]) * 0.7), true)
					draw_circle(projectile["pos"], float(projectile["radius"]), arsenal_color)
		else:
			var evolved := bool(projectile.get("evolved", false))
			var projectile_color := Color(0.95, 0.62, 1.0) if evolved else Color(0.5, 0.95, 1.0)
			draw_line(projectile["pos"] - direction * (14.0 if evolved else 10.0), projectile["pos"] + direction * 7.0, projectile_color, 7.0 if evolved else 5.0, true)


func _draw_hostile_projectiles() -> void:
	for projectile in hostile_projectiles:
		if not _is_world_visible(projectile["pos"], 48.0):
			continue
		var hostile_color := Color(1.0, 0.48, 0.12) if projectile.get("kind", "") == "fan" else Color(1.0, 0.2, 0.48)
		draw_circle(projectile["pos"], float(projectile["radius"]) + 3.0, Color(0.06, 0.0, 0.05, 0.85))
		draw_circle(projectile["pos"], float(projectile["radius"]), hostile_color)
		if enemies.size() < LOW_DETAIL_ENEMY_COUNT:
			draw_arc(projectile["pos"], float(projectile["radius"]) + 4.0, 0.0, TAU, 18, hostile_color.lightened(0.42), 2.0, true)


func _draw_map_object_indicator() -> void:
	if not run_started or game_over:
		return
	var target := _nearest_map_object()
	if target.is_empty() or _is_world_visible(target["pos"], -40.0):
		return
	var view_center := camera.get_screen_center_position()
	var offset: Vector2 = Vector2(target["pos"]) - view_center
	var edge := VIEW_SIZE * 0.5 - Vector2(60.0, 60.0)
	var edge_scale := minf(edge.x / maxf(absf(offset.x), 0.001), edge.y / maxf(absf(offset.y), 0.001))
	var direction := offset.normalized()
	var tip := view_center + offset * minf(edge_scale, 1.0)
	var side := direction.orthogonal() * 12.0
	draw_colored_polygon(PackedVector2Array([tip + direction * 18.0, tip - direction * 10.0 + side, tip - direction * 10.0 - side]), Color(1.0, 0.78, 0.25, 0.92))
	draw_string(ui_theme.default_font, tip - direction * 32.0 + Vector2(-40.0, 6.0), "補給 %dm" % int(offset.length() / 32.0), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 15, Color(1.0, 0.9, 0.6))


func _is_world_visible(world_position: Vector2, margin: float = DRAW_MARGIN) -> bool:
	var view_center: Vector2 = camera.get_screen_center_position() if is_instance_valid(camera) else player_pos
	var offset := world_position - view_center
	return absf(offset.x) <= VIEW_SIZE.x * 0.5 + margin and absf(offset.y) <= VIEW_SIZE.y * 0.5 + margin


func _draw_background() -> void:
	var tile_size := 160.0
	var left := floorf((player_pos.x - 780.0) / tile_size) * tile_size
	var right := player_pos.x + 780.0
	var top := floorf((player_pos.y - 480.0) / tile_size) * tile_size
	var bottom := player_pos.y + 480.0
	draw_rect(Rect2(left, top, right - left, bottom - top), Color(0.18, 0.21, 0.16))

	var start_x := int(floorf(left / tile_size))
	var end_x := int(ceilf(right / tile_size))
	var start_y := int(floorf(top / tile_size))
	var end_y := int(ceilf(bottom / tile_size))
	for cell_x in range(start_x, end_x + 1):
		for cell_y in range(start_y, end_y + 1):
			var origin := Vector2(cell_x * tile_size, cell_y * tile_size)
			var noise := _terrain_noise(cell_x, cell_y, 0.0)
			var tile_color := Color(0.23, 0.25, 0.17) if noise > 0.48 else Color(0.19, 0.23, 0.17)
			draw_colored_polygon(PackedVector2Array([
				origin + Vector2(2.0, 10.0), origin + Vector2(tile_size - 8.0, 0.0),
				origin + Vector2(tile_size, tile_size - 14.0), origin + Vector2(12.0, tile_size),
			]), tile_color)
			draw_line(origin + Vector2(0.0, tile_size), origin + Vector2(tile_size, tile_size - 8.0), Color(0.07, 0.1, 0.08, 0.22), 2.0)

			if noise > 0.72:
				var rock_center := origin + Vector2(30.0 + _terrain_noise(cell_x, cell_y, 1.0) * 96.0, 34.0 + _terrain_noise(cell_x, cell_y, 2.0) * 82.0)
				var rock_scale := 12.0 + _terrain_noise(cell_x, cell_y, 3.0) * 18.0
				draw_ellipse_shadow(rock_center + Vector2(8.0, 10.0), rock_scale * 1.2, rock_scale * 0.42, Color(0.02, 0.035, 0.03, 0.35))
				draw_colored_polygon(PackedVector2Array([
					rock_center + Vector2(-rock_scale, rock_scale * 0.3),
					rock_center + Vector2(-rock_scale * 0.45, -rock_scale * 0.7),
					rock_center + Vector2(rock_scale * 0.55, -rock_scale * 0.5),
					rock_center + Vector2(rock_scale, rock_scale * 0.45),
				]), Color(0.27, 0.3, 0.26))
				draw_line(rock_center + Vector2(-rock_scale * 0.4, -rock_scale * 0.45), rock_center + Vector2(rock_scale * 0.45, -rock_scale * 0.3), Color(0.43, 0.46, 0.36, 0.55), 3.0)

			if _terrain_noise(cell_x, cell_y, 4.0) > 0.78:
				var crystal := origin + Vector2(45.0 + _terrain_noise(cell_x, cell_y, 5.0) * 70.0, 44.0 + _terrain_noise(cell_x, cell_y, 6.0) * 64.0)
				draw_circle(crystal, 22.0, Color(0.12, 0.46, 0.38, 0.1))
				draw_colored_polygon(PackedVector2Array([
					crystal + Vector2(0.0, -18.0), crystal + Vector2(9.0, 7.0),
					crystal + Vector2(0.0, 15.0), crystal + Vector2(-8.0, 6.0),
				]), Color(0.3, 0.94, 0.68, 0.58))

	# 四選一探索寶箱：開啟任一個便清除同組其餘三個，下一組以新的角度環繞玩家生成。
	for map_object in active_map_objects:
		var marker: Vector2 = map_object["pos"]
		if not _is_world_visible(marker, 90.0):
			continue
		var object_color := Color(1.0, 0.72, 0.22)
		var pulse := 1.0 + sin(game_time * 2.4 + float(map_object.get("angle", 0.0))) * 0.05
		draw_ellipse_shadow(marker + Vector2(0.0, 18.0), 54.0, 20.0, Color(0.01, 0.04, 0.04, 0.42))
		draw_circle(marker, 49.0 * pulse, Color(1.0, 0.68, 0.16, 0.1))
		draw_arc(marker, 49.0 * pulse, 0.0, TAU, 32, Color(object_color, 0.42), 3.0)
		draw_rect(Rect2(marker + Vector2(-27.0, -9.0), Vector2(54.0, 33.0)), Color(0.26, 0.15, 0.2), true)
		draw_rect(Rect2(marker + Vector2(-27.0, -9.0), Vector2(54.0, 33.0)), object_color, false, 4.0)
		draw_rect(Rect2(marker + Vector2(-29.0, -22.0), Vector2(58.0, 17.0)), Color(0.38, 0.19, 0.22), true)
		draw_rect(Rect2(marker + Vector2(-29.0, -22.0), Vector2(58.0, 17.0)), Color(1.0, 0.84, 0.34), false, 4.0)
		draw_line(marker + Vector2(-27.0, 2.0), marker + Vector2(27.0, 2.0), Color(1.0, 0.86, 0.38), 4.0, true)
		draw_rect(Rect2(marker + Vector2(-6.0, 3.0), Vector2(12.0, 13.0)), Color(0.48, 0.95, 1.0), true)


func _terrain_noise(x: int, y: int, salt: float) -> float:
	var value := sin(float(x) * 12.9898 + float(y) * 78.233 + salt * 37.719) * 43758.5453
	return value - floorf(value)


func draw_ellipse_shadow(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var points := PackedVector2Array()
	for point_index in 24:
		var angle := TAU * float(point_index) / 24.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, color)


func _draw_sprite_billboard(texture: Texture2D, feet_position: Vector2, target_height: float, modulate: Color = Color.WHITE, lift: float = 0.0) -> void:
	if texture == null:
		return
	var texture_size := texture.get_size()
	var target_width := target_height * texture_size.x / maxf(1.0, texture_size.y)
	var rect := Rect2(
		feet_position.x - target_width * 0.5,
		feet_position.y - target_height + 12.0 - lift,
		target_width,
		target_height
	)
	draw_texture_rect(texture, rect, false, modulate)


func _draw_enemy(enemy: Dictionary) -> void:
	var position: Vector2 = enemy["pos"]
	var radius: float = enemy["radius"]
	var flash: bool = float(enemy["flash"]) > 0.0
	var low_detail := enemies.size() >= LOW_DETAIL_ENEMY_COUNT
	if enemy["boss"]:
		var boss_color := (Color(1.0, 0.16, 0.22) if int(enemy.get("phase", 1)) >= 2 else Color(1.0, 0.24, 0.52)) if not flash else Color.WHITE
		draw_ellipse_shadow(position + Vector2(0.0, 13.0), 82.0, 25.0, Color(0.01, 0.015, 0.02, 0.58))
		draw_circle(position, radius + 12.0, Color(boss_color, 0.14))
		draw_arc(position, radius + 16.0, game_time * 0.5, game_time * 0.5 + TAU * 0.78, 48, boss_color, 6.0, true)
		_draw_sprite_billboard(ANUBARAK_TEXTURE, position + Vector2(0.0, 20.0), 178.0, Color(1.7, 1.7, 1.7, 1.0) if flash else Color.WHITE)
		var burst_charge: float = float(enemy.get("burst_charge", 0.0))
		if burst_charge > 0.0:
			var charge_progress := clampf(1.0 - burst_charge / 0.85, 0.0, 1.0)
			var charge_alpha := 0.52 + 0.38 * sin(burst_charge * 34.0)
			var warning_radius := radius + 86.0 - charge_progress * 48.0
			draw_arc(position, warning_radius, 0.0, TAU, 64, Color(1.0, 0.2, 0.5, charge_alpha), 8.0, true)
			var burst_angle: float = float(enemy.get("burst_angle", 0.0))
			for warning_spoke in 12:
				var warning_angle := burst_angle + TAU * float(warning_spoke) / 12.0
				var warning_direction := Vector2.from_angle(warning_angle)
				draw_line(
					position + warning_direction * (radius + 8.0),
					position + warning_direction * (radius + 150.0),
					Color(1.0, 0.3, 0.58, charge_alpha * 0.72),
					3.0,
					true
				)
		var phase_transition: float = float(enemy.get("phase_transition", 0.0))
		if phase_transition > 0.0:
			var phase_progress := 1.0 - phase_transition / 1.15
			draw_circle(position, radius + 110.0 * phase_progress, Color(1.0, 0.08, 0.16, 0.12))
			draw_arc(position, radius + 110.0 * phase_progress, 0.0, TAU, 64, Color(1.0, 0.18, 0.12, 0.95 - phase_progress * 0.4), 10.0, true)
		var fan_charge: float = float(enemy.get("fan_charge", 0.0))
		if fan_charge > 0.0:
			var fan_direction: Vector2 = enemy.get("fan_dir", Vector2.RIGHT)
			var fan_alpha := 0.5 + 0.38 * sin(fan_charge * 30.0)
			for edge_angle in [-0.62, 0.62]:
				draw_line(position, position + fan_direction.rotated(edge_angle) * 330.0, Color(1.0, 0.48, 0.12, fan_alpha), 5.0, true)
			draw_arc(position, 180.0, fan_direction.angle() - 0.62, fan_direction.angle() + 0.62, 30, Color(1.0, 0.48, 0.12, fan_alpha), 4.0, true)
		var boss_dash_charge: float = float(enemy.get("boss_dash_charge", 0.0))
		if boss_dash_charge > 0.0:
			var boss_dash_direction: Vector2 = enemy.get("boss_dash_dir", Vector2.RIGHT)
			var dash_alpha := 0.5 + 0.38 * sin(boss_dash_charge * 34.0)
			draw_line(position, position + boss_dash_direction * 470.0, Color(1.0, 0.18, 0.12, dash_alpha), 13.0, true)
			draw_line(position, position + boss_dash_direction * 470.0, Color(1.0, 0.72, 0.22, dash_alpha), 4.0, true)
		var hazard_charge: float = float(enemy.get("hazard_charge", 0.0))
		if hazard_charge > 0.0:
			var hazard_target: Vector2 = enemy.get("hazard_target", player_pos)
			var hazard_direction: Vector2 = position.direction_to(hazard_target)
			var hazard_perpendicular := hazard_direction.rotated(PI * 0.5)
			var hazard_alpha := 0.5 + 0.38 * sin(hazard_charge * 30.0)
			for hazard_offset in [Vector2.ZERO, hazard_perpendicular * 112.0, hazard_perpendicular * -112.0]:
				draw_circle(hazard_target + hazard_offset, 76.0, Color(1.0, 0.12, 0.36, hazard_alpha * 0.12))
				draw_arc(hazard_target + hazard_offset, 76.0, 0.0, TAU, 42, Color(1.0, 0.3, 0.48, hazard_alpha), 5.0, true)
		if float(enemy.get("burn_time", 0.0)) > 0.0:
			draw_arc(position, radius + 12.0, -1.2, 2.2, 24, Color(1.0, 0.38, 0.08, 0.9), 5.0, true)
		if float(enemy.get("slow_time", 0.0)) > 0.0:
			draw_arc(position, radius + 15.0, 0.0, TAU, 36, Color(0.42, 0.82, 1.0, 0.9), 5.0, true)
		return

	var tint := Color.WHITE
	if flash:
		tint = Color(1.8, 1.8, 1.8)
	elif float(enemy.get("burn_time", 0.0)) > 0.0:
		tint = Color(1.35, 0.78, 0.55)
	elif float(enemy.get("slow_time", 0.0)) > 0.0:
		tint = Color(0.7, 0.9, 1.35)
	var enemy_texture: Texture2D = ENEMY_TEXTURES.get(enemy["kind"], ENEMY_TEXTURES["chaser"])
	draw_ellipse_shadow(position + Vector2(0.0, radius * 0.42), radius * 1.45, radius * 0.48, Color(0.01, 0.025, 0.025, 0.42))
	_draw_sprite_billboard(enemy_texture, position + Vector2(0.0, radius * 0.55), radius * 3.3, tint)
	match enemy["kind"]:
		"dasher":
			if float(enemy.get("dash_charge", 0.0)) > 0.0:
				var telegraph_alpha := 0.45 + 0.4 * sin(float(enemy["dash_charge"]) * 30.0)
				var dash_direction: Vector2 = enemy.get("dash_dir", Vector2.RIGHT)
				draw_line(position, position + dash_direction * (130.0 if low_detail else 165.0), Color(1.0, 0.42, 0.12, telegraph_alpha), 5.0 if low_detail else 7.0, true)
				if not low_detail:
					draw_arc(position, radius + 8.0, 0.0, TAU, 24, Color(1.0, 0.75, 0.2, telegraph_alpha), 4.0, true)
		"shooter":
			if float(enemy.get("shot_charge", 0.0)) > 0.0:
				var aim_alpha := 0.45 + 0.4 * sin(float(enemy["shot_charge"]) * 28.0)
				var shot_direction: Vector2 = enemy.get("shot_dir", Vector2.RIGHT)
				draw_line(position, position + shot_direction * (320.0 if low_detail else 520.0), Color(0.78, 0.35, 1.0, aim_alpha), 2.0 if low_detail else 3.0, true)
				if not low_detail:
					draw_arc(position, radius + 7.0, 0.0, TAU, 22, Color(0.9, 0.62, 1.0, aim_alpha), 3.0, true)
		"contaminant":
			draw_arc(position, radius + 4.0, game_time * 1.4, game_time * 1.4 + 4.8, 24, Color(0.72, 1.0, 0.35), 4.0, true)
	if enemy["elite"]:
		var affix_color := Color(1.0, 0.86, 0.22)
		match enemy.get("elite_affix", ""):
			"swift": affix_color = Color(1.0, 0.52, 0.12)
			"shielded": affix_color = Color(0.28, 0.82, 1.0)
			"explosive": affix_color = Color(1.0, 0.18, 0.28)
		draw_arc(position, radius + 5.0, 0.0, TAU, 24, affix_color, 3.0)
		if enemy.get("elite_affix", "") == "swift" and not low_detail:
			var trail_direction: Vector2 = position.direction_to(player_pos)
			draw_line(position - trail_direction * (radius + 8.0), position - trail_direction * (radius + 34.0), Color(affix_color, 0.7), 5.0, true)
		elif enemy.get("elite_affix", "") == "shielded" and float(enemy.get("elite_shield", 0.0)) > 0.0:
			draw_arc(position, radius + 10.0, -0.6, 4.6, 28, Color(affix_color, 0.88), 5.0, true)
		elif enemy.get("elite_affix", "") == "explosive" and not low_detail:
			draw_circle(position, 5.0 + 2.0 * sin(game_time * 9.0), affix_color)
		var hp_ratio: float = float(enemy["hp"]) / float(enemy["max_hp"])
		draw_rect(Rect2(position + Vector2(-radius, -radius - 11.0), Vector2(radius * 2.0, 4.0)), Color(0.18, 0.03, 0.08))
		draw_rect(Rect2(position + Vector2(-radius, -radius - 11.0), Vector2(radius * 2.0 * hp_ratio, 4.0)), Color(1.0, 0.75, 0.22))
	if float(enemy.get("guarded_time", 0.0)) > 0.0:
		draw_arc(position, radius + 7.0, 0.0, TAU, 28, Color(0.3, 0.82, 1.0, 0.82), 3.0, true)


func _draw_effect(effect: Dictionary) -> void:
	var progress := 1.0 - float(effect["life"]) / float(effect["total"])
	var alpha := 1.0 - progress
	match effect["kind"]:
		"burst":
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(1.0, 0.32, 0.48, alpha * 0.6))
		"hurt":
			draw_arc(effect["pos"], float(effect["radius"]) * (0.6 + progress), 0.0, TAU, 32, Color(1.0, 0.2, 0.28, alpha), 8.0)
		"warning":
			draw_arc(effect["pos"], float(effect["radius"]) * (0.7 + 0.3 * progress), 0.0, TAU, 64, Color(1.0, 0.12, 0.4, alpha), 9.0)
		"evolution":
			var evolution_color: Color = effect.get("color", Color(0.4, 0.92, 1.0))
			var evolution_radius := float(effect["radius"]) * (0.18 + progress * 0.82)
			draw_circle(effect["pos"], evolution_radius, Color(evolution_color, alpha * 0.08))
			draw_arc(effect["pos"], evolution_radius, 0.0, TAU, 72, Color(evolution_color.lightened(0.35), alpha), 12.0, true)
			draw_arc(effect["pos"], evolution_radius * 0.72, -progress * TAU, (1.0 - progress) * TAU, 56, Color(1.0, 0.82, 0.28, alpha), 6.0, true)
		"slash":
			var slash_color: Color = effect.get("color", Color(1.0, 0.55, 0.65))
			var slash_angle: float = float(effect.get("angle", 0.0))
			draw_arc(effect["pos"], float(effect["radius"]) * (0.55 + 0.45 * progress), slash_angle - 1.25, slash_angle + 1.25, 40, Color(slash_color, alpha), 12.0, true)
		"epathy_critical":
			var critical_color: Color = effect.get("color", Color(1.0, 0.42, 0.55))
			var critical_radius := float(effect["radius"]) * (0.4 + progress * 0.75)
			draw_arc(effect["pos"], critical_radius, -0.8, 2.3, 22, Color(1.0, 0.88, 0.42, alpha), 7.0, true)
			draw_arc(effect["pos"], critical_radius * 0.72, 2.4, 5.5, 20, Color(critical_color, alpha), 5.0, true)
		"pulse":
			var pulse_color: Color = effect.get("color", Color(0.35, 0.9, 1.0))
			draw_arc(effect["pos"], float(effect["radius"]) * (0.25 + 0.75 * progress), 0.0, TAU, 64, Color(pulse_color, alpha), 11.0, true)
		"ice":
			var ice_color: Color = effect.get("color", Color(0.55, 0.85, 1.0))
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(ice_color, alpha * 0.14))
			draw_arc(effect["pos"], float(effect["radius"]) * progress, 0.0, TAU, 64, Color(ice_color.lightened(0.25), alpha), 8.0, true)
		"map_supply":
			var supply_radius := float(effect["radius"]) * (0.28 + progress * 0.72)
			draw_arc(effect["pos"], supply_radius, -progress * TAU, (1.0 - progress) * TAU, 48, Color(1.0, 0.76, 0.24, alpha), 8.0, true)
			for shard_index in 6:
				var shard_direction := Vector2.from_angle(TAU * float(shard_index) / 6.0)
				draw_circle(effect["pos"] + shard_direction * supply_radius * 0.7, 6.0 * alpha, Color(1.0, 0.92, 0.48, alpha))
		"repair":
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(0.2, 1.0, 0.62, alpha * 0.18))
			draw_arc(effect["pos"], float(effect["radius"]) * (0.45 + progress * 0.55), 0.0, TAU, 40, Color(0.48, 1.0, 0.76, alpha), 6.0, true)
		"meteor":
			var meteor_radius_now := float(effect["radius"]) * progress
			draw_line(effect["pos"] + Vector2(90.0, -210.0) * (1.0 - progress), effect["pos"], Color(1.0, 0.55, 0.15, alpha), 12.0, true)
			draw_circle(effect["pos"], meteor_radius_now, Color(1.0, 0.3, 0.08, alpha * 0.18))
			draw_arc(effect["pos"], meteor_radius_now, 0.0, TAU, 48, Color(1.0, 0.62, 0.18, alpha), 8.0, true)
		"contamination":
			var hazard_alpha := minf(0.72, float(effect["life"]) * 0.28)
			draw_circle(effect["pos"], float(effect["radius"]), Color(0.28, 0.92, 0.38, hazard_alpha * 0.16))
			draw_arc(effect["pos"], float(effect["radius"]), game_time, game_time + TAU, 40, Color(0.4, 1.0, 0.48, hazard_alpha), 5.0, true)
			for node_index in 5:
				var node_angle := TAU * float(node_index) / 5.0 + game_time * 0.35
				draw_circle(effect["pos"] + Vector2.from_angle(node_angle) * float(effect["radius"]) * 0.62, 5.0, Color(0.66, 1.0, 0.32, hazard_alpha))
		"arsenal_orbit":
			var orbit_radius := float(effect["radius"])
			var orbit_amount := int(effect.get("amount", 3))
			for blade_index in orbit_amount:
				var blade_pos: Vector2 = effect["pos"] + Vector2.from_angle(game_time * 4.0 + TAU * float(blade_index) / float(orbit_amount)) * orbit_radius * 0.82
				draw_line(blade_pos - Vector2(8.0, 0.0), blade_pos + Vector2(8.0, 0.0), Color(0.72, 0.94, 1.0, alpha), 6.0, true)
			draw_arc(effect["pos"], orbit_radius, 0.0, TAU, 48, Color(0.32, 0.82, 1.0, alpha * 0.45), 3.0, true)
		"arsenal_aura":
			draw_circle(effect["pos"], float(effect["radius"]), Color(0.34, 0.88, 1.0, alpha * 0.08))
			draw_arc(effect["pos"], float(effect["radius"]), game_time, game_time + TAU, 52, Color(0.48, 1.0, 0.86, alpha), 5.0, true)
		"arsenal_pool":
			draw_circle(effect["pos"], float(effect["radius"]) * (0.65 + progress * 0.35), Color(0.18, 0.62, 1.0, alpha * 0.18))
			draw_arc(effect["pos"], float(effect["radius"]), 0.0, TAU, 44, Color(0.55, 0.88, 1.0, alpha), 5.0, true)
		"arsenal_chain":
			var chain_points: Array = effect.get("points", [])
			for point_index in range(chain_points.size() - 1):
				var chain_start: Vector2 = chain_points[point_index]
				var chain_end: Vector2 = chain_points[point_index + 1]
				draw_line(chain_start, chain_end, Color(0.42, 1.0, 0.72, alpha * 0.42), 10.0, true)
				draw_line(chain_start, chain_end, Color(0.82, 1.0, 0.94, alpha), 3.0, true)
				draw_circle(chain_end, 8.0 + progress * 5.0, Color(0.5, 1.0, 0.78, alpha))
		"shield_break":
			draw_arc(effect["pos"], float(effect["radius"]) * (0.75 + progress * 0.45), 0.0, TAU, 30, Color(0.35, 0.88, 1.0, alpha), 6.0, true)
		"elite_chest":
			var chest_radius := float(effect["radius"]) * progress
			draw_circle(effect["pos"], chest_radius, Color(1.0, 0.68, 0.12, alpha * 0.12))
			draw_arc(effect["pos"], chest_radius, -progress * TAU, (1.0 - progress) * TAU, 48, Color(1.0, 0.86, 0.3, alpha), 8.0, true)
		"elite_explosion":
			var explosion_radius := float(effect["radius"]) * (0.35 + progress * 0.65)
			draw_circle(effect["pos"], explosion_radius, Color(1.0, 0.12, 0.2, 0.08 + progress * 0.18))
			draw_arc(effect["pos"], explosion_radius, 0.0, TAU, 48, Color(1.0, 0.28, 0.18, 0.9), 7.0, true)
		"apostle_phase":
			var phase_radius := float(effect["radius"]) * (0.25 + progress * 0.75)
			draw_circle(effect["pos"], phase_radius, Color(1.0, 0.06, 0.14, alpha * 0.13))
			draw_arc(effect["pos"], phase_radius, -progress * TAU, (1.0 - progress) * TAU, 72, Color(1.0, 0.22, 0.16, alpha), 12.0, true)
		"apostle_hazard":
			var armed := float(effect.get("arm_time", 0.0)) <= 0.0
			var hazard_color := Color(1.0, 0.08, 0.22) if armed else Color(1.0, 0.72, 0.18)
			var apostle_hazard_alpha := 0.2 + 0.12 * sin(game_time * (9.0 if armed else 5.0))
			draw_circle(effect["pos"], float(effect["radius"]), Color(hazard_color, apostle_hazard_alpha))
			draw_arc(effect["pos"], float(effect["radius"]), game_time * 0.8, game_time * 0.8 + TAU, 48, Color(hazard_color, 0.92), 6.0, true)


func _draw_player() -> void:
	var flicker := player_invulnerable > 0.0 and int(player_invulnerable * 24.0) % 2 == 0
	var sprite_modulate := Color(1.0, 1.0, 1.0, 0.34 if flicker else 1.0)
	draw_ellipse_shadow(player_pos + Vector2(0.0, 13.0), 31.0, 10.0, Color(0.01, 0.02, 0.02, 0.52))
	if scythe_evolved:
		var aura_pulse := 1.0 + sin(game_time * 5.0) * 0.1
		draw_circle(player_pos + Vector2(0.0, -26.0), 47.0 * aura_pulse, Color(0.25, 1.0, 0.72, 0.09))
		draw_arc(player_pos + Vector2(0.0, -20.0), 42.0 * aura_pulse, game_time, game_time + 5.1, 40, Color(0.48, 1.0, 0.82, 0.72), 4.0, true)
	_draw_sprite_billboard(EPATHY_TEXTURE, player_pos + Vector2(0.0, 11.0), 94.0, sprite_modulate)
	draw_arc(player_pos, 28.0, -0.9, 3.9, 30, Color(0.4, 1.0, 0.78, 0.68), 4.0, true)
	if player_shield > 0.0:
		var shield_alpha := 0.22 + 0.38 * (player_shield / player_max_shield)
		draw_arc(player_pos, 34.0, 0.0, TAU, 36, Color(0.3, 0.78, 1.0, shield_alpha), 3.0, true)
	var health_ratio := clampf(player_health / maxf(1.0, player_max_health), 0.0, 1.0)
	draw_rect(Rect2(player_pos + Vector2(-30.0, 25.0), Vector2(60.0, 7.0)), Color(0.025, 0.04, 0.035, 0.88))
	draw_rect(Rect2(player_pos + Vector2(-29.0, 26.0), Vector2(58.0 * health_ratio, 5.0)), Color(0.25, 0.92, 0.55))
	if scythe_timer < 0.22:
		var preview_color := Color(_starter_ring_color(), 0.18)
		match selected_character:
			"epathy":
				var slash_angle := _nearest_enemy_direction().angle()
				draw_arc(player_pos, scythe_radius, slash_angle - 1.25, slash_angle + 1.25, 40, preview_color, 3.0)
				if scythe_level >= 2 or scythe_evolved:
					draw_arc(player_pos, scythe_radius, slash_angle + PI - 1.25, slash_angle + PI + 1.25, 40, preview_color, 3.0)
			"lucia": draw_circle(player_pos, 22.0, preview_color)
			"claire": draw_arc(player_pos, scythe_radius, 0.0, TAU, 48, preview_color, 3.0)
			"rafari": draw_circle(player_pos, 18.0, preview_color)
