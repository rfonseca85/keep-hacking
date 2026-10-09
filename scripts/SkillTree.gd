extends Control

const COL_BACKDROP := Color8(6, 8, 13)
const COL_PANEL := Color8(12, 15, 22)
const COL_CYAN := Color8(0, 229, 255)
const COL_DIM := Color8(90, 100, 115)
const COL_GREEN := Color8(57, 255, 106)

@onready var matrix_overlay: Node2D = $MatrixOverlay
@onready var scanlines: Node2D = $Scanlines
@onready var credits_lbl: Label = $BottomBar/CreditsLabel
@onready var progress_lbl: Label = $BottomBar/ProgressLabel
@onready var preview_panel: Panel = $PreviewPanel
@onready var preview_title: Label = $PreviewPanel/PreviewTitle
@onready var preview_body: Label = $PreviewPanel/PreviewBody
@onready var preview_cost: Label = $PreviewPanel/PreviewCost

var skill_cards: Dictionary = {}

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
	_bind_skill_cards()
	_refresh_hud()

func _bind_skill_cards() -> void:
	for node in get_tree().get_nodes_in_group("skill_card"):
		if not node.has_method("refresh"):
			continue
		skill_cards[node.skill_id] = node
		node.pressed.connect(_on_card_pressed)
		node.hover_changed.connect(_on_card_hover)

func _card(skill_id: String):
	return skill_cards.get(skill_id)

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

func _on_card_hover(skill_id: String, entered: bool) -> void:
	var card = _card(skill_id)
	if card == null:
		return
	if entered:
		_show_preview(card)
	else:
		_hide_preview()

func _on_card_pressed(skill_id: String) -> void:
	var card = _card(skill_id)
	if card == null:
		return
	if not card.is_revealed():
		Audio.play_denied()
		return
	var lvl: int = GameState.skill_levels.get(skill_id, 0)
	if lvl >= card.max_level:
		return
	var cost: int = int(card.base_cost * pow(1.5, lvl))
	if GameState.credits >= cost:
		GameState.credits -= cost
		GameState.skill_levels[skill_id] = lvl + 1
		SkillEffects.apply(skill_id)
		card.refresh()
		_refresh_hud()
		_show_preview(card)
		Audio.play_upgrade()
	else:
		Audio.play_denied()

func _show_preview(card) -> void:
	var snap = card.get_skill_snapshot()
	if not card.is_revealed():
		preview_title.text = "??? CLASSIFIED"
		preview_body.text = "reach %d lifetime credits earned to reveal this node" % snap["reveal_threshold"]
		preview_cost.text = "progress: %d / %d" % [GameState.lifetime_credits_earned, snap["reveal_threshold"]]
		preview_panel.visible = true
		return
	if card.max_level == 0:
		preview_title.text = snap["label"]
		preview_body.text = snap["desc"]
		preview_cost.text = ""
		preview_panel.visible = true
		return
	var lvl: int = GameState.skill_levels.get(card.skill_id, 0)
	preview_title.text = snap["label"]
	preview_body.text = snap["desc"]
	if lvl >= card.max_level:
		preview_cost.text = "MAX LEVEL (%d/%d)" % [lvl, card.max_level]
	else:
		var cost: int = int(card.base_cost * pow(1.5, lvl))
		preview_cost.text = "%d → %d   cost: %d credits" % [lvl, lvl + 1, cost]
	preview_panel.visible = true

func _hide_preview() -> void:
	preview_panel.visible = false

func _refresh_hud() -> void:
	credits_lbl.text = "◈ %d CREDITS" % GameState.credits
	var revealed_count := 0
	var total := 0
	for card in skill_cards.values():
		if card.max_level > 0:
			total += 1
			if card.is_revealed():
				revealed_count += 1
	progress_lbl.text = "%d / %d NODES REVEALED  ·  LIFETIME: %d◈" % [revealed_count, total, GameState.lifetime_credits_earned]
	for card in skill_cards.values():
		card.refresh()
