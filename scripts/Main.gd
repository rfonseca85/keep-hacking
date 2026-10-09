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

var bot_timer: float = 0.0
var tier: Dictionary

var trace_progress: float = 1.0

var round_active: bool = true
var round_start_credits: int = 0
var round_start_exploits: int = 0
var round_start_zerodays: int = 0

var is_decrypting: bool = false
var mouse_pos: Vector2 = Vector2.ZERO

var cells: Array[ServerNode] = []
var all_cell_positions: Array[Vector2] = []

var credits_label: Label
var exploits_label: Label
var zerodays_label: Label
var tier_label: Label
var trace_bar: ProgressBar
var trace_label: Label

var summary_panel: Panel
var summary_credits_lbl: Label
var summary_exploits_lbl: Label
var summary_zerodays_lbl: Label

func _ready() -> void:
	if OS.is_debug_build():
		for a in OS.get_cmdline_user_args():
			if a.begins_with("autotest_tier="):
				GameState.selected_tier = int(a.split("=")[1])
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
	_build_hud()
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_endround"):
		GameState.credits += 342
		GameState.exploits += 3
		GameState.zerodays += 1
		get_tree().create_timer(0.5).timeout.connect(_end_round)
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

func _draw_circuit_decor(node: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in range(46):
		var x: float = rng.randf_range(0, 1280)
		var y: float = rng.randf_range(0, 720)
		var in_grid := x > GRID_ORIGIN.x - 20 and x < GRID_ORIGIN.x + GRID_COLS * CELL + 20 \
			and y > GRID_ORIGIN.y - 20 and y < GRID_ORIGIN.y + GRID_ROWS * CELL + 20
		if in_grid or y < 115 or x < 190:
			continue
		var len_x: float = rng.randf_range(18, 70)
		var len_y: float = rng.randf_range(18, 70)
		var col := Color8(20, 40, 50) if rng.randf() > 0.3 else Color8(16, 50, 42)
		node.draw_line(Vector2(x, y), Vector2(x + len_x, y), col, 1.0)
		node.draw_line(Vector2(x + len_x, y), Vector2(x + len_x, y + len_y), col, 1.0)
		node.draw_circle(Vector2(x, y), 2.0, col)

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
	_trigger_shake(4.0, 0.2)
	Audio.play_denied()
	_respawn_elsewhere(n)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	var top_panel := Panel.new()
	top_panel.position = Vector2(16, 12)
	top_panel.size = Vector2(300, 100)
	hud.add_child(top_panel)

	credits_label = _make_label("◈ CREDITS: 0", COL_CYAN, Vector2(28, 20))
	exploits_label = _make_label("※ EXPLOITS: 0", COL_MAGENTA, Vector2(28, 46))
	zerodays_label = _make_label("♦ 0-DAYS: 0", COL_AMBER, Vector2(28, 72))
	hud.add_child(credits_label)
	hud.add_child(exploits_label)
	hud.add_child(zerodays_label)

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

	var hint := _make_label("hold click to crack nodes · click a READY node to exfiltrate", Color8(120,130,150), Vector2(16, 690))
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var clicked := _find_ready_node_at(event.position)
			if clicked:
				_exfiltrate(clicked)
			else:
				is_decrypting = true
		else:
			is_decrypting = false
	elif event is InputEventMouseMotion:
		mouse_pos = event.position

func _find_ready_node_at(pos: Vector2) -> ServerNode:
	for n in cells:
		if is_instance_valid(n) and n.state == ServerNode.State.READY:
			if n.position.distance_to(pos) < 26:
				return n
	return null

func _exfiltrate(n: ServerNode) -> void:
	var gain_text: String
	var fx_col: Color
	var was_honeypot := n.is_honeypot
	if was_honeypot:
		var amt := int(20 * float(tier["node_mult"]))
		GameState.credits += amt
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
		GameState.credits += amt
		gain_text = "+%d" % amt
		fx_col = COL_GREEN
		Audio.play_exfiltrate()
	_spawn_burst(n.position, fx_col)
	_spawn_floating_text(n.position, gain_text, fx_col)
	_respawn_elsewhere(n)

	var chain_chance: float = tier.get("chain_crack", 0.0)
	if not was_honeypot and randf() < chain_chance:
		var adjacent := _find_locked_node()
		if adjacent:
			adjacent.add_progress(1.0)
			_spawn_floating_text(adjacent.position, "CHAINED", COL_CYAN)

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
		var speed := GameState.decrypt_speed
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

func _refresh_hud() -> void:
	credits_label.text = "◈ CREDITS: %d" % GameState.credits
	exploits_label.text = "※ EXPLOITS: %d" % GameState.exploits
	zerodays_label.text = "♦ 0-DAYS: %d" % GameState.zerodays

func _draw() -> void:
	if is_decrypting:
		draw_arc(mouse_pos, GameState.decrypt_radius, 0, TAU, 32, COL_CYAN, 2.0)
