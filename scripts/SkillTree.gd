extends Node2D

const COL_BACKDROP := Color8(6, 8, 13)
const COL_PANEL := Color8(12, 15, 22)
const COL_LINE := Color8(40, 50, 60)
const COL_GREEN := Color8(57, 255, 106)
const COL_CYAN := Color8(0, 229, 255)
const COL_DIM := Color8(90, 100, 115)

class SkillDef:
	var id: String
	var label: String
	var icon: String
	var pos: Vector2
	var cost: int
	var max_level: int
	var apply: Callable
	var desc: String
	func _init(p_id, p_label, p_icon, p_pos, p_cost, p_max, p_apply, p_desc) -> void:
		id = p_id; label = p_label; icon = p_icon; pos = p_pos
		cost = p_cost; max_level = p_max; apply = p_apply; desc = p_desc

var levels: Dictionary = {}
var skills: Array = []
var credits_lbl: Label
var node_buttons: Dictionary = {}
var node_icons: Dictionary = {}
var preview_panel: Panel
var preview_title: Label
var preview_body: Label
var preview_cost: Label

func _ready() -> void:
	Audio.play_ambient()
	var bg := ColorRect.new()
	bg.color = COL_BACKDROP
	bg.size = Vector2(1280, 720)
	add_child(bg)

	_define_skills()
	_draw_links()
	_build_nodes()
	_build_hud()
	_build_preview_panel()

func _define_skills() -> void:
	var center := Vector2(640, 380)
	skills = [
		SkillDef.new("speed1", "FASTER CRACK", "bolt", center + Vector2(-220, -120), 30, 5, func(): GameState.decrypt_speed += 0.2, "+0.2 crack speed per level"),
		SkillDef.new("speed2", "BURST DECRYPT", "bolt2", center + Vector2(-380, -160), 150, 3, func(): GameState.decrypt_speed += 0.5, "+0.5 crack speed per level"),
		SkillDef.new("radius1", "WIDER SCAN", "scan", center + Vector2(-220, 120), 40, 5, func(): GameState.decrypt_radius += 6.0, "+6 scan radius per level"),
		SkillDef.new("radius2", "DEEP SCAN", "scan2", center + Vector2(-380, 160), 180, 3, func(): GameState.decrypt_radius += 14.0, "+14 scan radius per level"),
		SkillDef.new("bot1", "DEPLOY BOT", "bot", center + Vector2(220, -120), 120, 4, func(): GameState.bot_level += 1, "+1 auto-crack bot per level"),
		SkillDef.new("bot2", "BOTNET SWARM", "bot2", center + Vector2(380, -160), 500, 2, func(): GameState.bot_level += 2, "+2 auto-crack bots per level"),
		SkillDef.new("yield1", "DATA COMPRESS", "cash", center + Vector2(220, 120), 60, 5, func(): GameState.yield_mult += 0.15, "+15% credits from every node, per level"),
		SkillDef.new("yield2", "ZERO-DAY CACHE", "diamond", center + Vector2(380, 160), 800, 3, func(): GameState.zerodays += 1, "+1 0-day per level"),
		SkillDef.new("duration1", "STEALTH ROUTING", "clock", center + Vector2(0, -230), 80, 4, func(): GameState.round_duration += 4.0, "+4s per run before the backdoor fully charges"),
		SkillDef.new("forensics1", "COUNTER-FORENSICS", "shield", center + Vector2(0, 230), 150, 3, func(): GameState.honeypot_penalty_mult = max(0.2, GameState.honeypot_penalty_mult - 0.25), "-25% alarm penalty from tripped honeypots"),
	]
	for s in skills:
		levels[s.id] = 0

func _draw_links() -> void:
	var line_node := Node2D.new()
	add_child(line_node)
	var center := Vector2(640, 380)
	line_node.draw.connect(func():
		line_node.draw_circle(center, 36, COL_PANEL)
		line_node.draw_arc(center, 36, 0, TAU, 32, COL_GREEN, 2.0)
		for s in skills:
			var parent_pos: Vector2 = center
			for other in skills:
				if other.pos.distance_to(s.pos) < 180 and other != s and other.pos.distance_to(center) < s.pos.distance_to(center):
					parent_pos = other.pos
			line_node.draw_line(center if parent_pos == center else parent_pos, s.pos, COL_LINE, 2.0)
	)

func _build_nodes() -> void:
	var center_lbl := _label("◆", COL_GREEN, 28, Vector2(632, 366))
	add_child(center_lbl)
	for s in skills:
		var btn := Button.new()
		btn.text = "\n\n%s\nLv0" % s.label
		btn.position = s.pos - Vector2(55, 40)
		btn.size = Vector2(110, 80)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		var sb := StyleBoxFlat.new()
		sb.bg_color = COL_PANEL
		sb.border_color = COL_CYAN
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_color_override("font_color", COL_CYAN)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_node_pressed.bind(s, btn))
		btn.mouse_entered.connect(_show_preview.bind(s))
		btn.mouse_exited.connect(_hide_preview)
		add_child(btn)
		node_buttons[s.id] = btn

		var icon_node := _SkillIcon.new()
		icon_node.icon_key = s.icon
		icon_node.col = COL_CYAN
		icon_node.position = s.pos - Vector2(0, 16)
		add_child(icon_node)
		node_icons[s.id] = icon_node

		_refresh_node(s, btn)

func _on_node_pressed(s, btn: Button) -> void:
	if levels[s.id] >= s.max_level:
		return
	var cost: int = int(s.cost * pow(1.6, levels[s.id]))
	if GameState.credits >= cost:
		GameState.credits -= cost
		levels[s.id] += 1
		s.apply.call()
		_refresh_node(s, btn)
		_refresh_hud()
		_show_preview(s)
		Audio.play_upgrade()
	else:
		Audio.play_denied()

func _refresh_node(s, btn: Button) -> void:
	var lvl: int = levels[s.id]
	var icon_node: Node2D = node_icons[s.id]
	if lvl >= s.max_level:
		btn.text = "\n\n%s\nMAX" % s.label
		var sb := StyleBoxFlat.new()
		sb.bg_color = COL_PANEL
		sb.border_color = COL_GREEN
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_color_override("font_color", COL_GREEN)
		icon_node.col = COL_GREEN
	else:
		var cost: int = int(s.cost * pow(1.6, lvl))
		btn.text = "\n\n%s\nLv%d (%d)" % [s.label, lvl, cost]
	icon_node.queue_redraw()

func _build_hud() -> void:
	var bottom := Panel.new()
	bottom.position = Vector2(0, 660)
	bottom.size = Vector2(1280, 60)
	add_child(bottom)
	credits_lbl = _label("◈ %d CREDITS" % GameState.credits, COL_CYAN, 18, Vector2(24, 16))
	bottom.add_child(credits_lbl)

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
	preview_panel.position = Vector2(500, 20)
	preview_panel.size = Vector2(280, 90)
	preview_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(18, 22, 30)
	sb.border_color = COL_CYAN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	preview_panel.add_theme_stylebox_override("panel", sb)
	add_child(preview_panel)

	preview_title = _label("", COL_CYAN, 15, Vector2(12, 8))
	preview_panel.add_child(preview_title)
	preview_body = _label("", Color8(200, 210, 220), 12, Vector2(12, 32))
	preview_panel.add_child(preview_body)
	preview_cost = _label("", Color8(255, 184, 48), 13, Vector2(12, 60))
	preview_panel.add_child(preview_cost)

func _show_preview(s) -> void:
	var lvl: int = levels[s.id]
	preview_title.text = s.label
	preview_body.text = s.desc
	if lvl >= s.max_level:
		preview_cost.text = "MAX LEVEL (%d/%d)" % [lvl, s.max_level]
	else:
		var cost: int = int(s.cost * pow(1.6, lvl))
		preview_cost.text = "%d → %d   cost: %d credits" % [lvl, lvl + 1, cost]
	preview_panel.visible = true

func _hide_preview() -> void:
	preview_panel.visible = false

func _refresh_hud() -> void:
	credits_lbl.text = "◈ %d CREDITS" % GameState.credits

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
	func _ready() -> void:
		queue_redraw()
	func _draw() -> void:
		match icon_key:
			"bolt":
				draw_colored_polygon(PackedVector2Array([Vector2(2,-10), Vector2(-6,2), Vector2(-1,2), Vector2(-3,10), Vector2(6,-2), Vector2(1,-2)]), col)
			"bolt2":
				draw_colored_polygon(PackedVector2Array([Vector2(-4,-10), Vector2(-10,2), Vector2(-6,2), Vector2(-8,10), Vector2(0,-2), Vector2(-4,-2)]), col)
				draw_colored_polygon(PackedVector2Array([Vector2(8,-10), Vector2(2,2), Vector2(6,2), Vector2(4,10), Vector2(12,-2), Vector2(8,-2)]), col)
			"scan":
				draw_arc(Vector2.ZERO, 9, 0, TAU, 20, col, 2.0)
				draw_circle(Vector2.ZERO, 2, col)
			"scan2":
				draw_arc(Vector2.ZERO, 10, 0, TAU, 20, col, 2.0)
				draw_arc(Vector2.ZERO, 5, 0, TAU, 16, col, 1.5)
				draw_circle(Vector2.ZERO, 1.5, col)
			"bot":
				draw_rect(Rect2(-9, -7, 18, 14), col, false, 2.0)
				draw_circle(Vector2(-4, 0), 1.5, col)
				draw_circle(Vector2(4, 0), 1.5, col)
				draw_line(Vector2(0, -7), Vector2(0, -12), col, 1.5)
			"bot2":
				draw_rect(Rect2(-13, -7, 12, 14), col, false, 1.5)
				draw_rect(Rect2(1, -7, 12, 14), col, false, 1.5)
			"cash":
				draw_arc(Vector2.ZERO, 9, 0, TAU, 20, col, 2.0)
				draw_string(ThemeDB.fallback_font, Vector2(-4, 5), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
			"diamond":
				draw_colored_polygon(PackedVector2Array([Vector2(0,-10), Vector2(9,-1), Vector2(0,10), Vector2(-9,-1)]), col)
			"clock":
				draw_arc(Vector2.ZERO, 9, 0, TAU, 20, col, 2.0)
				draw_line(Vector2.ZERO, Vector2(0, -6), col, 1.5)
				draw_line(Vector2.ZERO, Vector2(4, 2), col, 1.5)
			"shield":
				draw_colored_polygon(PackedVector2Array([Vector2(0,-10), Vector2(8,-6), Vector2(8,2), Vector2(0,10), Vector2(-8,2), Vector2(-8,-6)]), Color(col.r, col.g, col.b, 0.25))
				var pts := PackedVector2Array([Vector2(0,-10), Vector2(8,-6), Vector2(8,2), Vector2(0,10), Vector2(-8,2), Vector2(-8,-6), Vector2(0,-10)])
				draw_polyline(pts, col, 2.0)
