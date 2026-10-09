extends Node2D

const COL_BACKDROP := Color8(6, 8, 13)
const COL_PANEL := Color8(12, 15, 22)
const COL_LINE := Color8(50, 70, 60)
const COL_GREEN := Color8(57, 255, 106)
const COL_CYAN := Color8(0, 229, 255)
const COL_DIM := Color8(90, 100, 115)
const COL_LOCKED := Color8(255, 90, 120)

const COLS := 4
const ROWS := 4
const COL_X := [170, 400, 630, 860]
const ROW_Y := [160, 310, 460, 610]

class SkillDef:
	var id: String
	var label: String
	var icon: String
	var row: int
	var col: int
	var cost: int
	var max_level: int
	var apply: Callable
	var desc: String
	var reveal_threshold: int
	func _init(p_id, p_label, p_icon, p_row, p_col, p_cost, p_max, p_apply, p_desc, p_reveal) -> void:
		id = p_id; label = p_label; icon = p_icon; row = p_row; col = p_col
		cost = p_cost; max_level = p_max; apply = p_apply; desc = p_desc
		reveal_threshold = p_reveal

var skills: Array = []
var credits_lbl: Label
var progress_lbl: Label
var node_buttons: Dictionary = {}
var node_icons: Dictionary = {}
var preview_panel: Panel
var preview_title: Label
var preview_body: Label
var preview_cost: Label

func _ready() -> void:
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_skills"):
		GameState.lifetime_credits_earned = 5000
		GameState.credits = 5000
		GameState.skill_levels["speed1"] = 3
		GameState.skill_levels["radius1"] = 5
	Audio.play_ambient()
	var bg := ColorRect.new()
	bg.color = COL_BACKDROP
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var mesh := Node2D.new()
	mesh.z_index = -2
	add_child(mesh)
	mesh.draw.connect(_draw_matrix_bg.bind(mesh))

	_define_skills()
	_draw_links()
	_build_nodes()
	_build_hud()
	_build_preview_panel()

func _pos(row: int, col: int) -> Vector2:
	return Vector2(COL_X[col], ROW_Y[row])

func _define_skills() -> void:
	skills = [
		SkillDef.new("speed1", "FASTER CRACK", "bolt", 0, 0, 18, 5,
			func(): GameState.decrypt_speed += 0.2,
			"+0.2 crack speed per level", 0),
		SkillDef.new("radius1", "WIDER SCAN", "scan", 0, 1, 22, 5,
			func(): GameState.decrypt_radius += 6.0,
			"+6 scan radius per level", 0),
		SkillDef.new("yield1", "DATA COMPRESS", "credits", 0, 2, 30, 5,
			func(): GameState.yield_mult += 0.15,
			"+15% credits from every node, per level", 15),
		SkillDef.new("footprint1", "NETWORK FOOTPRINT", "network", 0, 3, 35, 5,
			func(): GameState.max_nodes += 2,
			"+2 machines visible on the grid at once, per level", 20),

		SkillDef.new("duration1", "STEALTH ROUTING", "stealth", 1, 0, 40, 4,
			func(): GameState.round_duration += 4.0,
			"+4s of uplink stability before connection drops", 30),
		SkillDef.new("bot1", "DEPLOY BOT", "bot", 1, 1, 65, 4,
			func(): GameState.bot_level += 1,
			"+1 auto-crack bot per level", 50),
		SkillDef.new("weaken_all", "WEAKEN PROTOCOL", "cpu", 1, 2, 50, 5,
			func(): GameState.weaken_mult += 0.1,
			"-10% crack time needed on every node, per level", 40),
		SkillDef.new("forensics1", "COUNTER-FORENSICS", "shield", 1, 3, 80, 3,
			func(): GameState.honeypot_penalty_mult = max(0.2, GameState.honeypot_penalty_mult - 0.25),
			"-25% alarm penalty from tripped honeypots", 65),

		SkillDef.new("speed2", "BURST DECRYPT", "boost", 2, 0, 90, 3,
			func(): GameState.decrypt_speed += 0.5,
			"+0.5 crack speed per level", 90),
		SkillDef.new("radius2", "DEEP SCAN", "radar", 2, 1, 100, 3,
			func(): GameState.decrypt_radius += 14.0,
			"+14 scan radius per level", 100),
		SkillDef.new("bot2", "BOTNET SWARM", "upload", 2, 2, 275, 2,
			func(): GameState.bot_level += 2,
			"+2 auto-crack bots per level", 220),
		SkillDef.new("yield2", "ZERO-DAY CACHE", "data", 2, 3, 440, 3,
			func(): GameState.zerodays += 1,
			"+1 0-day per level", 360),

		SkillDef.new("hunter_bot", "HUNTER-KILLER", "target", 3, 0, 150, 3,
			func(): GameState.hunter_bot_count += 1,
			"+1 autonomous red scanner that hunts and cracks the nearest locked node on its own", 130),
		SkillDef.new("row_wipe", "LINE PURGE", "code", 3, 1, 200, 3,
			func(): GameState.row_wipe_level += 1,
			"automatically wipes a full row of the grid on a timer — faster per level", 170),
		SkillDef.new("ultimate_wipe", "ZERO-DAY ULTIMATE", "power", 3, 2, 350, 3,
			func(): GameState.ultimate_wipe_level += 1,
			"unlocks a clickable ability in the HUD: instantly exfiltrate every node on the board — shorter cooldown per level", 300),
		SkillDef.new("filler1", "CLASSIFIED", "lock", 3, 3, 0, 0,
			func(): pass,
			"requires further research", 999999999),
	]

func _draw_matrix_bg(node: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in range(60):
		var x: float = rng.randf_range(0, 1280)
		var y: float = rng.randf_range(0, 720)
		if rng.randf() < 0.1:
			node.draw_rect(Rect2(x, y, 2, 2), Color8(30, 50, 42), true)

func _draw_links() -> void:
	var line_node := Node2D.new()
	line_node.z_index = -1
	add_child(line_node)
	line_node.draw.connect(func():
		for c in range(COLS):
			line_node.draw_line(_pos(0, c), _pos(ROWS - 1, c), COL_LINE, 2.0)
		line_node.draw_line(_pos(0, 0), _pos(0, COLS - 1), COL_LINE, 2.0)
	)

func _build_nodes() -> void:
	for s in skills:
		var p := _pos(s.row, s.col)
		var btn := Button.new()
		btn.position = p - Vector2(52, 46)
		btn.size = Vector2(104, 92)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_node_pressed.bind(s, btn))
		btn.mouse_entered.connect(_show_preview.bind(s))
		btn.mouse_exited.connect(_hide_preview)
		add_child(btn)
		node_buttons[s.id] = btn

		var icon_node := _SkillIcon.new()
		icon_node.icon_key = s.icon
		icon_node.max_level = s.max_level
		icon_node.position = p - Vector2(0, 32)
		add_child(icon_node)
		node_icons[s.id] = icon_node

		_refresh_node(s, btn)

func _is_revealed(s) -> bool:
	return GameState.lifetime_credits_earned >= s.reveal_threshold

func _on_node_pressed(s, btn: Button) -> void:
	if not _is_revealed(s):
		Audio.play_denied()
		return
	var lvl: int = GameState.skill_levels.get(s.id, 0)
	if lvl >= s.max_level:
		return
	var cost: int = int(s.cost * pow(1.5, lvl))
	if GameState.credits >= cost:
		GameState.credits -= cost
		GameState.skill_levels[s.id] = lvl + 1
		s.apply.call()
		_refresh_node(s, btn)
		_refresh_hud()
		_show_preview(s)
		Audio.play_upgrade()
	else:
		Audio.play_denied()

func _refresh_node(s, btn: Button) -> void:
	var icon_node: Node2D = node_icons[s.id]
	var revealed := _is_revealed(s)
	if not revealed:
		btn.text = "\n\n\n???"
		btn.add_theme_stylebox_override("normal", _skill_stylebox("locked"))
		btn.add_theme_color_override("font_color", COL_LOCKED)
		icon_node.visible = false
		icon_node.level = 0
		return

	icon_node.visible = true
	var lvl: int = GameState.skill_levels.get(s.id, 0)
	icon_node.level = lvl
	if s.max_level == 0:
		btn.text = "\n\n\n%s" % s.label
		btn.add_theme_stylebox_override("normal", _skill_stylebox("locked"))
		btn.add_theme_color_override("font_color", COL_DIM)
		icon_node.visible = false
		return

	if lvl >= s.max_level:
		btn.text = "\n\n\n%s\nMAX" % s.label
		btn.add_theme_stylebox_override("normal", _skill_stylebox("active"))
		btn.add_theme_color_override("font_color", COL_GREEN)
		icon_node.col = COL_GREEN
	else:
		var cost: int = int(s.cost * pow(1.5, lvl))
		btn.text = "\n\n\n%s\nLv%d (%d)" % [s.label, lvl, cost]
		if lvl > 0:
			btn.add_theme_stylebox_override("normal", _skill_stylebox("active"))
			btn.add_theme_color_override("font_color", COL_GREEN)
			icon_node.col = COL_GREEN
		elif GameState.credits >= cost:
			btn.add_theme_stylebox_override("normal", _skill_stylebox("available"))
			btn.add_theme_color_override("font_color", COL_CYAN)
			icon_node.col = COL_CYAN
		else:
			btn.add_theme_stylebox_override("normal", _skill_stylebox("available"))
			btn.add_theme_color_override("font_color", COL_DIM)
			icon_node.col = COL_DIM
	icon_node.queue_redraw()

func _skill_stylebox(state: String) -> StyleBox:
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	match state:
		"active":
			sb.border_color = COL_GREEN
			sb.bg_color = Color8(10, 24, 18)
		"locked":
			sb.border_color = COL_LOCKED
			sb.bg_color = Color8(16, 10, 13)
		_:
			sb.border_color = COL_CYAN
			sb.bg_color = Color8(10, 18, 26)
	return sb

func _build_hud() -> void:
	var bottom := Panel.new()
	bottom.position = Vector2(0, 660)
	bottom.size = Vector2(1280, 60)
	add_child(bottom)
	credits_lbl = _label("◈ %d CREDITS" % GameState.credits, COL_CYAN, 18, Vector2(24, 16))
	bottom.add_child(credits_lbl)
	progress_lbl = _label("", Color8(140, 150, 165), 12, Vector2(220, 20))
	bottom.add_child(progress_lbl)

	var resume_btn := Button.new()
	resume_btn.text = "◂ BACK TO GAME"
	resume_btn.position = Vector2(784, 8)
	resume_btn.size = Vector2(220, 36)
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = COL_BACKDROP
	rsb.border_color = COL_GREEN
	rsb.set_border_width_all(2)
	resume_btn.add_theme_stylebox_override("normal", rsb)
	resume_btn.add_theme_color_override("font_color", COL_GREEN)
	resume_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	bottom.add_child(resume_btn)

	var back_btn := Button.new()
	back_btn.text = "CHANGE NETWORK"
	back_btn.position = Vector2(1020, 8)
	back_btn.size = Vector2(240, 36)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = COL_BACKDROP
	bsb.border_color = COL_DIM
	bsb.set_border_width_all(2)
	back_btn.add_theme_stylebox_override("normal", bsb)
	back_btn.add_theme_color_override("font_color", COL_DIM)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/NetworkSelect.tscn"))
	bottom.add_child(back_btn)

	var title := _label("SKILL TREE", COL_GREEN, 26, Vector2(24, 20))
	add_child(title)

func _build_preview_panel() -> void:
	preview_panel = Panel.new()
	preview_panel.position = Vector2(470, 20)
	preview_panel.size = Vector2(340, 100)
	preview_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(18, 22, 30)
	sb.border_color = COL_CYAN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	preview_panel.add_theme_stylebox_override("panel", sb)
	add_child(preview_panel)

	preview_title = _label("", COL_CYAN, 15, Vector2(12, 8))
	preview_panel.add_child(preview_title)
	preview_body = Label.new()
	preview_body.position = Vector2(12, 30)
	preview_body.size = Vector2(316, 40)
	preview_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	preview_body.add_theme_color_override("font_color", Color8(200, 210, 220))
	preview_body.add_theme_font_size_override("font_size", 12)
	preview_panel.add_child(preview_body)
	preview_cost = _label("", Color8(255, 184, 48), 13, Vector2(12, 74))
	preview_panel.add_child(preview_cost)

func _show_preview(s) -> void:
	if not _is_revealed(s):
		preview_title.text = "??? CLASSIFIED"
		preview_body.text = "reach %d lifetime credits earned to reveal this node" % s.reveal_threshold
		preview_cost.text = "progress: %d / %d" % [GameState.lifetime_credits_earned, s.reveal_threshold]
		preview_panel.visible = true
		return
	if s.max_level == 0:
		preview_title.text = s.label
		preview_body.text = s.desc
		preview_cost.text = ""
		preview_panel.visible = true
		return
	var lvl: int = GameState.skill_levels.get(s.id, 0)
	preview_title.text = s.label
	preview_body.text = s.desc
	if lvl >= s.max_level:
		preview_cost.text = "MAX LEVEL (%d/%d)" % [lvl, s.max_level]
	else:
		var cost: int = int(s.cost * pow(1.5, lvl))
		preview_cost.text = "%d → %d   cost: %d credits" % [lvl, lvl + 1, cost]
	preview_panel.visible = true

func _hide_preview() -> void:
	preview_panel.visible = false

func _refresh_hud() -> void:
	credits_lbl.text = "◈ %d CREDITS" % GameState.credits
	var revealed_count := 0
	for s in skills:
		if _is_revealed(s) and s.max_level > 0:
			revealed_count += 1
	var total := 0
	for s in skills:
		if s.max_level > 0:
			total += 1
	progress_lbl.text = "%d / %d NODES REVEALED  ·  LIFETIME: %d◈" % [revealed_count, total, GameState.lifetime_credits_earned]
	for s in skills:
		if node_buttons.has(s.id):
			_refresh_node(s, node_buttons[s.id])

func _label(text: String, col: Color, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", size)
	return l

class _SkillIcon extends Node2D:
	var icon_key: String
	var col: Color = Color8(0, 229, 255)
	var level: int = 0
	var max_level: int = 0
	var _tex: Texture2D
	func _ready() -> void:
		_tex = KHArt.tex("icons", icon_key)
		queue_redraw()
	func _draw() -> void:
		if _tex:
			draw_texture_rect(_tex, Rect2(-11, -11, 22, 22), false, col)
		if max_level > 0:
			var pip_w := 7.0
			var gap := 3.0
			var total_w := max_level * pip_w + (max_level - 1) * gap
			var start_x := -total_w / 2.0
			for i in range(max_level):
				var filled := i < level
				var c := col if filled else Color8(50, 58, 68)
				draw_rect(Rect2(start_x + i * (pip_w + gap), 16, pip_w, 5), c, true)
