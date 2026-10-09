extends Control

@onready var matrix_overlay: Node2D = $MatrixOverlay
@onready var scanlines: Node2D = $Scanlines
@onready var cursor_lbl: Label = $Cursor
@onready var credits_lbl: Label = $BottomBar/CreditsLabel
@onready var exploits_lbl: Label = $BottomBar/ExploitsLabel
@onready var zerodays_lbl: Label = $BottomBar/ZerodaysLabel
@onready var skill_tree_btn: Button = $BottomBar/SkillTreeButton
@onready var tier_cards: Array[Panel] = [
	$CardsRow/TierCard0,
	$CardsRow/TierCard1,
	$CardsRow/TierCard2,
	$CardsRow/TierCard3,
]

var cursor_t: float = 0.0

func _ready() -> void:
	Audio.play_ambient()
	set_process(true)
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("autotest_breach"):
		get_tree().create_timer(0.6).timeout.connect(func(): _on_breach(0))

	matrix_overlay.draw.connect(_draw_matrix_bg)
	scanlines.draw.connect(_draw_scanlines)

	for card in tier_cards:
		if card.has_signal("breach_pressed"):
			card.breach_pressed.connect(_on_breach)
			card.unlock_pressed.connect(_on_unlock)

	skill_tree_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/SkillTree.tscn"))
	_style_bottom_bar()
	_refresh_currency()
	# KH_HOLOGRAPHIC_BEGIN - visual-only addon, safe to remove
	var kh_holo_menu = preload("res://addons/kh_holographic/scripts/HoloMenuRuntime.gd").new()
	kh_holo_menu.screen = self
	add_child(kh_holo_menu)
	# KH_HOLOGRAPHIC_END

func _style_bottom_bar() -> void:
	var botsb := StyleBoxFlat.new()
	botsb.bg_color = Color8(14, 17, 25)
	botsb.border_color = Color8(30, 38, 48)
	botsb.border_width_top = 2
	$BottomBar.add_theme_stylebox_override("panel", botsb)
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color8(4, 5, 8)
	ssb.border_color = Color8(57, 255, 106)
	ssb.set_border_width_all(2)
	skill_tree_btn.add_theme_stylebox_override("normal", ssb)

func _refresh_currency() -> void:
	credits_lbl.text = "◈ %d" % GameState.credits
	exploits_lbl.text = "※ %d" % GameState.exploits
	zerodays_lbl.text = "♦ %d" % GameState.zerodays

func _process(delta: float) -> void:
	cursor_t += delta
	cursor_lbl.visible = fmod(cursor_t, 1.0) < 0.5

func _draw_matrix_bg() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for x in range(0, 1280, 28):
		for y in range(0, 720, 28):
			if rng.randf() < 0.08:
				matrix_overlay.draw_rect(Rect2(x, y, 2, 2), Color8(30, 60, 45), true)

func _draw_scanlines() -> void:
	var y := 0
	while y < 720:
		scanlines.draw_rect(Rect2(0, y, 1280, 1), Color(1, 1, 1, 0.012), true)
		y += 3

func _on_breach(i: int) -> void:
	GameState.selected_tier = i
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_unlock(i: int) -> void:
	if GameState.try_unlock_tier(i):
		Audio.play_breach()
		for card in tier_cards:
			if card.has_method("refresh"):
				card.refresh()
		_refresh_currency()
	else:
		Audio.play_denied()
