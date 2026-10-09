extends Node2D
## Animated background data twinkles. Drawn behind existing UI controls.
var _t: float = 0.0
var _draw_accum: float = 0.0

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    _t += delta
    _draw_accum += delta
    if _draw_accum > 0.05:
        _draw_accum = 0.0
        queue_redraw()

func _draw() -> void:
    for i in range(52):
        var x: float = fposmod(float((i*197+53) % 1280) + _t*(4.0 + float(i%4)), 1280.0)
        var y: float = float((i*131+37) % 720)
        var a: float = 0.10 + 0.24 * (0.5 + 0.5*sin(_t*1.8 + float(i)*1.71))
        draw_rect(Rect2(x,y,2.0,2.0),Color(0.22,0.98,0.76,a),true)
