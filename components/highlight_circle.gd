extends Node2D
class_name HighlightCircle

const MIN_ALPHA = 0.4

@export var area_radius:float = 75
@export var highlight_color: Color = Color.FOREST_GREEN:
	set(color_in):
		highlight_color = color_in
		highlight_color.a = MIN_ALPHA
		setup_tween()
		
@export var pulse_rate: float = 2.0:
	set(pulse):
		pulse_rate = pulse
		setup_tween()
		

var alpha_tween: Tween = null

func _ready() -> void:
	highlight_color.a = MIN_ALPHA
	alpha_tween = create_tween().set_loops()
	setup_tween()


func setup_tween() -> void:
	if alpha_tween:
		if alpha_tween.is_running(): alpha_tween.kill()
		alpha_tween = create_tween().set_loops()
		alpha_tween.tween_property(self, "highlight_color:a", MIN_ALPHA+0.2, pulse_rate)
		alpha_tween.tween_property(self, "highlight_color:a", MIN_ALPHA, pulse_rate)


func _process(delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	draw_circle( Vector2.ZERO, area_radius, highlight_color)
