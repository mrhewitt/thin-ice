extends Node2D
class_name ZambonieShed

## What percentage charge is added to zambonie per second
@export var charge_per_second: float = 0.1			# default 10%
@export var alert_color: Color
@export var charging_color: Color

@onready var highlight_circle: HighlightCircle = $HighlightCircle

# if a player is being charged his ref will be in this
var charging_player: Player = null


func _process(delta: float) -> void:
	# show charging area as a hint to player to come in an charge
	# flash faster if charge is lower
	if (charging_player and charging_player.charge < 1) or GameManager.player.charge < 0.5:
		highlight_circle.visible = true
		highlight_circle.pulse_rate = 1.0 if GameManager.player.charge < 0.25 else 2.0
		
		if GameManager.player.charge < 0.5:
			highlight_circle.highlight_color = alert_color
		else:
			highlight_circle.highlight_color = charging_color
	else:
		highlight_circle.visible = false
		
	if charging_player:
		charging_player.charge += charge_per_second * delta
		#print("Delivered ", charge_per_second * delta, "charge ")
		

func _on_charging_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		charging_player = body


func _on_charging_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		charging_player = null
