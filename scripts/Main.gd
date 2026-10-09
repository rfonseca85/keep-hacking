extends Node2D

const GRID_COLS := 12
const GRID_ROWS := 7
const CELL := 64
const GRID_ORIGIN := Vector2(160, 140)
const MIN_NODE_DIST_CELLS := 2

const COL_BACKDROP := Color8(6, 8, 13)
const COL_GRID_LINE := Color8(16, 22, 32)
const COL_CYAN := Color8(0, 229, 255)
const COL_GREEN := Color8(57, 255, 106)
const COL_MAGENTA := Color8(255, 46, 146)
const COL_AMBER := Color8(255, 184, 48)
const COL_PANEL := Color8(12, 15, 22)

var nodes_layer: Node2D
var grid_bg: Node2D
var hud: CanvasLayer
var fx_layer: Node2D
var cam: Camera2D
var shake_t: float = 0.0
var shake_amp: float = 0.0
var rig_t: float = 0.0
var rig_node: Node2D
var tick_timer: float = 0.0
var scan_fx_timer: float = 0.0

var bot_timer: float = 0.0
var tier: Dictionary

var hunter_bots: Array = []
var hunter_layer: Node2D
const HUNTER_SPEED := 160.0
const HUNTER_CRACK_SPEED := 0.6
const HUNTER_RADIUS := 16.0

var row_wipe_timer: float = 0.0

var ultimate_cooldown: float = 0.0
var ultimate_btn: Button
var ultimate_cd_bar: ProgressBar

var trace_progress: float = 1.0

var round_active: bool = true
var round_start_credits: int = 0
var round_start_exploits: int = 0
var round_start_zerodays: int = 0

var is_decrypting: bool = true
var mouse_pos: Vector2 = Vector2.ZERO

var cells: Array[ServerNode] = []
var all_cell_positions: Array[Vector2] = []

var credits_label: Label
var exploits_label: Label
var zerodays_label: Label
var tier_label: Label
var trace_bar: ProgressBar
var trace_label: Label

var _shown_credits: int = -1
var _shown_exploits: int = -1
var _shown_zerodays: int = -1

var summary_panel: Panel
var summary_credits_lbl: Label
var summary_exploits_lbl: Label
var summary_zerodays_lbl: Label

func _ready() -> void:
	if OS.is_debug_build():
		for a in OS.get_cmdline_user_args():
			if a.begins_with("autotest_tier="):
				GameState.selected_tier = int(a.split("=")[1])
		if OS.get_cmdline_user_args().has("autotest_abilities"):
			GameState.hunter_bot_count = 2
			GameState.row_wipe_level = 2
			GameState.ultimate_wipe_level = 2
			GameState.max_nodes = 10
	tier = GameState.TIERS[GameState.selected_tier]
	round_start_credits = GameState.credits
	round_start_exploits = GameState.exploits
	round_start_zerodays = GameState.zerodays
	Audio.play_ambient()
	get_viewport().transparent_bg = false
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	_build_background()
	_build_grid()
	fx_layer = Node2D.new()
	add_child(fx_layer)
	hunter_layer = Node2D.new()
	add_child(hunter_layer)
	hunter_layer.draw.connect(_draw_hunters.bind(hunter_layer))
	_build_hud()
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_endround"):
		GameState.add_credits(342)
		GameState.exploits += 3
		GameState.zerodays += 1
		get_tree().create_timer(0.5).timeout.connect(_end_round)
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_fx"):
		VisualFX.play(fx_layer, Vector2(400, 300), "data_extract", 8, 18.0, COL_GREEN)
		VisualFX.play(fx_layer, Vector2(500, 300), "glitch", 8, 16.0, COL_MAGENTA)
		VisualFX.play(fx_layer, Vector2(600, 300), "scan_pulse", 10, 20.0, COL_CYAN)
		var fx_count := fx_layer.get_child_count()
		print("FX_SMOKE: spawned=%d (expected 3)" % fx_count)
		get_tree().create_timer(1.5).timeout.connect(func():
			print("FX_SMOKE: after 1.5s remaining=%d (expected 0)" % fx_layer.get_child_count())
		)
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_audio"):
		Audio.play_tick()
		Audio.play_exfiltrate()
		Audio.play_exploit()
		Audio.play_upgrade()
		Audio.play_breach()
		Audio.play_denied()
		print("AUDIO_SMOKE_OK")
	set_process(true)
	set_process_input(true)

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = COL_BACKDROP
	bg.size = Vector2(1280, 720)
	bg.position = Vector2.ZERO
	bg.z_index = -10
	add_child(bg)

	var circuit := Node2D.new()
	circuit.z_index = -9
	add_child(circuit)
	circuit.draw.connect(_draw_circuit_decor.bind(circuit))

	rig_node = Node2D.new()
	rig_node.z_index = -4
	add_child(rig_node)
	rig_node.draw.connect(_draw_rig_panel.bind(rig_node))

	grid_bg = Node2D.new()
	grid_bg.z_index = -5
	add_child(grid_bg)
	grid_bg.draw.connect(_draw_grid_lines.bind(grid_bg))

	packets_layer = Node2D.new()
	packets_layer.z_index = -3
	add_child(packets_layer)
	packets_layer.draw.connect(_draw_packets.bind(packets_layer))
	_init_packet_lanes()

func _draw_circuit_decor(node: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var circuit_a := KHArt.tex("tiles", "circuit_a")
	var circuit_b := KHArt.tex("tiles", "circuit_b")
	var props_decor := ["cooling_fan", "satellite_dish", "relay_tower", "antenna", "neon_crate", "signal_orb"]
	for i in range(30):
		var x: float = rng.randf_range(0, 1280)
		var y: float = rng.randf_range(0, 720)
		var in_grid := x > GRID_ORIGIN.x - 20 and x < GRID_ORIGIN.x + GRID_COLS * CELL + 20 \
			and y > GRID_ORIGIN.y - 20 and y < GRID_ORIGIN.y + GRID_ROWS * CELL + 20
		if in_grid or y < 115 or x < 190:
			continue
		var tile_tex := circuit_a if rng.randf() > 0.5 else circuit_b
		if tile_tex:
			node.draw_texture_rect(tile_tex, Rect2(Vector2(x, y), Vector2(32, 32)), false, Color(1, 1, 1, 0.5))
	for i in range(7):
		var x: float = rng.randf_range(210, 1240)
		var y: float = rng.randf_range(130, 700)
		var in_grid := x > GRID_ORIGIN.x - 40 and x < GRID_ORIGIN.x + GRID_COLS * CELL + 40 \
			and y > GRID_ORIGIN.y - 40 and y < GRID_ORIGIN.y + GRID_ROWS * CELL + 40
		if in_grid:
			continue
		var prop_tex := KHArt.tex("props", props_decor[rng.randi_range(0, props_decor.size() - 1)])
		if prop_tex:
			node.draw_texture_rect(prop_tex, Rect2(Vector2(x, y), Vector2(40, 40)), false, Color(1, 1, 1, 0.8))

var packets_layer: Node2D
var packet_lanes: Array = []

func _init_packet_lanes() -> void:
	packet_lanes.clear()
	for c in range(2, GRID_COLS - 1, 3):
		var x := GRID_ORIGIN.x + c * CELL
		packet_lanes.append({"horizontal": false, "pos": x, "t": randf(), "speed": randf_range(0.08, 0.16)})
	for r in range(1, GRID_ROWS, 2):
		var y := GRID_ORIGIN.y + r * CELL
		packet_lanes.append({"horizontal": true, "pos": y, "t": randf(), "speed": randf_range(0.06, 0.13)})

func _draw_packets(node: Node2D) -> void:
	var grid_end := GRID_ORIGIN + Vector2(GRID_COLS * CELL, GRID_ROWS * CELL)
	for lane in packet_lanes:
		var t: float = lane["t"]
		var p: Vector2
		if lane["horizontal"]:
			p = Vector2(lerp(GRID_ORIGIN.x, grid_end.x, t), lane["pos"])
		else:
			p = Vector2(lane["pos"], lerp(GRID_ORIGIN.y, grid_end.y, t))
		node.draw_circle(p, 2.0, Color8(57, 255, 106, 160))
		node.draw_circle(p, 1.0, Color8(200, 255, 220, 220))

func _draw_rig_panel(node: Node2D) -> void:
	var r := Rect2(28, 140, 112, 420)
	node.draw_rect(r, COL_PANEL, true)
	node.draw_rect(r, COL_GREEN, false, 2.0)
	node.draw_string(ThemeDB.fallback_font, Vector2(42, 165), "RIG", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COL_GREEN)
	for i in range(6):
		var ly := 190 + i * 14
		var on := fmod(rig_t * 1.3 + i * 0.37, 2.0) < 1.0
		var c := COL_GREEN if on else Color8(30, 40, 36)
		node.draw_rect(Rect2(42, ly, 70, 6), c, true)
	var screen_r := Rect2(40, 300, 84, 60)
	node.draw_rect(screen_r, Color8(4, 10, 8), true)
	node.draw_rect(screen_r, COL_CYAN, false, 1.0)
	var bars := int(fmod(rig_t * 2.0, 5.0))
	for i in range(5):
		var h: float = 6 + (i + 1 if i <= bars else 1) * 6
		node.draw_rect(Rect2(48 + i * 15, 354 - h, 8, h), COL_CYAN if i <= bars else Color8(20,50,55), true)

func _draw_grid_lines(node: Node2D) -> void:
	var grid_a := KHArt.tex("tiles", "grid_a")
	var grid_b := KHArt.tex("tiles", "grid_b")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	if grid_a and grid_b:
		var tiles_x := (GRID_COLS * CELL) / 32
		var tiles_y := (GRID_ROWS * CELL) / 32
		for ty in range(tiles_y):
			for tx in range(tiles_x):
				var tex := grid_a if rng.randf() > 0.12 else grid_b
				var pos := GRID_ORIGIN + Vector2(tx * 32, ty * 32)
				node.draw_texture_rect(tex, Rect2(pos, Vector2(32, 32)), false)
	for c in range(GRID_COLS + 1):
		var x := GRID_ORIGIN.x + c * CELL
		node.draw_line(Vector2(x, GRID_ORIGIN.y), Vector2(x, GRID_ORIGIN.y + GRID_ROWS * CELL), COL_GRID_LINE, 1.0)
	for r in range(GRID_ROWS + 1):
		var y := GRID_ORIGIN.y + r * CELL
		node.draw_line(Vector2(GRID_ORIGIN.x, y), Vector2(GRID_ORIGIN.x + GRID_COLS * CELL, y), COL_GRID_LINE, 1.0)

func _build_grid() -> void:
	nodes_layer = Node2D.new()
	add_child(nodes_layer)
	all_cell_positions.clear()
	for r in range(GRID_ROWS):
		for c in range(GRID_COLS):
			all_cell_positions.append(GRID_ORIGIN + Vector2((c + 0.5) * CELL, (r + 0.5) * CELL))
	for i in range(GameState.max_nodes):
		_spawn_node_at_free_position([])

func _active_positions(exclude: ServerNode) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for n in cells:
		if is_instance_valid(n) and n != exclude:
			result.append(n.position)
	return result

func _pick_free_position(avoid: Array[Vector2], exclude: ServerNode = null) -> Vector2:
	var occupied := _active_positions(exclude)
	occupied.append_array(avoid)
	var min_dist := float(MIN_NODE_DIST_CELLS) * CELL
	while min_dist >= 0.0:
		var candidates := all_cell_positions.duplicate()
		candidates.shuffle()
		for pos in candidates:
			var ok := true
			for o in occupied:
				if pos.distance_to(o) < min_dist:
					ok = false
					break
			if ok:
				return pos
		min_dist -= CELL
	return all_cell_positions[randi() % all_cell_positions.size()]

func _spawn_node_at_free_position(avoid: Array[Vector2]) -> ServerNode:
	var n := ServerNode.new()
	n.position = _pick_free_position(avoid)
	n.reset_locked(_spawn_vulnerable(), _spawn_honeypot())
	n.honeypot_expired.connect(_on_honeypot_expired)
	nodes_layer.add_child(n)
	cells.append(n)
	return n

func _respawn_elsewhere(n: ServerNode) -> void:
	var old_pos := n.position
	cells.erase(n)
	n.queue_free()
	_spawn_node_at_free_position([old_pos])

func _spawn_vulnerable() -> bool:
	return randf() < 0.12

func _spawn_honeypot() -> bool:
	return bool(tier.get("honeypots", false)) and randf() < 0.05

func _on_honeypot_expired(n: ServerNode) -> void:
	if not round_active:
		return
	trace_progress = max(0.0, trace_progress - 0.12 * GameState.honeypot_penalty_mult)
	_spawn_floating_text(n.position, "ALARM TRIPPED", COL_MAGENTA)
	VisualFX.play(fx_layer, n.position, "glitch", 8, 16.0, Color8(255, 83, 120))
	_trigger_shake(4.0, 0.2)
	Audio.play_denied()
	_respawn_elsewhere(n)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	var top_panel := Panel.new()
	top_panel.position = Vector2(16, 12)
	top_panel.size = Vector2(300, 100)
	var hud_panel_tex := KHArt.tex("ui", "hud_counter")
	if hud_panel_tex:
		var psb := StyleBoxTexture.new()
		psb.texture = hud_panel_tex
		psb.set_texture_margin_all(8)
		top_panel.add_theme_stylebox_override("panel", psb)
	hud.add_child(top_panel)

	credits_label = _make_counter("credits", "CREDITS: 0", COL_CYAN, Vector2(28, 20))
	exploits_label = _make_counter("exploit", "EXPLOITS: 0", COL_MAGENTA, Vector2(28, 46))
	zerodays_label = _make_counter("key", "0-DAYS: 0", COL_AMBER, Vector2(28, 72))

	trace_label = _make_label("UPLINK STABILITY", COL_GREEN, Vector2(460, 16))
	hud.add_child(trace_label)

	trace_bar = ProgressBar.new()
	trace_bar.position = Vector2(400, 40)
	trace_bar.size = Vector2(480, 24)
	trace_bar.min_value = 0
	trace_bar.max_value = 1
	trace_bar.value = 1
	trace_bar.show_percentage = false
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color = COL_PANEL
	sb_bg.border_color = COL_GRID_LINE
	sb_bg.set_border_width_all(2)
	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = COL_GREEN
	trace_bar.add_theme_stylebox_override("background", sb_bg)
	trace_bar.add_theme_stylebox_override("fill", sb_fill)
	hud.add_child(trace_bar)

	var btn_y := 640
	var skill_btn := _make_upgrade_button("SKILL TREE", Vector2(972, btn_y))
	skill_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/SkillTree.tscn"))
	hud.add_child(skill_btn)

	var back_btn := _make_upgrade_button("← NETWORKS", Vector2(972, btn_y - 52))
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/NetworkSelect.tscn"))
	hud.add_child(back_btn)

	tier_label = _make_label(str(tier["name"]), tier["color"], Vector2(972, 12))
	hud.add_child(tier_label)

	var trait_text: String = tier.get("trait_name", "")
	if trait_text != "":
		var trait_lbl := Label.new()
		trait_lbl.text = trait_text
		trait_lbl.position = Vector2(400, 70)
		trait_lbl.size = Vector2(480, 40)
		trait_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		trait_lbl.add_theme_color_override("font_color", tier["color"])
		trait_lbl.add_theme_font_size_override("font_size", 12)
		hud.add_child(trait_lbl)

	var hint := _make_label("move your mouse over the grid to crack and collect nodes automatically", Color8(120,130,150), Vector2(16, 690))
	hud.add_child(hint)
	_refresh_hud()
	_build_summary_panel()

func _build_summary_panel() -> void:
	summary_panel = Panel.new()
	summary_panel.position = Vector2(964, 108)
	summary_panel.size = Vector2(300, 470)
	summary_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color8(10, 13, 19)
	sb.border_color = COL_GREEN
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	summary_panel.add_theme_stylebox_override("panel", sb)
	hud.add_child(summary_panel)

	var title := _make_label("RUN COMPLETE", COL_GREEN, Vector2(18, 16))
	title.add_theme_font_size_override("font_size", 20)
	summary_panel.add_child(title)
	var sub := Label.new()
	sub.text = "connection lost — here's\nwhat you pulled out this run"
	sub.position = Vector2(18, 46)
	sub.size = Vector2(264, 40)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD
	sub.add_theme_color_override("font_color", Color8(140,150,165))
	sub.add_theme_font_size_override("font_size", 12)
	summary_panel.add_child(sub)

	summary_credits_lbl = _make_label("", COL_CYAN, Vector2(18, 100))
	summary_credits_lbl.add_theme_font_size_override("font_size", 16)
	summary_panel.add_child(summary_credits_lbl)
	summary_exploits_lbl = _make_label("", COL_MAGENTA, Vector2(18, 126))
	summary_exploits_lbl.add_theme_font_size_override("font_size", 16)
	summary_panel.add_child(summary_exploits_lbl)
	summary_zerodays_lbl = _make_label("", COL_AMBER, Vector2(18, 152))
	summary_zerodays_lbl.add_theme_font_size_override("font_size", 16)
	summary_panel.add_child(summary_zerodays_lbl)

	var hint2 := Label.new()
	hint2.text = "spend your credits below in the\nskill tree, then breach again"
	hint2.position = Vector2(18, 190)
	hint2.size = Vector2(264, 40)
	hint2.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint2.add_theme_color_override("font_color", Color8(140,150,165))
	hint2.add_theme_font_size_override("font_size", 12)
	summary_panel.add_child(hint2)

	var again_btn := Button.new()
	again_btn.text = "BREACH AGAIN"
	again_btn.position = Vector2(18, 390)
	again_btn.size = Vector2(264, 44)
	var asb := StyleBoxFlat.new()
	asb.bg_color = COL_PANEL
	asb.border_color = COL_CYAN
	asb.set_border_width_all(2)
	again_btn.add_theme_stylebox_override("normal", asb)
	again_btn.add_theme_color_override("font_color", COL_CYAN)
	again_btn.pressed.connect(func(): get_tree().reload_current_scene())
	summary_panel.add_child(again_btn)

func _end_round() -> void:
	round_active = false
	is_decrypting = false
	trace_progress = 0.0
	trace_bar.value = 0.0
	trace_label.text = "CONNECTION LOST"
	_trigger_shake(8.0, 0.4)
	Audio.play_breach()

	var gained_credits := GameState.credits - round_start_credits
	var gained_exploits := GameState.exploits - round_start_exploits
	var gained_zerodays := GameState.zerodays - round_start_zerodays
	summary_credits_lbl.text = "◈ CREDITS EARNED: %d" % gained_credits
	summary_exploits_lbl.text = "※ EXPLOITS EARNED: %d" % gained_exploits
	summary_zerodays_lbl.text = "♦ 0-DAYS EARNED: %d" % gained_zerodays
	summary_panel.visible = true
	_refresh_hud()

func _make_label(text: String, col: Color, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 18)
	return l

func _make_counter(icon_name: String, text: String, col: Color, pos: Vector2) -> Label:
	var icon_tex := KHArt.tex("icons", icon_name)
	if icon_tex:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.position = pos + Vector2(0, 2)
		icon.custom_minimum_size = Vector2(18, 18)
		icon.size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(icon)
	var l := _make_label(text, col, pos + Vector2(34, 0))
	hud.add_child(l)
	return l

func _pop_counter(l: Label) -> void:
	if l == null:
		return
	l.pivot_offset = Vector2(0, l.size.y / 2.0)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.18, 1.18), 0.07)
	tw.tween_property(l, "scale", Vector2.ONE, 0.07)

func _make_upgrade_button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(228, 44)
	var sb := StyleBoxFlat.new()
	sb.bg_color = COL_PANEL
	sb.border_color = COL_CYAN
	sb.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", COL_CYAN)
	return b

func _input(event: InputEvent) -> void:
	if not round_active:
		return
	if event is InputEventMouseMotion:
		mouse_pos = event.position

func _exfiltrate(n: ServerNode) -> void:
	var gain_text: String
	var fx_col: Color
	var was_honeypot := n.is_honeypot
	if was_honeypot:
		var amt := int(20 * float(tier["node_mult"]))
		GameState.add_credits(amt)
		gain_text = "+%d HONEYPOT" % amt
		fx_col = Color8(255, 60, 60)
		Audio.play_exploit()
	elif n.is_vulnerable:
		GameState.exploits += 1
		gain_text = "+1 EXPLOIT"
		fx_col = COL_MAGENTA
		Audio.play_exploit()
	else:
		var amt := int((2 + GameState.bot_level) * float(tier["node_mult"]) * GameState.yield_mult)
		GameState.add_credits(amt)
		gain_text = "+%d" % amt
		fx_col = COL_GREEN
		Audio.play_exfiltrate()
	_spawn_burst(n.position, fx_col)
	_spawn_floating_text(n.position, gain_text, fx_col)
	VisualFX.play(fx_layer, n.position, "data_extract", 8, 18.0, fx_col)
	_respawn_elsewhere(n)

	var chain_chance: float = tier.get("chain_crack", 0.0)
	if not was_honeypot and randf() < chain_chance:
		var adjacent := _find_locked_node()
		if adjacent:
			adjacent.add_progress(1.0)
			_spawn_floating_text(adjacent.position, "CHAINED", COL_CYAN)
			VisualFX.play(fx_layer, adjacent.position, "scan_pulse", 10, 20.0, COL_CYAN, 0.7)

	_refresh_hud()

func _spawn_burst(pos: Vector2, col: Color) -> void:
	var p := CPUParticles2D.new()
	fx_layer.add_child(p)
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = 14
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	p.color = col
	var t := get_tree().create_timer(0.8)
	t.timeout.connect(func(): if is_instance_valid(p): p.queue_free())

func _spawn_floating_text(pos: Vector2, text: String, col: Color) -> void:
	var l := Label.new()
	fx_layer.add_child(l)
	l.text = text
	l.position = pos + Vector2(-20, -30)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 16)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 36, 0.7)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	tw.tween_callback(l.queue_free)

func _trigger_shake(amp: float, dur: float) -> void:
	shake_amp = amp
	shake_t = dur

func _process(delta: float) -> void:
	if round_active:
		var speed := GameState.decrypt_speed * GameState.weaken_mult
		var radius := GameState.decrypt_radius

		if is_decrypting:
			var any_in_range := false
			for n in cells.duplicate():
				if not is_instance_valid(n):
					continue
				if n.position.distance_to(mouse_pos) > radius:
					continue
				if n.state == ServerNode.State.LOCKED:
					n.add_progress(speed * delta)
					any_in_range = true
				elif n.state == ServerNode.State.READY:
					_exfiltrate(n)
			tick_timer -= delta
			if any_in_range and tick_timer <= 0.0:
				tick_timer = 0.14
				Audio.play_tick()
			scan_fx_timer -= delta
			if scan_fx_timer <= 0.0:
				scan_fx_timer = 0.42
				var scan_scale: float = GameState.decrypt_radius / 32.0
				VisualFX.play(fx_layer, mouse_pos, "scan_pulse", 10, 20.0, COL_CYAN, scan_scale)

		if GameState.bot_level > 0:
			bot_timer += delta
			var interval: float = max(0.4, 1.6 - GameState.bot_level * 0.2)
			if bot_timer >= interval:
				bot_timer = 0.0
				var cracks: int = 2 if bool(tier.get("swarm_bots", false)) else 1
				for i in range(cracks):
					var target := _find_locked_node()
					if target:
						target.add_progress(1.0)

		_update_hunter_bots(delta)
		_update_row_wipe(delta)
		_update_ultimate(delta)

		if not (DevMode.infinite_time or DevMode.god_mode):
			trace_progress -= delta / GameState.round_duration
		if trace_progress <= 0.0:
			trace_progress = 0.0
			_end_round()
		trace_bar.value = trace_progress
		var fill_sb := trace_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_sb:
			fill_sb.bg_color = COL_GREEN.lerp(Color8(255, 60, 60), 1.0 - trace_progress)

	rig_t += delta
	if rig_node:
		rig_node.queue_redraw()

	for lane in packet_lanes:
		lane["t"] += delta * lane["speed"]
		if lane["t"] > 1.0:
			lane["t"] -= 1.0
	if packets_layer:
		packets_layer.queue_redraw()

	if shake_t > 0.0:
		shake_t -= delta
		cam.offset = Vector2(randf_range(-shake_amp, shake_amp), randf_range(-shake_amp, shake_amp))
	else:
		cam.offset = Vector2.ZERO

	queue_redraw()

func _find_locked_node() -> ServerNode:
	var locked: Array[ServerNode] = []
	for n in cells:
		if is_instance_valid(n) and n.state == ServerNode.State.LOCKED:
			locked.append(n)
	if locked.is_empty():
		return null
	return locked[randi() % locked.size()]

func _update_hunter_bots(delta: float) -> void:
	while hunter_bots.size() < GameState.hunter_bot_count:
		hunter_bots.append({"pos": GRID_ORIGIN + Vector2(-40, -40), "target": null})
	while hunter_bots.size() > GameState.hunter_bot_count:
		hunter_bots.pop_back()
	if hunter_bots.is_empty():
		return

	var taken: Array[ServerNode] = []
	for h in hunter_bots:
		var target = h["target"]
		if not (target is ServerNode) or not is_instance_valid(target) or target.state != ServerNode.State.LOCKED:
			h["target"] = null
		if h["target"] == null:
			h["target"] = _find_nearest_locked(h["pos"], taken)
		if h["target"] != null:
			taken.append(h["target"])
			var t: ServerNode = h["target"]
			var to_target: Vector2 = t.position - h["pos"]
			var dist: float = to_target.length()
			if dist > HUNTER_RADIUS:
				h["pos"] += to_target.normalized() * HUNTER_SPEED * delta
			else:
				t.add_progress(HUNTER_CRACK_SPEED * delta)
	hunter_layer.queue_redraw()

func _find_nearest_locked(from: Vector2, exclude: Array[ServerNode]) -> ServerNode:
	var best: ServerNode = null
	var best_dist := INF
	for n in cells:
		if not is_instance_valid(n) or n.state != ServerNode.State.LOCKED:
			continue
		if n in exclude:
			continue
		var d := n.position.distance_to(from)
		if d < best_dist:
			best_dist = d
			best = n
	return best

func _draw_hunters(node: Node2D) -> void:
	for h in hunter_bots:
		var p: Vector2 = h["pos"]
		node.draw_arc(p, HUNTER_RADIUS, 0, TAU, 20, Color8(255, 70, 90), 2.0)
		node.draw_circle(p, 3.0, Color8(255, 70, 90))

func _update_row_wipe(delta: float) -> void:
	if GameState.row_wipe_level <= 0:
		return
	var interval: float = max(2.5, 6.0 - GameState.row_wipe_level * 1.5)
	row_wipe_timer += delta
	if row_wipe_timer < interval:
		return
	row_wipe_timer = 0.0
	var rows_with_nodes: Dictionary = {}
	for n in cells:
		if not is_instance_valid(n):
			continue
		var row := int(round((n.position.y - GRID_ORIGIN.y - CELL / 2.0) / CELL))
		if not rows_with_nodes.has(row):
			rows_with_nodes[row] = []
		rows_with_nodes[row].append(n)
	if rows_with_nodes.is_empty():
		return
	var row_keys := rows_with_nodes.keys()
	var chosen_row = row_keys[randi() % row_keys.size()]
	var targets: Array = rows_with_nodes[chosen_row]
	_trigger_shake(5.0, 0.25)
	Audio.play_breach()
	for n in targets:
		if is_instance_valid(n):
			VisualFX.play(fx_layer, n.position, "glitch", 8, 18.0, COL_CYAN, 0.6)
			_exfiltrate(n)

func _update_ultimate(delta: float) -> void:
	if GameState.ultimate_wipe_level <= 0 and not DevMode.god_mode:
		return
	if ultimate_btn == null:
		_build_ultimate_button()
	if DevMode.infinite_ultimates or DevMode.god_mode:
		ultimate_cooldown = 0.0
	if ultimate_cooldown > 0.0:
		ultimate_cooldown -= delta
		ultimate_cd_bar.value = 1.0 - max(0.0, ultimate_cooldown) / _ultimate_cooldown_max()
		ultimate_btn.disabled = true
	else:
		ultimate_cd_bar.value = 1.0
		ultimate_btn.disabled = false

func _ultimate_cooldown_max() -> float:
	return max(10.0, 30.0 - GameState.ultimate_wipe_level * 5.0)

func _build_ultimate_button() -> void:
	var icon_tex := KHArt.tex("icons", "power")
	ultimate_btn = Button.new()
	ultimate_btn.text = "  ZERO-DAY ULTIMATE"
	ultimate_btn.position = Vector2(988, 444)
	ultimate_btn.size = Vector2(260, 48)
	if icon_tex:
		ultimate_btn.icon = icon_tex
		ultimate_btn.expand_icon = true
	var usb := StyleBoxFlat.new()
	usb.bg_color = Color8(20, 10, 24)
	usb.border_color = Color8(216, 110, 255)
	usb.set_border_width_all(2)
	usb.set_corner_radius_all(0)
	ultimate_btn.add_theme_stylebox_override("normal", usb)
	ultimate_btn.add_theme_color_override("font_color", Color8(216, 110, 255))
	ultimate_btn.pressed.connect(_on_ultimate_pressed)
	hud.add_child(ultimate_btn)

	ultimate_cd_bar = ProgressBar.new()
	ultimate_cd_bar.position = Vector2(988, 496)
	ultimate_cd_bar.size = Vector2(260, 8)
	ultimate_cd_bar.min_value = 0
	ultimate_cd_bar.max_value = 1
	ultimate_cd_bar.value = 1
	ultimate_cd_bar.show_percentage = false
	var cdbg := StyleBoxFlat.new()
	cdbg.bg_color = COL_PANEL
	var cdfill := StyleBoxFlat.new()
	cdfill.bg_color = Color8(216, 110, 255)
	ultimate_cd_bar.add_theme_stylebox_override("background", cdbg)
	ultimate_cd_bar.add_theme_stylebox_override("fill", cdfill)
	hud.add_child(ultimate_cd_bar)

func _on_ultimate_pressed() -> void:
	if ultimate_cooldown > 0.0 or not round_active:
		return
	ultimate_cooldown = _ultimate_cooldown_max()
	_trigger_shake(10.0, 0.5)
	Audio.play_breach()
	for n in cells.duplicate():
		if not is_instance_valid(n):
			continue
		VisualFX.play(fx_layer, n.position, "data_extract", 8, 20.0, COL_GREEN)
		if n.state == ServerNode.State.LOCKED:
			n.add_progress(1.0)
		_exfiltrate(n)

func _refresh_hud() -> void:
	if GameState.credits != _shown_credits:
		_shown_credits = GameState.credits
		_pop_counter(credits_label)
	if GameState.exploits != _shown_exploits:
		_shown_exploits = GameState.exploits
		_pop_counter(exploits_label)
	if GameState.zerodays != _shown_zerodays:
		_shown_zerodays = GameState.zerodays
		_pop_counter(zerodays_label)
	credits_label.text = "CREDITS: %d" % GameState.credits
	exploits_label.text = "EXPLOITS: %d" % GameState.exploits
	zerodays_label.text = "0-DAYS: %d" % GameState.zerodays

func _draw() -> void:
	if is_decrypting:
		draw_arc(mouse_pos, GameState.decrypt_radius, 0, TAU, 32, COL_CYAN, 2.0)
