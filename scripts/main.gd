extends Node2D

# 五分鐘垂直切片。全部圖像都由 CanvasItem 即時繪製，方便先驗證玩法，
# 後續可將繪圖函式替換成 GPT 生成的 2D 素材而不更動戰鬥規則。

const RUN_DURATION := 300.0
const APOSTLE_TIME := 240.0
const VIEW_SIZE := Vector2(1280.0, 720.0)
const MAX_ENEMIES := 650
const MAX_GEMS := 480
const MAX_REPAIR_CORES := 24
const MAX_EVOLUTION_CORES := 1
const MAX_WEAPON_SLOTS := 6
const MAX_PASSIVE_SLOTS := 6
const MAX_EFFECTS := 220
const MAX_PLAYER_PROJECTILES := 220
const MAX_HOSTILE_PROJECTILES := 180
const LOW_DETAIL_ENEMY_COUNT := 220
const DRAW_MARGIN := 180.0
const WAVE_TIMES := [60.0, 120.0, 180.0]
const VERSION := "Beta0.13.1"
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

var rng := RandomNumberGenerator.new()
var camera: Camera2D

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
var selected_character := "claire"
var run_started := false
var build_open := false
var total_damage_dealt := 0.0
var total_damage_taken := 0.0
var damage_by_source := {
	"starter": 0.0,
	"needle": 0.0,
	"storm": 0.0,
	"drone": 0.0,
	"gravity": 0.0,
	"meteor": 0.0,
	"skill": 0.0,
	"burn": 0.0,
	"other": 0.0,
}

var game_time := 0.0
var spawn_timer := 0.0
var kills := 0
var game_over := false
var choosing_upgrade := false
var manual_paused := false
var pending_levels := 0
var instruction_time := 10.0
var wave_index := 0
var hud_refresh_timer := 0.0
var gm_triple_speed := false

var level := 1
var experience := 0.0
var experience_required := 12.0
var meta_levels := {
	"health": 0,
	"speed": 0,
	"pickup": 0,
	"armor": 0,
	"damage": 0,
	"cooldown": 0,
	"area": 0,
	"recovery": 0,
	"precision": 0,
}

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

var storm_level := 0
var storm_damage := 36.0
var storm_radius := 56.0
var storm_interval := 2.2
var storm_timer := 0.7

var drone_level := 0
var drone_damage := 13.0
var drone_interval := 0.82
var drone_timer := 0.45

var gravity_level := 0
var gravity_damage := 28.0
var gravity_radius := 82.0
var gravity_interval := 3.3
var gravity_timer := 1.1

var meteor_level := 0
var meteor_damage := 42.0
var meteor_radius := 70.0
var meteor_interval := 2.75
var meteor_timer := 1.35

var enemies: Array = []
var projectiles: Array = []
var hostile_projectiles: Array = []
var gems: Array = []
var repair_cores: Array = []
var evolution_cores: Array = []
var evolution_cores_owned := 0
var effects: Array = []
var apostle_spawned := false
var apostle_present := false
var apostle_hp := 0.0
var apostle_max_hp := 0.0
var apostle_phase := 1

var canvas_layer: CanvasLayer
var ui_theme: Theme
var time_label: Label
var stats_label: Label
var enemy_label: Label
var weapon_label: Label
var instruction_label: Label
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
var gm_panel: PanelContainer
var gm_speed_button: Button
var gm_level_button: Button
var gm_reroll_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_ensure_input_map()
	_create_camera()
	_build_interface()
	_show_character_select()


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
	_update_passive_recovery(delta)
	_update_spawning(delta)
	_update_weapons(delta)
	_update_projectiles(delta)
	_update_enemy_statuses(delta)
	_update_enemies(delta)
	_update_hostile_projectiles(delta)
	_update_gems(delta)
	_update_repair_cores(delta)
	_update_evolution_cores(delta)
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


func _build_interface() -> void:
	ui_theme = Theme.new()
	ui_theme.default_font = load("res://assets/fonts/NotoSansTC-VF.ttf")
	ui_theme.default_font_size = 18

	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "Interface"
	add_child(canvas_layer)

	var hud := Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.theme = ui_theme
	canvas_layer.add_child(hud)

	xp_bar = ProgressBar.new()
	xp_bar.anchor_left = 0.0
	xp_bar.anchor_right = 1.0
	xp_bar.offset_left = 18.0
	xp_bar.offset_top = 14.0
	xp_bar.offset_right = -18.0
	xp_bar.offset_bottom = 32.0
	xp_bar.show_percentage = false
	hud.add_child(xp_bar)

	time_label = Label.new()
	time_label.anchor_left = 0.5
	time_label.anchor_right = 0.5
	time_label.offset_left = -120.0
	time_label.offset_top = 40.0
	time_label.offset_right = 120.0
	time_label.offset_bottom = 78.0
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 28)
	hud.add_child(time_label)

	stats_label = Label.new()
	stats_label.position = Vector2(20.0, 48.0)
	stats_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(stats_label)

	enemy_label = Label.new()
	enemy_label.anchor_left = 1.0
	enemy_label.anchor_right = 1.0
	enemy_label.offset_left = -265.0
	enemy_label.offset_top = 48.0
	enemy_label.offset_right = -20.0
	enemy_label.offset_bottom = 128.0
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemy_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(enemy_label)

	weapon_label = Label.new()
	weapon_label.anchor_top = 1.0
	weapon_label.anchor_bottom = 1.0
	weapon_label.offset_left = 20.0
	weapon_label.offset_top = -122.0
	weapon_label.offset_right = 520.0
	weapon_label.offset_bottom = -18.0
	weapon_label.add_theme_font_size_override("font_size", 17)
	hud.add_child(weapon_label)

	skill_label = Label.new()
	skill_label.anchor_left = 1.0
	skill_label.anchor_right = 1.0
	skill_label.anchor_top = 1.0
	skill_label.anchor_bottom = 1.0
	skill_label.offset_left = -480.0
	skill_label.offset_top = -92.0
	skill_label.offset_right = -20.0
	skill_label.offset_bottom = -18.0
	skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skill_label.add_theme_font_size_override("font_size", 17)
	hud.add_child(skill_label)

	instruction_label = Label.new()
	instruction_label.anchor_left = 0.5
	instruction_label.anchor_right = 0.5
	instruction_label.anchor_top = 1.0
	instruction_label.anchor_bottom = 1.0
	instruction_label.offset_left = -360.0
	instruction_label.offset_top = -62.0
	instruction_label.offset_right = 360.0
	instruction_label.offset_bottom = -20.0
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 20)
	instruction_label.text = "WASD／方向鍵移動　武器自動攻擊　B／Tab 建構　Esc／P 暫停"
	hud.add_child(instruction_label)

	boss_bar = ProgressBar.new()
	boss_bar.anchor_left = 0.25
	boss_bar.anchor_right = 0.75
	boss_bar.offset_top = 86.0
	boss_bar.offset_bottom = 108.0
	boss_bar.show_percentage = false
	boss_bar.visible = false
	hud.add_child(boss_bar)

	boss_label = Label.new()
	boss_label.anchor_left = 0.25
	boss_label.anchor_right = 0.75
	boss_label.offset_top = 108.0
	boss_label.offset_bottom = 138.0
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.text = "測試使徒"
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.visible = false
	hud.add_child(boss_label)

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
	gm_panel.theme = ui_theme
	gm_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	gm_panel.visible = false
	canvas_layer.add_child(gm_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	gm_panel.add_child(column)

	var title := Label.new()
	title.text = "GM 測試"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)

	gm_speed_button = Button.new()
	gm_speed_button.text = "3 倍速：關"
	gm_speed_button.custom_minimum_size = Vector2(160.0, 36.0)
	gm_speed_button.process_mode = Node.PROCESS_MODE_ALWAYS
	gm_speed_button.pressed.connect(_toggle_gm_speed)
	column.add_child(gm_speed_button)

	gm_level_button = Button.new()
	gm_level_button.text = "立即升級"
	gm_level_button.custom_minimum_size = Vector2(160.0, 36.0)
	gm_level_button.process_mode = Node.PROCESS_MODE_ALWAYS
	gm_level_button.pressed.connect(_gm_level_up)
	column.add_child(gm_level_button)

	gm_reroll_button = Button.new()
	gm_reroll_button.text = "重骰次數 +1"
	gm_reroll_button.custom_minimum_size = Vector2(160.0, 36.0)
	gm_reroll_button.process_mode = Node.PROCESS_MODE_ALWAYS
	gm_reroll_button.pressed.connect(_gm_add_reroll)
	column.add_child(gm_reroll_button)


func _build_pause_overlay() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.color = Color(0.008, 0.015, 0.045, 0.9)
	pause_overlay.theme = ui_theme
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	canvas_layer.add_child(pause_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480.0, 430.0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)

	var title := Label.new()
	title.text = "已暫停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	column.add_child(title)

	var resume_button := Button.new()
	resume_button.text = "繼續戰鬥"
	resume_button.custom_minimum_size = Vector2(280.0, 56.0)
	resume_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_button.add_theme_font_size_override("font_size", 21)
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_resume_game)
	column.add_child(resume_button)

	var restart_button := Button.new()
	restart_button.text = "重新開始本角色"
	restart_button.custom_minimum_size = Vector2(280.0, 54.0)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.add_theme_font_size_override("font_size", 19)
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_start_game)
	column.add_child(restart_button)

	var select_button := Button.new()
	select_button.text = "返回角色選擇"
	select_button.custom_minimum_size = Vector2(280.0, 54.0)
	select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_button.add_theme_font_size_override("font_size", 19)
	select_button.process_mode = Node.PROCESS_MODE_ALWAYS
	select_button.pressed.connect(_show_character_select)
	column.add_child(select_button)

	var hint := Label.new()
	hint.text = "按 Esc／P 也可繼續"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	column.add_child(hint)


func _build_upgrade_overlay() -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.color = Color(0.01, 0.02, 0.06, 0.91)
	upgrade_overlay.theme = ui_theme
	upgrade_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_overlay.visible = false
	canvas_layer.add_child(upgrade_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1010.0, 350.0)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	column.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_child(column)

	upgrade_title = Label.new()
	upgrade_title.text = "星源共鳴：選擇一項升級"
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_title.add_theme_font_size_override("font_size", 30)
	column.add_child(upgrade_title)

	upgrade_buttons = HBoxContainer.new()
	upgrade_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_buttons.add_theme_constant_override("separation", 18)
	upgrade_buttons.process_mode = Node.PROCESS_MODE_ALWAYS
	column.add_child(upgrade_buttons)

	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(260.0, 46.0)
	reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reroll_button.add_theme_font_size_override("font_size", 17)
	reroll_button.process_mode = Node.PROCESS_MODE_ALWAYS
	reroll_button.pressed.connect(_reroll_upgrades)
	column.add_child(reroll_button)

	var hint := Label.new()
	hint.text = "點擊卡片或按 1／2／3 選擇；R 可重抽"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	column.add_child(hint)


func _build_end_overlay() -> void:
	end_overlay = ColorRect.new()
	end_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_overlay.color = Color(0.01, 0.015, 0.04, 0.94)
	end_overlay.theme = ui_theme
	end_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	end_overlay.visible = false
	canvas_layer.add_child(end_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	end_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560.0, 410.0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)

	end_title = Label.new()
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 42)
	column.add_child(end_title)

	end_summary = Label.new()
	end_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_summary.add_theme_font_size_override("font_size", 20)
	column.add_child(end_summary)

	var restart_button := Button.new()
	restart_button.text = "重新開始"
	restart_button.custom_minimum_size = Vector2(260.0, 58.0)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_start_game)
	column.add_child(restart_button)

	var select_button := Button.new()
	select_button.text = "返回角色選擇"
	select_button.custom_minimum_size = Vector2(260.0, 50.0)
	select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	select_button.add_theme_font_size_override("font_size", 19)
	select_button.process_mode = Node.PROCESS_MODE_ALWAYS
	select_button.pressed.connect(_show_character_select)
	column.add_child(select_button)

	var disclaimer := Label.new()
	disclaimer.text = "%s｜非官方同人原型｜所有圖形皆為程式暫代素材" % VERSION
	disclaimer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disclaimer.add_theme_font_size_override("font_size", 14)
	column.add_child(disclaimer)


func _build_loadout_overlay() -> void:
	build_overlay = ColorRect.new()
	build_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_overlay.color = Color(0.01, 0.02, 0.06, 0.92)
	build_overlay.theme = ui_theme
	build_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	build_overlay.visible = false
	canvas_layer.add_child(build_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	build_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780.0, 640.0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var title := Label.new()
	title.text = "當前建構"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	column.add_child(title)

	build_text = Label.new()
	build_text.custom_minimum_size = Vector2(690.0, 470.0)
	build_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	build_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	build_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_text.add_theme_font_size_override("font_size", 18)
	column.add_child(build_text)

	var hint := Label.new()
	hint.text = "按 B／Tab 或 Esc／P 返回戰鬥"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	column.add_child(hint)


func _build_character_overlay() -> void:
	character_overlay = ColorRect.new()
	character_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	character_overlay.color = Color(0.008, 0.015, 0.045, 0.98)
	character_overlay.theme = ui_theme
	character_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas_layer.add_child(character_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	character_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1180.0, 640.0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var title := Label.new()
	title.text = "星隕倖存者"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "選擇本次出擊角色｜五分鐘原型"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	column.add_child(subtitle)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 12)
	cards.process_mode = Node.PROCESS_MODE_ALWAYS
	column.add_child(cards)

	for character_id in CHARACTERS:
		var data: Dictionary = CHARACTERS[character_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(268.0, 250.0)
		button.text = "%s\n%s\n\n%s\n\n自動能力｜%s" % [data["name"], data["role"], data["passive"], data["starter_weapon"]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 16)
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.pressed.connect(_choose_character.bind(character_id))
		cards.add_child(button)
		character_buttons[character_id] = button

	character_detail = Label.new()
	character_detail.custom_minimum_size = Vector2(0.0, 82.0)
	character_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	character_detail.add_theme_font_size_override("font_size", 18)
	column.add_child(character_detail)

	var start_button := Button.new()
	start_button.text = "開始出擊"
	start_button.custom_minimum_size = Vector2(320.0, 62.0)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(_start_game)
	column.add_child(start_button)

	var disclaimer := Label.new()
	disclaimer.text = "%s｜免費、非商業、非官方同人原型" % VERSION
	disclaimer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disclaimer.add_theme_font_size_override("font_size", 14)
	column.add_child(disclaimer)

	_choose_character(selected_character)


func _choose_character(character_id: String) -> void:
	if not CHARACTERS.has(character_id):
		return
	selected_character = character_id
	var data: Dictionary = CHARACTERS[selected_character]
	character_detail.text = "%s｜%s\n自動能力｜%s：%s\n%s" % [
		data["name"], data["role"], data["starter_weapon"], data["starter_trait"],
		data["skill"],
	]
	for button_id in character_buttons:
		var button: Button = character_buttons[button_id]
		button.modulate = Color.WHITE if button_id == selected_character else Color(0.62, 0.66, 0.75)


func _show_character_select() -> void:
	_set_gm_speed(false)
	get_tree().paused = true
	run_started = false
	game_over = false
	choosing_upgrade = false
	manual_paused = false
	build_open = false
	upgrade_overlay.visible = false
	end_overlay.visible = false
	pause_overlay.visible = false
	build_overlay.visible = false
	character_overlay.visible = true
	gm_panel.visible = false
	_choose_character(selected_character)
	queue_redraw()


func _start_game() -> void:
	_set_gm_speed(false)
	get_tree().paused = false
	run_started = true
	game_over = false
	choosing_upgrade = false
	manual_paused = false
	build_open = false
	pending_levels = 0
	rerolls_remaining = 1
	current_upgrade_choices.clear()
	game_time = 0.0
	spawn_timer = 0.15
	kills = 0
	total_damage_dealt = 0.0
	total_damage_taken = 0.0
	damage_by_source = {"starter": 0.0, "needle": 0.0, "storm": 0.0, "drone": 0.0, "gravity": 0.0, "meteor": 0.0, "skill": 0.0, "burn": 0.0, "other": 0.0}
	instruction_time = 10.0
	wave_index = 0
	hud_refresh_timer = 0.0

	player_pos = Vector2.ZERO
	player_speed = 255.0
	player_max_health = 110.0
	player_health = player_max_health
	player_max_shield = 24.0
	player_shield = 8.0
	player_armor = 0.0
	player_invulnerable = 0.0
	pickup_radius = 115.0
	damage_multiplier = 1.0
	close_damage_multiplier = 1.0
	burn_duration_multiplier = 1.0
	slow_effect_multiplier = 1.0
	projectile_area_scale = 1.0
	projectile_damage_multiplier = 1.0
	recovery_per_second = 0.0
	match selected_character:
		"epathy":
			player_armor = 3.0
			close_damage_multiplier = 1.2
		"lucia":
			burn_duration_multiplier = 1.3
		"rafari":
			slow_effect_multiplier = 1.35

	level = 1
	experience = 0.0
	experience_required = 12.0
	meta_levels = {"health": 0, "speed": 0, "pickup": 0, "armor": 0, "damage": 0, "cooldown": 0, "area": 0, "recovery": 0, "precision": 0}

	scythe_level = 1
	scythe_damage = 24.0
	scythe_radius = 132.0
	match selected_character:
		"epathy": scythe_interval = 1.4
		"lucia": scythe_interval = 1.9
		"rafari": scythe_interval = 2.8
		_: scythe_interval = 1.55
	scythe_timer = 0.25
	scythe_evolved = false
	needle_level = 0
	needle_damage = 17.0
	needle_interval = 0.72
	needle_timer = 0.2
	needle_evolved = false
	storm_level = 0
	storm_damage = 36.0
	storm_radius = 56.0
	storm_interval = 2.2
	storm_timer = 0.7
	drone_level = 0
	drone_damage = 13.0
	drone_interval = 0.82
	drone_timer = 0.45
	gravity_level = 0
	gravity_damage = 28.0
	gravity_radius = 82.0
	gravity_interval = 3.3
	gravity_timer = 1.1
	meteor_level = 0
	meteor_damage = 42.0
	meteor_radius = 70.0
	meteor_interval = 2.75
	meteor_timer = 1.35

	enemies.clear()
	projectiles.clear()
	hostile_projectiles.clear()
	gems.clear()
	repair_cores.clear()
	evolution_cores.clear()
	evolution_cores_owned = 0
	effects.clear()
	apostle_spawned = false
	apostle_present = false
	apostle_hp = 0.0
	apostle_max_hp = 0.0
	apostle_phase = 1

	camera.position = player_pos
	character_overlay.visible = false
	build_overlay.visible = false
	upgrade_overlay.visible = false
	end_overlay.visible = false
	pause_overlay.visible = false
	gm_panel.visible = true
	boss_bar.visible = false
	boss_label.visible = false
	instruction_label.visible = true
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
	if not run_started or game_over or manual_paused or build_open:
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
	if choosing_upgrade or game_over or not run_started:
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
	if not run_started or choosing_upgrade or game_over or manual_paused:
		return
	build_open = true
	_update_build_text()
	build_overlay.visible = true
	get_tree().paused = true


func _update_build_text() -> void:
	var character_data: Dictionary = CHARACTERS[selected_character]
	var starter_name := _starter_weapon_name()
	var starter_display := "%s　已進化" % _starter_evolution_name() if scythe_evolved else "%s　Lv.%d / 5" % [starter_name, scythe_level]
	build_text.text = "%s｜%s\n%s\n\n武器 %d / %d\n• %s\n• 星針　　　%s　　• 脈衝雷暴　%s\n• 守望無人機　%s　　• 重力奇點　%s\n• 隕炎彈　　%s\n\n能力 %d / %d\n• 強化生命　Lv.%d / 5　　• 高速模組　Lv.%d / 5\n• 回收磁場　Lv.%d / 5　　• 強化裝甲　Lv.%d / 5\n• 星源增幅　Lv.%d / 5　　• 冷卻模組　Lv.%d / 5\n• 廣域線圈　Lv.%d / 5　　• 修復奈米機　Lv.%d / 5\n• 精密核心　Lv.%d / 5\n\n%s\n%s\n進化核心　%d（精英異變體掉落）\n重抽剩餘　%d" % [
		character_data["name"],
		character_data["role"],
		character_data["passive"],
		_weapon_slot_count(),
		MAX_WEAPON_SLOTS,
		starter_display,
		("未取得" if needle_level == 0 else ("追星蜂群　已進化" if needle_evolved else "Lv.%d / 5" % needle_level)),
		("未取得" if storm_level == 0 else "Lv.%d / 5" % storm_level),
		("未取得" if drone_level == 0 else "Lv.%d / 5" % drone_level),
		("未取得" if gravity_level == 0 else "Lv.%d / 5" % gravity_level),
		("未取得" if meteor_level == 0 else "Lv.%d / 5" % meteor_level),
		_passive_slot_count(),
		MAX_PASSIVE_SLOTS,
		int(meta_levels["health"]),
		int(meta_levels["speed"]),
		int(meta_levels["pickup"]),
		int(meta_levels["armor"]),
		int(meta_levels["damage"]),
		int(meta_levels["cooldown"]),
		int(meta_levels["area"]),
		int(meta_levels["recovery"]),
		int(meta_levels["precision"]),
		_starter_evolution_requirement_text(),
		_needle_evolution_requirement_text(),
		evolution_cores_owned,
		rerolls_remaining,
	]


func _starter_weapon_name() -> String:
	return String(CHARACTERS[selected_character]["starter_weapon"])


func _starter_weapon_trait_text() -> String:
	return String(CHARACTERS[selected_character]["starter_trait"])


func _starter_ring_color() -> Color:
	return CHARACTERS[selected_character]["ring_color"]


func _weapon_slot_count() -> int:
	var count := 1
	for weapon_level in [needle_level, storm_level, drone_level, gravity_level, meteor_level]:
		if weapon_level > 0:
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
	var weapon_state := "完成" if scythe_level >= 5 else "%d / 5" % scythe_level
	var passive_state := "完成" if int(meta_levels[passive_id]) >= 3 else "%d / 3" % int(meta_levels[passive_id])
	var core_state := "已有" if evolution_cores_owned > 0 else "尚未取得"
	return "專屬進化：%s｜%s Lv.5（%s）＋%s Lv.3（%s）＋進化核心（%s）" % [
		data["name"], _starter_weapon_name(), weapon_state, data["passive_name"], passive_state, core_state,
	]


func _can_evolve_starter() -> bool:
	if scythe_evolved or scythe_level < 5 or evolution_cores_owned <= 0:
		return false
	var passive_id: String = _starter_evolution_data()["passive_id"]
	return int(meta_levels[passive_id]) >= 3


func _can_evolve_needle() -> bool:
	return not needle_evolved and needle_level >= 5 and int(meta_levels["cooldown"]) >= 3 and evolution_cores_owned > 0


func _needle_evolution_requirement_text() -> String:
	if needle_evolved:
		return "共通進化：追星蜂群（完成）"
	var weapon_state := "完成" if needle_level >= 5 else "%d / 5" % needle_level
	var passive_state := "完成" if int(meta_levels["cooldown"]) >= 3 else "%d / 3" % int(meta_levels["cooldown"])
	var core_state := "已有" if evolution_cores_owned > 0 else "尚未取得"
	return "共通進化：追星蜂群｜星針 Lv.5（%s）＋冷卻模組 Lv.3（%s）＋進化核心（%s）" % [weapon_state, passive_state, core_state]


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
	if not choosing_upgrade:
		return
	for index in mini(3, current_upgrade_choices.size()):
		if Input.is_action_just_pressed("upgrade_%d" % (index + 1)):
			_select_upgrade(current_upgrade_choices[index]["id"])
			return
	if Input.is_action_just_pressed("reroll"):
		_reroll_upgrades()


func _update_player(delta: float) -> void:
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player_pos += movement * player_speed * delta
	camera.position = player_pos
	player_invulnerable = maxf(0.0, player_invulnerable - delta)


func _update_passive_recovery(delta: float) -> void:
	if recovery_per_second <= 0.0 or player_health >= player_max_health:
		return
	player_health = minf(player_max_health, player_health + recovery_per_second * delta)


func _use_epathy_skill() -> void:
	var radius := scythe_radius
	var slash_direction := _nearest_enemy_direction()
	var slash_angle := slash_direction.angle()
	var half_arc := 1.25
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		var hit_radius: float = radius + float(enemy["radius"])
		if player_pos.distance_squared_to(enemy["pos"]) > hit_radius * hit_radius:
			continue
		var enemy_direction: Vector2 = player_pos.direction_to(enemy["pos"])
		var angle_difference := absf(wrapf(enemy_direction.angle() - slash_angle, -PI, PI))
		if angle_difference > half_arc and (not scythe_evolved or absf(angle_difference - PI) > half_arc):
			continue
		var push_direction: Vector2 = player_pos.direction_to(enemy["pos"])
		enemy["pos"] += push_direction * (12.0 if enemy["boss"] else 34.0 + scythe_level * 5.0)
		enemies[index] = enemy
		_damage_enemy(index, scythe_damage * damage_multiplier * close_damage_multiplier, "starter")
	effects.append({"kind": "slash", "pos": player_pos, "life": 0.38, "total": 0.38, "radius": radius, "angle": slash_angle, "color": _starter_ring_color()})
	if scythe_evolved:
		effects.append({"kind": "slash", "pos": player_pos, "life": 0.42, "total": 0.42, "radius": radius, "angle": slash_angle + PI, "color": _starter_ring_color()})


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
		enemy["slow_time"] = maxf(float(enemy.get("slow_time", 0.0)), base_slow_time * slow_effect_multiplier)
		enemy["slow_factor"] = 0.38 if enemy["boss"] and scythe_evolved else (0.52 if enemy["boss"] else (0.0 if scythe_evolved else 0.28))
		enemies[index] = enemy
		_damage_enemy(index, scythe_damage * (0.88 if scythe_evolved else 0.72) * damage_multiplier, "starter")
	for target_pos in target_positions:
		effects.append({"kind": "ice", "pos": target_pos, "life": 0.92 if scythe_evolved else 0.72, "total": 0.92 if scythe_evolved else 0.72, "radius": radius, "color": _starter_ring_color()})


func _update_spawning(delta: float) -> void:
	game_time += delta
	while wave_index < WAVE_TIMES.size() and game_time >= float(WAVE_TIMES[wave_index]):
		_trigger_wave(wave_index)
		wave_index += 1
	spawn_timer -= delta
	var interval := maxf(0.16, 0.72 - game_time * 0.0016)
	if spawn_timer <= 0.0 and enemies.size() < MAX_ENEMIES:
		var batch := 1 + int(game_time / 95.0)
		for index in batch:
			_spawn_mutant()
		spawn_timer += interval

	if game_time >= APOSTLE_TIME and not apostle_spawned:
		_spawn_apostle()


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


func _spawn_mutant(force_kind: String = "", force_elite: bool = false, force_affix: String = "") -> void:
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(650.0, 830.0)
	var kind := force_kind
	if kind.is_empty():
		var roll := rng.randf()
		if game_time > 165.0 and roll < 0.08:
			kind = "guardian"
		elif game_time > 135.0 and roll < 0.16:
			kind = "splitter"
		elif game_time > 105.0 and roll < 0.24:
			kind = "contaminant"
		elif game_time > 150.0 and roll < 0.34:
			kind = "tank"
		elif game_time > 90.0 and roll < 0.48:
			kind = "shooter"
		elif game_time > 35.0 and roll < 0.66:
			kind = "dasher"
		else:
			kind = "chaser"
	var difficulty := 1.0 + game_time / 360.0
	var elite := force_elite or (game_time > 50.0 and rng.randf() < 0.025)
	var elite_affix := ""
	if elite:
		elite_affix = force_affix if force_affix in ["swift", "shielded", "explosive"] else ["swift", "shielded", "explosive"][rng.randi_range(0, 2)]
	var base_hp := 31.0
	var base_speed := 76.0
	var radius := 15.0
	match kind:
		"dasher":
			base_hp = 24.0
			base_speed = 66.0
			radius = 13.0
		"shooter":
			base_hp = 30.0
			base_speed = 58.0
			radius = 14.0
		"tank":
			base_hp = 98.0
			base_speed = 42.0
			radius = 24.0
		"guardian":
			base_hp = 74.0
			base_speed = 48.0
			radius = 21.0
		"splitter":
			base_hp = 46.0
			base_speed = 64.0
			radius = 17.0
		"contaminant":
			base_hp = 40.0
			base_speed = 54.0
			radius = 18.0
	var hp := base_hp * difficulty
	var speed := base_speed * (1.0 + game_time / 900.0)
	if elite:
		hp *= 4.2
		speed *= 1.12
		radius *= 1.45
		if elite_affix == "swift":
			speed *= 1.35
	var elite_shield := hp * 0.34 if elite_affix == "shielded" else 0.0
	enemies.append({
		"pos": player_pos + Vector2.from_angle(angle) * distance,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"radius": radius,
		"kind": kind,
		"elite": elite,
		"elite_affix": elite_affix,
		"elite_shield": elite_shield,
		"elite_max_shield": elite_shield,
		"boss": false,
		"dash_cooldown": rng.randf_range(1.4, 3.2),
		"dash_time": 0.0,
		"dash_charge": 0.0,
		"dash_dir": Vector2.ZERO,
		"contact_cooldown": 0.0,
		"attack_cooldown": rng.randf_range(0.5, 2.2),
		"shot_charge": 0.0,
		"shot_dir": Vector2.ZERO,
		"flash": 0.0,
		"burn_time": 0.0,
		"burn_tick": 0.0,
		"burn_damage": 0.0,
		"slow_time": 0.0,
		"slow_factor": 1.0,
		"guarded_time": 0.0,
		"support_cooldown": rng.randf_range(0.2, 0.8),
		"contamination_cooldown": rng.randf_range(0.8, 2.2),
	})


func _spawn_apostle() -> void:
	apostle_spawned = true
	apostle_present = true
	apostle_max_hp = 4800.0
	apostle_hp = apostle_max_hp
	apostle_phase = 1
	enemies.append({
		"pos": player_pos + Vector2(0.0, -650.0),
		"hp": apostle_max_hp,
		"max_hp": apostle_max_hp,
		"speed": 48.0,
		"radius": 64.0,
		"kind": "apostle",
		"elite": true,
		"elite_affix": "",
		"elite_shield": 0.0,
		"elite_max_shield": 0.0,
		"boss": true,
		"dash_cooldown": 2.4,
		"dash_time": 0.0,
		"dash_charge": 0.0,
		"dash_dir": Vector2.ZERO,
		"contact_cooldown": 0.0,
		"attack_cooldown": 1.8,
		"phase": 1,
		"phase_transition": 0.0,
		"attack_cycle": 0,
		"burst_charge": 0.0,
		"burst_angle": 0.0,
		"fan_charge": 0.0,
		"fan_dir": Vector2.ZERO,
		"boss_dash_charge": 0.0,
		"boss_dash_time": 0.0,
		"boss_dash_dir": Vector2.ZERO,
		"hazard_charge": 0.0,
		"hazard_target": Vector2.ZERO,
		"shot_charge": 0.0,
		"shot_dir": Vector2.ZERO,
		"summon_cooldown": 6.0,
		"flash": 0.0,
		"burn_time": 0.0,
		"burn_tick": 0.0,
		"burn_damage": 0.0,
		"slow_time": 0.0,
		"slow_factor": 1.0,
		"guarded_time": 0.0,
	})
	boss_bar.visible = true
	boss_label.visible = true
	effects.append({"kind": "warning", "pos": player_pos, "life": 1.8, "total": 1.8, "radius": 420.0})
	instruction_label.text = "警告：使徒降臨"
	instruction_label.visible = true
	instruction_time = 4.0


func _update_weapons(delta: float) -> void:
	scythe_timer -= delta
	if scythe_timer <= 0.0:
		_fire_scythe_ring()
		scythe_timer += scythe_interval

	if needle_level > 0:
		needle_timer -= delta
		if needle_timer <= 0.0:
			_fire_star_needles()
			needle_timer += needle_interval

	if storm_level > 0:
		storm_timer -= delta
		if storm_timer <= 0.0:
			_fire_pulse_storm()
			storm_timer += storm_interval

	if drone_level > 0:
		drone_timer -= delta
		if drone_timer <= 0.0:
			_fire_watch_drone()
			drone_timer += drone_interval

	if gravity_level > 0:
		gravity_timer -= delta
		if gravity_timer <= 0.0:
			_fire_gravity_singularity()
			gravity_timer += gravity_interval

	if meteor_level > 0:
		meteor_timer -= delta
		if meteor_timer <= 0.0:
			_fire_meteor_round()
			meteor_timer += meteor_interval


func _fire_scythe_ring() -> void:
	match selected_character:
		"epathy": _use_epathy_skill()
		"lucia": _use_lucia_skill()
		"claire": _use_claire_skill()
		"rafari": _use_rafari_skill()


func _fire_star_needles() -> void:
	if enemies.is_empty():
		return
	var shot_count := 1 + int((needle_level - 1) / 2.0) + (2 if needle_evolved else 0)
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
		})


func _fire_pulse_storm() -> void:
	if enemies.is_empty():
		return
	var strike_count := 1 + int((storm_level - 1) / 2.0)
	var targets := _nearest_enemy_indices(strike_count)
	var strike_positions: Array = []
	for enemy_index in targets:
		if enemy_index >= 0 and enemy_index < enemies.size():
			strike_positions.append(enemies[enemy_index]["pos"])
	for position in strike_positions:
		effects.append({"kind": "storm", "pos": position, "life": 0.42, "total": 0.42, "radius": storm_radius})
	for enemy_index in range(enemies.size() - 1, -1, -1):
		var hit_count := 0
		for position in strike_positions:
			var hit_radius: float = storm_radius + float(enemies[enemy_index]["radius"])
			if enemies[enemy_index]["pos"].distance_squared_to(position) <= hit_radius * hit_radius:
				hit_count += 1
		if hit_count > 0:
			_damage_enemy(enemy_index, storm_damage * damage_multiplier * hit_count, "storm")


func _fire_watch_drone() -> void:
	if enemies.is_empty():
		return
	var shot_count := 1 + (1 if drone_level >= 3 else 0) + (1 if drone_level >= 5 else 0)
	var targets := _nearest_enemy_indices(shot_count)
	for enemy_index in targets:
		if projectiles.size() >= MAX_PLAYER_PROJECTILES:
			break
		if enemy_index < 0 or enemy_index >= enemies.size():
			continue
		var direction := player_pos.direction_to(enemies[enemy_index]["pos"])
		projectiles.append({
			"kind": "drone_bolt",
			"pos": player_pos + direction.rotated(-0.45) * 26.0,
			"velocity": direction * (720.0 + drone_level * 22.0),
			"damage": drone_damage * damage_multiplier * projectile_damage_multiplier,
			"source": "drone",
			"radius": 5.0 * projectile_area_scale,
			"life": 1.25,
		})


func _fire_gravity_singularity() -> void:
	if enemies.is_empty():
		return
	var nearest := _nearest_enemy_indices(1)
	if nearest.is_empty():
		return
	var target_index: int = nearest[0]
	if target_index < 0 or target_index >= enemies.size():
		return
	var target_pos: Vector2 = enemies[target_index]["pos"]
	var radius := gravity_radius
	for enemy_index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[enemy_index]
		var hit_radius: float = radius + float(enemy["radius"])
		if target_pos.distance_squared_to(enemy["pos"]) > hit_radius * hit_radius:
			continue
		var pull_distance := 8.0 if enemy["boss"] else 22.0 + gravity_level * 3.0
		enemy["pos"] += enemy["pos"].direction_to(target_pos) * pull_distance
		enemies[enemy_index] = enemy
		_damage_enemy(enemy_index, gravity_damage * damage_multiplier, "gravity")
	effects.append({"kind": "gravity", "pos": target_pos, "life": 0.85, "total": 0.85, "radius": radius})


func _fire_meteor_round() -> void:
	if enemies.is_empty():
		return
	var strike_count := 1 + (1 if meteor_level >= 3 else 0) + (1 if meteor_level >= 5 else 0)
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
		var projectile = projectiles[projectile_index]
		projectile["pos"] += projectile["velocity"] * delta
		projectile["life"] -= delta
		var consumed := false
		for enemy_index in range(enemies.size() - 1, -1, -1):
			var enemy = enemies[enemy_index]
			var collision_radius: float = float(projectile["radius"]) + float(enemy["radius"])
			var offset: Vector2 = projectile["pos"] - enemy["pos"]
			if absf(offset.x) > collision_radius or absf(offset.y) > collision_radius:
				continue
			if offset.length_squared() <= collision_radius * collision_radius:
				if projectile.get("kind", "") == "fireball":
					enemy["burn_time"] = maxf(float(enemy.get("burn_time", 0.0)), float(projectile.get("burn_time", 0.0)))
					enemy["burn_tick"] = 0.0
					enemy["burn_damage"] = maxf(float(enemy.get("burn_damage", 0.0)), float(projectile.get("burn_damage", 0.0)))
					enemies[enemy_index] = enemy
				_damage_enemy(enemy_index, float(projectile["damage"]), String(projectile.get("source", "other")))
				consumed = true
				break
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
				total_damage_dealt += actual_burn_damage
				damage_by_source["burn"] = float(damage_by_source["burn"]) + actual_burn_damage
				enemy["hp"] = float(enemy["hp"]) - burn_damage
				enemy["flash"] = 0.08
				if enemy["boss"]:
					apostle_hp = maxf(0.0, float(enemy["hp"]))
		if float(enemy["hp"]) <= 0.0:
			enemies[index] = enemy
			_kill_enemy(index)
			continue
		enemies[index] = enemy


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
			enemy = _update_apostle(enemy, delta, status_speed)
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


func _damage_enemy(index: int, amount: float, source: String = "other") -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy = enemies[index]
	if float(enemy.get("guarded_time", 0.0)) > 0.0 and enemy.get("kind", "") != "guardian" and not bool(enemy.get("boss", false)):
		amount *= 0.65
	if not damage_by_source.has(source):
		source = "other"
	var elite_shield: float = float(enemy.get("elite_shield", 0.0))
	if elite_shield > 0.0:
		var shield_absorbed := minf(amount, elite_shield)
		enemy["elite_shield"] = elite_shield - shield_absorbed
		total_damage_dealt += shield_absorbed
		damage_by_source[source] = float(damage_by_source[source]) + shield_absorbed
		amount -= shield_absorbed
		enemy["flash"] = 0.08
		if float(enemy["elite_shield"]) <= 0.0:
			effects.append({"kind": "shield_break", "pos": enemy["pos"], "life": 0.35, "total": 0.35, "radius": float(enemy["radius"]) + 18.0})
		if amount <= 0.0:
			enemies[index] = enemy
			return
	var actual_damage := minf(amount, float(enemy["hp"]))
	total_damage_dealt += actual_damage
	damage_by_source[source] = float(damage_by_source[source]) + actual_damage
	enemy["hp"] = float(enemy["hp"]) - amount
	enemy["flash"] = 0.08
	if enemy["boss"]:
		apostle_hp = maxf(0.0, float(enemy["hp"]))
	if float(enemy["hp"]) <= 0.0:
		_kill_enemy(index)
	else:
		enemies[index] = enemy


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


func _spawn_splitlings(position: Vector2, count: int) -> void:
	for split_index in count:
		if enemies.size() >= MAX_ENEMIES:
			return
		_spawn_mutant("chaser")
		var child_index := enemies.size() - 1
		var child = enemies[child_index]
		child["pos"] = position + Vector2.from_angle(TAU * float(split_index) / maxf(1.0, float(count))) * 18.0
		child["hp"] = minf(float(child["hp"]), 16.0)
		child["max_hp"] = float(child["hp"])
		child["radius"] = 10.0
		child["speed"] = maxf(float(child["speed"]), 92.0)
		child["elite"] = false
		enemies[child_index] = child


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


func _update_gems(delta: float) -> void:
	for index in range(gems.size() - 1, -1, -1):
		var gem = gems[index]
		var pickup_distance := pickup_radius * 2.0
		var distance_squared: float = gem["pos"].distance_squared_to(player_pos)
		if distance_squared <= pickup_distance * pickup_distance:
			var distance := sqrt(distance_squared)
			var pull_speed: float = 240.0 + maxf(0.0, pickup_radius * 2.0 - distance) * 3.0
			gem["pos"] += gem["pos"].direction_to(player_pos) * pull_speed * delta
		if gem["pos"].distance_squared_to(player_pos) <= 625.0:
			_gain_experience(float(gem["value"]))
			gems.remove_at(index)
		else:
			gems[index] = gem


func _update_repair_cores(delta: float) -> void:
	for index in range(repair_cores.size() - 1, -1, -1):
		var core = repair_cores[index]
		var pickup_distance := pickup_radius * 1.5
		var distance_squared: float = core["pos"].distance_squared_to(player_pos)
		if distance_squared <= pickup_distance * pickup_distance:
			var distance := sqrt(distance_squared)
			var pull_speed := 210.0 + maxf(0.0, pickup_radius * 1.5 - distance) * 3.2
			core["pos"] += core["pos"].direction_to(player_pos) * pull_speed * delta
		if core["pos"].distance_squared_to(player_pos) <= 729.0:
			var missing_health := maxf(0.0, player_max_health - player_health)
			var restored := minf(float(core["heal"]), missing_health)
			player_health += restored
			if restored <= 0.0:
				player_shield = minf(player_max_shield, player_shield + 8.0)
			instruction_label.text = "修復核心：%s" % ("護盾 +8" if restored <= 0.0 else "生命 +%d" % int(restored))
			instruction_label.visible = true
			instruction_time = 2.0
			effects.append({"kind": "repair", "pos": player_pos, "life": 0.55, "total": 0.55, "radius": 72.0})
			repair_cores.remove_at(index)
		else:
			repair_cores[index] = core


func _update_evolution_cores(delta: float) -> void:
	for index in range(evolution_cores.size() - 1, -1, -1):
		var core = evolution_cores[index]
		var pickup_distance := pickup_radius * 1.65
		var distance_squared: float = core["pos"].distance_squared_to(player_pos)
		if distance_squared <= pickup_distance * pickup_distance:
			var distance := sqrt(distance_squared)
			var pull_speed: float = 225.0 + maxf(0.0, pickup_distance - distance) * 3.4
			core["pos"] += core["pos"].direction_to(player_pos) * pull_speed * delta
		if core["pos"].distance_squared_to(player_pos) <= 729.0:
			evolution_cores_owned = 1
			evolution_cores.remove_at(index)
			if not _try_consume_evolution_core():
				_show_game_notice("取得進化核心｜達成條件後自動進化")
		else:
			evolution_cores[index] = core


func _gain_experience(amount: float) -> void:
	experience += amount
	while experience >= experience_required:
		experience -= experience_required
		level += 1
		experience_required = floorf(12.0 * pow(float(level), 1.28))
		pending_levels += 1
	if pending_levels > 0 and not choosing_upgrade:
		_show_upgrade_choices()


func _show_upgrade_choices() -> void:
	choosing_upgrade = true
	get_tree().paused = true
	upgrade_overlay.visible = true
	upgrade_title.text = "星源共鳴｜等級 %d" % level

	for child in upgrade_buttons.get_children():
		upgrade_buttons.remove_child(child)
		child.queue_free()

	var candidates := _pick_upgrade_choices(_available_upgrades())
	var option_count := mini(3, candidates.size())
	current_upgrade_choices.clear()
	for index in option_count:
		var option = candidates[index]
		current_upgrade_choices.append(option)
		var button := Button.new()
		button.custom_minimum_size = Vector2(285.0, 205.0)
		var category := "進化" if String(option["id"]).ends_with("_evolution") else ("武器" if _is_weapon_upgrade(option["id"]) else "能力")
		button.text = "[%d]【%s】%s\n\n%s" % [index + 1, category, option["name"], option["description"]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 19)
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.pressed.connect(_select_upgrade.bind(option["id"]))
		upgrade_buttons.add_child(button)
	reroll_button.text = "[R] 重新抽取（剩餘 %d 次）" % rerolls_remaining
	reroll_button.disabled = rerolls_remaining <= 0


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
	return upgrade_id in ["scythe", "needle", "storm", "drone", "gravity", "meteor"]


func _reroll_upgrades() -> void:
	if not choosing_upgrade or rerolls_remaining <= 0:
		return
	rerolls_remaining -= 1
	_show_upgrade_choices()


func _available_upgrades() -> Array:
	var result: Array = []
	if scythe_level < 5:
		result.append({
			"id": "scythe",
			"name": "%s Lv.%d" % [_starter_weapon_name(), scythe_level + 1],
			"description": _scythe_upgrade_description(scythe_level + 1),
		})
	if needle_level < 5 and _can_offer_common_weapon(needle_level):
		result.append({
			"id": "needle",
			"name": "星針 Lv.%d" % (needle_level + 1),
			"description": _needle_upgrade_description(needle_level + 1),
		})
	if storm_level < 5 and _can_offer_common_weapon(storm_level):
		result.append({
			"id": "storm",
			"name": "脈衝雷暴 Lv.%d" % (storm_level + 1),
			"description": _storm_upgrade_description(storm_level + 1),
		})
	if drone_level < 5 and _can_offer_common_weapon(drone_level):
		result.append({"id": "drone", "name": "守望無人機 Lv.%d" % (drone_level + 1), "description": _drone_upgrade_description(drone_level + 1)})
	if gravity_level < 5 and _can_offer_common_weapon(gravity_level):
		result.append({"id": "gravity", "name": "重力奇點 Lv.%d" % (gravity_level + 1), "description": _gravity_upgrade_description(gravity_level + 1)})
	if meteor_level < 5 and _can_offer_common_weapon(meteor_level):
		result.append({"id": "meteor", "name": "隕炎彈 Lv.%d" % (meteor_level + 1), "description": _meteor_upgrade_description(meteor_level + 1)})
	if int(meta_levels["health"]) < 5 and _can_offer_passive("health"):
		result.append({"id": "health", "name": "強化生命 Lv.%d" % (int(meta_levels["health"]) + 1), "description": "最大生命 +15，並回復 15 生命"})
	if int(meta_levels["speed"]) < 5 and _can_offer_passive("speed"):
		result.append({"id": "speed", "name": "高速模組 Lv.%d" % (int(meta_levels["speed"]) + 1), "description": "移動速度提高 8%"})
	if int(meta_levels["pickup"]) < 5 and _can_offer_passive("pickup"):
		result.append({"id": "pickup", "name": "回收磁場 Lv.%d" % (int(meta_levels["pickup"]) + 1), "description": "星源碎片拾取範圍 +25"})
	if int(meta_levels["armor"]) < 5 and _can_offer_passive("armor"):
		result.append({"id": "armor", "name": "強化裝甲 Lv.%d" % (int(meta_levels["armor"]) + 1), "description": "護甲 +1，降低每次受到的傷害"})
	if int(meta_levels["damage"]) < 5 and _can_offer_passive("damage"):
		result.append({"id": "damage", "name": "星源增幅 Lv.%d" % (int(meta_levels["damage"]) + 1), "description": "所有武器傷害提高 12%"})
	if int(meta_levels["cooldown"]) < 5 and _can_offer_passive("cooldown"):
		result.append({"id": "cooldown", "name": "冷卻模組 Lv.%d" % (int(meta_levels["cooldown"]) + 1), "description": "所有自動武器冷卻縮短 6%"})
	if int(meta_levels["area"]) < 5 and _can_offer_passive("area"):
		result.append({"id": "area", "name": "廣域線圈 Lv.%d" % (int(meta_levels["area"]) + 1), "description": "能力與範圍武器擴大，投射物尺寸 +8%"})
	if int(meta_levels["recovery"]) < 5 and _can_offer_passive("recovery"):
		result.append({"id": "recovery", "name": "修復奈米機 Lv.%d" % (int(meta_levels["recovery"]) + 1), "description": "每秒回復 0.4 生命"})
	if int(meta_levels["precision"]) < 5 and _can_offer_passive("precision"):
		result.append({"id": "precision", "name": "精密核心 Lv.%d" % (int(meta_levels["precision"]) + 1), "description": "火球、星針與無人機光彈傷害提高 12%"})
	return result


func _scythe_upgrade_description(next_level: int) -> String:
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
	return "強化星針"


func _storm_upgrade_description(next_level: int) -> String:
	match next_level:
		1: return "取得武器：定期轟擊最近的異變體"
		2: return "雷暴傷害 +16"
		3: return "額外轟擊 1 個目標"
		4: return "攻擊間隔縮短 25%"
		5: return "再增加 1 個目標，作用半徑 +24"
	return "強化脈衝雷暴"


func _drone_upgrade_description(next_level: int) -> String:
	match next_level:
		1: return "取得武器：無人機高速射擊最近異變體"
		2: return "射擊傷害 +7"
		3: return "每輪額外發射 1 枚光彈"
		4: return "射擊間隔縮短 20%"
		5: return "再增加 1 枚光彈，傷害 +7"
	return "強化守望無人機"


func _gravity_upgrade_description(next_level: int) -> String:
	match next_level:
		1: return "取得武器：在敵人腳下生成牽引奇點"
		2: return "奇點傷害 +12"
		3: return "牽引與傷害範圍 +22"
		4: return "生成間隔縮短 22%"
		5: return "牽引力提高，傷害 +16"
	return "強化重力奇點"


func _meteor_upgrade_description(next_level: int) -> String:
	match next_level:
		1: return "取得武器：轟擊敵人並留下燃燒"
		2: return "爆炸傷害 +16"
		3: return "每輪額外轟擊 1 個目標"
		4: return "發射間隔縮短 22%"
		5: return "再增加 1 個目標，爆炸範圍 +20"
	return "強化隕炎彈"


func _select_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"scythe":
			scythe_level += 1
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
				2: needle_damage += 8.0
				4: needle_interval *= 0.8
				5: needle_damage += 8.0
		"storm":
			storm_level += 1
			match storm_level:
				2: storm_damage += 16.0
				4: storm_interval *= 0.75
				5: storm_radius += 24.0
		"drone":
			drone_level += 1
			match drone_level:
				2: drone_damage += 7.0
				4: drone_interval *= 0.8
				5: drone_damage += 7.0
		"gravity":
			gravity_level += 1
			match gravity_level:
				2: gravity_damage += 12.0
				3: gravity_radius += 22.0
				4: gravity_interval *= 0.78
				5: gravity_damage += 16.0
		"meteor":
			meteor_level += 1
			match meteor_level:
				2: meteor_damage += 16.0
				4: meteor_interval *= 0.78
				5: meteor_radius += 20.0
		"health":
			meta_levels["health"] = int(meta_levels["health"]) + 1
			player_max_health += 15.0
			player_health = minf(player_max_health, player_health + 15.0)
		"speed":
			meta_levels["speed"] = int(meta_levels["speed"]) + 1
			player_speed *= 1.08
		"pickup":
			meta_levels["pickup"] = int(meta_levels["pickup"]) + 1
			pickup_radius += 25.0
		"armor":
			meta_levels["armor"] = int(meta_levels["armor"]) + 1
			player_armor += 1.0
		"damage":
			meta_levels["damage"] = int(meta_levels["damage"]) + 1
			damage_multiplier *= 1.12
		"cooldown":
			meta_levels["cooldown"] = int(meta_levels["cooldown"]) + 1
			scythe_interval *= 0.94
			needle_interval *= 0.94
			storm_interval *= 0.94
			drone_interval *= 0.94
			gravity_interval *= 0.94
			meteor_interval *= 0.94
		"area":
			meta_levels["area"] = int(meta_levels["area"]) + 1
			scythe_radius += 12.0
			storm_radius += 7.0
			gravity_radius += 8.0
			meteor_radius += 8.0
			projectile_area_scale *= 1.08
		"recovery":
			meta_levels["recovery"] = int(meta_levels["recovery"]) + 1
			recovery_per_second += 0.4
			player_health = minf(player_max_health, player_health + 5.0)
		"precision":
			meta_levels["precision"] = int(meta_levels["precision"]) + 1
			projectile_damage_multiplier *= 1.12

	_try_consume_evolution_core()

	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels > 0:
		_show_upgrade_choices()
	else:
		choosing_upgrade = false
		upgrade_overlay.visible = false
		get_tree().paused = false


func _update_effects(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		var effect = effects[index]
		effect["life"] = float(effect["life"]) - delta
		if effect.get("kind", "") == "contamination":
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


func _enforce_runtime_limits() -> void:
	if effects.size() > MAX_EFFECTS:
		effects = effects.slice(effects.size() - MAX_EFFECTS)
	if projectiles.size() > MAX_PLAYER_PROJECTILES:
		projectiles = projectiles.slice(projectiles.size() - MAX_PLAYER_PROJECTILES)
	if hostile_projectiles.size() > MAX_HOSTILE_PROJECTILES:
		hostile_projectiles = hostile_projectiles.slice(hostile_projectiles.size() - MAX_HOSTILE_PROJECTILES)
	if evolution_cores.size() > MAX_EVOLUTION_CORES:
		evolution_cores = evolution_cores.slice(evolution_cores.size() - MAX_EVOLUTION_CORES)
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
	time_label.text = "%02d:%02d" % [minutes, seconds]
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
	weapon_label.text = "%s\n星針 %s｜雷暴 %s\n無人機 %s｜奇點 %s｜隕炎 %s" % [
		("%s｜進化" % _starter_evolution_name() if scythe_evolved else "%s Lv.%d%s" % [_starter_weapon_name(), scythe_level, ("｜待核心" if scythe_level >= 5 else "")]),
		("未取得" if needle_level == 0 else ("追星蜂群｜進化" if needle_evolved else "Lv.%d" % needle_level)),
		("未取得" if storm_level == 0 else "Lv.%d" % storm_level),
		("未取得" if drone_level == 0 else "Lv.%d" % drone_level),
		("未取得" if gravity_level == 0 else "Lv.%d" % gravity_level),
		("未取得" if meteor_level == 0 else "Lv.%d" % meteor_level),
	]
	var skill_name: String = _starter_evolution_name() if scythe_evolved else CHARACTERS[selected_character]["skill_name"]
	skill_label.text = "自動能力｜%s\n每 %.1f 秒發動" % [skill_name, scythe_interval]
	skill_label.modulate = _starter_ring_color()
	xp_bar.max_value = experience_required
	xp_bar.value = experience

	if apostle_present:
		boss_bar.max_value = apostle_max_hp
		boss_bar.value = apostle_hp
		boss_label.text = "使徒｜第 %d 階段" % apostle_phase
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
	_set_gm_speed(false)
	gm_panel.visible = false
	get_tree().paused = true
	end_overlay.visible = true
	end_title.text = "使徒討伐完成" if victory else "任務失敗"
	end_title.modulate = Color(0.45, 0.95, 1.0) if victory else Color(1.0, 0.4, 0.48)
	end_summary.text = "生存時間　%s\n擊殺數　%d　最終等級　%d\n造成傷害　%d　承受傷害　%d\n\n傷害分布\n%s　%d｜星針　%d｜脈衝雷暴　%d\n守望無人機　%d｜重力奇點　%d｜隕炎彈　%d｜燃燒　%d\n\n%s" % [
		_format_countdown(game_time),
		kills,
		level,
		int(total_damage_dealt),
		int(total_damage_taken),
		(_starter_evolution_name() if scythe_evolved else _starter_weapon_name()),
		int(damage_by_source["starter"]),
		int(damage_by_source["needle"]),
		int(damage_by_source["storm"]),
		int(damage_by_source["drone"]),
		int(damage_by_source["gravity"]),
		int(damage_by_source["meteor"]),
		int(damage_by_source["burn"]),
		("方舟防線暫時安全。" if victory else "重新調整強化後再次出擊。"),
	]


func _draw() -> void:
	_draw_background()

	for gem in gems:
		var position: Vector2 = gem["pos"]
		if not _is_world_visible(position, 24.0):
			continue
		var size := 7.0 if float(gem["value"]) <= 1.0 else 11.0
		var points := PackedVector2Array([
			position + Vector2(0.0, -size),
			position + Vector2(size * 0.72, 0.0),
			position + Vector2(0.0, size),
			position + Vector2(-size * 0.72, 0.0),
		])
		draw_colored_polygon(points, Color(0.26, 0.95, 1.0))

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

	for projectile in projectiles:
		if not _is_world_visible(projectile["pos"], 48.0):
			continue
		var direction: Vector2 = projectile["velocity"].normalized()
		if projectile.get("kind", "") == "fireball":
			var fireball_color: Color = projectile.get("color", Color(1.0, 0.42, 0.16))
			draw_line(projectile["pos"] - direction * 18.0, projectile["pos"], Color(fireball_color, 0.48), 8.0, true)
			draw_circle(projectile["pos"], float(projectile["radius"]), fireball_color)
			draw_circle(projectile["pos"], float(projectile["radius"]) * 0.46, fireball_color.lightened(0.55))
		elif projectile.get("kind", "") == "drone_bolt":
			draw_line(projectile["pos"] - direction * 15.0, projectile["pos"] + direction * 5.0, Color(1.0, 0.83, 0.26), 5.0, true)
			draw_circle(projectile["pos"], float(projectile["radius"]) * 0.72, Color(1.0, 0.97, 0.72))
		else:
			var projectile_color := Color(0.95, 0.62, 1.0) if projectile.get("evolved", false) else Color(0.5, 0.95, 1.0)
			draw_line(projectile["pos"] - direction * (14.0 if projectile.get("evolved", false) else 10.0), projectile["pos"] + direction * 7.0, projectile_color, 7.0 if projectile.get("evolved", false) else 5.0, true)

	for projectile in hostile_projectiles:
		if not _is_world_visible(projectile["pos"], 48.0):
			continue
		var hostile_color := Color(1.0, 0.48, 0.12) if projectile.get("kind", "") == "fan" else Color(1.0, 0.2, 0.48)
		draw_circle(projectile["pos"], float(projectile["radius"]), hostile_color)
		if enemies.size() < LOW_DETAIL_ENEMY_COUNT:
			draw_arc(projectile["pos"], float(projectile["radius"]) + 4.0, 0.0, TAU, 18, hostile_color.lightened(0.42), 2.0, true)

	for enemy in enemies:
		if not _is_world_visible(enemy["pos"], DRAW_MARGIN + float(enemy["radius"])):
			continue
		_draw_enemy(enemy)

	for effect in effects:
		if not _is_world_visible(effect["pos"], float(effect.get("radius", 0.0)) + 48.0):
			continue
		_draw_effect(effect)

	_draw_player()


func _is_world_visible(position: Vector2, margin: float = DRAW_MARGIN) -> bool:
	var offset := position - player_pos
	return absf(offset.x) <= VIEW_SIZE.x * 0.5 + margin and absf(offset.y) <= VIEW_SIZE.y * 0.5 + margin


func _draw_background() -> void:
	var grid_size := 96.0
	var left := floorf((player_pos.x - 760.0) / grid_size) * grid_size
	var right := player_pos.x + 760.0
	var top := floorf((player_pos.y - 460.0) / grid_size) * grid_size
	var bottom := player_pos.y + 460.0
	var grid_color := Color(0.085, 0.14, 0.22, 0.42)
	var x := left
	while x <= right:
		draw_line(Vector2(x, top), Vector2(x, bottom), grid_color, 1.0)
		x += grid_size
	var y := top
	while y <= bottom:
		draw_line(Vector2(left, y), Vector2(right, y), grid_color, 1.0)
		y += grid_size

	# 方舟設施地板的簡化標記。
	var sector := 384.0
	var sector_x := floorf(player_pos.x / sector) * sector
	var sector_y := floorf(player_pos.y / sector) * sector
	for offset_x in range(-2, 3):
		for offset_y in range(-2, 3):
			var marker := Vector2(sector_x + offset_x * sector, sector_y + offset_y * sector)
			draw_arc(marker, 42.0, 0.0, TAU, 32, Color(0.12, 0.32, 0.43, 0.28), 3.0)
			draw_line(marker - Vector2(28.0, 0.0), marker + Vector2(28.0, 0.0), Color(0.12, 0.32, 0.43, 0.22), 2.0)


func _draw_enemy(enemy: Dictionary) -> void:
	var position: Vector2 = enemy["pos"]
	var radius: float = enemy["radius"]
	var flash: bool = float(enemy["flash"]) > 0.0
	var low_detail := enemies.size() >= LOW_DETAIL_ENEMY_COUNT
	if enemy["boss"]:
		var boss_color := (Color(1.0, 0.16, 0.22) if int(enemy.get("phase", 1)) >= 2 else Color(1.0, 0.24, 0.52)) if not flash else Color.WHITE
		draw_circle(position, radius, Color(boss_color, 0.28))
		draw_arc(position, radius, 0.0, TAU, 48, boss_color, 7.0, true)
		draw_arc(position, radius * 0.64, game_time, game_time + TAU * 0.74, 38, Color(0.9, 0.55, 1.0), 5.0, true)
		for spoke in 6:
			var angle := TAU * float(spoke) / 6.0 + game_time * 0.25
			draw_line(position + Vector2.from_angle(angle) * (radius * 0.7), position + Vector2.from_angle(angle) * (radius * 1.22), boss_color, 4.0)
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

	var base_color := Color(0.82, 0.2, 0.38)
	match enemy["kind"]:
		"dasher": base_color = Color(1.0, 0.52, 0.2)
		"shooter": base_color = Color(0.72, 0.34, 1.0)
		"tank": base_color = Color(0.9, 0.26, 0.22)
		"guardian": base_color = Color(0.22, 0.72, 1.0)
		"splitter": base_color = Color(1.0, 0.32, 0.68)
		"contaminant": base_color = Color(0.35, 0.9, 0.38)
	if low_detail and float(enemy.get("burn_time", 0.0)) > 0.0:
		base_color = base_color.lerp(Color(1.0, 0.48, 0.08), 0.48)
	elif low_detail and float(enemy.get("slow_time", 0.0)) > 0.0:
		base_color = base_color.lerp(Color(0.35, 0.72, 1.0), 0.52)
	if flash:
		base_color = Color.WHITE
	match enemy["kind"]:
		"dasher":
			if float(enemy.get("dash_charge", 0.0)) > 0.0:
				var telegraph_alpha := 0.45 + 0.4 * sin(float(enemy["dash_charge"]) * 30.0)
				var dash_direction: Vector2 = enemy.get("dash_dir", Vector2.RIGHT)
				draw_line(position, position + dash_direction * (130.0 if low_detail else 165.0), Color(1.0, 0.42, 0.12, telegraph_alpha), 5.0 if low_detail else 7.0, true)
				if not low_detail:
					draw_arc(position, radius + 8.0, 0.0, TAU, 24, Color(1.0, 0.75, 0.2, telegraph_alpha), 4.0, true)
			var dasher_points := PackedVector2Array([
				position + Vector2(0.0, -radius),
				position + Vector2(radius, 0.0),
				position + Vector2(0.0, radius),
				position + Vector2(-radius, 0.0),
			])
			draw_colored_polygon(dasher_points, base_color)
		"shooter":
			if float(enemy.get("shot_charge", 0.0)) > 0.0:
				var aim_alpha := 0.45 + 0.4 * sin(float(enemy["shot_charge"]) * 28.0)
				var shot_direction: Vector2 = enemy.get("shot_dir", Vector2.RIGHT)
				draw_line(position, position + shot_direction * (320.0 if low_detail else 520.0), Color(0.78, 0.35, 1.0, aim_alpha), 2.0 if low_detail else 3.0, true)
				if not low_detail:
					draw_arc(position, radius + 7.0, 0.0, TAU, 22, Color(0.9, 0.62, 1.0, aim_alpha), 3.0, true)
			var shooter_points := PackedVector2Array([
				position + Vector2(0.0, -radius),
				position + Vector2(radius, radius * 0.82),
				position + Vector2(-radius, radius * 0.82),
			])
			draw_colored_polygon(shooter_points, base_color)
			if not low_detail:
				draw_circle(position, 4.0, Color(0.08, 0.02, 0.12))
		"tank":
			draw_rect(Rect2(position - Vector2(radius * 0.82, radius * 0.72), Vector2(radius * 1.64, radius * 1.44)), base_color)
			if not low_detail:
				draw_arc(position, radius, 0.0, TAU, 24, Color(1.0, 0.58, 0.4), 4.0, true)
		"guardian":
			draw_circle(position, radius, Color(base_color, 0.34))
			draw_arc(position, radius, 0.0, TAU, 28, base_color, 6.0, true)
			draw_arc(position, radius * 0.62, -0.8, 3.9, 22, Color(0.75, 0.95, 1.0), 4.0, true)
		"splitter":
			draw_circle(position + Vector2(-radius * 0.34, 0.0), radius * 0.72, base_color)
			draw_circle(position + Vector2(radius * 0.34, 0.0), radius * 0.72, base_color.darkened(0.18))
			if not low_detail:
				draw_line(position + Vector2(0.0, -radius), position + Vector2(0.0, radius), Color(1.0, 0.72, 0.9), 3.0, true)
		"contaminant":
			draw_circle(position, radius, base_color)
			draw_arc(position, radius + 4.0, game_time * 1.4, game_time * 1.4 + 4.8, 24, Color(0.72, 1.0, 0.35), 4.0, true)
			if not low_detail:
				draw_circle(position, radius * 0.35, Color(0.04, 0.18, 0.06))
		_:
			draw_circle(position, radius, base_color)
			if not low_detail:
				draw_circle(position + Vector2(-5.0, -3.0), 2.5, Color(0.03, 0.02, 0.06))
				draw_circle(position + Vector2(5.0, -3.0), 2.5, Color(0.03, 0.02, 0.06))
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
	if float(enemy.get("burn_time", 0.0)) > 0.0 and not low_detail:
		draw_arc(position, radius + 8.0, -1.2, 2.2, 18, Color(1.0, 0.38, 0.08, 0.9), 4.0, true)
	if float(enemy.get("slow_time", 0.0)) > 0.0 and not low_detail:
		draw_arc(position, radius + 10.0, 0.0, TAU, 24, Color(0.42, 0.82, 1.0, 0.9), 4.0, true)


func _draw_effect(effect: Dictionary) -> void:
	var progress := 1.0 - float(effect["life"]) / float(effect["total"])
	var alpha := 1.0 - progress
	match effect["kind"]:
		"ring":
			var radius := lerpf(32.0, float(effect["radius"]), progress)
			var ring_color: Color = effect.get("color", Color(0.25, 0.9, 1.0))
			draw_arc(effect["pos"], radius, 0.0, TAU, 64, Color(ring_color, alpha), 8.0, true)
			draw_arc(effect["pos"], radius * 0.82, -0.4, 3.8, 48, Color(ring_color.lightened(0.45), alpha * 0.85), 4.0, true)
			if scythe_evolved:
				draw_arc(effect["pos"], radius * 0.66, 0.8, 5.7, 52, Color(0.95, 0.78, 1.0, alpha), 6.0, true)
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
		"fire":
			var fire_color: Color = effect.get("color", Color(1.0, 0.5, 0.14))
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(fire_color, alpha * 0.16))
			draw_arc(effect["pos"], float(effect["radius"]) * progress, 0.0, TAU, 64, Color(fire_color.lightened(0.22), alpha), 7.0, true)
		"pulse":
			var pulse_color: Color = effect.get("color", Color(0.35, 0.9, 1.0))
			draw_arc(effect["pos"], float(effect["radius"]) * (0.25 + 0.75 * progress), 0.0, TAU, 64, Color(pulse_color, alpha), 11.0, true)
		"ice":
			var ice_color: Color = effect.get("color", Color(0.55, 0.85, 1.0))
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(ice_color, alpha * 0.14))
			draw_arc(effect["pos"], float(effect["radius"]) * progress, 0.0, TAU, 64, Color(ice_color.lightened(0.25), alpha), 8.0, true)
		"repair":
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(0.2, 1.0, 0.62, alpha * 0.18))
			draw_arc(effect["pos"], float(effect["radius"]) * (0.45 + progress * 0.55), 0.0, TAU, 40, Color(0.48, 1.0, 0.76, alpha), 6.0, true)
		"storm":
			var strike_top: Vector2 = effect["pos"] + Vector2(0.0, -220.0)
			draw_line(strike_top, effect["pos"], Color(0.72, 0.92, 1.0, alpha), 9.0, true)
			draw_arc(effect["pos"], float(effect["radius"]) * (0.55 + progress * 0.45), 0.0, TAU, 36, Color(0.35, 0.78, 1.0, alpha), 7.0, true)
		"gravity":
			var gravity_radius_now := float(effect["radius"]) * (0.35 + progress * 0.65)
			draw_circle(effect["pos"], gravity_radius_now, Color(0.45, 0.18, 0.78, alpha * 0.12))
			draw_arc(effect["pos"], gravity_radius_now, progress * 2.0, TAU + progress * 2.0, 52, Color(0.72, 0.38, 1.0, alpha), 8.0, true)
			draw_circle(effect["pos"], maxf(4.0, 16.0 * (1.0 - progress)), Color(0.06, 0.01, 0.12, alpha))
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
		"shield_break":
			draw_arc(effect["pos"], float(effect["radius"]) * (0.75 + progress * 0.45), 0.0, TAU, 30, Color(0.35, 0.88, 1.0, alpha), 6.0, true)
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
	var character_color: Color = CHARACTERS[selected_character]["color"]
	var body_color := Color(character_color, 0.35 if flicker else 1.0)
	draw_circle(player_pos, 18.0, body_color)
	draw_arc(player_pos, 23.0, -0.9, 3.9, 30, Color(0.74, 0.96, 1.0, 0.85), 5.0, true)
	draw_line(player_pos + Vector2(-10.0, 12.0), player_pos + Vector2(13.0, -14.0), Color(0.85, 0.98, 1.0), 4.0, true)
	if player_shield > 0.0:
		var shield_alpha := 0.22 + 0.38 * (player_shield / player_max_shield)
		draw_arc(player_pos, 30.0, 0.0, TAU, 36, Color(0.3, 0.78, 1.0, shield_alpha), 3.0, true)
	if drone_level > 0:
		var drone_pos := player_pos + Vector2.from_angle(game_time * 2.2) * 42.0
		draw_line(player_pos, drone_pos, Color(1.0, 0.78, 0.2, 0.2), 2.0, true)
		draw_circle(drone_pos, 8.0, Color(1.0, 0.76, 0.22))
		draw_circle(drone_pos, 3.0, Color(1.0, 1.0, 0.78))
	if scythe_timer < 0.22:
		var preview_color := Color(_starter_ring_color(), 0.18)
		match selected_character:
			"epathy":
				var slash_angle := _nearest_enemy_direction().angle()
				draw_arc(player_pos, scythe_radius, slash_angle - 1.25, slash_angle + 1.25, 40, preview_color, 3.0)
			"lucia": draw_circle(player_pos, 22.0, preview_color)
			"claire": draw_arc(player_pos, scythe_radius, 0.0, TAU, 48, preview_color, 3.0)
			"rafari": draw_circle(player_pos, 18.0, preview_color)
