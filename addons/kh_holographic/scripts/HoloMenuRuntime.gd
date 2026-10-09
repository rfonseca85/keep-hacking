extends Node
## Optional visual upgrade for NetworkSelect and SkillTree.

var screen: Node

func _ready() -> void:
    if not is_instance_valid(screen):
        return
    var styler = preload("res://addons/kh_holographic/scripts/HoloStyler.gd").new()
    styler.apply_to_menu(screen)
    var bg = screen.get_node_or_null("MatrixOverlay")
    if bg is Node2D:
        var ambient: Node2D = preload("res://addons/kh_holographic/scripts/HoloMenuAmbient.gd").new()
        ambient.name = "HoloAmbient"
        bg.add_child(ambient)
