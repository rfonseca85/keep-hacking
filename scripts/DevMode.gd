extends CanvasLayer

var infinite_time: bool = false
var infinite_ultimates: bool = false
var show_fps: bool = false
var show_debug_info: bool = false
var disable_fx: bool = false

var menu_open: bool = false
var panel: Panel
var fps_lbl: Label
var fields: Array = []

# Mirrors scripts/SkillTree.gd's SkillDef ids/max levels so dev-mode can
# mark every node MAX without needing the scene-local SkillDef instances.
const SKILL_MAX := {
	"speed1": 5, "radius1": 5, "yield1": 5, "footprint1": 5,
	"duration1": 4, "bot1": 4, "weaken_all": 5, "forensics1": 3,
	"speed2": 3, "radius2": 3, "bot2": 2, "yield2": 3,
	"hunter_bot": 3, "row_wipe": 3, "ultimate_wipe": 3,
}

func _ready() -> void:
	layer = 100
	_build_ui()
	panel.visible = false
	set_process(true)
	set_process_unhandled_input(true)
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_devmode"):
		get_tree().create_timer(0.4).timeout.connect(func():
			menu_open = true
			panel.visible = true
			_refresh_fields()
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_QUOTELEFT:
		menu_open = not menu_open
		panel.visible = menu_open
		if menu_open:
			_refresh_fields()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if show_fps:
		fps_lbl.visible = true
		fps_lbl.text = "FPS: %d" % Engine.get_frames_per_second()
	else:
		fps_lbl.visible = false

# ---------------------------------------------------------------- layout

func _build_ui() -> void:
	fps_lbl = Label.new()
	fps_lbl.position = Vector2(1180, 8)
	fps_lbl.add_theme_font_size_override("font_size", 14)
	fps_lbl.add_theme_color_override("font_color", Color8(57, 255, 106))
	fps_lbl.visible = false
	add_child(fps_lbl)

	panel = Panel.new()
	panel.position = Vector2(930, 0)
	panel.size = Vector2(350, 720)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(9, 11, 17, 250)
	sb.border_color = Color8(255, 184, 48)
	sb.border_width_left = 3
	sb.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 0)
	scroll.size = Vector2(350, 720)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(20, 14)
	vbox.custom_minimum_size = Vector2(310, 0)
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	_add_title(vbox, "⚙ DEV TOOLS")
	_add_hint(vbox, "testing aid — press ` to close")

	_add_section(vbox, "ECONOMY")
	_add_number_field(vbox, "Credits",
		func(): return str(GameState.credits),
		func(t): GameState.credits = _pi(t); GameState.lifetime_credits_earned = max(GameState.lifetime_credits_earned, GameState.credits))
	_add_number_field(vbox, "Exploits",
		func(): return str(GameState.exploits),
		func(t): GameState.exploits = _pi(t))
	_add_number_field(vbox, "0-Days",
		func(): return str(GameState.zerodays),
		func(t): GameState.zerodays = _pi(t))
	_add_number_field(vbox, "Lifetime earned (skill reveal)",
		func(): return str(GameState.lifetime_credits_earned),
		func(t): GameState.lifetime_credits_earned = _pi(t))

	_add_section(vbox, "RUN")
	_add_checkbox(vbox, "infinite_time", "Infinite time (uplink never drops)")
	_add_checkbox(vbox, "infinite_ultimates", "Infinite ultimates (no cooldown)")
	_add_action(vbox, "End round now", _on_end_round_now)
	_add_action(vbox, "Restart round (reload Main)", _on_restart_round)
	_add_action(vbox, "Force-spawn a honeypot", _on_force_honeypot)

	_add_section(vbox, "STATS")
	_add_number_field(vbox, "Decrypt speed",
		func(): return str(GameState.decrypt_speed),
		func(t): GameState.decrypt_speed = _pf(t))
	_add_number_field(vbox, "Decrypt radius",
		func(): return str(GameState.decrypt_radius),
		func(t): GameState.decrypt_radius = _pf(t))
	_add_number_field(vbox, "Bot level",
		func(): return str(GameState.bot_level),
		func(t): GameState.bot_level = _pi(t))
	_add_number_field(vbox, "Yield multiplier",
		func(): return str(GameState.yield_mult),
		func(t): GameState.yield_mult = _pf(t))
	_add_number_field(vbox, "Round duration (s)",
		func(): return str(GameState.round_duration),
		func(t): GameState.round_duration = _pf(t))
	_add_number_field(vbox, "Max nodes on grid",
		func(): return str(GameState.max_nodes),
		func(t): GameState.max_nodes = _pi(t))
	_add_number_field(vbox, "Weaken multiplier",
		func(): return str(GameState.weaken_mult),
		func(t): GameState.weaken_mult = _pf(t))
	_add_number_field(vbox, "Hunter-bot count",
		func(): return str(GameState.hunter_bot_count),
		func(t): GameState.hunter_bot_count = _pi(t))
	_add_number_field(vbox, "Row-purge level",
		func(): return str(GameState.row_wipe_level),
		func(t): GameState.row_wipe_level = _pi(t))
	_add_number_field(vbox, "Ultimate level",
		func(): return str(GameState.ultimate_wipe_level),
		func(t): GameState.ultimate_wipe_level = _pi(t))

	_add_section(vbox, "NETWORKS & SKILLS")
	_add_action(vbox, "Unlock: Home Network", func(): GameState.unlocked_tiers[0] = true)
	_add_action(vbox, "Unlock: Office LAN", func(): GameState.unlocked_tiers[1] = true)
	_add_action(vbox, "Unlock: Corp Network", func(): GameState.unlocked_tiers[2] = true)
	_add_action(vbox, "Unlock: Botnet Array", func(): GameState.unlocked_tiers[3] = true)
	_add_action(vbox, "Unlock all networks", func(): GameState.unlocked_tiers = [true, true, true, true])
	_add_action(vbox, "Reveal all skill nodes", func(): GameState.lifetime_credits_earned = max(GameState.lifetime_credits_earned, 999999999))
	_add_action(vbox, "Max all skills (levels + effects)", _on_max_all_skills)

	_add_section(vbox, "NAVIGATE")
	_add_action(vbox, "Go to Network Select", func(): get_tree().change_scene_to_file("res://scenes/NetworkSelect.tscn"))
	_add_action(vbox, "Go to Main (game)", func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	_add_action(vbox, "Go to Skill Tree", func(): get_tree().change_scene_to_file("res://scenes/SkillTree.tscn"))

	_add_section(vbox, "DEBUG / VISUAL")
	_add_checkbox(vbox, "show_fps", "Show FPS counter")
	_add_checkbox(vbox, "show_debug_info", "Show node debug info (state/progress)")
	_add_checkbox(vbox, "disable_fx", "Disable particle/FX (perf testing)")

	_add_section(vbox, "RESET")
	_add_action(vbox, "Reset save to defaults", _on_reset_save, Color8(255, 90, 120))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

# ---------------------------------------------------------------- widgets

func _add_title(parent: Node, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color8(255, 184, 48))
	parent.add_child(l)

func _add_hint(parent: Node, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color8(120, 130, 145))
	parent.add_child(l)

func _add_section(parent: Node, text: String) -> void:
	var sep := HSeparator.new()
	parent.add_child(sep)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color8(0, 229, 255))
	parent.add_child(l)

func _add_checkbox(parent: Node, key: String, label: String) -> void:
	var cb := CheckBox.new()
	cb.text = label
	cb.button_pressed = get(key)
	cb.add_theme_font_size_override("font_size", 9)
	cb.add_theme_color_override("font_color", Color8(200, 210, 220))
	cb.toggled.connect(func(pressed: bool): set(key, pressed))
	parent.add_child(cb)

func _add_action(parent: Node, label: String, callback: Callable, color: Color = Color8(0, 229, 255)) -> void:
	var btn := Button.new()
	btn.text = "▸ " + label
	btn.custom_minimum_size = Vector2(310, 22)
	btn.add_theme_font_size_override("font_size", 9)
	var sb := _field_stylebox(color)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(func():
		callback.call()
		_refresh_fields()
	)
	parent.add_child(btn)

func _field_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(14, 16, 22)
	sb.border_color = color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

func _add_number_field(parent: Node, label: String, getter: Callable, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)

	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(118, 22)
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color8(170, 180, 192))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)

	var field := LineEdit.new()
	field.text = getter.call()
	field.custom_minimum_size = Vector2(118, 22)
	field.add_theme_font_size_override("font_size", 10)
	field.add_theme_color_override("font_color", Color8(220, 240, 255))
	var fsb := _field_stylebox(Color8(0, 229, 255))
	field.add_theme_stylebox_override("normal", fsb)
	field.add_theme_stylebox_override("focus", _field_stylebox(Color8(57, 255, 106)))
	field.add_theme_stylebox_override("read_only", fsb)
	row.add_child(field)

	var btn := Button.new()
	btn.text = "SET"
	btn.custom_minimum_size = Vector2(50, 22)
	btn.add_theme_font_size_override("font_size", 9)
	var bsb := _field_stylebox(Color8(0, 229, 255))
	btn.add_theme_stylebox_override("normal", bsb)
	btn.add_theme_stylebox_override("hover", bsb)
	btn.add_theme_stylebox_override("pressed", bsb)
	btn.add_theme_stylebox_override("focus", bsb)
	btn.add_theme_color_override("font_color", Color8(0, 229, 255))
	row.add_child(btn)

	var apply := func():
		setter.call(field.text)
		field.text = getter.call()
	btn.pressed.connect(apply)
	field.text_submitted.connect(func(_t): apply.call())

	fields.append({"field": field, "getter": getter})

func _refresh_fields() -> void:
	for f in fields:
		f["field"].text = f["getter"].call()

func _pi(t: String) -> int:
	return int(t.strip_edges()) if t.strip_edges().is_valid_int() else 0

func _pf(t: String) -> float:
	return float(t.strip_edges()) if t.strip_edges().is_valid_float() else 0.0

# ---------------------------------------------------------------- actions

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
