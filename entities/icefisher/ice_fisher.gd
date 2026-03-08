extends NpcCharacterBody
class_name IceFisher

## Emitted when the ice fisher wants a hole to be made in the lake
signal create_hole( ice_fisher: IceFisher )

## Emitted when the fisher has left the scene and we can start another
signal left_the_lake( ice_fisher: IceFisher )

@export var speed: float = 50

var target_point: Vector2


func _ready() -> void:
	target_point = Vector2( randf_range(200,600), randf_range(45,595) )
	global_position = Vector2(-16,target_point.y)
	rotation = 0
	
	# get 3% faster for every round we progressed
	speed *= ( 1 + ((GameManager.round_number-1) * 0.03) )
	
	
func _process(_delta: float) -> void:
	match state:
		SkaterState.STUCK:
			if not has_call_for_help and timer.time_left < drown_time * 0.3:
				has_call_for_help = true
				call_for_help(true)
		SkaterState.DROWNING: pass
		_: check_for_hole()
	

func _physics_process(_delta: float) -> void:
	if state == SkaterState.ENTERING or state == SkaterState.EXITING:
		if (target_point - global_position).length() < 5:
			# reached goal when leaving so remove instance
			if state == SkaterState.EXITING:
				left_the_lake.emit(self)
				queue_free()
			else:
				# walking, so settle down and make a hole
				state = SkaterState.WAITING
				timer.start(4.0)
		else:	
			velocity = transform.x * speed
			move_and_slide()


func start_fishing() -> void:
	state = SkaterState.FISHING
	create_hole.emit(self)
	#var hole_instance: HoleCrack = hole_scene.instantiate()
	#hole_instance.global_position = global_position + (Vector2(cos(rotation),sin(rotation)) * 50)
	timer.start(8.0)
	
	
func go_home() -> void:
	# done fishing, lets go home
	# cannot go home if towed or in hole, so jsut remove
	if state == SkaterState.STUCK or state == SkaterState.TOWING:
		queue_free()
	else:
		state = SkaterState.EXITING
		rotation = PI	  # head to left
		target_point = Vector2(-16, global_position.y)


func _on_timer_timeout() -> void:
	if state == SkaterState.STUCK:
		# we drowned ... 
		drown()
	elif state == SkaterState.WAITING:
		start_fishing()
	else:
		go_home()
