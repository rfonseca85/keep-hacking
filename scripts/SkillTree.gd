extends Control

const COL_BACKDROP := Color8(6, 8, 13)
const COL_PANEL := Color8(12, 15, 22)
const COL_LINE := Color8(50, 70, 60)
const COL_GREEN := Color8(57, 255, 106)
const COL_CYAN := Color8(0, 229, 255)
const COL_DIM := Color8(90, 100, 115)
const COL_LOCKED := Color8(255, 90, 120)

const COLS := 4
const ROWS := 4
const COL_X := [190, 450, 710, 970]
const ROW_Y := [145, 295, 445, 595]
const CARD_W := 132.0
const CARD_H := 118.0

@onready var matrix_overlay: Node2D = $MatrixOverlay
@onready var scanlines: Node2D = $Scanlines
@onready var link_layer: Node2D = $LinkLayer
@onready var skill_nodes_layer: Control = $SkillNodesLayer
@onready var credits_lbl: Label = $BottomBar/CreditsLabel
@onready var progress_lbl: Label = $BottomBar/ProgressLabel
@onready var preview_panel: Panel = $PreviewPanel
@onready var preview_title: Label = $PreviewPanel/PreviewTitle
@onready var preview_body: Label = $PreviewPanel/PreviewBody
@onready var preview_cost: Label = $PreviewPanel/PreviewCost

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
var node_buttons: Dictionary = {}
var node_icons: Dictionary = {}

func _ready() -> void:
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_skills"):
		GameState.lifetime_credits_earned = 5000
		GameState.credits = 5000
		GameState.skill_levels["speed1"] = 3
		GameState.skill_levels["radius1"] = 5
	Audio.play_ambient()
	matrix_overlay.draw.connect(_draw_matrix_bg)
	scanlines.draw.connect(_draw_scanlines)
	_style_chrome()
	$BottomBar/ResumeButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))
	$BottomBar/NetworksButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/NetworkSelect.tscn"))
	_define_skills()
	_draw_links()
	_build_nodes()
	_refresh_hud()

func _style_chrome() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(18, 22, 30)
	sb.border_color = COL_CYAN
	sb.set_border_width_all(2)
	preview_panel.add_theme_stylebox_override("panel", sb)
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = COL_BACKDROP
	rsb.border_color = COL_GREEN
	rsb.set_border_width_all(2)
	$BottomBar/ResumeButton.add_theme_stylebox_override("normal", rsb)
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = COL_BACKDROP
	bsb.border_color = COL_DIM
	bsb.set_border_width_all(2)
	$BottomBar/NetworksButton.add_theme_stylebox_override("normal", bsb)
	var botsb := StyleBoxFlat.new()
	botsb.bg_color = COL_PANEL
	botsb.border_width_top = 2
	botsb.border_color = Color8(40, 50, 60)
	$BottomBar.add_theme_stylebox_override("panel", botsb)

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

func _draw_matrix_bg() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in range(60):
		var x: float = rng.randf_range(0, 1280)
		var y: float = rng.randf_range(0, 720)
		if rng.randf() < 0.1:
			matrix_overlay.draw_rect(Rect2(x, y, 2, 2), Color8(30, 50, 42), true)

func _draw_scanlines() -> void:
	var y := 0
	while y < 720:
		scanlines.draw_rect(Rect2(0, y, 1280, 1), Color(1, 1, 1, 0.012), true)
		y += 3

func _draw_links() -> void:
	link_layer.draw.connect(func():
		for c in range(COLS):
			link_layer.draw_line(_pos(0, c), _pos(ROWS - 1, c), COL_LINE, 2.0)
		link_layer.draw_line(_pos(0, 0), _pos(0, COLS - 1), COL_LINE, 2.0)
	)

func _build_nodes() -> void:
	for s in skills:
		var p := _pos(s.row, s.col)
		var btn := Button.new()
		btn.position = p - Vector2(CARD_W / 2.0, CARD_H / 2.0)
		btn.size = Vector2(CARD_W, CARD_H)
		btn.text = ""
		btn.pressed.connect(_on_node_pressed.bind(s, btn))
		btn.mouse_entered.connect(_on_node_hover.bind(s, true))
		btn.mouse_exited.connect(_on_node_hover.bind(s, false))
		skill_nodes_layer.add_child(btn)
		node_buttons[s.id] = btn

		var header := Node2D.new()
		header.position = p - Vector2(CARD_W / 2.0, CARD_H / 2.0)
		skill_nodes_layer.add_child(header)
		header.draw.connect(_draw_card_header.bind(header, s))
		node_icons[s.id + "_header"] = header

		var icon_node := _SkillIcon.new()
		icon_node.icon_key = s.icon
		icon_node.max_level = s.max_level
		icon_node.position = p - Vector2(0, 30)
		skill_nodes_layer.add_child(icon_node)
		node_icons[s.id] = icon_node

		var name_lbl := Label.new()
		name_lbl.position = p - Vector2(CARD_W / 2.0 - 4, -6)
		name_lbl.size = Vector2(CARD_W - 8, 30)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_lbl.add_theme_font_size_override("font_size", 12)
		skill_nodes_layer.add_child(name_lbl)
		node_icons[s.id + "_name"] = name_lbl

		var sub_lbl := Label.new()
		sub_lbl.position = p - Vector2(CARD_W / 2.0 - 4, -42)
		sub_lbl.size = Vector2(CARD_W - 8, 18)
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_font_size_override("font_size", 11)
		skill_nodes_layer.add_child(sub_lbl)
		node_icons[s.id + "_sub"] = sub_lbl

		_refresh_node(s, btn)

func _on_node_hover(s, entered: bool) -> void:
	var icon_node: Node2D = node_icons.get(s.id)
	if entered:
		_show_preview(s)
		if icon_node:
			icon_node.hovered = true
			icon_node.queue_redraw()
	else:
		_hide_preview()
		if icon_node:
			icon_node.hovered = false
			icon_node.queue_redraw()

func _draw_card_header(node: Node2D, s) -> void:
	var col := _state_color(s)
	node.draw_rect(Rect2(0, 0, CARD_W, 20), Color(col.r, col.g, col.b, 0.16), true)
	node.draw_line(Vector2(0, 20), Vector2(CARD_W, 20), col, 1.0)
	for d in range(3):
		node.draw_rect(Rect2(8 + d * 11, 8, 6, 6), Color(col.r, col.g, col.b, 0.7), true)

func _state_color(s) -> Color:
	if not _is_revealed(s) or s.max_level == 0:
		return COL_LOCKED
	var lvl: int = GameState.skill_levels.get(s.id, 0)
	if lvl > 0:
		return COL_GREEN
	return COL_CYAN

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
	var name_lbl: Label = node_icons[s.id + "_name"]
	var sub_lbl: Label = node_icons[s.id + "_sub"]
	var icon_node: _SkillIcon = node_icons[s.id]
	var header: Node2D = node_icons[s.id + "_header"]
	var lvl: int = GameState.skill_levels.get(s.id, 0)
	icon_node.level = lvl
	if not _is_revealed(s):
		name_lbl.text = "???"
		sub_lbl.text = "locked"
		name_lbl.add_theme_color_override("font_color", COL_LOCKED)
		sub_lbl.add_theme_color_override("font_color", Color8(140, 70, 85))
		btn.add_theme_stylebox_override("normal", _skill_stylebox("locked"))
		icon_node.col = COL_LOCKED
	elif s.max_level == 0:
		name_lbl.text = s.label
		sub_lbl.text = "—"
		name_lbl.add_theme_color_override("font_color", COL_DIM)
		sub_lbl.add_theme_color_override("font_color", COL_DIM)
		btn.add_theme_stylebox_override("normal", _skill_stylebox("locked"))
		icon_node.col = COL_DIM
	elif lvl >= s.max_level:
		name_lbl.text = s.label
		sub_lbl.text = "MAX %d/%d" % [lvl, s.max_level]
		name_lbl.add_theme_color_override("font_color", COL_GREEN)
		sub_lbl.add_theme_color_override("font_color", COL_GREEN)
		btn.add_theme_stylebox_override("normal", _skill_stylebox("active"))
		icon_node.col = COL_GREEN
	else:
		var cost: int = int(s.cost * pow(1.5, lvl))
		name_lbl.text = s.label
		if GameState.credits >= cost:
			sub_lbl.text = "%d◈  Lv %d→%d" % [cost, lvl, lvl + 1]
			name_lbl.add_theme_color_override("font_color", COL_CYAN)
			sub_lbl.add_theme_color_override("font_color", COL_CYAN)
			btn.add_theme_stylebox_override("normal", _skill_stylebox("available"))
			icon_node.col = COL_CYAN
		else:
			sub_lbl.text = "%d◈ credits" % cost
			name_lbl.add_theme_color_override("font_color", Color8(150, 170, 185))
			sub_lbl.add_theme_color_override("font_color", COL_DIM)
			btn.add_theme_stylebox_override("normal", _skill_stylebox("available"))
			icon_node.col = COL_DIM
	icon_node.queue_redraw()
	header.queue_redraw()

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

class _SkillIcon extends Node2D:
	var icon_key: String
	var col: Color = Color8(0, 229, 255)
	var level: int = 0
	var max_level: int = 0
	var hovered: bool = false
	var _tex: Texture2D
	func _ready() -> void:
		_tex = KHArt.tex("icons", icon_key)
		queue_redraw()
	func _draw() -> void:
		var glow_r := 24.0 if hovered else 20.0
		draw_circle(Vector2.ZERO, glow_r, Color(col.r, col.g, col.b, 0.14))
		draw_arc(Vector2.ZERO, glow_r, 0, TAU, 28, Color(col.r, col.g, col.b, 0.5), 1.0)
		if _tex:
			var sz := 30.0 if hovered else 26.0
			draw_texture_rect(_tex, Rect2(-sz / 2.0, -sz / 2.0, sz, sz), false, col)
		if max_level > 0:
			var pip_w := 10.0
			var gap := 4.0
			var total_w := max_level * pip_w + (max_level - 1) * gap
			var start_x := -total_w / 2.0
			var track := Rect2(start_x - 3, 25, total_w + 6, 10)
			draw_rect(track, Color8(8, 10, 15), true)
			draw_rect(track, Color(col.r, col.g, col.b, 0.3), false, 1.0)
			for i in range(max_level):
				var filled := i < level
				var c := col if filled else Color8(42, 48, 58)
				draw_rect(Rect2(start_x + i * (pip_w + gap), 27, pip_w, 6), c, true)
