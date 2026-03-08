extends CharacterBody2D
class_name NpcCharacterBody

enum SkaterState { ENTERING, SKATING, STUCK, EXITING, TOWING, DROWNING, FISHING, WAITING }

@export var speech_bubble_scene: PackedScene
@export var drown_time: float = 10.0

@onready var timer: Timer = $Timer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var state: SkaterState = SkaterState.ENTERING
var last_hole: HoleCrack = null
var has_call_for_help: bool = false


func check_for_hole() -> void:
	if state != SkaterState.STUCK and state != SkaterState.DROWNING:
		# check to see if we have fallen into a hole
		for hole in get_tree().get_nodes_in_group( Groups.GROUP_HOLES ):
			if hole.is_in_hole(global_position):
				# if this is the same hole we were in do nothing, as we are being pulled out if not stuck
				# otherwise move into the hole and get stuck
				if hole != last_hole:
					# if our center is in the hole we have fallen in, so move about half our size towards the center
					var offset_to_hole_center: Vector2 = hole.global_position - global_position
					global_position += (offset_to_hole_center.normalized() * 16)
					# .. reparent in case we were being towed...
					reparent(hole)
					# ....and go to the stuck state
					state = SkaterState.STUCK
					last_hole = hole
					call_for_help()
					timer.start(drown_time)
				return
				
		# been dragged out hole so clear it in so we can fall into it again
		last_hole = null


func call_for_help( is_frantic: bool = false ) -> void:
	var help = speech_bubble_scene.instantiate()
	help.frantic = is_frantic
	help.global_position = global_position + Vector2(0,-16) 
	get_tree().root.add_child(help)


func being_towed() -> void:
	state = SkaterState.TOWING
	timer.stop()
	
	
func drown() -> void:
	state = SkaterState.DROWNING
	var tween = create_tween().parallel()
	tween.tween_property(self,"scale", Vector2.ZERO, 2)
	tween.tween_property(self,"modulate:a", 0.0, 2)
	await tween.finished
	queue_free()
	GameManager.total_deaths += 1
	
		
func has_point( global_point: Vector2 ) -> bool:
	var distance = (global_point - global_position).length()
	return distance < collision_shape_2d.shape.radius
