extends Node2D

const COL_BACKDROP := Color8(4, 5, 8)
const COL_PANEL := Color8(10, 12, 18)
const COL_HEADER := Color8(14, 17, 25)
const COL_TEXT := Color8(220, 240, 255)
const COL_DIM := Color8(110, 120, 135)
const COL_CYAN := Color8(0, 229, 255)
const COL_MAGENTA := Color8(255, 46, 146)
const COL_AMBER := Color8(255, 184, 48)

var panels: Array[Panel] = []
var cursor_lbl: Label
var cursor_t: float = 0.0

func _ready() -> void:
	Audio.play_ambient()
	set_process(true)
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_breach"):
		get_tree().create_timer(0.6).timeout.connect(func(): _on_breach(0))

	var bg := ColorRect.new()
	bg.color = COL_BACKDROP
	bg.size = Vector2(1280, 720)
	add_child(bg)

	var mesh := Node2D.new()
	mesh.z_index = -5
	add_child(mesh)
	mesh.draw.connect(_draw_matrix_bg.bind(mesh))

	var scan := Node2D.new()
	scan.z_index = -4
	add_child(scan)
	scan.draw.connect(_draw_scanlines.bind(scan))

	var prompt := _label("root@keephacking:~$ select_target --list", Color8(70, 100, 85), 13, Vector2(64, 26))
	add_child(prompt)
	cursor_lbl = _label("_", Color8(57,255,106), 13, Vector2(64 + prompt.text.length() * 7.5, 26))
	add_child(cursor_lbl)

	var title := _label("[ KEEP HACKING ]", Color8(57,255,106), 38, Vector2(420, 48))
	title.add_theme_font_size_override("font_size", 38)
	add_child(title)
	var sub := _label("select a target network to breach", COL_DIM, 14, Vector2(470, 98))
	add_child(sub)

	var panel_w := 264
	var gap := 24
	var start_x := (1280 - (panel_w * 4 + gap * 3)) / 2
	for i in range(4):
		var tier: Dictionary = GameState.TIERS[i]
		var p := Panel.new()
		p.position = Vector2(start_x + i * (panel_w + gap), 140)
		p.size = Vector2(panel_w, 470)
		var sb := StyleBoxFlat.new()
		sb.bg_color = COL_PANEL
		sb.border_color = tier["color"]
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(0)
		p.add_theme_stylebox_override("panel", sb)
		add_child(p)
		panels.append(p)

		var header := Panel.new()
		header.position = Vector2(0, 0)
		header.size = Vector2(panel_w, 30)
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color(tier["color"].r, tier["color"].g, tier["color"].b, 0.14)
		hsb.border_color = tier["color"]
		hsb.border_width_bottom = 2
		header.add_theme_stylebox_override("panel", hsb)
		p.add_child(header)
		for d in range(3):
			var dot := ColorRect.new()
			dot.color = Color(tier["color"].r, tier["color"].g, tier["color"].b, 0.6)
			dot.size = Vector2(6, 6)
			dot.position = Vector2(10 + d * 12, 12)
			header.add_child(dot)

		var decor := Node2D.new()
		p.add_child(decor)
		decor.draw.connect(_draw_card_decor.bind(decor, tier["color"], i, panel_w))

		var name_lbl := _label("> " + str(tier["name"]), tier["color"], 16, Vector2(16, 42))
		p.add_child(name_lbl)

		var icon := _TierIcon.new()
		icon.col = tier["color"]
		icon.position = Vector2(panel_w / 2.0, 150)
		p.add_child(icon)

		var unlocked: bool = GameState.unlocked_tiers[i]
		if unlocked:
			var mult_lbl := _label("node value  x%.1f" % tier["node_mult"], COL_TEXT, 13, Vector2(16, 250))
			p.add_child(mult_lbl)
			var trait_text: String = tier.get("trait_name", "")
			if trait_text != "":
				var trait_lbl := Label.new()
				trait_lbl.text = trait_text
				trait_lbl.position = Vector2(16, 280)
				trait_lbl.size = Vector2(panel_w - 32, 100)
				trait_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
				trait_lbl.add_theme_color_override("font_color", tier["color"])
				trait_lbl.add_theme_font_size_override("font_size", 12)
				p.add_child(trait_lbl)
			var btn := Button.new()
			btn.text = "BREACH ▸"
			btn.position = Vector2(16, 404)
			btn.size = Vector2(panel_w - 32, 44)
			var bsb := StyleBoxFlat.new()
			bsb.bg_color = COL_BACKDROP
			bsb.border_color = tier["color"]
			bsb.set_border_width_all(2)
			bsb.set_corner_radius_all(0)
			btn.add_theme_stylebox_override("normal", bsb)
			btn.add_theme_color_override("font_color", tier["color"])
			btn.pressed.connect(_on_breach.bind(i))
			p.add_child(btn)
		else:
			var cost: int = tier["unlock_cost"]
			var lock_lbl := _label("[ LOCKED ]", COL_DIM, 15, Vector2(16, 250))
			p.add_child(lock_lbl)
			var cost_lbl := _label("unlock: %d◈ credits" % cost, COL_DIM, 13, Vector2(16, 280))
			p.add_child(cost_lbl)
			var teaser: String = tier.get("trait_name", "")
			if teaser != "":
				var teaser_lbl := Label.new()
				teaser_lbl.text = teaser
				teaser_lbl.position = Vector2(16, 310)
				teaser_lbl.size = Vector2(panel_w - 32, 90)
				teaser_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
				teaser_lbl.add_theme_color_override("font_color", COL_DIM)
				teaser_lbl.add_theme_font_size_override("font_size", 11)
				p.add_child(teaser_lbl)
			var btn := Button.new()
			btn.text = "UNLOCK"
			btn.position = Vector2(16, 404)
			btn.size = Vector2(panel_w - 32, 44)
			var bsb := StyleBoxFlat.new()
			bsb.bg_color = COL_BACKDROP
			bsb.border_color = COL_DIM
			bsb.set_border_width_all(2)
			bsb.set_corner_radius_all(0)
			btn.add_theme_stylebox_override("normal", bsb)
			btn.add_theme_color_override("font_color", COL_DIM)
			btn.pressed.connect(_on_unlock.bind(i))
			p.add_child(btn)

	var bottom := Panel.new()
	bottom.position = Vector2(0, 656)
	bottom.size = Vector2(1280, 64)
	var botsb := StyleBoxFlat.new()
	botsb.bg_color = COL_HEADER
	botsb.border_color = Color8(30, 38, 48)
	botsb.border_width_top = 2
	botsb.set_corner_radius_all(0)
	bottom.add_theme_stylebox_override("panel", botsb)
	add_child(bottom)

	credits_lbl = _label("◈ %d" % GameState.credits, COL_CYAN, 18, Vector2(24, 18))
	bottom.add_child(credits_lbl)
	exploits_lbl = _label("※ %d" % GameState.exploits, COL_MAGENTA, 18, Vector2(140, 18))
	bottom.add_child(exploits_lbl)
	zerodays_lbl = _label("♦ %d" % GameState.zerodays, COL_AMBER, 18, Vector2(256, 18))
	bottom.add_child(zerodays_lbl)

	var skill_btn := Button.new()
	skill_btn.text = "SKILL TREE ▸"
	skill_btn.position = Vector2(1056, 8)
	skill_btn.size = Vector2(204, 40)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = COL_BACKDROP
	ssb.border_color = Color8(57,255,106)
	ssb.set_border_width_all(2)
	ssb.set_corner_radius_all(0)
	skill_btn.add_theme_stylebox_override("normal", ssb)
	skill_btn.add_theme_color_override("font_color", Color8(57,255,106))
	skill_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/SkillTree.tscn"))
	bottom.add_child(skill_btn)

var credits_lbl: Label
var exploits_lbl: Label
var zerodays_lbl: Label

func _process(delta: float) -> void:
	cursor_t += delta
	if cursor_lbl:
		cursor_lbl.visible = fmod(cursor_t, 1.0) < 0.5

func _draw_matrix_bg(node: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for x in range(0, 1280, 28):
		for y in range(0, 720, 28):
			if rng.randf() < 0.08:
				node.draw_rect(Rect2(x, y, 2, 2), Color8(30, 60, 45), true)

func _draw_scanlines(node: Node2D) -> void:
	var y := 0
	while y < 720:
		node.draw_rect(Rect2(0, y, 1280, 1), Color(1, 1, 1, 0.012), true)
		y += 3

func _draw_card_decor(node: Node2D, col: Color, seed_i: int, panel_w: int) -> void:
	var dim := Color(col.r, col.g, col.b, 0.14)
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + seed_i
	for i in range(10):
		var x: float = rng.randf_range(10, panel_w - 10)
		var y: float = rng.randf_range(60, 430)
		if y > 230 and y < 400:
			continue
		var w: float = rng.randf_range(10, 36)
		node.draw_rect(Rect2(x, y, w, 2), dim, true)
		node.draw_circle(Vector2(x, y), 1.6, dim)
	for i in range(5):
		var cx: float = rng.randf_range(20, panel_w - 20)
		var cy: float = rng.randf_range(300, 395)
		node.draw_rect(Rect2(cx, cy, 14, 18), Color(col.r, col.g, col.b, 0.1), true)
		node.draw_rect(Rect2(cx, cy, 14, 18), dim, false, 1.0)

func _label(text: String, col: Color, size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", size)
	return l

func _on_breach(i: int) -> void:
	GameState.selected_tier = i
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_unlock(i: int) -> void:
	if GameState.try_unlock_tier(i):
		Audio.play_breach()
		get_tree().reload_current_scene()
	else:
		Audio.play_denied()

class _TierIcon extends Node2D:
	var col: Color
	func _ready() -> void:
		queue_redraw()
	func _draw() -> void:
		draw_rect(Rect2(-50, -40, 100, 80), Color8(6,8,13), true)
		draw_rect(Rect2(-50, -40, 100, 80), col, false, 2.0)
		for i in range(3):
			var y: float = -22 + i * 22
			draw_rect(Rect2(-40, y, 80, 14), Color8(12,16,24), true)
			draw_rect(Rect2(-40, y, 80, 14), col, false, 1.0)
			draw_rect(Rect2(-36, y + 4, 6, 6), col, true)
