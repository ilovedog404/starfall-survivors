extends Node2D

# 五分鐘垂直切片。設定、主選單、小屋以內部類別形式放在本檔案最底部。

const EPATHY_TEXTURE: Texture2D = preload("res://assets/sprites/epathy_chibi_v1.png")
const ANUBARAK_TEXTURE: Texture2D = preload("res://assets/sprites/anubarak_chibi_v1.png")
const HUT_BACKGROUND_TEXTURE: Texture2D = preload("res://assets/sprites/hut_campfire_background_v2.png")
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

const CHARACTER_PATHS := {
	"epathy": "res://characters/epathy.gd",
	"lucia": "res://characters/lucia.gd",
	"claire": "res://characters/claire.gd",
	"rafari": "res://characters/rafari.gd",
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
const MAX_DAMAGE_NUMBERS := 80
const LOW_DETAIL_ENEMY_COUNT := 220
const DRAW_MARGIN := 180.0
const MAP_OBJECT_RANGE := 76.0
const MAP_CHEST_COUNT := 4
const MAP_CHEST_DISTANCE := 4920.0
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
const LEVEL_TEXT := {
	2: "傷害提高 25%",
	4: "間隔縮短 15%",
	5: "傷害再提高 30%",
	7: "間隔再縮短 15%",
	8: "傷害提高 35%（極限強化）",
}
const WEAPON_BLUEPRINTS := {
	"starter": {
		"name": "起始武器", "pattern": "starter", "damage": 24.0, "interval": 1.55, "radius": 132.0,
		"speed": 0.0, "amount": 1, "duration": 0.0, "pierce": 0, "start_timer": 0.25,
		"description": "角色專屬自動武器", "scale_text": "增加斬擊數量或作用範圍",
	},
	"needle": {
		"name": "星針", "pattern": "needle", "damage": 17.0, "interval": 1.2, "radius": 6.0,
		"speed": 660.0, "amount": 1, "duration": 1.5, "pierce": 0, "start_timer": 0.2,
		"description": "向最近異變體發射高速星針", "scale_text": "增加星針數量或穿透",
		"level_effects": {
			2: {"amount": 1}, 3: {"interval": -0.2}, 4: {"amount": 1}, 5: {"damage": 10.0},
			6: {"amount": 1}, 7: {"pierce": 1}, 8: {"damage": 10.0},
		},
	},
	"rail_blade": {
		"name": "磁軌飛刃", "pattern": "aimed_pierce", "damage": 13.0, "interval": 1.0, "radius": 6.0,
		"speed": 760.0, "amount": 1, "duration": 1.35, "pierce": 0,
		"description": "朝最近異變體高速連射並穿透目標", "scale_text": "增加飛刃數量或穿透",
		"level_effects": {
			2: {"amount": 1}, 3: {"amount": 1, "damage": 5.0}, 4: {"amount": 1}, 5: {"pierce": 1},
			6: {"amount": 1}, 7: {"amount": 1, "damage": 5.0}, 8: {"pierce": 1},
		},
	},
	"ion_axe": {
		"name": "離子戰斧", "pattern": "heavy_axes", "damage": 32.0, "interval": 4.0, "radius": 13.0,
		"speed": 330.0, "amount": 1, "duration": 2.0, "pierce": 2,
		"description": "向周圍拋出緩慢但高傷害的重型戰斧", "scale_text": "增加戰斧數量或穿透",
		"level_effects": {
			2: {"amount": 1}, 3: {"damage": 20.0}, 4: {"pierce": 2}, 5: {"amount": 1},
			6: {"damage": 20.0}, 7: {"pierce": 2}, 8: {"damage": 20.0},
		},
	},
	"return_disc": {
		"name": "折返星環", "pattern": "returning_disc", "damage": 20.0, "interval": 2.0, "radius": 10.0,
		"speed": 470.0, "amount": 1, "duration": 2.15, "pierce": 4,
		"description": "射出會轉向飛回角色的穿透星環", "scale_text": "增加星環數量、範圍或速度",
		"level_effects": {
			2: {"damage": 10.0}, 3: {"radius_pct": 0.1, "speed_pct": 0.25}, 4: {"amount": 1},
			5: {"damage": 10.0}, 6: {"radius_pct": 0.1, "speed_pct": 0.25}, 7: {"amount": 1}, 8: {"damage": 10.0},
		},
	},
	"orbit_blades": {
		"name": "軌道刃陣", "pattern": "orbit", "damage": 13.0, "interval": 0.72, "radius": 92.0,
		"speed": 1.0, "amount": 1, "duration": 3.0, "pierce": 0,
		"description": "旋轉刃陣持續切割近身目標", "scale_text": "增加軌道刃、範圍或持續時間",
		"level_effects": {
			2: {"amount": 1}, 3: {"radius_pct": 0.25, "speed_pct": 0.3}, 4: {"duration": 0.5, "damage": 10.0},
			5: {"amount": 1}, 6: {"radius_pct": 0.25, "speed_pct": 0.3}, 7: {"duration": 0.5, "damage": 10.0}, 8: {"amount": 1},
		},
	},
	"meteor": {
		"name": "隕炎彈", "pattern": "meteor", "damage": 42.0, "interval": 3.0, "radius": 70.0,
		"speed": 1.0, "amount": 3, "duration": 0.68, "pierce": 0, "start_timer": 1.35,
		"description": "鎖定敵群轟擊並留下燃燒", "scale_text": "提高隕炎速度或傷害",
		"level_effects": {
			2: {"damage": 10.0}, 3: {"damage": 10.0, "speed_pct": 0.2}, 4: {"damage": 10.0},
			5: {"damage": 10.0, "speed_pct": 0.2}, 6: {"damage": 10.0}, 7: {"damage": 10.0, "speed_pct": 0.2}, 8: {"damage": 10.0},
		},
	},
	"plasma_aura": {
		"name": "等離子場", "pattern": "aura", "damage": 8.0, "interval": 1.3, "radius": 108.0,
		"speed": 0.0, "amount": 1, "duration": 0.0, "pierce": 0,
		"description": "週期傷害並削弱身旁異變體", "scale_text": "擴大等離子範圍或縮短冷卻",
		"level_effects": {
			2: {"radius_pct": 0.4, "damage": 2.0}, 3: {"interval": -0.1, "damage": 1.0},
			4: {"radius_pct": 0.2, "damage": 1.0}, 5: {"interval": -0.1, "damage": 2.0},
			6: {"radius_pct": 0.2, "damage": 1.0}, 7: {"interval": -0.1, "damage": 1.0},
			8: {"radius_pct": 0.2, "damage": 2.0},
		},
	},
	"cryo_pool": {
		"name": "冷媒污染區", "pattern": "target_area", "damage": 8.0, "interval": 4.5, "radius": 76.0,
		"speed": 0.0, "amount": 1, "duration": 2.0, "pierce": 0,
		"description": "在敵群腳下留下持續傷害與減速區", "scale_text": "增加污染區、範圍或持續時間",
		"level_effects": {
			2: {"amount": 1, "radius_pct": 0.2}, 3: {"duration": 0.5, "damage": 10.0},
			4: {"amount": 1, "radius_pct": 0.2}, 5: {"duration": 0.3, "damage": 10.0},
			6: {"amount": 1, "radius_pct": 0.2}, 7: {"duration": 0.3, "damage": 5.0},
			8: {"radius_pct": 0.2, "damage": 5.0},
		},
	},
	"ricochet_ray": {
		"name": "折射游標", "pattern": "chain", "damage": 17.0, "interval": 3.0, "radius": 7.0,
		"speed": 610.0, "amount": 1, "duration": 2.25, "pierce": 0,
		"description": "在多個鄰近目標之間連鎖折射", "scale_text": "增加游標數量、速度或持續時間",
		"level_effects": {
			2: {"damage": 5.0, "speed_pct": 0.2}, 3: {"duration": 0.3, "damage": 5.0}, 4: {"amount": 1},
			5: {"damage": 5.0, "speed_pct": 0.2}, 6: {"duration": 0.3, "damage": 5.0}, 7: {"amount": 1}, 8: {"duration": 0.5},
		},
	},
}

var rng := RandomNumberGenerator.new()
var camera: Camera2D
var battle_music_player: AudioStreamPlayer
var settings
var main_menu
var hut

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
var character_cache: Dictionary = {}
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

var weapon_levels: Dictionary = {}
var weapon_timers: Dictionary = {}
var weapon_stats: Dictionary = {}
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
var damage_numbers: Array = []
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
var gm_panel: PanelContainer
var gm_speed_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	settings = GameSettingsData.new()
	settings.load_from_disk()
	settings.changed.connect(_apply_settings)
	_setup_battle_music()
	_apply_settings()
	_ensure_input_map()
	_create_camera()
	_build_interface()
	_show_main_menu()

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(settings.master_volume), 0.0001)))
	battle_music_player.volume_db = -10.0 + linear_to_db(maxf(float(settings.music_volume), 0.0001))
	var wanted_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != wanted_mode:
		DisplayServer.window_set_mode(wanted_mode)

func _get_character(character_id: String):
	if not character_cache.has(character_id):
		var script: GDScript = load(CHARACTER_PATHS[character_id])
		character_cache[character_id] = script.new()
	return character_cache[character_id]

func _char():
	return _get_character(selected_character)

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
	_update_damage_numbers(delta)
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


# ───────── 介面建構 ─────────

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
	_build_menu_screens()

func _build_menu_screens() -> void:
	hut = HutSceneUI.new()
	ui_root.add_child(hut)
	hut.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hut.setup(HUT_BACKGROUND_TEXTURE, EPATHY_TEXTURE, PLAYABLE_CHARACTERS)
	hut.character_chosen.connect(_on_hut_character_chosen)
	hut.back_pressed.connect(_show_main_menu)

	main_menu = MainMenuUI.new()
	ui_root.add_child(main_menu)
	main_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu.setup(settings, VERSION)
	main_menu.start_pressed.connect(_show_character_select)
	main_menu.quit_pressed.connect(_quit_game)

func _build_gm_panel() -> void:
	gm_panel = PanelContainer.new()
	gm_panel.position = Vector2(16.0, 142.0)
	gm_panel.custom_minimum_size = Vector2(178.0, 217.0)
	gm_panel.visible = false
	ui_root.add_child(gm_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	gm_panel.add_child(column)
	_make_label(column, "GM 測試", 16)
	gm_speed_button = _make_button(column, "3 倍速：關", Vector2(160.0, 36.0), 16, _toggle_gm_speed)
	_make_button(column, "立即升級", Vector2(160.0, 36.0), 16, _gm_level_up)
	_make_button(column, "重骰次數 +1", Vector2(160.0, 36.0), 16, _gm_add_reroll)
	_make_button(column, "十武器測試", Vector2(160.0, 36.0), 16, _gm_unlock_all_weapons)

func _build_pause_overlay() -> void:
	pause_overlay = _make_overlay(Color(0.008, 0.015, 0.045, 0.9))
	var column := _add_panel_column(pause_overlay, Vector2(480.0, 520.0), 18)
	_make_label(column, "已暫停", 38)
	_make_button(column, "繼續戰鬥", Vector2(280.0, 56.0), 21, _resume_game)
	_make_button(column, "重新開始本角色", Vector2(280.0, 54.0), 19, _start_game)
	_make_button(column, "返回小屋", Vector2(280.0, 54.0), 19, _show_character_select)
	_make_button(column, "返回主選單", Vector2(280.0, 54.0), 19, _show_main_menu)
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
	var column := _add_panel_column(end_overlay, Vector2(560.0, 480.0), 20)
	end_title = _make_label(column, "", 42)
	end_summary = _make_label(column, "", 20)
	_make_button(column, "重新開始", Vector2(260.0, 58.0), 22, _start_game)
	_make_button(column, "返回小屋", Vector2(260.0, 50.0), 19, _show_character_select)
	_make_button(column, "返回主選單", Vector2(260.0, 50.0), 19, _show_main_menu)
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


# ───────── 主選單、小屋與流程 ─────────

func _enter_idle_state() -> void:
	_set_gm_speed(false)
	_stop_battle_music()
	get_tree().paused = true
	run_started = false
	game_over = false
	choosing_upgrade = false
	choosing_elite_reward = false
	manual_paused = false
	build_open = false
	for node in [upgrade_overlay, end_overlay, pause_overlay, build_overlay, gm_panel, interaction_label, boss_bar, boss_label, main_menu, hut]:
		node.visible = false

func _show_main_menu() -> void:
	_enter_idle_state()
	main_menu.show_menu()
	queue_redraw()

func _show_character_select() -> void:
	_enter_idle_state()
	hut.show_hut()
	queue_redraw()

func _on_hut_character_chosen(character_id: String) -> void:
	if not PLAYABLE_CHARACTERS.has(character_id):
		return
	selected_character = character_id
	_start_game()

func _quit_game() -> void:
	get_tree().quit()


# ───────── 開局與武器初始化 ─────────

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
	cooldown_scale = 1.0
	arsenal_area_scale = 1.0
	_char().apply_passives(self)

	_initialize_weapons()

	for list in [enemies, projectiles, hostile_projectiles, gems, repair_cores, evolution_cores, elite_chests, effects, damage_numbers]:
		list.clear()
	evolution_cores_owned = 0
	apostle_spawned = false
	apostle_present = false
	apostle_enraged = false
	apostle_hp = 0.0
	apostle_max_hp = 0.0
	apostle_phase = 1
	_spawn_map_object_ring(rng.randf_range(-0.18, 0.18))

	camera.position = player_pos
	camera.reset_smoothing()
	for node in [main_menu, hut, build_overlay, upgrade_overlay, end_overlay, pause_overlay, boss_bar, boss_label]:
		node.visible = false
	gm_panel.visible = true
	_show_game_notice("WASD／方向鍵移動　E 互動　B／Tab 建構　Esc／P 暫停")
	instruction_time = 10.0
	_update_interface(0.0)
	queue_redraw()

func _initialize_weapons() -> void:
	weapon_levels.clear()
	weapon_timers.clear()
	weapon_stats.clear()
	for weapon_id in WEAPON_BLUEPRINTS:
		var blueprint: Dictionary = WEAPON_BLUEPRINTS[weapon_id]
		weapon_levels[weapon_id] = 1 if weapon_id == "starter" else 0
		weapon_timers[weapon_id] = float(blueprint.get("start_timer", float(blueprint["interval"]) * 0.45))
		weapon_stats[weapon_id] = {
			"damage": float(blueprint["damage"]),
			"interval": float(blueprint["interval"]),
			"radius": float(blueprint["radius"]),
			"speed": float(blueprint.get("speed", 0.0)),
			"amount": int(blueprint.get("amount", 1)),
			"duration": float(blueprint.get("duration", 0.0)),
			"pierce": int(blueprint.get("pierce", 0)),
			"evolved": false,
		}
	weapon_stats["starter"]["interval"] = float(_char().base_interval)

func _weapon_level(weapon_id: String) -> int:
	return int(weapon_levels.get(weapon_id, 0))

func _weapon_stat(weapon_id: String, stat: String, fallback = 0.0) -> Variant:
	return weapon_stats.get(weapon_id, {}).get(stat, fallback)

func _weapon_is_evolved(weapon_id: String) -> bool:
	return bool(_weapon_stat(weapon_id, "evolved", false))

func _weapon_name(weapon_id: String) -> String:
	if weapon_id == "starter":
		return _starter_weapon_name()
	return String(WEAPON_BLUEPRINTS[weapon_id]["name"])

func _weapon_max_level(weapon_id: String) -> int:
	return _starter_max_level() if weapon_id == "starter" else 8


# ───────── 小工具 ─────────

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _add_effect(kind: String, pos: Vector2, life: float, radius: float, extra: Dictionary = {}) -> void:
	var effect := {"kind": kind, "pos": pos, "life": life, "total": life, "radius": radius}
	effect.merge(extra, true)
	effects.append(effect)

func _blink(time_value: float, frequency: float, base: float = 0.5, amp: float = 0.38) -> float:
	return base + amp * sin(time_value * frequency)

func _within(a: Vector2, b: Vector2, distance: float) -> bool:
	return a.distance_squared_to(b) <= distance * distance

func _can_add_projectile() -> bool:
	return projectiles.size() < MAX_PLAYER_PROJECTILES

func _format_countdown(value: float) -> String:
	var total := maxi(0, ceili(value))
	return "%02d:%02d" % [total / 60, total % 60]

func _show_game_notice(message: String, duration: float = 2.0) -> void:
	instruction_label.text = message
	instruction_label.visible = true
	instruction_time = duration

func _add_damage_number(pos: Vector2, amount: float, color: Color = Color.WHITE) -> void:
	if not settings.damage_numbers or amount < 1.0 or not _is_world_visible(pos, 0.0):
		return
	if damage_numbers.size() >= MAX_DAMAGE_NUMBERS:
		damage_numbers.pop_front()
	damage_numbers.append({
		"pos": pos + Vector2(rng.randf_range(-12.0, 12.0), -26.0),
		"text": str(int(amount)), "life": 0.7, "total": 0.7, "color": color,
	})

func _update_damage_numbers(delta: float) -> void:
	for index in range(damage_numbers.size() - 1, -1, -1):
		var number: Dictionary = damage_numbers[index]
		number["life"] = float(number["life"]) - delta
		number["pos"] = Vector2(number["pos"]) + Vector2(0.0, -46.0 * delta)
		if float(number["life"]) <= 0.0:
			damage_numbers.remove_at(index)


# ───────── GM 與暫停 ─────────

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

func _gm_unlock_all_weapons() -> void:
	if not run_started or game_over:
		return
	for weapon_id in WEAPON_BLUEPRINTS:
		if _weapon_level(weapon_id) <= 0:
			weapon_levels[weapon_id] = 1
		weapon_timers[weapon_id] = 0.05
	_show_game_notice("GM：已啟用十組基礎武器 Lv.1")
	_update_interface(0.0)

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
	var character_data: Dictionary = _char().data
	var weapon_lines := PackedStringArray()
	for weapon_id in WEAPON_BLUEPRINTS:
		var level_text := "已進化" if _weapon_is_evolved(weapon_id) else _weapon_level_text(_weapon_level(weapon_id), _weapon_max_level(weapon_id))
		weapon_lines.append("• %s　%s" % [_weapon_name(weapon_id), level_text])
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

func _weapon_level_text(weapon_level: int, max_level: int = 8) -> String:
	return "未取得" if weapon_level <= 0 else "Lv.%d / %d" % [weapon_level, max_level]


# ───────── 起始武器與進化 ─────────

func _starter_weapon_name() -> String:
	return String(_char().data["starter_weapon"])

func _starter_max_level() -> int:
	return int(_char().max_level)

func _starter_passive_required_level() -> int:
	return int(_char().passive_required_level)

func _starter_ring_color() -> Color:
	var color: Color = _char().data["ring_color"]
	return color

func _starter_evolution_data() -> Dictionary:
	var evolution: Dictionary = _char().evolution
	return evolution

func _starter_evolution_name() -> String:
	return String(_starter_evolution_data()["name"])

func _weapon_slot_count() -> int:
	var count := 0
	for weapon_id in weapon_levels:
		if _weapon_level(weapon_id) > 0:
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

func _starter_evolution_requirement_text() -> String:
	if _weapon_is_evolved("starter"):
		return "專屬進化：%s（完成）" % _starter_evolution_name()
	var data := _starter_evolution_data()
	var passive_id: String = data["passive_id"]
	var max_level := _starter_max_level()
	var passive_required_level := _starter_passive_required_level()
	var starter_level := _weapon_level("starter")
	var weapon_state := "完成" if starter_level >= max_level else "%d / %d" % [starter_level, max_level]
	var passive_state := "完成" if int(meta_levels[passive_id]) >= passive_required_level else "%d / %d" % [int(meta_levels[passive_id]), passive_required_level]
	var core_state := "已有" if evolution_cores_owned > 0 else "尚未取得"
	return "專屬進化：%s｜%s Lv.%d（%s）＋%s Lv.%d（%s）＋進化核心（%s）" % [
		data["name"], _starter_weapon_name(), max_level, weapon_state, data["passive_name"], passive_required_level, passive_state, core_state,
	]

func _can_evolve_starter() -> bool:
	if _weapon_is_evolved("starter") or _weapon_level("starter") < _starter_max_level() or evolution_cores_owned <= 0:
		return false
	var passive_id: String = _starter_evolution_data()["passive_id"]
	return int(meta_levels[passive_id]) >= _starter_passive_required_level()

func _can_evolve_needle() -> bool:
	return not _weapon_is_evolved("needle") and _weapon_level("needle") >= 8 and int(meta_levels["cooldown"]) >= 3 and evolution_cores_owned > 0

func _needle_evolution_requirement_text() -> String:
	if _weapon_is_evolved("needle"):
		return "共通進化：追星蜂群（完成）"
	var needle_level := _weapon_level("needle")
	var weapon_state := "完成" if needle_level >= 8 else "%d / 8" % needle_level
	var passive_state := "完成" if int(meta_levels["cooldown"]) >= 3 else "%d / 3" % int(meta_levels["cooldown"])
	var core_state := "已有" if evolution_cores_owned > 0 else "尚未取得"
	return "共通進化：追星蜂群｜星針 Lv.8（%s）＋冷卻模組 Lv.3（%s）＋進化核心（%s）" % [weapon_state, passive_state, core_state]

func _try_consume_evolution_core() -> bool:
	if _can_evolve_starter():
		evolution_cores_owned -= 1
		var starter_stats: Dictionary = weapon_stats["starter"]
		starter_stats["evolved"] = true
		_char().apply_evolution(self, starter_stats)
		_add_effect("evolution", player_pos, 1.15, float(starter_stats["radius"]), {"color": _starter_ring_color()})
		_show_game_notice("進化完成：%s" % _starter_evolution_name())
		return true
	if _can_evolve_needle():
		evolution_cores_owned -= 1
		var needle_stats: Dictionary = weapon_stats["needle"]
		needle_stats["evolved"] = true
		needle_stats["damage"] = float(needle_stats["damage"]) + 12.0
		needle_stats["interval"] = float(needle_stats["interval"]) * 0.72
		_add_effect("evolution", player_pos, 1.05, 150.0, {"color": Color(0.92, 0.52, 1.0)})
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


# ───────── 玩家與地圖寶箱 ─────────

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
		var distance := MAP_CHEST_DISTANCE + rng.randf_range(-390.0, 510.0)
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
	_add_effect("map_supply", map_object["pos"], 1.0, 112.0)
	_show_game_notice("先遣補給箱｜獲得星源經驗、重骰 +1")
	_spawn_map_object_ring(float(map_object["angle"]) + MAP_CHEST_ANGLE_SHIFT + rng.randf_range(-0.11, 0.11))
	_gain_experience(16.0 + level * 1.5)

func _update_passive_recovery(delta: float) -> void:
	if recovery_per_second <= 0.0 or player_health >= player_max_health:
		return
	player_health = minf(player_max_health, player_health + recovery_per_second * delta)

func _apply_slow(enemy: Dictionary, duration: float, factor: float) -> void:
	var remaining := float(enemy.get("slow_time", 0.0))
	var current_factor := float(enemy.get("slow_factor", 1.0))
	if remaining <= 0.0 or factor <= current_factor:
		enemy["slow_factor"] = factor
		enemy["slow_time"] = maxf(remaining, duration)
	elif remaining < duration:
		enemy["slow_factor"] = factor
		enemy["slow_time"] = duration


# ───────── 敵人生成 ─────────

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
	_show_game_notice("異變體波次 %d／%d 接近｜偵測到精英" % [index + 1, WAVE_TIMES.size()], 4.0)
	_add_effect("warning", player_pos, 1.1, 300.0)

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
	_add_effect("warning", player_pos, 1.8, 420.0)
	_show_game_notice("警告：使徒降臨", 4.0)


# ───────── 武器 ─────────

func _update_weapons(delta: float) -> void:
	for weapon_id in WEAPON_BLUEPRINTS:
		var weapon_level := _weapon_level(weapon_id)
		if weapon_level <= 0:
			continue
		weapon_timers[weapon_id] = float(weapon_timers[weapon_id]) - delta
		if float(weapon_timers[weapon_id]) <= 0.0:
			_fire_weapon(weapon_id, weapon_level)
			weapon_timers[weapon_id] = float(_weapon_stat(weapon_id, "interval")) * cooldown_scale

func _fire_weapon(weapon_id: String, weapon_level: int) -> void:
	match String(WEAPON_BLUEPRINTS[weapon_id]["pattern"]):
		"starter": _char().fire(self)
		"needle": _fire_star_needles()
		"meteor": _fire_meteor_round()
		_: _fire_blueprint_weapon(weapon_id, weapon_level)

func _fire_blueprint_weapon(weapon_id: String, weapon_level: int) -> void:
	var stats: Dictionary = weapon_stats[weapon_id]
	var damage := float(stats["damage"]) * damage_multiplier
	var radius := float(stats["radius"])
	var field_radius := radius * arsenal_area_scale
	var amount := int(stats["amount"])
	var speed := float(stats["speed"])
	var duration := float(stats["duration"])
	var pierce := int(stats["pierce"])
	match String(WEAPON_BLUEPRINTS[weapon_id]["pattern"]):
		"aimed_pierce":
			var aim := _nearest_enemy_direction()
			for shot_index in amount:
				var spread := (float(shot_index) - float(amount - 1) * 0.5) * 0.09
				_spawn_weapon_projectile(player_pos, aim.rotated(spread), speed, damage, radius, duration, weapon_id, pierce)
		"heavy_axes":
			var aim := _nearest_enemy_direction()
			for shot_index in amount:
				var spread := (float(shot_index) - float(amount - 1) * 0.5) * 0.36
				var direction := aim.rotated(spread)
				_spawn_weapon_projectile(player_pos, direction, speed, damage, radius, duration, weapon_id, pierce)
		"returning_disc":
			var aim := _nearest_enemy_direction()
			for shot_index in amount:
				var spread := (float(shot_index) - float(amount - 1) * 0.5) * 0.32
				_spawn_weapon_projectile(player_pos, aim.rotated(spread), speed, damage, radius, duration, weapon_id, pierce, true)
		"orbit":
			for enemy_index in range(enemies.size() - 1, -1, -1):
				var enemy_radius := float(enemies[enemy_index]["radius"])
				var distance := player_pos.distance_to(enemies[enemy_index]["pos"])
				if distance >= field_radius * 0.55 - enemy_radius and distance <= field_radius + enemy_radius:
					_damage_enemy(enemy_index, damage, weapon_id)
			_add_effect("arsenal_orbit", player_pos, 0.38, field_radius, {"amount": amount})
		"aura":
			for enemy_index in range(enemies.size() - 1, -1, -1):
				var enemy: Dictionary = enemies[enemy_index]
				if not _within(player_pos, enemy["pos"], field_radius + float(enemy["radius"])):
					continue
				if weapon_level >= 6:
					_apply_slow(enemy, 0.55, 0.82 if enemy["boss"] else 0.68)
				_damage_enemy(enemy_index, damage, weapon_id)
			_add_effect("arsenal_aura", player_pos, 0.42, field_radius)
		"target_area":
			for target_index in _nearest_enemy_indices(amount):
				_add_effect("arsenal_pool", enemies[target_index]["pos"], duration, field_radius, {
					"damage": damage, "damage_tick": 0.0,
					"slow_factor": 0.42 if weapon_level >= 5 else 0.56, "source": weapon_id,
				})
		"chain":
			var target_indices := _nearest_enemy_indices(amount + 1)
			var chain_points: Array[Vector2] = [player_pos]
			for target_index in target_indices:
				chain_points.append(enemies[target_index]["pos"])
			target_indices.sort()
			target_indices.reverse()
			var chain_step := 0
			for target_index in target_indices:
				_damage_enemy(target_index, damage * pow(0.9, chain_step), weapon_id)
				chain_step += 1
			_add_effect("arsenal_chain", player_pos, 0.28, radius, {"points": chain_points})

func _spawn_weapon_projectile(origin: Vector2, direction: Vector2, speed: float, damage: float, radius: float, lifetime: float, weapon_id: String, pierce_left: int = 0, returning: bool = false) -> void:
	if not _can_add_projectile():
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
		"return_at": lifetime * 0.5,
		"returning": returning,
		"pierce_left": pierce_left,
		"hit_ids": [],
		"color": _weapon_color(weapon_id),
	})

func _weapon_color(weapon_id: String) -> Color:
	match weapon_id:
		"ion_axe": return Color(1.0, 0.45, 0.16)
		"return_disc": return Color(1.0, 0.85, 0.24)
		"ricochet_ray": return Color(0.42, 1.0, 0.72)
		_: return Color(0.35, 0.82, 1.0)

func _fire_star_needles() -> void:
	if enemies.is_empty():
		return
	var needle_level := _weapon_level("needle")
	var needle_stats: Dictionary = weapon_stats["needle"]
	var needle_evolved := bool(needle_stats["evolved"])
	var shot_count := int(needle_stats["amount"]) + (2 if needle_evolved else 0)
	for enemy_index in _nearest_enemy_indices(shot_count):
		if not _can_add_projectile():
			break
		var direction := player_pos.direction_to(enemies[enemy_index]["pos"])
		projectiles.append({
			"pos": player_pos,
			"velocity": direction * (float(needle_stats["speed"]) + needle_level * 25.0 + (120.0 if needle_evolved else 0.0)),
			"damage": float(needle_stats["damage"]) * damage_multiplier * projectile_damage_multiplier,
			"source": "needle",
			"radius": (float(needle_stats["radius"]) + (2.0 if needle_evolved else 0.0)) * projectile_area_scale,
			"life": float(needle_stats["duration"]),
			"evolved": needle_evolved,
			"pierce_left": int(needle_stats["pierce"]) + (2 if needle_evolved else 0),
			"hit_ids": [],
		})

func _fire_meteor_round() -> void:
	if enemies.is_empty():
		return
	var meteor_level := _weapon_level("meteor")
	var meteor_stats: Dictionary = weapon_stats["meteor"]
	var blast_radius := float(meteor_stats["radius"])
	var blast_damage := float(meteor_stats["damage"])
	var strike_positions: Array = []
	for enemy_index in _nearest_enemy_indices(int(meteor_stats["amount"])):
		strike_positions.append(enemies[enemy_index]["pos"])
	for enemy_index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[enemy_index]
		var hit_radius: float = blast_radius + float(enemy["radius"])
		var inside_blast := false
		for strike_pos in strike_positions:
			if _within(enemy["pos"], strike_pos, hit_radius):
				inside_blast = true
				break
		if not inside_blast:
			continue
		enemy["burn_time"] = maxf(float(enemy.get("burn_time", 0.0)), (1.5 + meteor_level * 0.18) * burn_duration_multiplier)
		enemy["burn_tick"] = 0.0
		enemy["burn_damage"] = maxf(float(enemy.get("burn_damage", 0.0)), blast_damage * 0.1 * damage_multiplier)
		_damage_enemy(enemy_index, blast_damage * damage_multiplier, "meteor")
	for strike_pos in strike_positions:
		_add_effect("meteor", strike_pos, float(meteor_stats["duration"]) / maxf(0.1, float(meteor_stats["speed"])), blast_radius)

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
	return player_pos.direction_to(enemies[nearest[0]]["pos"])

func _update_projectiles(delta: float) -> void:
	for projectile_index in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[projectile_index]
		if bool(projectile.get("returning", false)) and float(projectile["life"]) <= float(projectile.get("return_at", 0.0)):
			if not bool(projectile.get("has_returned", false)):
				projectile["has_returned"] = true
				projectile["hit_ids"] = []
			var return_speed: float = maxf(300.0, Vector2(projectile["velocity"]).length())
			projectile["velocity"] = Vector2(projectile["pos"]).direction_to(player_pos) * return_speed
			if _within(projectile["pos"], player_pos, 25.0):
				projectiles.remove_at(projectile_index)
				continue
		projectile["pos"] = Vector2(projectile["pos"]) + Vector2(projectile["velocity"]) * delta
		projectile["life"] = float(projectile["life"]) - delta
		var consumed := false
		var hit_ids: Array = projectile.get("hit_ids", [])
		for enemy_index in range(enemies.size() - 1, -1, -1):
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


# ───────── 敵人狀態與 AI ─────────

func _update_enemy_statuses(delta: float) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[index]
		enemy["slow_time"] = maxf(0.0, float(enemy.get("slow_time", 0.0)) - delta)
		enemy["guarded_time"] = maxf(0.0, float(enemy.get("guarded_time", 0.0)) - delta)
		if float(enemy.get("burn_time", 0.0)) > 0.0:
			enemy["burn_time"] = maxf(0.0, float(enemy["burn_time"]) - delta)
			enemy["burn_tick"] = float(enemy.get("burn_tick", 0.0)) - delta
			if float(enemy["burn_tick"]) <= 0.0:
				enemy["burn_tick"] = 0.5
				var burn_damage: float = float(enemy.get("burn_damage", 0.0))
				_record_damage("burn", minf(burn_damage, float(enemy["hp"])))
				_add_damage_number(enemy["pos"], burn_damage, Color(1.0, 0.55, 0.2))
				enemy["hp"] = float(enemy["hp"]) - burn_damage
				enemy["flash"] = 0.08
				if enemy["boss"]:
					apostle_hp = maxf(0.0, float(enemy["hp"]))
		if float(enemy["hp"]) <= 0.0:
			_kill_enemy(index)

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
		var enemy = enemies[index]
		enemy["flash"] = maxf(0.0, float(enemy["flash"]) - delta)
		enemy["contact_cooldown"] = maxf(0.0, float(enemy["contact_cooldown"]) - delta)
		var direction: Vector2 = enemy["pos"].direction_to(player_pos)
		var status_speed := float(enemy.get("slow_factor", 1.0)) if float(enemy.get("slow_time", 0.0)) > 0.0 else 1.0
		if enemy["boss"]:
			_ai_apostle(enemy, delta * (APOSTLE_ENRAGE_TEMPO if apostle_enraged else 1.0), status_speed)
		else:
			match String(enemy["kind"]):
				"guardian": _ai_guardian(enemy, index, delta, direction, status_speed)
				"contaminant": _ai_contaminant(enemy, delta, direction, status_speed)
				"shooter": _ai_shooter(enemy, delta, direction, status_speed)
				"dasher": _ai_dasher(enemy, delta, direction, status_speed)
				_: _ai_chaser(enemy, delta, direction, status_speed)
		if not enemy["boss"] and not _within(enemy["pos"], player_pos, RECYCLE_DISTANCE):
			enemy["pos"] = _offscreen_spawn_position()
			enemy["dash_time"] = 0.0
			enemy["dash_charge"] = 0.0
		if float(enemy["contact_cooldown"]) <= 0.0 and _within(enemy["pos"], player_pos, float(enemy["radius"]) + 18.0):
			var contact_damage := 22.0 if enemy["boss"] else (14.0 if enemy["kind"] == "tank" else (11.0 if enemy["elite"] else 7.0))
			_take_player_damage(contact_damage)
			enemy["contact_cooldown"] = 0.75

func _ai_chaser(enemy: Dictionary, delta: float, direction: Vector2, status_speed: float) -> void:
	enemy["pos"] += direction * float(enemy["speed"]) * status_speed * delta

func _ai_guardian(enemy: Dictionary, index: int, delta: float, direction: Vector2, status_speed: float) -> void:
	_ai_chaser(enemy, delta, direction, status_speed)
	enemy["support_cooldown"] = float(enemy.get("support_cooldown", 0.0)) - delta
	if float(enemy["support_cooldown"]) > 0.0:
		return
	for ally_index in enemies.size():
		if ally_index == index or bool(enemies[ally_index].get("boss", false)):
			continue
		if _within(enemy["pos"], enemies[ally_index]["pos"], 140.0):
			var ally: Dictionary = enemies[ally_index]
			ally["guarded_time"] = maxf(float(ally.get("guarded_time", 0.0)), 1.1)
	enemy["support_cooldown"] = 0.75

func _ai_contaminant(enemy: Dictionary, delta: float, direction: Vector2, status_speed: float) -> void:
	if not _within(enemy["pos"], player_pos, 220.0):
		_ai_chaser(enemy, delta, direction, status_speed)
	else:
		enemy["pos"] += direction.rotated(PI * 0.5) * float(enemy["speed"]) * 0.35 * status_speed * delta
	enemy["contamination_cooldown"] = float(enemy.get("contamination_cooldown", 0.0)) - delta
	if float(enemy["contamination_cooldown"]) <= 0.0:
		_add_effect("contamination", enemy["pos"], 4.2, 58.0, {"damage_tick": 0.0})
		enemy["contamination_cooldown"] = 3.4

func _ai_shooter(enemy: Dictionary, delta: float, direction: Vector2, status_speed: float) -> void:
	if float(enemy.get("shot_charge", 0.0)) > 0.0:
		enemy["shot_charge"] = float(enemy["shot_charge"]) - delta
		if float(enemy["shot_charge"]) <= 0.0:
			enemy["shot_charge"] = 0.0
			_fire_mutant_shot(enemy["pos"], enemy["shot_dir"])
			enemy["attack_cooldown"] = rng.randf_range(2.1, 2.8)
		return
	var distance_squared: float = enemy["pos"].distance_squared_to(player_pos)
	if distance_squared > 136900.0:
		_ai_chaser(enemy, delta, direction, status_speed)
	elif distance_squared < 60025.0:
		enemy["pos"] -= direction * float(enemy["speed"]) * status_speed * delta
	else:
		enemy["pos"] += direction.rotated(PI * 0.5) * float(enemy["speed"]) * 0.45 * status_speed * delta
	enemy["attack_cooldown"] = float(enemy["attack_cooldown"]) - delta
	if float(enemy["attack_cooldown"]) <= 0.0 and status_speed > 0.0:
		enemy["shot_dir"] = direction
		enemy["shot_charge"] = 0.52

func _ai_dasher(enemy: Dictionary, delta: float, direction: Vector2, status_speed: float) -> void:
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
		_ai_chaser(enemy, delta, direction, status_speed)
		if float(enemy["dash_cooldown"]) <= 0.0:
			enemy["dash_dir"] = direction
			enemy["dash_charge"] = 0.48

func _ai_apostle(enemy: Dictionary, delta: float, status_speed: float) -> void:
	var hp_ratio: float = float(enemy["hp"]) / maxf(1.0, float(enemy["max_hp"]))
	if int(enemy.get("phase", 1)) == 1 and hp_ratio <= 0.5:
		enemy["phase"] = 2
		enemy["phase_transition"] = 1.15
		enemy["attack_cooldown"] = 0.75
		enemy["speed"] = float(enemy["speed"]) * 1.16
		enemy["summon_cooldown"] = 3.0
		apostle_phase = 2
		hostile_projectiles.clear()
		_add_effect("apostle_phase", enemy["pos"], 1.15, 230.0)
		_show_game_notice("使徒進入第二階段：攻擊模式改變")
	if float(enemy.get("phase_transition", 0.0)) > 0.0:
		enemy["phase_transition"] = maxf(0.0, float(enemy["phase_transition"]) - delta)
		return
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
		var phase_two := int(enemy.get("phase", 1)) >= 2
		for summon_index in (3 if phase_two else 5):
			_spawn_mutant("chaser" if summon_index % 2 == 0 else "dasher")
		enemy["summon_cooldown"] = 8.5 if phase_two else 7.0

func _fire_apostle_burst(origin: Vector2, angle_offset: float = 0.0) -> void:
	var projectile_count := 12
	for index in projectile_count:
		if hostile_projectiles.size() >= MAX_HOSTILE_PROJECTILES:
			break
		var angle := TAU * float(index) / float(projectile_count) + angle_offset
		hostile_projectiles.append({
			"pos": origin, "velocity": Vector2.from_angle(angle) * 185.0,
			"radius": 9.0, "damage": 10.0, "life": 6.0,
		})

func _fire_apostle_fan(origin: Vector2, locked_direction: Vector2) -> void:
	var base_direction := locked_direction.normalized()
	if base_direction == Vector2.ZERO:
		base_direction = origin.direction_to(player_pos)
	for projectile_index in 7:
		if hostile_projectiles.size() >= MAX_HOSTILE_PROJECTILES:
			break
		var shot_direction := base_direction.rotated(lerpf(-0.62, 0.62, float(projectile_index) / 6.0))
		hostile_projectiles.append({
			"kind": "fan", "pos": origin, "velocity": shot_direction * 275.0,
			"radius": 10.0, "damage": 12.0, "life": 5.0,
		})

func _create_apostle_hazards(center: Vector2, cast_direction: Vector2) -> void:
	var perpendicular := cast_direction.normalized().rotated(PI * 0.5)
	if perpendicular == Vector2.ZERO:
		perpendicular = Vector2.UP
	for offset in [Vector2.ZERO, perpendicular * 112.0, perpendicular * -112.0]:
		_add_effect("apostle_hazard", center + offset, 4.0, 76.0, {"arm_time": 0.62, "damage_tick": 0.0})

func _fire_mutant_shot(origin: Vector2, locked_direction: Vector2 = Vector2.ZERO) -> void:
	if hostile_projectiles.size() >= MAX_HOSTILE_PROJECTILES:
		return
	var direction := locked_direction.normalized()
	if direction == Vector2.ZERO:
		direction = origin.direction_to(player_pos)
	hostile_projectiles.append({
		"pos": origin, "velocity": direction * 255.0,
		"radius": 7.0, "damage": 8.0, "life": 5.0,
	})

func _update_hostile_projectiles(delta: float) -> void:
	for index in range(hostile_projectiles.size() - 1, -1, -1):
		var projectile = hostile_projectiles[index]
		projectile["pos"] += projectile["velocity"] * delta
		projectile["life"] -= delta
		if _within(projectile["pos"], player_pos, float(projectile["radius"]) + 17.0):
			_take_player_damage(float(projectile["damage"]))
			hostile_projectiles.remove_at(index)
		elif float(projectile["life"]) <= 0.0:
			hostile_projectiles.remove_at(index)


# ───────── 傷害與擊殺 ─────────

func _record_damage(source: String, amount: float) -> void:
	if amount <= 0.0:
		return
	total_damage_dealt += amount
	damage_by_source[source] = float(damage_by_source.get(source, 0.0)) + amount

func _damage_source_name(source: String) -> String:
	if WEAPON_BLUEPRINTS.has(source):
		if source == "starter" and _weapon_is_evolved("starter"):
			return _starter_evolution_name()
		if source == "needle" and _weapon_is_evolved("needle"):
			return "追星蜂群"
		return _weapon_name(source)
	return "燃燒" if source == "burn" else "其他"

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
	_add_damage_number(enemy["pos"], amount, Color(1.0, 0.86, 0.3) if enemy["elite"] else Color.WHITE)
	var elite_shield: float = float(enemy.get("elite_shield", 0.0))
	if elite_shield > 0.0:
		var shield_absorbed := minf(amount, elite_shield)
		enemy["elite_shield"] = elite_shield - shield_absorbed
		_record_damage(source, shield_absorbed)
		amount -= shield_absorbed
		enemy["flash"] = 0.08
		if float(enemy["elite_shield"]) <= 0.0:
			_add_effect("shield_break", enemy["pos"], 0.35, float(enemy["radius"]) + 18.0)
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
	var death_pos: Vector2 = enemy["pos"]
	var split_count := 3 if bool(enemy.get("elite", false)) else 2
	if not was_boss:
		_drop_experience_gem(death_pos, 8.0 if enemy["elite"] else 1.0)
		if enemy["elite"]:
			_drop_repair_core(death_pos)
			_drop_evolution_core(death_pos)
			_drop_elite_chest(death_pos)
	kills += 1
	_add_effect("burst", death_pos, 0.24, float(enemy["radius"]) * 2.2)
	enemies.remove_at(index)
	if was_explosive and not was_boss:
		_add_effect("elite_explosion", death_pos, 0.75, 104.0, {"damage": 18.0})
	if was_splitter and not was_boss:
		_spawn_splitlings(death_pos, split_count)
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

func _drop_experience_gem(pos: Vector2, value: float) -> void:
	if gems.size() < MAX_GEMS:
		gems.append({"pos": pos, "value": value})
		return
	var receiver = gems[gems.size() - 1]
	receiver["value"] = float(receiver["value"]) + value

func _drop_repair_core(pos: Vector2) -> void:
	if repair_cores.size() < MAX_REPAIR_CORES:
		repair_cores.append({"pos": pos, "heal": 24.0})
		return
	var receiver = repair_cores[repair_cores.size() - 1]
	receiver["heal"] = minf(72.0, float(receiver["heal"]) + 8.0)

func _drop_evolution_core(pos: Vector2) -> void:
	if (_weapon_is_evolved("starter") and _weapon_is_evolved("needle")) or evolution_cores_owned > 0:
		return
	if evolution_cores.size() >= MAX_EVOLUTION_CORES:
		return
	evolution_cores.append({"pos": pos + Vector2(22.0, -8.0)})

func _drop_elite_chest(pos: Vector2) -> void:
	if elite_chests.size() >= MAX_ELITE_CHESTS:
		pending_elite_rewards += 1
		return
	elite_chests.append({"pos": pos + Vector2(-22.0, 8.0), "pulse": rng.randf_range(0.0, TAU)})

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
	_add_effect("hurt", player_pos, 0.28, 54.0)
	if player_health <= 0.0:
		player_health = 0.0
		_finish_game(false)


# ───────── 拾取物 ─────────

func _magnet_pickup(item: Dictionary, magnet_range: float, base_pull: float, pull_gain: float, collect_radius: float, delta: float) -> bool:
	var item_pos: Vector2 = item["pos"]
	var distance := item_pos.distance_to(player_pos)
	if distance <= magnet_range:
		item_pos = item_pos.move_toward(player_pos, (base_pull + (magnet_range - distance) * pull_gain) * delta)
		item["pos"] = item_pos
	return _within(item_pos, player_pos, collect_radius)

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
			_add_effect("elite_chest", player_pos, 0.7, 92.0)
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
	_add_effect("repair", player_pos, 0.55, 72.0)


# ───────── 升級與獎勵選擇 ─────────

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
	if evolution_cores_owned <= 0 and (not _weapon_is_evolved("starter") or not _weapon_is_evolved("needle")):
		result.append({"id": "evolution_core", "name": "進化核心", "description": "取得 1 枚進化核心；達成條件時自動完成進化"})
	return result

func _select_elite_reward(reward_id: String) -> void:
	match reward_id:
		"weapon_tuning":
			var starter_stats: Dictionary = weapon_stats["starter"]
			starter_stats["damage"] = float(starter_stats["damage"]) + 8.0
			starter_stats["radius"] = float(starter_stats["radius"]) * 1.05
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
	return WEAPON_BLUEPRINTS.has(upgrade_id)

func _reroll_upgrades() -> void:
	if not choosing_upgrade or rerolls_remaining <= 0:
		return
	rerolls_remaining -= 1
	_show_upgrade_choices()

func _available_upgrades() -> Array:
	var result: Array = []
	for weapon_id in WEAPON_BLUEPRINTS:
		var weapon_level := _weapon_level(weapon_id)
		if weapon_level < _weapon_max_level(weapon_id) and (weapon_id == "starter" or _can_offer_common_weapon(weapon_level)):
			result.append({
				"id": weapon_id,
				"name": "%s Lv.%d" % [_weapon_name(weapon_id), weapon_level + 1],
				"description": _weapon_upgrade_description(weapon_id, weapon_level + 1),
			})
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

func _weapon_upgrade_description(weapon_id: String, next_level: int) -> String:
	var blueprint: Dictionary = WEAPON_BLUEPRINTS[weapon_id]
	if next_level == 1:
		return "取得武器：%s" % blueprint["description"]
	if weapon_id == "starter":
		return _char().upgrade_description(self, next_level)
	var level_effects: Dictionary = blueprint.get("level_effects", {}).get(next_level, {})
	if not level_effects.is_empty():
		return _describe_weapon_effects(level_effects)
	if next_level in [3, 6]:
		return String(blueprint.get("scale_text", "增加數量或範圍"))
	if LEVEL_TEXT.has(next_level):
		return String(LEVEL_TEXT[next_level])
	return "強化%s" % blueprint["name"]

func _describe_weapon_effects(level_effects: Dictionary) -> String:
	var descriptions := PackedStringArray()
	if level_effects.has("damage"):
		descriptions.append("傷害 +%g" % float(level_effects["damage"]))
	if level_effects.has("amount"):
		descriptions.append("數量 +%d" % int(level_effects["amount"]))
	if level_effects.has("interval"):
		descriptions.append("冷卻縮短 %.1f 秒" % absf(float(level_effects["interval"])))
	if level_effects.has("radius_pct"):
		descriptions.append("範圍 +%d%%" % roundi(float(level_effects["radius_pct"]) * 100.0))
	if level_effects.has("speed_pct"):
		descriptions.append("速度 +%d%%" % roundi(float(level_effects["speed_pct"]) * 100.0))
	if level_effects.has("duration"):
		descriptions.append("持續時間 +%.1f 秒" % float(level_effects["duration"]))
	if level_effects.has("pierce"):
		descriptions.append("穿透 +%d" % int(level_effects["pierce"]))
	return "、".join(descriptions)

func _select_upgrade(upgrade_id: String) -> void:
	if WEAPON_BLUEPRINTS.has(upgrade_id):
		_apply_weapon_upgrade(upgrade_id)
	else:
		_apply_standard_upgrade(upgrade_id)
	_try_consume_evolution_core()
	pending_levels = maxi(0, pending_levels - 1)
	_advance_choice_queue()

func _apply_weapon_upgrade(weapon_id: String) -> void:
	var next_level := mini(_weapon_max_level(weapon_id), _weapon_level(weapon_id) + 1)
	weapon_levels[weapon_id] = next_level
	weapon_timers[weapon_id] = 0.05
	if weapon_id == "starter":
		_char().apply_upgrade(self, next_level)
		return
	var level_effects: Dictionary = WEAPON_BLUEPRINTS[weapon_id].get("level_effects", {}).get(next_level, {})
	_apply_weapon_level_effect(weapon_stats[weapon_id], level_effects)

func _apply_weapon_level_effect(stats: Dictionary, level_effects: Dictionary) -> void:
	if level_effects.has("damage"):
		stats["damage"] = float(stats["damage"]) + float(level_effects["damage"])
	if level_effects.has("amount"):
		stats["amount"] = int(stats["amount"]) + int(level_effects["amount"])
	if level_effects.has("interval"):
		stats["interval"] = maxf(0.05, float(stats["interval"]) + float(level_effects["interval"]))
	if level_effects.has("radius_pct"):
		stats["radius"] = float(stats["radius"]) * (1.0 + float(level_effects["radius_pct"]))
	if level_effects.has("speed_pct"):
		stats["speed"] = float(stats["speed"]) * (1.0 + float(level_effects["speed_pct"]))
	if level_effects.has("duration"):
		stats["duration"] = float(stats["duration"]) + float(level_effects["duration"])
	if level_effects.has("pierce"):
		stats["pierce"] = int(stats["pierce"]) + int(level_effects["pierce"])

func _apply_standard_upgrade(upgrade_id: String) -> void:
	if meta_levels.has(upgrade_id):
		meta_levels[upgrade_id] = int(meta_levels[upgrade_id]) + 1
	match upgrade_id:
		"health":
			player_max_health += 15.0
			player_health = minf(player_max_health, player_health + 15.0)
		"speed": player_speed *= 1.08
		"pickup": pickup_radius += 25.0
		"armor": player_armor += 1.0
		"damage": damage_multiplier *= 1.12
		"cooldown": cooldown_scale *= 0.94
		"area":
			weapon_stats["starter"]["radius"] = float(weapon_stats["starter"]["radius"]) + 12.0
			weapon_stats["meteor"]["radius"] = float(weapon_stats["meteor"]["radius"]) + 8.0
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


# ───────── 特效更新與上限 ─────────

func _update_effects(delta: float) -> void:
	for index in range(effects.size() - 1, -1, -1):
		var effect = effects[index]
		effect["life"] = float(effect["life"]) - delta
		match String(effect.get("kind", "")):
			"arsenal_pool":
				effect["damage_tick"] = float(effect.get("damage_tick", 0.0)) - delta
				if float(effect["damage_tick"]) <= 0.0:
					var pool_source := String(effect.get("source", "other"))
					var pool_slow := float(effect.get("slow_factor", 0.56))
					for enemy_index in range(enemies.size() - 1, -1, -1):
						var enemy: Dictionary = enemies[enemy_index]
						if not _within(effect["pos"], enemy["pos"], float(effect["radius"]) + float(enemy["radius"])):
							continue
						_apply_slow(enemy, 0.72, maxf(0.35, pool_slow) if enemy["boss"] else pool_slow)
						_damage_enemy(enemy_index, float(effect.get("damage", 8.0)), pool_source)
					effect["damage_tick"] = 0.45
			"contamination":
				effect["damage_tick"] = float(effect.get("damage_tick", 0.0)) - delta
				if float(effect["damage_tick"]) <= 0.0 and _within(player_pos, effect["pos"], float(effect["radius"]) + 16.0):
					_take_player_damage(8.0)
					effect["damage_tick"] = 0.7
			"apostle_hazard":
				effect["arm_time"] = maxf(0.0, float(effect.get("arm_time", 0.0)) - delta)
				if float(effect["arm_time"]) <= 0.0:
					effect["damage_tick"] = float(effect.get("damage_tick", 0.0)) - delta
					if float(effect["damage_tick"]) <= 0.0 and _within(player_pos, effect["pos"], float(effect["radius"]) + 16.0):
						_take_player_damage(11.0)
						effect["damage_tick"] = 0.65
			"elite_explosion":
				if float(effect["life"]) <= 0.0 and _within(player_pos, effect["pos"], float(effect["radius"]) + 16.0):
					_take_player_damage(float(effect.get("damage", 18.0)))
		if float(effect["life"]) <= 0.0:
			effects.remove_at(index)

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
	while repair_cores.size() > MAX_REPAIR_CORES:
		var overflow_core = repair_cores.pop_back()
		var core_receiver = repair_cores[repair_cores.size() - 1]
		core_receiver["heal"] = minf(72.0, float(core_receiver["heal"]) + float(overflow_core["heal"]))


# ───────── HUD 與結算 ─────────

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
	time_label.text = "星蝕荒原　區域 1 / 1\n%02d:%02d" % [int(game_time) / 60, int(game_time) % 60]
	var character_data: Dictionary = _char().data
	stats_label.text = "%s　Lv.%d\n生命 %d / %d　護盾 %d\n護甲 %d　擊殺 %d" % [
		character_data["name"], level,
		ceili(player_health), ceili(player_max_health), ceili(player_shield),
		int(player_armor), kills,
	]
	var threat_level := mini(5, 1 + int(game_time / 60.0))
	var next_wave_text := "已完成" if wave_index >= WAVE_TIMES.size() else _format_countdown(maxf(0.0, float(WAVE_TIMES[wave_index]) - game_time))
	enemy_label.text = "異變體 %d　威脅 Lv.%d\n波次 %d / %d　下一波 %s\n使徒降臨 %s" % [
		enemies.size(), threat_level, wave_index, WAVE_TIMES.size(), next_wave_text,
		("戰鬥中" if apostle_spawned else _format_countdown(maxf(0.0, APOSTLE_TIME - game_time))),
	]
	var active_weapons: Array[String] = []
	for weapon_id in WEAPON_BLUEPRINTS:
		var weapon_level := _weapon_level(weapon_id)
		if weapon_level <= 0:
			continue
		var evolved := _weapon_is_evolved(weapon_id)
		var display_name := _weapon_name(weapon_id)
		if evolved:
			display_name = _starter_evolution_name() if weapon_id == "starter" else "追星蜂群"
		active_weapons.append("%s %s" % [display_name, "進化" if evolved else "Lv.%d" % weapon_level])
	weapon_label.text = "｜".join(active_weapons.slice(0, 3))
	if active_weapons.size() > 3:
		weapon_label.text += "\n" + "｜".join(active_weapons.slice(3))
	var skill_name: String = _starter_evolution_name() if _weapon_is_evolved("starter") else character_data["skill_name"]
	skill_label.text = "自動能力｜%s\n每 %.1f 秒發動" % [skill_name, float(_weapon_stat("starter", "interval")) * cooldown_scale]
	skill_label.modulate = _starter_ring_color()
	xp_bar.max_value = experience_required
	xp_bar.value = experience
	boss_bar.visible = apostle_present
	boss_label.visible = apostle_present
	if apostle_present:
		boss_bar.max_value = apostle_max_hp
		boss_bar.value = apostle_hp
		boss_label.text = "使徒｜第 %d 階段%s" % [apostle_phase, "｜狂暴" if apostle_enraged else ""]

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
		_format_countdown(game_time), kills, level,
		int(total_damage_dealt), int(total_damage_taken),
		_damage_breakdown_text(),
		("方舟防線暫時安全。" if victory else "重新調整強化後再次出擊。"),
	]


# ───────── 繪圖 ─────────

func _draw() -> void:
	_draw_background()
	_draw_effect_layer(true)
	_draw_pickups()
	_draw_units_y_sorted()
	_draw_player_projectiles()
	_draw_hostile_projectiles()
	_draw_effect_layer(false)
	_draw_damage_numbers()
	_draw_map_object_indicator()

func _draw_effect_layer(ground_layer: bool) -> void:
	for effect in effects:
		if GROUND_EFFECT_KINDS.has(effect.get("kind", "")) != ground_layer:
			continue
		if not _is_world_visible(effect["pos"], float(effect.get("radius", 0.0)) + 48.0):
			continue
		_draw_effect(effect)

func _draw_damage_numbers() -> void:
	if not run_started or damage_numbers.is_empty():
		return
	var font: Font = ui_theme.default_font
	for number in damage_numbers:
		var alpha := clampf(float(number["life"]) / float(number["total"]) * 1.6, 0.0, 1.0)
		var color: Color = number["color"]
		var text_pos: Vector2 = number["pos"]
		draw_string_outline(font, text_pos, String(number["text"]), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 20, 5, Color(0.0, 0.0, 0.0, alpha))
		draw_string(font, text_pos, String(number["text"]), HORIZONTAL_ALIGNMENT_CENTER, 80.0, 20, Color(color, alpha))

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
		var chest_rect := Rect2(chest_pos + Vector2(-17.0, -10.0) * chest_pulse, Vector2(34.0, 24.0) * chest_pulse)
		draw_circle(chest_pos, 25.0 * chest_pulse, Color(1.0, 0.72, 0.16, 0.15))
		draw_rect(chest_rect, Color(0.18, 0.12, 0.28), true)
		draw_rect(chest_rect, Color(1.0, 0.72, 0.2), false, 4.0)
		draw_line(chest_pos + Vector2(-17.0, -2.0), chest_pos + Vector2(17.0, -2.0), Color(1.0, 0.9, 0.45), 4.0, true)
		draw_circle(chest_pos + Vector2(0.0, 4.0), 4.0, Color(0.48, 0.95, 1.0))

func _draw_player_projectiles() -> void:
	for projectile in projectiles:
		var pos: Vector2 = projectile["pos"]
		if not _is_world_visible(pos, 48.0):
			continue
		var direction: Vector2 = Vector2(projectile["velocity"]).normalized()
		var radius := float(projectile["radius"])
		if projectile.get("kind", "") == "fireball":
			var fireball_color: Color = projectile.get("color", Color(1.0, 0.42, 0.16))
			draw_line(pos - direction * 18.0, pos, Color(fireball_color, 0.48), 8.0, true)
			draw_circle(pos, radius, fireball_color)
			draw_circle(pos, radius * 0.46, fireball_color.lightened(0.55))
		elif projectile.get("kind", "") == "arsenal":
			var arsenal_color: Color = projectile.get("color", Color(0.35, 0.82, 1.0))
			match projectile.get("weapon_id", ""):
				"ion_axe":
					var side := direction.rotated(PI * 0.5) * radius
					draw_colored_polygon(PackedVector2Array([pos + direction * 15.0, pos + side, pos - direction * 15.0, pos - side]), arsenal_color)
					draw_arc(pos, radius + 4.0, game_time * 7.0, game_time * 7.0 + 4.7, 16, Color(1.0, 0.82, 0.36, 0.8), 3.0, true)
				"return_disc":
					draw_arc(pos, radius + 5.0, game_time * 9.0, game_time * 9.0 + 5.2, 20, arsenal_color, 6.0, true)
					draw_circle(pos, 3.0, Color(1.0, 1.0, 0.78))
				_:
					draw_line(pos - direction * 14.0, pos + direction * 7.0, Color(arsenal_color, 0.42), maxf(4.0, radius * 0.7), true)
					draw_circle(pos, radius, arsenal_color)
		else:
			var evolved := bool(projectile.get("evolved", false))
			var projectile_color := Color(0.95, 0.62, 1.0) if evolved else Color(0.5, 0.95, 1.0)
			draw_line(pos - direction * (14.0 if evolved else 10.0), pos + direction * 7.0, projectile_color, 7.0 if evolved else 5.0, true)

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

func _draw_sprite_billboard(texture: Texture2D, feet_position: Vector2, target_height: float, tint: Color = Color.WHITE, lift: float = 0.0) -> void:
	if texture == null:
		return
	var texture_size := texture.get_size()
	var target_width := target_height * texture_size.x / maxf(1.0, texture_size.y)
	var rect := Rect2(feet_position.x - target_width * 0.5, feet_position.y - target_height + 12.0 - lift, target_width, target_height)
	draw_texture_rect(texture, rect, false, tint)

func _draw_enemy(enemy: Dictionary) -> void:
	if enemy["boss"]:
		_draw_boss(enemy)
		return
	var position: Vector2 = enemy["pos"]
	var radius: float = enemy["radius"]
	var low_detail := enemies.size() >= LOW_DETAIL_ENEMY_COUNT
	var tint := Color.WHITE
	if float(enemy["flash"]) > 0.0:
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
				var telegraph_alpha := _blink(float(enemy["dash_charge"]), 30.0, 0.45, 0.4)
				var dash_direction: Vector2 = enemy.get("dash_dir", Vector2.RIGHT)
				draw_line(position, position + dash_direction * (130.0 if low_detail else 165.0), Color(1.0, 0.42, 0.12, telegraph_alpha), 5.0 if low_detail else 7.0, true)
				if not low_detail:
					draw_arc(position, radius + 8.0, 0.0, TAU, 24, Color(1.0, 0.75, 0.2, telegraph_alpha), 4.0, true)
		"shooter":
			if float(enemy.get("shot_charge", 0.0)) > 0.0:
				var aim_alpha := _blink(float(enemy["shot_charge"]), 28.0, 0.45, 0.4)
				var shot_direction: Vector2 = enemy.get("shot_dir", Vector2.RIGHT)
				draw_line(position, position + shot_direction * (320.0 if low_detail else 520.0), Color(0.78, 0.35, 1.0, aim_alpha), 2.0 if low_detail else 3.0, true)
				if not low_detail:
					draw_arc(position, radius + 7.0, 0.0, TAU, 22, Color(0.9, 0.62, 1.0, aim_alpha), 3.0, true)
		"contaminant":
			draw_arc(position, radius + 4.0, game_time * 1.4, game_time * 1.4 + 4.8, 24, Color(0.72, 1.0, 0.35), 4.0, true)
	if enemy["elite"]:
		_draw_elite_marks(enemy, low_detail)
	if float(enemy.get("guarded_time", 0.0)) > 0.0:
		draw_arc(position, radius + 7.0, 0.0, TAU, 28, Color(0.3, 0.82, 1.0, 0.82), 3.0, true)

func _draw_elite_marks(enemy: Dictionary, low_detail: bool) -> void:
	var position: Vector2 = enemy["pos"]
	var radius: float = enemy["radius"]
	var affix: String = enemy.get("elite_affix", "")
	var affix_color := Color(1.0, 0.86, 0.22)
	match affix:
		"swift": affix_color = Color(1.0, 0.52, 0.12)
		"shielded": affix_color = Color(0.28, 0.82, 1.0)
		"explosive": affix_color = Color(1.0, 0.18, 0.28)
	draw_arc(position, radius + 5.0, 0.0, TAU, 24, affix_color, 3.0)
	if affix == "swift" and not low_detail:
		var trail_direction: Vector2 = position.direction_to(player_pos)
		draw_line(position - trail_direction * (radius + 8.0), position - trail_direction * (radius + 34.0), Color(affix_color, 0.7), 5.0, true)
	elif affix == "shielded" and float(enemy.get("elite_shield", 0.0)) > 0.0:
		draw_arc(position, radius + 10.0, -0.6, 4.6, 28, Color(affix_color, 0.88), 5.0, true)
	elif affix == "explosive" and not low_detail:
		draw_circle(position, 5.0 + 2.0 * sin(game_time * 9.0), affix_color)
	var hp_ratio: float = float(enemy["hp"]) / float(enemy["max_hp"])
	draw_rect(Rect2(position + Vector2(-radius, -radius - 11.0), Vector2(radius * 2.0, 4.0)), Color(0.18, 0.03, 0.08))
	draw_rect(Rect2(position + Vector2(-radius, -radius - 11.0), Vector2(radius * 2.0 * hp_ratio, 4.0)), Color(1.0, 0.75, 0.22))

func _draw_boss(enemy: Dictionary) -> void:
	var position: Vector2 = enemy["pos"]
	var radius: float = enemy["radius"]
	var flash: bool = float(enemy["flash"]) > 0.0
	var boss_color := (Color(1.0, 0.16, 0.22) if int(enemy.get("phase", 1)) >= 2 else Color(1.0, 0.24, 0.52)) if not flash else Color.WHITE
	draw_ellipse_shadow(position + Vector2(0.0, 13.0), 82.0, 25.0, Color(0.01, 0.015, 0.02, 0.58))
	draw_circle(position, radius + 12.0, Color(boss_color, 0.14))
	draw_arc(position, radius + 16.0, game_time * 0.5, game_time * 0.5 + TAU * 0.78, 48, boss_color, 6.0, true)
	_draw_sprite_billboard(ANUBARAK_TEXTURE, position + Vector2(0.0, 20.0), 178.0, Color(1.7, 1.7, 1.7, 1.0) if flash else Color.WHITE)
	var burst_charge: float = float(enemy.get("burst_charge", 0.0))
	if burst_charge > 0.0:
		var charge_progress := clampf(1.0 - burst_charge / 0.85, 0.0, 1.0)
		var charge_alpha := _blink(burst_charge, 34.0, 0.52)
		draw_arc(position, radius + 86.0 - charge_progress * 48.0, 0.0, TAU, 64, Color(1.0, 0.2, 0.5, charge_alpha), 8.0, true)
		var burst_angle: float = float(enemy.get("burst_angle", 0.0))
		for warning_spoke in 12:
			var warning_direction := Vector2.from_angle(burst_angle + TAU * float(warning_spoke) / 12.0)
			draw_line(position + warning_direction * (radius + 8.0), position + warning_direction * (radius + 150.0), Color(1.0, 0.3, 0.58, charge_alpha * 0.72), 3.0, true)
	var phase_transition: float = float(enemy.get("phase_transition", 0.0))
	if phase_transition > 0.0:
		var phase_progress := 1.0 - phase_transition / 1.15
		draw_circle(position, radius + 110.0 * phase_progress, Color(1.0, 0.08, 0.16, 0.12))
		draw_arc(position, radius + 110.0 * phase_progress, 0.0, TAU, 64, Color(1.0, 0.18, 0.12, 0.95 - phase_progress * 0.4), 10.0, true)
	var fan_charge: float = float(enemy.get("fan_charge", 0.0))
	if fan_charge > 0.0:
		var fan_direction: Vector2 = enemy.get("fan_dir", Vector2.RIGHT)
		var fan_alpha := _blink(fan_charge, 30.0)
		for edge_angle in [-0.62, 0.62]:
			draw_line(position, position + fan_direction.rotated(edge_angle) * 330.0, Color(1.0, 0.48, 0.12, fan_alpha), 5.0, true)
		draw_arc(position, 180.0, fan_direction.angle() - 0.62, fan_direction.angle() + 0.62, 30, Color(1.0, 0.48, 0.12, fan_alpha), 4.0, true)
	var boss_dash_charge: float = float(enemy.get("boss_dash_charge", 0.0))
	if boss_dash_charge > 0.0:
		var boss_dash_direction: Vector2 = enemy.get("boss_dash_dir", Vector2.RIGHT)
		var dash_alpha := _blink(boss_dash_charge, 34.0)
		draw_line(position, position + boss_dash_direction * 470.0, Color(1.0, 0.18, 0.12, dash_alpha), 13.0, true)
		draw_line(position, position + boss_dash_direction * 470.0, Color(1.0, 0.72, 0.22, dash_alpha), 4.0, true)
	var hazard_charge: float = float(enemy.get("hazard_charge", 0.0))
	if hazard_charge > 0.0:
		var hazard_target: Vector2 = enemy.get("hazard_target", player_pos)
		var hazard_perpendicular := position.direction_to(hazard_target).rotated(PI * 0.5)
		var hazard_alpha := _blink(hazard_charge, 30.0)
		for hazard_offset in [Vector2.ZERO, hazard_perpendicular * 112.0, hazard_perpendicular * -112.0]:
			draw_circle(hazard_target + hazard_offset, 76.0, Color(1.0, 0.12, 0.36, hazard_alpha * 0.12))
			draw_arc(hazard_target + hazard_offset, 76.0, 0.0, TAU, 42, Color(1.0, 0.3, 0.48, hazard_alpha), 5.0, true)
	if float(enemy.get("burn_time", 0.0)) > 0.0:
		draw_arc(position, radius + 12.0, -1.2, 2.2, 24, Color(1.0, 0.38, 0.08, 0.9), 5.0, true)
	if float(enemy.get("slow_time", 0.0)) > 0.0:
		draw_arc(position, radius + 15.0, 0.0, TAU, 36, Color(0.42, 0.82, 1.0, 0.9), 5.0, true)

func _draw_effect(effect: Dictionary) -> void:
	var progress := 1.0 - float(effect["life"]) / float(effect["total"])
	var alpha := 1.0 - progress
	var pos: Vector2 = effect["pos"]
	var radius := float(effect["radius"])
	match effect["kind"]:
		"burst":
			draw_circle(pos, radius * progress, Color(1.0, 0.32, 0.48, alpha * 0.6))
		"hurt":
			draw_arc(pos, radius * (0.6 + progress), 0.0, TAU, 32, Color(1.0, 0.2, 0.28, alpha), 8.0)
		"warning":
			draw_arc(pos, radius * (0.7 + 0.3 * progress), 0.0, TAU, 64, Color(1.0, 0.12, 0.4, alpha), 9.0)
		"evolution":
			var evolution_color: Color = effect.get("color", Color(0.4, 0.92, 1.0))
			var evolution_radius := radius * (0.18 + progress * 0.82)
			draw_circle(pos, evolution_radius, Color(evolution_color, alpha * 0.08))
			draw_arc(pos, evolution_radius, 0.0, TAU, 72, Color(evolution_color.lightened(0.35), alpha), 12.0, true)
			draw_arc(pos, evolution_radius * 0.72, -progress * TAU, (1.0 - progress) * TAU, 56, Color(1.0, 0.82, 0.28, alpha), 6.0, true)
		"slash":
			var slash_color: Color = effect.get("color", Color(1.0, 0.55, 0.65))
			var slash_angle: float = float(effect.get("angle", 0.0))
			draw_arc(pos, radius * (0.55 + 0.45 * progress), slash_angle - 1.25, slash_angle + 1.25, 40, Color(slash_color, alpha), 12.0, true)
		"epathy_critical":
			var critical_color: Color = effect.get("color", Color(1.0, 0.42, 0.55))
			var critical_radius := radius * (0.4 + progress * 0.75)
			draw_arc(pos, critical_radius, -0.8, 2.3, 22, Color(1.0, 0.88, 0.42, alpha), 7.0, true)
			draw_arc(pos, critical_radius * 0.72, 2.4, 5.5, 20, Color(critical_color, alpha), 5.0, true)
		"pulse":
			var pulse_color: Color = effect.get("color", Color(0.35, 0.9, 1.0))
			draw_arc(pos, radius * (0.25 + 0.75 * progress), 0.0, TAU, 64, Color(pulse_color, alpha), 11.0, true)
		"ice":
			var ice_color: Color = effect.get("color", Color(0.55, 0.85, 1.0))
			draw_circle(pos, radius * progress, Color(ice_color, alpha * 0.14))
			draw_arc(pos, radius * progress, 0.0, TAU, 64, Color(ice_color.lightened(0.25), alpha), 8.0, true)
		"map_supply":
			var supply_radius := radius * (0.28 + progress * 0.72)
			draw_arc(pos, supply_radius, -progress * TAU, (1.0 - progress) * TAU, 48, Color(1.0, 0.76, 0.24, alpha), 8.0, true)
			for shard_index in 6:
				var shard_direction := Vector2.from_angle(TAU * float(shard_index) / 6.0)
				draw_circle(pos + shard_direction * supply_radius * 0.7, 6.0 * alpha, Color(1.0, 0.92, 0.48, alpha))
		"repair":
			draw_circle(pos, radius * progress, Color(0.2, 1.0, 0.62, alpha * 0.18))
			draw_arc(pos, radius * (0.45 + progress * 0.55), 0.0, TAU, 40, Color(0.48, 1.0, 0.76, alpha), 6.0, true)
		"meteor":
			var meteor_radius_now := radius * progress
			draw_line(pos + Vector2(90.0, -210.0) * (1.0 - progress), pos, Color(1.0, 0.55, 0.15, alpha), 12.0, true)
			draw_circle(pos, meteor_radius_now, Color(1.0, 0.3, 0.08, alpha * 0.18))
			draw_arc(pos, meteor_radius_now, 0.0, TAU, 48, Color(1.0, 0.62, 0.18, alpha), 8.0, true)
		"contamination":
			var hazard_alpha := minf(0.72, float(effect["life"]) * 0.28)
			draw_circle(pos, radius, Color(0.28, 0.92, 0.38, hazard_alpha * 0.16))
			draw_arc(pos, radius, game_time, game_time + TAU, 40, Color(0.4, 1.0, 0.48, hazard_alpha), 5.0, true)
			for node_index in 5:
				var node_angle := TAU * float(node_index) / 5.0 + game_time * 0.35
				draw_circle(pos + Vector2.from_angle(node_angle) * radius * 0.62, 5.0, Color(0.66, 1.0, 0.32, hazard_alpha))
		"arsenal_orbit":
			var orbit_amount := int(effect.get("amount", 3))
			for blade_index in orbit_amount:
				var blade_pos: Vector2 = pos + Vector2.from_angle(game_time * 4.0 + TAU * float(blade_index) / float(orbit_amount)) * radius * 0.82
				draw_line(blade_pos - Vector2(8.0, 0.0), blade_pos + Vector2(8.0, 0.0), Color(0.72, 0.94, 1.0, alpha), 6.0, true)
			draw_arc(pos, radius, 0.0, TAU, 48, Color(0.32, 0.82, 1.0, alpha * 0.45), 3.0, true)
		"arsenal_aura":
			draw_circle(pos, radius, Color(0.34, 0.88, 1.0, alpha * 0.08))
			draw_arc(pos, radius, game_time, game_time + TAU, 52, Color(0.48, 1.0, 0.86, alpha), 5.0, true)
		"arsenal_pool":
			draw_circle(pos, radius * (0.65 + progress * 0.35), Color(0.18, 0.62, 1.0, alpha * 0.18))
			draw_arc(pos, radius, 0.0, TAU, 44, Color(0.55, 0.88, 1.0, alpha), 5.0, true)
		"arsenal_chain":
			var chain_points: Array = effect.get("points", [])
			for point_index in range(chain_points.size() - 1):
				var chain_start: Vector2 = chain_points[point_index]
				var chain_end: Vector2 = chain_points[point_index + 1]
				draw_line(chain_start, chain_end, Color(0.42, 1.0, 0.72, alpha * 0.42), 10.0, true)
				draw_line(chain_start, chain_end, Color(0.82, 1.0, 0.94, alpha), 3.0, true)
				draw_circle(chain_end, 8.0 + progress * 5.0, Color(0.5, 1.0, 0.78, alpha))
		"shield_break":
			draw_arc(pos, radius * (0.75 + progress * 0.45), 0.0, TAU, 30, Color(0.35, 0.88, 1.0, alpha), 6.0, true)
		"elite_chest":
			var chest_radius := radius * progress
			draw_circle(pos, chest_radius, Color(1.0, 0.68, 0.12, alpha * 0.12))
			draw_arc(pos, chest_radius, -progress * TAU, (1.0 - progress) * TAU, 48, Color(1.0, 0.86, 0.3, alpha), 8.0, true)
		"elite_explosion":
			var explosion_radius := radius * (0.35 + progress * 0.65)
			draw_circle(pos, explosion_radius, Color(1.0, 0.12, 0.2, 0.08 + progress * 0.18))
			draw_arc(pos, explosion_radius, 0.0, TAU, 48, Color(1.0, 0.28, 0.18, 0.9), 7.0, true)
		"apostle_phase":
			var phase_radius := radius * (0.25 + progress * 0.75)
			draw_circle(pos, phase_radius, Color(1.0, 0.06, 0.14, alpha * 0.13))
			draw_arc(pos, phase_radius, -progress * TAU, (1.0 - progress) * TAU, 72, Color(1.0, 0.22, 0.16, alpha), 12.0, true)
		"apostle_hazard":
			var armed := float(effect.get("arm_time", 0.0)) <= 0.0
			var hazard_color := Color(1.0, 0.08, 0.22) if armed else Color(1.0, 0.72, 0.18)
			var apostle_hazard_alpha := 0.2 + 0.12 * sin(game_time * (9.0 if armed else 5.0))
			draw_circle(pos, radius, Color(hazard_color, apostle_hazard_alpha))
			draw_arc(pos, radius, game_time * 0.8, game_time * 0.8 + TAU, 48, Color(hazard_color, 0.92), 6.0, true)

func _draw_player() -> void:
	var flicker := player_invulnerable > 0.0 and int(player_invulnerable * 24.0) % 2 == 0
	var sprite_modulate := Color(1.0, 1.0, 1.0, 0.34 if flicker else 1.0)
	draw_ellipse_shadow(player_pos + Vector2(0.0, 13.0), 31.0, 10.0, Color(0.01, 0.02, 0.02, 0.52))
	if _weapon_is_evolved("starter"):
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
	if float(weapon_timers.get("starter", 1.0)) < 0.22:
		_char().draw_preview(self)


# ═════════ 內部類別：設定 ═════════

class GameSettingsData extends RefCounted:
	signal changed

	const PATH := "user://settings.cfg"

	var master_volume := 0.8
	var music_volume := 1.0
	var damage_numbers := true
	var fullscreen := false

	func load_from_disk() -> void:
		var config := ConfigFile.new()
		if config.load(PATH) != OK:
			return
		master_volume = clampf(float(config.get_value("audio", "master", master_volume)), 0.0, 1.0)
		music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
		damage_numbers = bool(config.get_value("gameplay", "damage_numbers", damage_numbers))
		fullscreen = bool(config.get_value("video", "fullscreen", fullscreen))

	func save_to_disk() -> void:
		var config := ConfigFile.new()
		config.set_value("audio", "master", master_volume)
		config.set_value("audio", "music", music_volume)
		config.set_value("gameplay", "damage_numbers", damage_numbers)
		config.set_value("video", "fullscreen", fullscreen)
		config.save(PATH)

	func commit() -> void:
		save_to_disk()
		changed.emit()


# ═════════ 內部類別：主選單 ═════════

class MainMenuUI extends Control:
	signal start_pressed
	signal quit_pressed

	var settings
	var version_text := ""
	var time := 0.0
	var menu_column: VBoxContainer
	var start_button: Button
	var modal_layer: ColorRect
	var options_box: VBoxContainer
	var credits_box: VBoxContainer

	func setup(settings_ref, version: String) -> void:
		settings = settings_ref
		version_text = version
		mouse_filter = Control.MOUSE_FILTER_STOP
		_build_menu()
		_build_modal()
		visible = false

	func show_menu() -> void:
		visible = true
		modal_layer.visible = false
		start_button.grab_focus()

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		time += delta
		queue_redraw()

	func _add_button(parent: Control, text: String, min_size: Vector2, font_size: int, on_pressed: Callable) -> Button:
		var button := Button.new()
		button.text = text
		button.custom_minimum_size = min_size
		button.add_theme_font_size_override("font_size", font_size)
		button.pressed.connect(on_pressed)
		parent.add_child(button)
		return button

	func _add_label(parent: Control, text: String, font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = align
		label.add_theme_font_size_override("font_size", font_size)
		parent.add_child(label)
		return label

	func _build_menu() -> void:
		menu_column = VBoxContainer.new()
		menu_column.add_theme_constant_override("separation", 16)
		add_child(menu_column)
		menu_column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
		menu_column.offset_left = 90.0
		menu_column.offset_right = 420.0
		menu_column.offset_top = -80.0
		menu_column.offset_bottom = 250.0
		var button_size := Vector2(320.0, 62.0)
		start_button = _add_button(menu_column, "開始遊戲", button_size, 26, func(): start_pressed.emit())
		_add_button(menu_column, "選項", button_size, 26, _on_options)
		_add_button(menu_column, "製作資訊", button_size, 26, _on_credits)
		_add_button(menu_column, "離開遊戲", button_size, 26, func(): quit_pressed.emit())

	func _build_modal() -> void:
		modal_layer = ColorRect.new()
		modal_layer.color = Color(0.0, 0.0, 0.0, 0.72)
		modal_layer.visible = false
		add_child(modal_layer)
		modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var center := CenterContainer.new()
		modal_layer.add_child(center)
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(620.0, 460.0)
		center.add_child(panel)
		var holder := VBoxContainer.new()
		holder.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(holder)

		options_box = VBoxContainer.new()
		options_box.alignment = BoxContainer.ALIGNMENT_CENTER
		options_box.add_theme_constant_override("separation", 20)
		holder.add_child(options_box)
		_add_label(options_box, "選項", 36)
		_add_slider_row(options_box, "主音量", settings.master_volume, func(v: float): settings.master_volume = v; settings.commit())
		_add_slider_row(options_box, "音樂音量", settings.music_volume, func(v: float): settings.music_volume = v; settings.commit())
		var damage_toggle := CheckButton.new()
		damage_toggle.text = "顯示傷害數字"
		damage_toggle.button_pressed = settings.damage_numbers
		damage_toggle.add_theme_font_size_override("font_size", 22)
		damage_toggle.toggled.connect(func(on: bool): settings.damage_numbers = on; settings.commit())
		options_box.add_child(damage_toggle)
		var fullscreen_toggle := CheckButton.new()
		fullscreen_toggle.text = "全螢幕"
		fullscreen_toggle.button_pressed = settings.fullscreen
		fullscreen_toggle.add_theme_font_size_override("font_size", 22)
		fullscreen_toggle.toggled.connect(func(on: bool): settings.fullscreen = on; settings.commit())
		options_box.add_child(fullscreen_toggle)
		_add_button(options_box, "返回", Vector2(220.0, 52.0), 22, _close_modal).size_flags_horizontal = Control.SIZE_SHRINK_CENTER

		credits_box = VBoxContainer.new()
		credits_box.alignment = BoxContainer.ALIGNMENT_CENTER
		credits_box.add_theme_constant_override("separation", 20)
		holder.add_child(credits_box)
		_add_label(credits_box, "製作資訊", 36)
		_add_label(credits_box, "星隕倖存者｜荒原先遣\n%s\n\n免費、非商業、非官方同人原型\n美術素材由使用者提供" % version_text, 22)
		_add_button(credits_box, "返回", Vector2(220.0, 52.0), 22, _close_modal).size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	func _add_slider_row(parent: Control, title: String, value: float, on_changed: Callable) -> void:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		parent.add_child(row)
		var name_label := _add_label(row, title, 22, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.custom_minimum_size = Vector2(130.0, 0.0)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = value
		slider.custom_minimum_size = Vector2(260.0, 28.0)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(slider)
		var value_label := _add_label(row, "%d%%" % roundi(value * 100.0), 20, HORIZONTAL_ALIGNMENT_RIGHT)
		value_label.custom_minimum_size = Vector2(64.0, 0.0)
		slider.value_changed.connect(func(v: float) -> void: value_label.text = "%d%%" % roundi(v * 100.0))
		slider.value_changed.connect(on_changed)

	func _on_options() -> void:
		options_box.visible = true
		credits_box.visible = false
		modal_layer.visible = true

	func _on_credits() -> void:
		options_box.visible = false
		credits_box.visible = true
		modal_layer.visible = true

	func _close_modal() -> void:
		modal_layer.visible = false
		start_button.grab_focus()

	func _star_noise(index: int, salt: float) -> float:
		var value := sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
		return value - floorf(value)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_polygon(
			PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
			PackedColorArray([Color(0.02, 0.04, 0.12), Color(0.02, 0.04, 0.12), Color(0.16, 0.12, 0.22), Color(0.16, 0.12, 0.22)])
		)
		for star_index in 90:
			var star_pos := Vector2(_star_noise(star_index, 1.0) * w, _star_noise(star_index, 2.0) * h * 0.65)
			var twinkle := 0.45 + 0.4 * sin(time * (1.0 + _star_noise(star_index, 3.0) * 2.0) + float(star_index))
			draw_circle(star_pos, 1.0 + _star_noise(star_index, 4.0) * 1.6, Color(1.0, 1.0, 0.92, twinkle))
		var moon := Vector2(w * 0.8, h * 0.2)
		draw_circle(moon, 78.0, Color(0.8, 0.9, 1.0, 0.07))
		draw_circle(moon, 52.0, Color(0.92, 0.96, 1.0, 0.95))
		var meteor_t := fmod(time * 0.22, 1.0)
		var meteor_head := Vector2(w * (0.15 + meteor_t * 0.6), h * (0.05 + meteor_t * 0.4))
		draw_line(meteor_head - Vector2(120.0, 60.0), meteor_head, Color(1.0, 0.7, 0.35, 1.0 - meteor_t), 4.0, true)
		draw_circle(meteor_head, 6.0, Color(1.0, 0.92, 0.7, 1.0 - meteor_t))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, h * 0.72), Vector2(w * 0.18, h * 0.6), Vector2(w * 0.34, h * 0.7), Vector2(w * 0.55, h * 0.56),
			Vector2(w * 0.78, h * 0.68), Vector2(w, h * 0.6), Vector2(w, h), Vector2(0, h),
		]), Color(0.07, 0.09, 0.13))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, h * 0.84), Vector2(w * 0.4, h * 0.78), Vector2(w * 0.7, h * 0.82), Vector2(w, h * 0.77), Vector2(w, h), Vector2(0, h),
		]), Color(0.04, 0.06, 0.07))
		var hut_pos := Vector2(w * 0.7, h * 0.79)
		draw_rect(Rect2(hut_pos + Vector2(-70.0, -60.0), Vector2(140.0, 60.0)), Color(0.03, 0.03, 0.04))
		draw_colored_polygon(PackedVector2Array([hut_pos + Vector2(-86.0, -58.0), hut_pos + Vector2(0.0, -120.0), hut_pos + Vector2(86.0, -58.0)]), Color(0.02, 0.02, 0.03))
		var glow := 0.75 + 0.15 * sin(time * 3.0)
		draw_rect(Rect2(hut_pos + Vector2(-14.0, -44.0), Vector2(28.0, 26.0)), Color(1.0, 0.75, 0.35, glow))
		draw_rect(Rect2(0.0, 0.0, w * 0.44, h), Color(0.0, 0.0, 0.0, 0.32))
		var font := get_theme_default_font()
		var title_pos := Vector2(90.0, h * 0.24)
		draw_string_outline(font, title_pos, "星隕倖存者", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 78, 10, Color(0.0, 0.03, 0.05, 0.9))
		draw_string(font, title_pos, "星隕倖存者", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 78, Color(0.78, 1.0, 0.92))
		draw_string(font, title_pos + Vector2(6.0, 54.0), "荒原先遣", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 34, Color(1.0, 0.78, 0.4))
		draw_string(font, Vector2(24.0, h - 20.0), version_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(1.0, 1.0, 1.0, 0.55))


# ═════════ 內部類別：小屋 ═════════

class HutSceneUI extends Control:
	signal character_chosen(character_id: String)
	signal back_pressed

	const ROSTER := [
		{"id": "epathy", "name": "埃帕蒂", "role": "近戰／生存", "color": Color(1.0, 0.48, 0.55), "texture": true},
		{"id": "lucia", "name": "璐茜婭", "role": "法術／持續傷害", "color": Color(0.92, 0.45, 1.0), "texture": false},
		{"id": "claire", "name": "克萊兒", "role": "新手／均衡", "color": Color(0.6, 0.92, 1.0), "texture": false},
		{"id": "rafari", "name": "菈法瑞", "role": "控場／冰霜", "color": Color(0.55, 0.72, 1.0), "texture": false},
		{"id": "unit_5", "name": "？？？", "role": "尚未公開", "color": Color(1.0, 0.82, 0.35), "texture": false},
		{"id": "unit_6", "name": "？？？", "role": "尚未公開", "color": Color(0.5, 1.0, 0.65), "texture": false},
	]

	var background_texture: Texture2D
	var epathy_texture: Texture2D
	var playable: Array = []
	var hovered := -1
	var notice_text := ""
	var notice_time := 0.0
	var time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		var back_button := Button.new()
		back_button.text = "← 主選單"
		back_button.position = Vector2(24.0, 20.0)
		back_button.custom_minimum_size = Vector2(170.0, 48.0)
		back_button.add_theme_font_size_override("font_size", 20)
		back_button.pressed.connect(func(): back_pressed.emit())
		add_child(back_button)

	func setup(background: Texture2D, character_texture: Texture2D, playable_ids: Array) -> void:
		background_texture = background
		epathy_texture = character_texture
		playable = playable_ids
		visible = false

	func show_hut() -> void:
		visible = true
		hovered = -1
		notice_time = 0.0

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return
		time += delta
		notice_time = maxf(0.0, notice_time - delta)
		queue_redraw()
	func _input(event: InputEvent) -> void:
		if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			back_pressed.emit()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			hovered = _index_at(event.position)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var index := _index_at(event.position)
			if index < 0:
				return
			var character_id: String = ROSTER[index]["id"]
			if playable.has(character_id):
				character_chosen.emit(character_id)
			else:
				notice_text = "%s　尚未開放" % ROSTER[index]["name"]
				notice_time = 1.8

	func _slot_pos(index: int) -> Vector2:
		var t := (float(index) + 0.5) / float(ROSTER.size())
		var x := lerpf(size.x * 0.08, size.x * 0.92, t)
		var y := size.y * (0.82 if index % 2 == 0 else 0.7)
		return Vector2(x, y)

	func _index_at(point: Vector2) -> int:
		var found := -1
		var best_y := -INF
		for index in ROSTER.size():
			var pos := _slot_pos(index)
			if Rect2(pos.x - 56.0, pos.y - 150.0, 112.0, 170.0).has_point(point) and pos.y > best_y:
				found = index
				best_y = pos.y
		return found

	func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
		var points := PackedVector2Array()
		for point_index in 28:
			var angle := TAU * float(point_index) / 28.0
			points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
		draw_colored_polygon(points, color)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var font := get_theme_default_font()
		if background_texture != null:
			draw_texture_rect(background_texture, Rect2(0.0, 0.0, w, h), false)
		else:
			draw_rect(Rect2(0.0, 0.0, w, h), Color(0.08, 0.06, 0.08))
		# 深色遮罩讓上方標題、返回鍵與底部說明在明亮火光前仍清楚。
		draw_rect(Rect2(0.0, 0.0, w, 88.0), Color(0.015, 0.02, 0.04, 0.52))
		draw_rect(Rect2(0.0, h - 66.0, w, 66.0), Color(0.015, 0.02, 0.04, 0.68))
		draw_string_outline(font, Vector2(0.0, 54.0), "先遣小屋", HORIZONTAL_ALIGNMENT_CENTER, w, 36, 7, Color(0.02, 0.02, 0.03, 0.8))
		draw_string(font, Vector2(0.0, 54.0), "先遣小屋", HORIZONTAL_ALIGNMENT_CENTER, w, 36, Color(1.0, 0.92, 0.75))
		for index in [1, 3, 5, 0, 2, 4]:
			_draw_character(index, font)
		var info := "點擊角色進入星蝕荒原　｜　Esc 返回主選單"
		if hovered >= 0:
			var hovered_data: Dictionary = ROSTER[hovered]
			info = "%s　｜　%s　｜　%s" % [hovered_data["name"], hovered_data["role"], "點擊出發" if playable.has(hovered_data["id"]) else "尚未開放"]
		draw_string(font, Vector2(0.0, h - 24.0), info, HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color(1.0, 0.94, 0.8))
		if notice_time > 0.0:
			var alpha := clampf(notice_time / 0.5, 0.0, 1.0)
			draw_string_outline(font, Vector2(0.0, h * 0.34), notice_text, HORIZONTAL_ALIGNMENT_CENTER, w, 34, 6, Color(0.0, 0.0, 0.0, alpha))
			draw_string(font, Vector2(0.0, h * 0.34), notice_text, HORIZONTAL_ALIGNMENT_CENTER, w, 34, Color(1.0, 0.85, 0.5, alpha))

	func _draw_character(index: int, font: Font) -> void:
		var data: Dictionary = ROSTER[index]
		var pos := _slot_pos(index)
		var color: Color = data["color"]
		var unlocked := playable.has(data["id"])
		var is_hovered := index == hovered
		_ellipse(pos + Vector2(0.0, 6.0), 42.0, 12.0, Color(0.0, 0.0, 0.0, 0.4))
		if is_hovered:
			draw_arc(pos + Vector2(0.0, 6.0), 50.0, 0.0, TAU, 36, Color(color, 0.85), 4.0, true)
		if bool(data["texture"]) and epathy_texture != null:
			var height := (160.0 if is_hovered else 150.0) * (1.0 + 0.015 * sin(time * 2.4 + float(index)))
			var tex_size := epathy_texture.get_size()
			var width := height * tex_size.x / maxf(1.0, tex_size.y)
			draw_texture_rect(epathy_texture, Rect2(pos.x - width * 0.5, pos.y - height + 12.0, width, height), false)
		else:
			var center := pos + Vector2(0.0, -62.0 + sin(time * 2.2 + float(index) * 1.1) * 4.0)
			var radius := 38.0 * (1.08 if is_hovered else 1.0)
			var alpha := 1.0 if is_hovered else 0.78
			draw_circle(center, radius, Color(color, 0.2 * alpha))
			draw_arc(center, radius, 0.0, TAU, 40, Color(color, alpha), 5.0, true)
			var spin := time * 1.5 + float(index)
			draw_arc(center, radius + 9.0, spin, spin + 1.7, 16, Color(color, 0.6 * alpha), 3.0, true)
			draw_circle(center, radius * 0.3, Color(color, alpha))
		draw_string(font, Vector2(pos.x - 90.0, pos.y + 34.0), String(data["name"]), HORIZONTAL_ALIGNMENT_CENTER, 180.0, 22, Color(1.0, 0.95, 0.85) if unlocked else Color(0.75, 0.75, 0.8))
		if not unlocked:
			draw_string(font, Vector2(pos.x - 90.0, pos.y + 54.0), "尚未開放", HORIZONTAL_ALIGNMENT_CENTER, 180.0, 15, Color(0.7, 0.7, 0.75, 0.85))
