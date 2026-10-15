extends Node2D

# 五分鐘垂直切片。全部圖像都由 CanvasItem 即時繪製，方便先驗證玩法，
# 後續可將繪圖函式替換成 GPT 生成的 2D 素材而不更動戰鬥規則。

const RUN_DURATION := 300.0
const APOSTLE_TIME := 240.0
const VIEW_SIZE := Vector2(1280.0, 720.0)
const MAX_ENEMIES := 650
const MAX_GEMS := 480
const MAX_REPAIR_CORES := 24
const MAX_EFFECTS := 320
const WAVE_TIMES := [60.0, 120.0, 180.0]
const VERSION := "Beta0.6.2"
const CHARACTERS := {
	"epathy": {
		"name": "埃帕蒂",
		"role": "近戰／生存",
		"passive": "護甲 +3；近距離傷害提高 20%",
		"skill": "主動戰技：用刀攻擊並擊退周圍敵人",
		"skill_name": "環刃震退",
		"skill_cooldown": 9.0,
		"starter_weapon": "近衛刀輪",
		"starter_trait": "命中時擊退異變體",
		"ring_color": Color(1.0, 0.38, 0.48),
		"color": Color(1.0, 0.48, 0.55),
	},
	"lucia": {
		"name": "璐茜婭",
		"role": "法術／持續傷害",
		"passive": "燃燒持續時間 +30%",
		"skill": "主動戰技：點燃全畫面已受傷敵人",
		"skill_name": "灼星引燃",
		"skill_cooldown": 13.0,
		"starter_weapon": "灼星法環",
		"starter_trait": "命中時附加短暫燃燒",
		"ring_color": Color(1.0, 0.42, 0.16),
		"color": Color(0.92, 0.45, 1.0),
	},
	"claire": {
		"name": "克萊兒",
		"role": "新手／均衡",
		"passive": "初始武器：星源鐮環",
		"skill": "範圍傷害與護盾兼備，適合第一次遊玩",
		"skill_name": "鐮環過載",
		"skill_cooldown": 11.0,
		"starter_weapon": "星源鐮環",
		"starter_trait": "發動時回復護盾",
		"ring_color": Color(0.25, 0.9, 1.0),
		"color": Color(0.6, 0.92, 1.0),
	},
	"rafari": {
		"name": "菈法瑞・零度・諾恩",
		"role": "控場／冰霜",
		"passive": "減速效果提高",
		"skill": "主動戰技：凍結普通敵人，首領大幅減速",
		"skill_name": "零度封鎖",
		"skill_cooldown": 14.0,
		"starter_weapon": "零度環域",
		"starter_trait": "命中時附加短暫冰緩",
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
var selected_character := "claire"
var run_started := false
var skill_cooldown_remaining := 0.0
var build_open := false
var total_damage_dealt := 0.0
var total_damage_taken := 0.0
var damage_by_source := {
	"starter": 0.0,
	"needle": 0.0,
	"storm": 0.0,
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

var level := 1
var experience := 0.0
var experience_required := 12.0
var meta_levels := {
	"health": 0,
	"speed": 0,
	"pickup": 0,
	"armor": 0,
	"damage": 0,
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

var storm_level := 0
var storm_damage := 36.0
var storm_radius := 56.0
var storm_interval := 2.2
var storm_timer := 0.7

var enemies: Array = []
var projectiles: Array = []
var hostile_projectiles: Array = []
var gems: Array = []
var repair_cores: Array = []
var effects: Array = []
var apostle_spawned := false
var apostle_present := false
var apostle_hp := 0.0
var apostle_max_hp := 0.0

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

	skill_cooldown_remaining = maxf(0.0, skill_cooldown_remaining - delta)
	_handle_skill_input()
	_update_player(delta)
	_update_spawning(delta)
	_update_weapons(delta)
	_update_projectiles(delta)
	_update_enemy_statuses(delta)
	_update_enemies(delta)
	_update_hostile_projectiles(delta)
	_update_gems(delta)
	_update_repair_cores(delta)
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
		"pause": [KEY_ESCAPE],
		"skill": [KEY_SPACE],
		"upgrade_1": [KEY_1],
		"upgrade_2": [KEY_2],
		"upgrade_3": [KEY_3],
		"reroll": [KEY_R],
		"build": [KEY_TAB],
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
	enemy_label.offset_bottom = 105.0
	enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	enemy_label.add_theme_font_size_override("font_size", 18)
	hud.add_child(enemy_label)

	weapon_label = Label.new()
	weapon_label.anchor_top = 1.0
	weapon_label.anchor_bottom = 1.0
	weapon_label.offset_left = 20.0
	weapon_label.offset_top = -92.0
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
	instruction_label.text = "WASD／方向鍵移動　空白鍵戰技　Tab 建構　Esc 暫停"
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

	_build_pause_overlay()
	_build_upgrade_overlay()
	_build_end_overlay()
	_build_loadout_overlay()
	_build_character_overlay()


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
	hint.text = "按 Esc 也可繼續"
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
	panel.custom_minimum_size = Vector2(780.0, 560.0)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 20)
	panel.add_child(column)

	var title := Label.new()
	title.text = "當前建構"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	column.add_child(title)

	build_text = Label.new()
	build_text.custom_minimum_size = Vector2(690.0, 390.0)
	build_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	build_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	build_text.add_theme_font_size_override("font_size", 20)
	column.add_child(build_text)

	var hint := Label.new()
	hint.text = "按 Tab 或 Esc 返回戰鬥"
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
		button.text = "%s\n%s\n\n%s\n\n起始｜%s\n戰技｜%s" % [data["name"], data["role"], data["passive"], data["starter_weapon"], data["skill_name"]]
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
	character_detail.text = "%s｜%s\n起始｜%s：%s\n空白鍵｜%s（%.0f 秒）：%s" % [
		data["name"], data["role"], data["starter_weapon"], data["starter_trait"],
		data["skill_name"], data["skill_cooldown"], data["skill"],
	]
	for button_id in character_buttons:
		var button: Button = character_buttons[button_id]
		button.modulate = Color.WHITE if button_id == selected_character else Color(0.62, 0.66, 0.75)


func _show_character_select() -> void:
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
	_choose_character(selected_character)
	queue_redraw()


func _start_game() -> void:
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
	damage_by_source = {"starter": 0.0, "needle": 0.0, "storm": 0.0, "skill": 0.0, "burn": 0.0, "other": 0.0}
	instruction_time = 10.0
	wave_index = 0

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
	skill_cooldown_remaining = 0.0
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
	meta_levels = {"health": 0, "speed": 0, "pickup": 0, "armor": 0, "damage": 0}

	scythe_level = 1
	scythe_damage = 24.0
	scythe_radius = 132.0
	scythe_interval = 1.55
	scythe_timer = 0.25
	scythe_evolved = false
	needle_level = 0
	needle_damage = 17.0
	needle_interval = 0.72
	needle_timer = 0.2
	storm_level = 0
	storm_damage = 36.0
	storm_radius = 56.0
	storm_interval = 2.2
	storm_timer = 0.7

	enemies.clear()
	projectiles.clear()
	hostile_projectiles.clear()
	gems.clear()
	repair_cores.clear()
	effects.clear()
	apostle_spawned = false
	apostle_present = false
	apostle_hp = 0.0
	apostle_max_hp = 0.0

	camera.position = player_pos
	character_overlay.visible = false
	build_overlay.visible = false
	upgrade_overlay.visible = false
	end_overlay.visible = false
	pause_overlay.visible = false
	boss_bar.visible = false
	boss_label.visible = false
	instruction_label.visible = true
	_update_interface(0.0)
	queue_redraw()


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
	var evolution_text := "進化條件：星源鐮環 Lv.5 ＋ 強化裝甲 Lv.3" if selected_character == "claire" else "專屬環域：%s" % _starter_weapon_trait_text()
	build_text.text = "%s｜%s\n%s\n\n武器\n• %s\n• 星針　　　%s\n• 脈衝雷暴　%s\n\n能力\n• 強化生命　Lv.%d / 5　　• 高速模組　Lv.%d / 5\n• 回收磁場　Lv.%d / 5　　• 強化裝甲　Lv.%d / 5\n• 星源增幅　Lv.%d / 5\n\n%s\n重抽剩餘　%d" % [
		character_data["name"],
		character_data["role"],
		character_data["passive"],
		("崩星護界　已進化" if scythe_evolved else "%s　Lv.%d / 5" % [starter_name, scythe_level]),
		("未取得" if needle_level == 0 else "Lv.%d / 5" % needle_level),
		("未取得" if storm_level == 0 else "Lv.%d / 5" % storm_level),
		int(meta_levels["health"]),
		int(meta_levels["speed"]),
		int(meta_levels["pickup"]),
		int(meta_levels["armor"]),
		int(meta_levels["damage"]),
		evolution_text,
		rerolls_remaining,
	]


func _starter_weapon_name() -> String:
	return String(CHARACTERS[selected_character]["starter_weapon"])


func _starter_weapon_trait_text() -> String:
	return String(CHARACTERS[selected_character]["starter_trait"])


func _starter_ring_color() -> Color:
	return CHARACTERS[selected_character]["ring_color"]


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


func _handle_skill_input() -> void:
	if Input.is_action_just_pressed("skill"):
		_use_character_skill()


func _use_character_skill() -> bool:
	if not run_started or game_over or choosing_upgrade or skill_cooldown_remaining > 0.0:
		return false
	match selected_character:
		"epathy": _use_epathy_skill()
		"lucia": _use_lucia_skill()
		"claire": _use_claire_skill()
		"rafari": _use_rafari_skill()
	skill_cooldown_remaining = float(CHARACTERS[selected_character]["skill_cooldown"])
	return true


func _use_epathy_skill() -> void:
	var radius := 205.0
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		if player_pos.distance_to(enemy["pos"]) > radius + float(enemy["radius"]):
			continue
		var push_direction: Vector2 = player_pos.direction_to(enemy["pos"])
		enemy["pos"] += push_direction * (55.0 if enemy["boss"] else 135.0)
		enemies[index] = enemy
		_damage_enemy(index, 72.0 * damage_multiplier * close_damage_multiplier, "skill")
	effects.append({"kind": "slash", "pos": player_pos, "life": 0.38, "total": 0.38, "radius": radius})


func _use_lucia_skill() -> void:
	var ignited := 0
	for index in enemies.size():
		var enemy = enemies[index]
		if float(enemy["hp"]) >= float(enemy["max_hp"]):
			continue
		enemy["burn_time"] = 4.0 * burn_duration_multiplier
		enemy["burn_tick"] = 0.0
		enemy["burn_damage"] = 11.0 * damage_multiplier
		enemies[index] = enemy
		ignited += 1
	effects.append({"kind": "fire", "pos": player_pos, "life": 0.8, "total": 0.8, "radius": 420.0 + ignited * 3.0})


func _use_claire_skill() -> void:
	var radius := 255.0
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		if player_pos.distance_to(enemy["pos"]) <= radius + float(enemy["radius"]):
			_damage_enemy(index, 55.0 * damage_multiplier, "skill")
	player_shield = minf(player_max_shield, player_shield + 12.0)
	effects.append({"kind": "pulse", "pos": player_pos, "life": 0.55, "total": 0.55, "radius": radius})


func _use_rafari_skill() -> void:
	var radius := 360.0
	for index in enemies.size():
		var enemy = enemies[index]
		if player_pos.distance_to(enemy["pos"]) > radius + float(enemy["radius"]):
			continue
		enemy["slow_time"] = (4.0 if enemy["boss"] else 3.0) * slow_effect_multiplier
		enemy["slow_factor"] = 0.32 if enemy["boss"] else 0.0
		enemies[index] = enemy
	effects.append({"kind": "ice", "pos": player_pos, "life": 0.65, "total": 0.65, "radius": radius})


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
		1: composition = ["shooter", "shooter", "shooter", "shooter", "shooter", "shooter", "chaser", "chaser", "chaser", "chaser"]
		_: composition = ["tank", "tank", "tank", "tank", "tank", "dasher", "dasher", "dasher", "dasher", "dasher", "dasher"]
	for kind in composition:
		if enemies.size() >= MAX_ENEMIES:
			break
		_spawn_mutant(kind)
	instruction_label.text = "異變體波次 %d／%d 接近" % [index + 1, WAVE_TIMES.size()]
	instruction_label.visible = true
	instruction_time = 4.0
	effects.append({"kind": "warning", "pos": player_pos, "life": 1.1, "total": 1.1, "radius": 300.0})


func _spawn_mutant(force_kind: String = "") -> void:
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(650.0, 830.0)
	var kind := force_kind
	if kind.is_empty():
		var roll := rng.randf()
		if game_time > 150.0 and roll < 0.1:
			kind = "tank"
		elif game_time > 90.0 and roll < 0.28:
			kind = "shooter"
		elif game_time > 35.0 and roll < 0.52:
			kind = "dasher"
		else:
			kind = "chaser"
	var difficulty := 1.0 + game_time / 360.0
	var elite := game_time > 50.0 and rng.randf() < 0.025
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
	var hp := base_hp * difficulty
	var speed := base_speed * (1.0 + game_time / 900.0)
	if elite:
		hp *= 4.2
		speed *= 1.12
		radius *= 1.45
	enemies.append({
		"pos": player_pos + Vector2.from_angle(angle) * distance,
		"hp": hp,
		"max_hp": hp,
		"speed": speed,
		"radius": radius,
		"kind": kind,
		"elite": elite,
		"boss": false,
		"dash_cooldown": rng.randf_range(1.4, 3.2),
		"dash_time": 0.0,
		"dash_dir": Vector2.ZERO,
		"contact_cooldown": 0.0,
		"attack_cooldown": rng.randf_range(0.5, 2.2),
		"flash": 0.0,
		"burn_time": 0.0,
		"burn_tick": 0.0,
		"burn_damage": 0.0,
		"slow_time": 0.0,
		"slow_factor": 1.0,
	})


func _spawn_apostle() -> void:
	apostle_spawned = true
	apostle_present = true
	apostle_max_hp = 4800.0
	apostle_hp = apostle_max_hp
	enemies.append({
		"pos": player_pos + Vector2(0.0, -650.0),
		"hp": apostle_max_hp,
		"max_hp": apostle_max_hp,
		"speed": 48.0,
		"radius": 64.0,
		"kind": "apostle",
		"elite": true,
		"boss": true,
		"dash_cooldown": 2.4,
		"dash_time": 0.0,
		"dash_dir": Vector2.ZERO,
		"contact_cooldown": 0.0,
		"attack_cooldown": 1.8,
		"summon_cooldown": 6.0,
		"flash": 0.0,
		"burn_time": 0.0,
		"burn_tick": 0.0,
		"burn_damage": 0.0,
		"slow_time": 0.0,
		"slow_factor": 1.0,
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


func _fire_scythe_ring() -> void:
	var dealt_damage := scythe_damage * damage_multiplier * close_damage_multiplier
	if scythe_level >= 5:
		dealt_damage *= 1.35
	if scythe_evolved:
		dealt_damage *= 1.5
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		if player_pos.distance_to(enemy["pos"]) <= scythe_radius + float(enemy["radius"]):
			match selected_character:
				"epathy":
					var push_direction: Vector2 = player_pos.direction_to(enemy["pos"])
					enemy["pos"] += push_direction * (10.0 if enemy["boss"] else 32.0)
				"lucia":
					enemy["burn_time"] = maxf(float(enemy.get("burn_time", 0.0)), 1.8 * burn_duration_multiplier)
					enemy["burn_tick"] = 0.0
					enemy["burn_damage"] = maxf(float(enemy.get("burn_damage", 0.0)), 6.0 * damage_multiplier)
				"rafari":
					enemy["slow_time"] = maxf(float(enemy.get("slow_time", 0.0)), 1.4 * slow_effect_multiplier)
					enemy["slow_factor"] = minf(float(enemy.get("slow_factor", 1.0)), 0.65 if not enemy["boss"] else 0.78)
			enemies[index] = enemy
			_damage_enemy(index, dealt_damage, "starter")
	if selected_character == "claire":
		var shield_restore := 1.2 + scythe_level * 0.35 + (3.0 if scythe_evolved else 0.0)
		player_shield = minf(player_max_shield, player_shield + shield_restore)
	effects.append({
		"kind": "ring",
		"pos": player_pos,
		"life": 0.42,
		"total": 0.42,
		"radius": scythe_radius,
		"color": _starter_ring_color(),
	})


func _fire_star_needles() -> void:
	if enemies.is_empty():
		return
	var shot_count := 1 + int((needle_level - 1) / 2.0)
	var targets := _nearest_enemy_indices(shot_count)
	for enemy_index in targets:
		if enemy_index < 0 or enemy_index >= enemies.size():
			continue
		var target_pos: Vector2 = enemies[enemy_index]["pos"]
		var direction := player_pos.direction_to(target_pos)
		projectiles.append({
			"pos": player_pos,
			"velocity": direction * (660.0 + needle_level * 25.0),
			"damage": needle_damage * damage_multiplier,
			"source": "needle",
			"radius": 6.0,
			"life": 1.5,
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
			if enemies[enemy_index]["pos"].distance_to(position) <= storm_radius + float(enemies[enemy_index]["radius"]):
				hit_count += 1
		if hit_count > 0:
			_damage_enemy(enemy_index, storm_damage * damage_multiplier * hit_count, "storm")


func _nearest_enemy_indices(count: int) -> Array:
	var scored: Array = []
	for index in enemies.size():
		scored.append({"index": index, "distance": player_pos.distance_squared_to(enemies[index]["pos"])})
	scored.sort_custom(func(a, b): return a["distance"] < b["distance"])
	var result: Array = []
	for index in mini(count, scored.size()):
		result.append(scored[index]["index"])
	return result


func _update_projectiles(delta: float) -> void:
	for projectile_index in range(projectiles.size() - 1, -1, -1):
		var projectile = projectiles[projectile_index]
		projectile["pos"] += projectile["velocity"] * delta
		projectile["life"] -= delta
		var consumed := false
		for enemy_index in range(enemies.size() - 1, -1, -1):
			var enemy = enemies[enemy_index]
			if projectile["pos"].distance_to(enemy["pos"]) <= float(projectile["radius"]) + float(enemy["radius"]):
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
			enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
			enemy["attack_cooldown"] = float(enemy["attack_cooldown"]) - delta
			enemy["summon_cooldown"] = float(enemy["summon_cooldown"]) - delta
			if float(enemy["attack_cooldown"]) <= 0.0:
				_fire_apostle_burst(enemy["pos"])
				enemy["attack_cooldown"] = 2.15
			if float(enemy["summon_cooldown"]) <= 0.0:
				for summon_index in 5:
					_spawn_mutant("chaser" if summon_index % 2 == 0 else "dasher")
				enemy["summon_cooldown"] = 7.0
		elif enemy["kind"] == "shooter":
			var distance_to_player: float = enemy["pos"].distance_to(player_pos)
			if distance_to_player > 370.0:
				enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
			elif distance_to_player < 245.0:
				enemy["pos"] -= direction * float(enemy["speed"]) * status_speed * delta
			else:
				enemy["pos"] += direction.rotated(PI * 0.5) * float(enemy["speed"]) * 0.45 * status_speed * delta
			enemy["attack_cooldown"] = float(enemy["attack_cooldown"]) - delta
			if float(enemy["attack_cooldown"]) <= 0.0 and status_speed > 0.0:
				_fire_mutant_shot(enemy["pos"])
				enemy["attack_cooldown"] = rng.randf_range(2.1, 2.8)
		elif enemy["kind"] == "dasher":
			if float(enemy["dash_time"]) > 0.0:
				enemy["dash_time"] = float(enemy["dash_time"]) - delta
				enemy["pos"] += enemy["dash_dir"] * float(enemy["speed"]) * 4.2 * status_speed * delta
			else:
				enemy["dash_cooldown"] = float(enemy["dash_cooldown"]) - delta
				enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta
				if float(enemy["dash_cooldown"]) <= 0.0:
					enemy["dash_dir"] = direction
					enemy["dash_time"] = 0.42
					enemy["dash_cooldown"] = rng.randf_range(2.4, 3.5)
		else:
			enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta

		if enemy["pos"].distance_to(player_pos) <= float(enemy["radius"]) + 18.0 and float(enemy["contact_cooldown"]) <= 0.0:
			var contact_damage := 22.0 if enemy["boss"] else (14.0 if enemy["kind"] == "tank" else (11.0 if enemy["elite"] else 7.0))
			_take_player_damage(contact_damage)
			enemy["contact_cooldown"] = 0.75
		enemies[index] = enemy


func _fire_apostle_burst(origin: Vector2) -> void:
	var projectile_count := 12
	for index in projectile_count:
		var angle := TAU * float(index) / float(projectile_count) + game_time * 0.22
		hostile_projectiles.append({
			"pos": origin,
			"velocity": Vector2.from_angle(angle) * 185.0,
			"radius": 9.0,
			"damage": 10.0,
			"life": 6.0,
		})


func _fire_mutant_shot(origin: Vector2) -> void:
	var direction := origin.direction_to(player_pos)
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
	var actual_damage := minf(amount, float(enemy["hp"]))
	total_damage_dealt += actual_damage
	if not damage_by_source.has(source):
		source = "other"
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
	var gem_value := 8.0 if enemy["elite"] else 1.0
	if not was_boss:
		_drop_experience_gem(enemy["pos"], gem_value)
		if enemy["elite"]:
			_drop_repair_core(enemy["pos"])
	kills += 1
	effects.append({"kind": "burst", "pos": enemy["pos"], "life": 0.24, "total": 0.24, "radius": float(enemy["radius"]) * 2.2})
	enemies.remove_at(index)
	if was_boss:
		apostle_present = false
		apostle_hp = 0.0
		_finish_game(true)


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
		var distance: float = gem["pos"].distance_to(player_pos)
		if distance <= pickup_radius * 2.0:
			var pull_speed: float = 240.0 + maxf(0.0, pickup_radius * 2.0 - distance) * 3.0
			gem["pos"] += gem["pos"].direction_to(player_pos) * pull_speed * delta
		if gem["pos"].distance_to(player_pos) <= 25.0:
			_gain_experience(float(gem["value"]))
			gems.remove_at(index)
		else:
			gems[index] = gem


func _update_repair_cores(delta: float) -> void:
	for index in range(repair_cores.size() - 1, -1, -1):
		var core = repair_cores[index]
		var distance: float = core["pos"].distance_to(player_pos)
		if distance <= pickup_radius * 1.5:
			var pull_speed := 210.0 + maxf(0.0, pickup_radius * 1.5 - distance) * 3.2
			core["pos"] += core["pos"].direction_to(player_pos) * pull_speed * delta
		if core["pos"].distance_to(player_pos) <= 27.0:
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

	var candidates := _available_upgrades()
	candidates.shuffle()
	var option_count := mini(3, candidates.size())
	current_upgrade_choices.clear()
	for index in option_count:
		var option = candidates[index]
		current_upgrade_choices.append(option)
		var button := Button.new()
		button.custom_minimum_size = Vector2(285.0, 205.0)
		button.text = "[%d] %s\n\n%s" % [index + 1, option["name"], option["description"]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 19)
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.pressed.connect(_select_upgrade.bind(option["id"]))
		upgrade_buttons.add_child(button)
	reroll_button.text = "[R] 重新抽取（剩餘 %d 次）" % rerolls_remaining
	reroll_button.disabled = rerolls_remaining <= 0


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
	elif selected_character == "claire" and int(meta_levels["armor"]) >= 3 and not scythe_evolved:
		result.append({
			"id": "scythe_evolution",
			"name": "進化：崩星護界",
			"description": "星源鐮環 Lv.5 ＋ 強化裝甲 Lv.3\n大幅提高傷害、範圍、攻速與護盾回復",
		})
	if needle_level < 5:
		result.append({
			"id": "needle",
			"name": "星針 Lv.%d" % (needle_level + 1),
			"description": _needle_upgrade_description(needle_level + 1),
		})
	if storm_level < 5:
		result.append({
			"id": "storm",
			"name": "脈衝雷暴 Lv.%d" % (storm_level + 1),
			"description": _storm_upgrade_description(storm_level + 1),
		})
	if int(meta_levels["health"]) < 5:
		result.append({"id": "health", "name": "強化生命 Lv.%d" % (int(meta_levels["health"]) + 1), "description": "最大生命 +15，並回復 15 生命"})
	if int(meta_levels["speed"]) < 5:
		result.append({"id": "speed", "name": "高速模組 Lv.%d" % (int(meta_levels["speed"]) + 1), "description": "移動速度提高 8%"})
	if int(meta_levels["pickup"]) < 5:
		result.append({"id": "pickup", "name": "回收磁場 Lv.%d" % (int(meta_levels["pickup"]) + 1), "description": "星源碎片拾取範圍 +25"})
	if int(meta_levels["armor"]) < 5:
		result.append({"id": "armor", "name": "強化裝甲 Lv.%d" % (int(meta_levels["armor"]) + 1), "description": "護甲 +1，降低每次受到的傷害"})
	if int(meta_levels["damage"]) < 5:
		result.append({"id": "damage", "name": "星源增幅 Lv.%d" % (int(meta_levels["damage"]) + 1), "description": "所有武器傷害提高 12%"})
	return result


func _scythe_upgrade_description(next_level: int) -> String:
	match next_level:
		2: return "鐮環傷害 +10"
		3: return "鐮環半徑 +34"
		4: return "攻擊間隔縮短 20%"
		5: return "超載：傷害提高並強化護盾回復"
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
					player_max_shield += 8.0
		"scythe_evolution":
			if selected_character == "claire" and scythe_level >= 5 and int(meta_levels["armor"]) >= 3 and not scythe_evolved:
				scythe_evolved = true
				scythe_radius += 36.0
				scythe_interval *= 0.82
				player_max_shield += 12.0
				player_shield = player_max_shield
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

	pending_levels = maxi(0, pending_levels - 1)
	if pending_levels > 0:
		_show_upgrade_choices()
	else:
		choosing_upgrade = false
		upgrade_overlay.visible = false
		get_tree().paused = false


func _update_effects(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		effects[index]["life"] = float(effects[index]["life"]) - delta
		if float(effects[index]["life"]) <= 0.0:
			effects.remove_at(index)


func _enforce_runtime_limits() -> void:
	if effects.size() > MAX_EFFECTS:
		effects = effects.slice(effects.size() - MAX_EFFECTS)
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
	enemy_label.text = "異變體 %d　波次 %d / %d\n使徒降臨 %s" % [
		enemies.size(),
		wave_index,
		WAVE_TIMES.size(),
		("戰鬥中" if apostle_spawned else _format_countdown(maxf(0.0, APOSTLE_TIME - game_time))),
	]
	weapon_label.text = "%s\n星針 %s｜脈衝雷暴 %s" % [
		("崩星護界｜進化" if scythe_evolved else "%s Lv.%d%s" % [_starter_weapon_name(), scythe_level, ("｜超載" if scythe_level >= 5 else "")]),
		("未取得" if needle_level == 0 else "Lv.%d" % needle_level),
		("未取得" if storm_level == 0 else "Lv.%d" % storm_level),
	]
	var skill_name: String = CHARACTERS[selected_character]["skill_name"]
	skill_label.text = "空白鍵｜%s\n%s" % [
		skill_name,
		("可施放" if skill_cooldown_remaining <= 0.0 else "冷卻 %.1f 秒" % skill_cooldown_remaining),
	]
	skill_label.modulate = Color(0.65, 1.0, 0.86) if skill_cooldown_remaining <= 0.0 else Color(0.7, 0.75, 0.84)
	xp_bar.max_value = experience_required
	xp_bar.value = experience

	if apostle_present:
		boss_bar.max_value = apostle_max_hp
		boss_bar.value = apostle_hp
		boss_bar.visible = true
		boss_label.visible = true
	else:
		boss_bar.visible = false
		boss_label.visible = false

	if instruction_time > 0.0:
		instruction_time -= delta
		instruction_label.visible = true
	else:
		instruction_label.visible = false


func _format_countdown(value: float) -> String:
	var total := maxi(0, ceili(value))
	return "%02d:%02d" % [total / 60, total % 60]


func _finish_game(victory: bool) -> void:
	if game_over:
		return
	game_over = true
	get_tree().paused = true
	end_overlay.visible = true
	end_title.text = "使徒討伐完成" if victory else "任務失敗"
	end_title.modulate = Color(0.45, 0.95, 1.0) if victory else Color(1.0, 0.4, 0.48)
	end_summary.text = "生存時間　%s\n擊殺數　%d　最終等級　%d\n造成傷害　%d　承受傷害　%d\n\n傷害分布\n%s　%d｜星針　%d｜脈衝雷暴　%d\n主動戰技　%d｜燃燒　%d\n\n%s" % [
		_format_countdown(game_time),
		kills,
		level,
		int(total_damage_dealt),
		int(total_damage_taken),
		_starter_weapon_name(),
		int(damage_by_source["starter"]),
		int(damage_by_source["needle"]),
		int(damage_by_source["storm"]),
		int(damage_by_source["skill"]),
		int(damage_by_source["burn"]),
		("方舟防線暫時安全。" if victory else "重新調整強化後再次出擊。"),
	]


func _draw() -> void:
	_draw_background()

	for gem in gems:
		var position: Vector2 = gem["pos"]
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
		draw_circle(core_pos, 13.0, Color(0.14, 0.95, 0.62, 0.22))
		draw_arc(core_pos, 12.0, 0.0, TAU, 24, Color(0.35, 1.0, 0.72), 3.0, true)
		draw_rect(Rect2(core_pos + Vector2(-3.0, -8.0), Vector2(6.0, 16.0)), Color(0.7, 1.0, 0.86))
		draw_rect(Rect2(core_pos + Vector2(-8.0, -3.0), Vector2(16.0, 6.0)), Color(0.7, 1.0, 0.86))

	for projectile in projectiles:
		var direction: Vector2 = projectile["velocity"].normalized()
		draw_line(projectile["pos"] - direction * 10.0, projectile["pos"] + direction * 7.0, Color(0.5, 0.95, 1.0), 5.0, true)

	for projectile in hostile_projectiles:
		draw_circle(projectile["pos"], float(projectile["radius"]), Color(1.0, 0.2, 0.48))
		draw_arc(projectile["pos"], float(projectile["radius"]) + 4.0, 0.0, TAU, 18, Color(1.0, 0.65, 0.8), 2.0, true)

	for enemy in enemies:
		_draw_enemy(enemy)

	for effect in effects:
		_draw_effect(effect)

	_draw_player()


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
	if enemy["boss"]:
		var boss_color := Color(1.0, 0.24, 0.52) if not flash else Color.WHITE
		draw_circle(position, radius, Color(boss_color, 0.28))
		draw_arc(position, radius, 0.0, TAU, 48, boss_color, 7.0, true)
		draw_arc(position, radius * 0.64, game_time, game_time + TAU * 0.74, 38, Color(0.9, 0.55, 1.0), 5.0, true)
		for spoke in 6:
			var angle := TAU * float(spoke) / 6.0 + game_time * 0.25
			draw_line(position + Vector2.from_angle(angle) * (radius * 0.7), position + Vector2.from_angle(angle) * (radius * 1.22), boss_color, 4.0)
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
	if flash:
		base_color = Color.WHITE
	match enemy["kind"]:
		"dasher":
			var dasher_points := PackedVector2Array([
				position + Vector2(0.0, -radius),
				position + Vector2(radius, 0.0),
				position + Vector2(0.0, radius),
				position + Vector2(-radius, 0.0),
			])
			draw_colored_polygon(dasher_points, base_color)
		"shooter":
			var shooter_points := PackedVector2Array([
				position + Vector2(0.0, -radius),
				position + Vector2(radius, radius * 0.82),
				position + Vector2(-radius, radius * 0.82),
			])
			draw_colored_polygon(shooter_points, base_color)
			draw_circle(position, 4.0, Color(0.08, 0.02, 0.12))
		"tank":
			draw_rect(Rect2(position - Vector2(radius * 0.82, radius * 0.72), Vector2(radius * 1.64, radius * 1.44)), base_color)
			draw_arc(position, radius, 0.0, TAU, 24, Color(1.0, 0.58, 0.4), 4.0, true)
		_:
			draw_circle(position, radius, base_color)
			draw_circle(position + Vector2(-5.0, -3.0), 2.5, Color(0.03, 0.02, 0.06))
			draw_circle(position + Vector2(5.0, -3.0), 2.5, Color(0.03, 0.02, 0.06))
	if enemy["elite"]:
		draw_arc(position, radius + 5.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.22), 3.0)
		var hp_ratio: float = float(enemy["hp"]) / float(enemy["max_hp"])
		draw_rect(Rect2(position + Vector2(-radius, -radius - 11.0), Vector2(radius * 2.0, 4.0)), Color(0.18, 0.03, 0.08))
		draw_rect(Rect2(position + Vector2(-radius, -radius - 11.0), Vector2(radius * 2.0 * hp_ratio, 4.0)), Color(1.0, 0.75, 0.22))
	if float(enemy.get("burn_time", 0.0)) > 0.0:
		draw_arc(position, radius + 8.0, -1.2, 2.2, 18, Color(1.0, 0.38, 0.08, 0.9), 4.0, true)
	if float(enemy.get("slow_time", 0.0)) > 0.0:
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
		"slash":
			draw_arc(effect["pos"], float(effect["radius"]) * (0.55 + 0.45 * progress), -1.4, 2.7, 52, Color(1.0, 0.55, 0.65, alpha), 12.0, true)
		"fire":
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(1.0, 0.26, 0.08, alpha * 0.16))
			draw_arc(effect["pos"], float(effect["radius"]) * progress, 0.0, TAU, 64, Color(1.0, 0.5, 0.14, alpha), 7.0, true)
		"pulse":
			draw_arc(effect["pos"], float(effect["radius"]) * (0.25 + 0.75 * progress), 0.0, TAU, 64, Color(0.35, 0.9, 1.0, alpha), 11.0, true)
		"ice":
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(0.3, 0.65, 1.0, alpha * 0.14))
			draw_arc(effect["pos"], float(effect["radius"]) * progress, 0.0, TAU, 64, Color(0.55, 0.85, 1.0, alpha), 8.0, true)
		"repair":
			draw_circle(effect["pos"], float(effect["radius"]) * progress, Color(0.2, 1.0, 0.62, alpha * 0.18))
			draw_arc(effect["pos"], float(effect["radius"]) * (0.45 + progress * 0.55), 0.0, TAU, 40, Color(0.48, 1.0, 0.76, alpha), 6.0, true)
		"storm":
			var strike_top: Vector2 = effect["pos"] + Vector2(0.0, -220.0)
			draw_line(strike_top, effect["pos"], Color(0.72, 0.92, 1.0, alpha), 9.0, true)
			draw_arc(effect["pos"], float(effect["radius"]) * (0.55 + progress * 0.45), 0.0, TAU, 36, Color(0.35, 0.78, 1.0, alpha), 7.0, true)


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
	if scythe_timer < 0.22:
		draw_arc(player_pos, scythe_radius, 0.0, TAU, 48, Color(_starter_ring_color(), 0.15), 2.0)
