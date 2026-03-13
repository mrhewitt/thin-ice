extends TextureButton
class_name WhistleButton

const WHISTLE_SFX = preload("uid://wq2pmvp3ced2")

@onready var cooldown_timer: Timer = $CooldownTimer

@export var cool_down_period: float = 5.0

var shake_tween: Tween


func _on_cooldown_timer_timeout() -> void:
	pass # Replace with function body.


func _on_pressed() -> void:
	# can only blow the whistle when the cooldown period is over
	if cooldown_timer.is_stopped():
		GameManager.whistle_blown.emit()
		SoundPlayer.play(WHISTLE_SFX)
		
		# start cooldown and increase cooldown period for next blast
		cooldown_timer.start(cool_down_period)
		var tween = TweenHelper.pop(self)
		tween.tween_property(self.material,"shader_parameter/progress",0.0,0)
		tween.tween_property(self.material,"shader_parameter/progress",1.0,cool_down_period)
		cool_down_period *= 1.1
		
		
