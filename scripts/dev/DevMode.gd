@tool
extends Control

var infinite_time: bool = false
var infinite_ultimates: bool = false
var show_fps: bool = false
var show_debug_info: bool = false
var disable_fx: bool = false

var menu_open: bool = false
var fields: Array = []

const SKILL_MAX := {
	"speed1": 5, "radius1": 5, "yield1": 5, "footprint1": 5,
	"duration1": 4, "bot1": 4, "weaken_all": 5, "forensics1": 3,
	"speed2": 3, "radius2": 3, "bot2": 2, "yield2": 3,
	"hunter_bot": 3, "row_wipe": 3, "ultimate_wipe": 3, "mesh_link": 4,
}

@export_group("Panel (edit in scene)")
@export var panel_style: StyleBoxFlat

@onready var editor_frame: TextureRect = $EditorFrame
@onready var overlay_layer: CanvasLayer = $OverlayLayer
@onready var backdrop: ColorRect = $OverlayLayer/Backdrop
@onready var fps_lbl: Label = $OverlayLayer/FpsLabel
@onready var panel: Panel = $OverlayLayer/DevPanel
@onready var cb_infinite_time: CheckBox = $OverlayLayer/DevPanel/Scroll/Content/CbInfiniteTime
@onready var cb_infinite_ultimates: CheckBox = $OverlayLayer/DevPanel/Scroll/Content/CbInfiniteUltimates
@onready var cb_show_fps: CheckBox = $OverlayLayer/DevPanel/Scroll/Content/CbShowFps
@onready var cb_show_debug_info: CheckBox = $OverlayLayer/DevPanel/Scroll/Content/CbShowDebugInfo
@onready var cb_disable_fx: CheckBox = $OverlayLayer/DevPanel/Scroll/Content/CbDisableFx

var _editor_last_edited: Node = null


func _apply_editor_visibility() -> void:
	# DevMode is an autoload: its @tool script runs while you edit ANY scene and was drawing
	# a full-screen frame + dev panel on top. Only the scene tab's own instance should preview.
	if not Engine.is_editor_hint():
		return
	var edited := get_tree().get_edited_scene_root()
	if edited == self:
		visible = true
		editor_frame.visible = true
		_set_menu_visible(true)
	else:
		visible = false
		_set_menu_visible(false)


func _ready() -> void:
	if panel_style:
		panel.add_theme_stylebox_override("panel", panel_style)
	if Engine.is_editor_hint():
		set_process(true)
		_apply_editor_visibility()
		return
	editor_frame.visible = false
	_set_menu_visible(false)
	set_process(true)
	set_process_unhandled_input(true)
	_wire_checkboxes()
	_wire_number_fields()
	_wire_actions()
	_sync_checkboxes_from_state()
	_refresh_fields()
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_devmode"):
		get_tree().create_timer(0.4).timeout.connect(func():
			menu_open = true
			_set_menu_visible(true)
			_refresh_fields()
		)


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_visibility")


func _set_menu_visible(open: bool) -> void:
	panel.visible = open
	backdrop.visible = open
	menu_open = open

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_QUOTELEFT:
		_set_menu_visible(not menu_open)
		if menu_open:
			_refresh_fields()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var edited := get_tree().get_edited_scene_root()
		if edited != _editor_last_edited:
			_editor_last_edited = edited
			_apply_editor_visibility()
		return
	if show_fps:
		fps_lbl.visible = true
		fps_lbl.text = "FPS: %d" % Engine.get_frames_per_second()
	else:
		fps_lbl.visible = false

func _wire_checkboxes() -> void:
	cb_infinite_time.toggled.connect(func(p): infinite_time = p)
	cb_infinite_ultimates.toggled.connect(func(p): infinite_ultimates = p)
	cb_show_fps.toggled.connect(func(p): show_fps = p)
	cb_show_debug_info.toggled.connect(func(p): show_debug_info = p)
	cb_disable_fx.toggled.connect(func(p): disable_fx = p)

func _sync_checkboxes_from_state() -> void:
	cb_infinite_time.button_pressed = infinite_time
	cb_infinite_ultimates.button_pressed = infinite_ultimates
	cb_show_fps.button_pressed = show_fps
	cb_show_debug_info.button_pressed = show_debug_info
	cb_disable_fx.button_pressed = disable_fx

func _wire_number_fields() -> void:
	_bind_num("RowCredits",
		func(): return str(GameState.credits),
		func(t): GameState.credits = _pi(t); GameState.lifetime_credits_earned = max(GameState.lifetime_credits_earned, GameState.credits))
	_bind_num("RowExploits",
		func(): return str(GameState.exploits),
		func(t): GameState.exploits = _pi(t))
	_bind_num("RowZerodays",
		func(): return str(GameState.zerodays),
		func(t): GameState.zerodays = _pi(t))
	_bind_num("RowLifetime",
		func(): return str(GameState.lifetime_credits_earned),
		func(t): GameState.lifetime_credits_earned = _pi(t))
	_bind_num("RowDecryptSpeed",
		func(): return str(GameState.decrypt_speed),
		func(t): GameState.decrypt_speed = _pf(t))
	_bind_num("RowDecryptRadius",
		func(): return str(GameState.decrypt_radius),
		func(t): GameState.decrypt_radius = _pf(t))
	_bind_num("RowBotLevel",
		func(): return str(GameState.bot_level),
		func(t): GameState.bot_level = _pi(t))
	_bind_num("RowYieldMult",
		func(): return str(GameState.yield_mult),
		func(t): GameState.yield_mult = _pf(t))
	_bind_num("RowRoundDuration",
		func(): return str(GameState.round_duration),
		func(t): GameState.round_duration = _pf(t))
	_bind_num("RowMaxNodes",
		func(): return str(GameState.max_nodes),
		func(t): GameState.max_nodes = _pi(t))
	_bind_num("RowWeakenMult",
		func(): return str(GameState.weaken_mult),
		func(t): GameState.weaken_mult = _pf(t))
	_bind_num("RowHunterBots",
		func(): return str(GameState.hunter_bot_count),
		func(t): GameState.hunter_bot_count = _pi(t))
	_bind_num("RowRowPurge",
		func(): return str(GameState.row_wipe_level),
		func(t): GameState.row_wipe_level = _pi(t))
	_bind_num("RowUltimateLevel",
		func(): return str(GameState.ultimate_wipe_level),
		func(t): GameState.ultimate_wipe_level = _pi(t))

func _bind_num(row_name: String, getter: Callable, setter: Callable) -> void:
	var row := panel.get_node("Scroll/Content/" + row_name)
	var field: LineEdit = row.get_node("Field")
	var set_btn: Button = row.get_node("SetBtn")
	var apply := func():
		setter.call(field.text)
		field.text = getter.call()
	set_btn.pressed.connect(apply)
	field.text_submitted.connect(func(_t): apply.call())
	fields.append({"field": field, "getter": getter})

func _wire_actions() -> void:
	_connect_action("BtnEndRound", _on_end_round_now)
	_connect_action("BtnRestartRound", _on_restart_round)
	_connect_action("BtnForceHoneypot", _on_force_honeypot)
	_connect_action("BtnUnlockHome", func(): GameState.unlocked_tiers[0] = true)
	_connect_action("BtnUnlockOffice", func(): GameState.unlocked_tiers[1] = true)
	_connect_action("BtnUnlockCorp", func(): GameState.unlocked_tiers[2] = true)
	_connect_action("BtnUnlockBotnet", func(): GameState.unlocked_tiers[3] = true)
	_connect_action("BtnUnlockAllNetworks", func(): GameState.unlocked_tiers = [true, true, true, true])
	_connect_action("BtnRevealSkills", func(): GameState.lifetime_credits_earned = max(GameState.lifetime_credits_earned, 999999999))
	_connect_action("BtnMaxSkills", _on_max_all_skills)
	_connect_action("BtnGoNetworkSelect", func(): get_tree().change_scene_to_file("res://scenes/NetworkSelect.tscn"))
	_connect_action("BtnGoMain", func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	_connect_action("BtnGoSkillTree", func(): get_tree().change_scene_to_file("res://scenes/SkillTree.tscn"))
	_connect_action("BtnResetSave", _on_reset_save)

func _connect_action(btn_name: String, callback: Callable) -> void:
	var btn: Button = panel.get_node("Scroll/Content/" + btn_name)
	btn.pressed.connect(func():
		callback.call()
		_refresh_fields()
		_refresh_skill_cards()
	)

func _refresh_fields() -> void:
	for f in fields:
		f["field"].text = f["getter"].call()

func _refresh_skill_cards() -> void:
	get_tree().call_group("skill_card", "refresh")

func _pi(t: String) -> int:
	return int(t.strip_edges()) if t.strip_edges().is_valid_int() else 0

func _pf(t: String) -> float:
	return float(t.strip_edges()) if t.strip_edges().is_valid_float() else 0.0

func _on_max_all_skills() -> void:
	GameState.lifetime_credits_earned = max(GameState.lifetime_credits_earned, 999999999)
	for id in SKILL_MAX.keys():
		GameState.skill_levels[id] = SKILL_MAX[id]
	GameState.decrypt_speed = 5.0
	GameState.decrypt_radius = 160.0
	GameState.bot_level = 10
	GameState.yield_mult = 3.5
	GameState.round_duration = 90.0
	GameState.honeypot_penalty_mult = 0.2
	GameState.max_nodes = 25
	GameState.weaken_mult = 2.0
	GameState.hunter_bot_count = 3
	GameState.row_wipe_level = 3
	GameState.ultimate_wipe_level = 3

func _on_end_round_now() -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_end_round"):
		scene._end_round()

func _on_restart_round() -> void:
	if get_tree().current_scene and get_tree().current_scene.has_method("_end_round"):
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_force_honeypot() -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_debug_force_honeypot"):
		scene._debug_force_honeypot()

func _on_reset_save() -> void:
	GameState.reset_all()
	infinite_time = false
	infinite_ultimates = false
	show_fps = false
	show_debug_info = false
	disable_fx = false
	_sync_checkboxes_from_state()
	_refresh_fields()
	_refresh_skill_cards()
