extends CanvasLayer

var infinite_money: bool = false
var infinite_time: bool = false
var infinite_ultimates: bool = false
var god_mode: bool = false

var menu_open: bool = false
var panel: Panel
var status_lbl: Label
var toggle_meta: Dictionary = {}

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
	node_dim.visible = false
	set_process(true)
	set_process_unhandled_input(true)
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_devmode"):
		get_tree().create_timer(0.4).timeout.connect(func():
			menu_open = true
			panel.visible = true
			node_dim.visible = true
			_refresh_status()
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_QUOTELEFT:
		menu_open = not menu_open
		panel.visible = menu_open
		node_dim.visible = menu_open
		_refresh_status()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if infinite_money or god_mode:
		GameState.credits = max(GameState.credits, 999999999)
		GameState.exploits = max(GameState.exploits, 999999)
		GameState.zerodays = max(GameState.zerodays, 999999)
		GameState.lifetime_credits_earned = max(GameState.lifetime_credits_earned, 999999999)
	if god_mode:
		GameState.unlocked_tiers = [true, true, true, true]

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	node_dim = dim

	panel = Panel.new()
	panel.position = Vector2(340, 90)
	panel.size = Vector2(600, 550)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(8, 10, 16, 250)
	sb.border_color = Color8(255, 184, 48)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var title := Label.new()
	title.text = "⚙ DEV MODE"
	title.position = Vector2(20, 14)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color8(255, 184, 48))
	panel.add_child(title)

	var hint := Label.new()
	hint.text = "press ` to close"
	hint.position = Vector2(460, 20)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color8(120, 130, 145))
	panel.add_child(hint)

	var y := 56
	_add_toggle("god_mode", "★ GOD MODE — unlock + max everything + infinite all", y, Color8(255, 184, 48)); y += 50
	y += 8
	_add_toggle("infinite_money", "INFINITE MONEY (credits / exploits / 0-days)", y); y += 44
	_add_toggle("infinite_time", "INFINITE TIME (uplink stability never drops)", y); y += 44
	_add_toggle("infinite_ultimates", "INFINITE ULTIMATES (zero cooldown)", y); y += 44
	y += 14

	_add_action("UNLOCK ALL NETWORKS", y, _on_unlock_all_tiers); y += 44
	_add_action("MAX ALL SKILLS (levels + effects)", y, _on_max_all_skills); y += 44
	_add_action("SPAWN MAXIMUM NODES ON GRID", y, _on_max_nodes); y += 44
	_add_action("RESET SAVE TO DEFAULTS", y, _on_reset_save, Color8(255, 90, 120)); y += 50

	status_lbl = Label.new()
	status_lbl.position = Vector2(20, y)
	status_lbl.size = Vector2(560, 100)
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color", Color8(140, 150, 165))
	panel.add_child(status_lbl)

var node_dim: ColorRect

func _add_toggle(key: String, label: String, y: int, accent: Color = Color8(57, 255, 106)) -> void:
	var btn := Button.new()
	btn.position = Vector2(20, y)
	btn.size = Vector2(560, 40)
	btn.pressed.connect(func():
		set(key, not get(key))
		_style_toggle(btn, get(key), label, accent)
		_refresh_status()
	)
	_style_toggle(btn, get(key), label, accent)
	panel.add_child(btn)
	toggle_meta[key] = {"btn": btn, "label": label, "accent": accent}

func _style_toggle(btn: Button, on: bool, label: String, accent: Color) -> void:
	btn.text = ("●  " if on else "○  ") + label
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(accent.r, accent.g, accent.b, 0.18) if on else Color8(14, 16, 22)
	sb.border_color = accent if on else Color8(60, 68, 80)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", accent if on else Color8(180, 190, 200))

func _add_action(label: String, y: int, callback: Callable, color: Color = Color8(0, 229, 255)) -> void:
	var btn := Button.new()
	btn.position = Vector2(20, y)
	btn.size = Vector2(560, 38)
	btn.text = "▸  " + label
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(14, 16, 22)
	sb.border_color = color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(func():
		callback.call()
		_refresh_status()
	)
	panel.add_child(btn)

func _on_unlock_all_tiers() -> void:
	GameState.unlocked_tiers = [true, true, true, true]

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
	GameState.zerodays += 10

func _on_max_nodes() -> void:
	GameState.max_nodes = 25

func _on_reset_save() -> void:
	GameState.reset_all()
	infinite_money = false
	infinite_time = false
	infinite_ultimates = false
	god_mode = false
	for key in toggle_meta.keys():
		var m: Dictionary = toggle_meta[key]
		_style_toggle(m["btn"], false, m["label"], m["accent"])

func _refresh_status() -> void:
	if status_lbl == null:
		return
	status_lbl.text = "◈ %d credits (lifetime %d)   ※ %d exploits   ♦ %d 0-days\nspeed %.2f  radius %.0f  bots %d  yield x%.2f  round %.0fs  max_nodes %d\nhunters %d  row-purge Lv%d  ultimate Lv%d  tiers unlocked: %d/4" % [
		GameState.credits, GameState.lifetime_credits_earned, GameState.exploits, GameState.zerodays,
		GameState.decrypt_speed, GameState.decrypt_radius, GameState.bot_level, GameState.yield_mult,
		GameState.round_duration, GameState.max_nodes,
		GameState.hunter_bot_count, GameState.row_wipe_level, GameState.ultimate_wipe_level,
		GameState.unlocked_tiers.count(true)
	]
