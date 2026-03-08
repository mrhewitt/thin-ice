extends Node2D
class_name SpeechBubbleSprite

@export var frantic: bool = false

@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	if frantic:
		sprite_2d.frame = 1
		label.add_theme_color_override("font_color", Color.from_string("ac3232", Color.WHITE) )
		label.text = "HURRY!"
		#modulate = Color.from_string("ffbebe", Color.WHITE)
		var tween = create_tween().set_loops()
		tween.tween_property(self, "position:y", position.y - 5, 0.15)
		tween.tween_property(self, "position:y", position.y + 10, 0.3)
		tween.tween_property(self, "position:y", position.y - 5, 0.15)
	
	
func _on_timer_timeout() -> void:
	var tween := create_tween()
	tween.tween_property(self,"modulate:a",0.0,0.2)
	tween.tween_callback(queue_free)
