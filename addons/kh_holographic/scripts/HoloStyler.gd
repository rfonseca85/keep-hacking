extends RefCounted
## Themes native Control nodes. The original Button, ProgressBar and Panel
## instances remain alive; signals, values and input are not changed.

const ROOT: String = "res://addons/kh_holographic/art/ui/"

func _box(path: String, margin: int=12) -> StyleBoxTexture:
    var sb := StyleBoxTexture.new()
    sb.texture = load(ROOT + path)
    sb.set_texture_margin_all(margin)
    return sb

func apply_to(game: Node2D) -> void:
    var top_panel = game.get_node_or_null("HUD/TopPanel")
    if top_panel is Panel:
        top_panel.add_theme_stylebox_override("panel",_box("panel_9slice.png",15))

    var trace = game.get_node_or_null("HUD/TraceBar")
    if trace is ProgressBar:
        var bg := StyleBoxFlat.new()
        bg.bg_color = Color(0.015,0.04,0.08)
        bg.border_color = Color(0.08,0.49,0.58)
        bg.set_border_width_all(2)
        var fill := StyleBoxFlat.new()
        fill.bg_color = Color(0.12,0.92,0.64)
        fill.set_corner_radius_all(2)
        trace.add_theme_stylebox_override("background",bg)
        trace.add_theme_stylebox_override("fill",fill)

    var hud = game.get_node_or_null("HUD")
    if hud != null:
        for child in hud.get_children():
            if child is Button:
                _theme_button(child)

    var summary = game.get_node_or_null("HUD/SummaryPanel")
    if summary is Panel:
        summary.add_theme_stylebox_override("panel",_box("panel_magenta_9slice.png",15))
        for node in summary.get_children():
            if node is Button:
                _theme_button(node)

func _theme_button(btn: Button) -> void:
    btn.add_theme_stylebox_override("normal",_box("button_9slice.png",12))
    btn.add_theme_stylebox_override("hover",_box("button_hover_9slice.png",12))
    btn.add_theme_stylebox_override("pressed",_box("button_pressed_9slice.png",12))
    var disabled := _box("button_9slice.png",12)
    btn.add_theme_stylebox_override("disabled",disabled)
    btn.add_theme_color_override("font_color",Color(0.59,0.96,0.97))
    btn.add_theme_color_override("font_hover_color",Color(0.94,1.0,1.0))
    btn.add_theme_color_override("font_pressed_color",Color(0.35,0.84,0.77))
    btn.add_theme_color_override("font_disabled_color",Color(0.28,0.44,0.47))

func apply_to_menu(screen: Node) -> void:
    # Keep each tier's pre-existing color and locked/unlocked state unchanged.
    var bottom := screen.get_node_or_null("BottomBar")
    if bottom is Panel:
        bottom.add_theme_stylebox_override("panel",_box("panel_9slice.png",15))
    var preview := screen.get_node_or_null("PreviewPanel")
    if preview is Panel:
        preview.add_theme_stylebox_override("panel",_box("panel_magenta_9slice.png",15))
    _buttons_recursive(screen)

func _buttons_recursive(root: Node) -> void:
    for child in root.get_children():
        if child is Button:
            _theme_button(child)
        _buttons_recursive(child)
