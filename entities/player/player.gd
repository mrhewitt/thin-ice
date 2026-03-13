extends CharacterBody2D
class_name Player

const TOW_SPACING = 32

## Emitted when player starts to sink, typically intercepted to stop other game mechanics
signal sinking

enum PlayerState { NORMAL, SINKING, STOPPING }

@export var max_speed: float = 120
@export var accel: float = 60
@export var braking_speed: float = 100
@export var max_rope_distance: float =64
@export var towing_capacity: int = 5

@onready var towing: Node2D = $Towing
@onready var rope_line_2d: Line2D = $RopeLine2D

var state: PlayerState = PlayerState.NORMAL
var speed: float = 0
var charge: float = 1:
	set(charge_in):
		charge = clamp(charge_in,0,1)
		GameManager.zambonie_charge.emit(charge)

var towing_target_points: Dictionary
var run_flat: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var target = look_for_target( get_global_mouse_position() )
			if target != null:
				if is_target_close(target):
					if towing.get_child_count() < towing_capacity:
						# put it in group so we know its behind us
						target.reparent(towing)
						# tell if to setup state for towing
						target.being_towed()
						# extend rpoe line to target
					##	rope_line_2d.points = [ Vector2.ZERO, target.position - rope_line_2d.position ]
					##	rope_line_2d.visible = true
						# where target must end up behind us so it is being towed directly behind
						towing_target_points[target] = rope_line_2d.position + Vector2( -TOW_SPACING * towing.get_child_count(), 0)
					else:
						GameManager.towline_full.emit()


func _process(delta: float) -> void:
	# if we lost a towee (so in first aid or a hole ensure the rope is not too long
	var rebuild_rope: bool = get_towee_count() != rope_line_2d.points.size() - 1

	# check to see if any towees still need to come into position
	for towee in towing.get_children():
		if towing_target_points.has(towee):
			towee.position = towee.position.move_toward( towing_target_points[towee], 75 * delta )
			if towee.position == towing_target_points[towee]:
				towing_target_points.erase(towee)
			# rebuild ropw points if any of the towees changed orientation
			rebuild_rope = true
				
				
	if rebuild_rope:
		if get_towee_count() == 0:
			rope_line_2d.visible = false
		else:
			var rope_points: Array[Vector2] = [ Vector2.ZERO ]
			for child in towing.get_children():
				rope_points.append(child.position - rope_line_2d.position)
			rope_line_2d.points = rope_points
			rope_line_2d.visible = true
			
	# check to see if we have fallen into a hole
	for hole in get_tree().get_nodes_in_group( Groups.GROUP_HOLES ):
		if is_instance_valid(hole) and hole.is_in_hole(global_position):
			# release all towees	
			rope_line_2d.visible = false
			for child in towing.get_children():
				child.reparent(get_parent())
				
			# if our center is in the hole we have fallen in, so move about half our size towards the center
			var offset_to_hole_center: Vector2 = hole.global_position - global_position
			global_position += (offset_to_hole_center.normalized() * 24)
			
			# set sinking state and animate vehicle sinking before a game over
			state = PlayerState.SINKING
			sinking.emit()
			
			var tween = create_tween().parallel()
			tween.tween_property(self,"scale", Vector2.ZERO, 2)
			tween.tween_property(self,"modulate:a", 0.0, 2)
			await tween.finished
			
			GameManager.game_over.emit( GameManager.GameOverCondition.FELL_IN_HOLE )


func _physics_process(delta: float) -> void:
	if state == PlayerState.NORMAL:
		# can move and turn if zamboni has charge, if we are flat just glide to halt game over!
		if charge > 0:
			# invert cos we dont want screen unit (y up == -1) we want acceleration, so up is +1, down -1
			var speed_change := Input.get_axis("ui_up", "ui_down") * -1
			# braking or reversing  
			# if speed is positive we are braking so apply braking acceleration, otherwise normal
			if speed_change > 1 and speed > 0:
				speed = max(speed - (braking_speed * delta), 0, max_speed)
			else:		
				speed = clampf(speed + (speed_change * accel * delta ),-max_speed, max_speed)
			
			# can only turn if we are moving
			if abs(speed) > 5:
				var direction := Input.get_axis("ui_left", "ui_right")
				rotation += direction * PI * 1 * delta
		else:
			if not run_flat:
				SoundPlayer.play( preload("uid://dgbt3lcxs4ei") )
			speed = lerpf( speed, 0, delta )
			run_flat = true
			if speed < 5:
				speed = 0
				GameManager.game_over.emit( GameManager.GameOverCondition.RUN_FLAT )
				
		# loose 5% + 0.75% per towee charge at full speed / second for prototype
		charge = max( charge - (((0.025+(0.0075*get_towee_count())) * (abs(speed)/max_speed)) * delta), 0 )
				
		velocity = transform.x * speed * delta
		if move_and_collide(velocity):
			speed = 0
	# used at end of round, just glide to a stop
	elif state == PlayerState.STOPPING:
		speed = lerpf( speed, 0, delta )
		velocity = transform.x * speed * delta
		move_and_collide(velocity)
		
		
## Return number of towees behind us
func get_towee_count() -> int:
	return towing.get_child_count()
	
	
func look_for_target( at_position: Vector2 ) -> CharacterBody2D:
	# check if we clicked on a skater stuck in a hole
	for skater in get_tree().get_nodes_in_group(Groups.GROUP_SKATERS):
		if skater.state == Skater.SkaterState.STUCK and skater.has_point(at_position):
			return skater
			
	# check if we clicked on an ice fisherman
	for fisher in get_tree().get_nodes_in_group(Groups.GROUP_FISHERS):
		if fisher.state != Skater.SkaterState.TOWING and fisher.state != Skater.SkaterState.DROWNING and fisher.has_point(at_position):
			return fisher
			
	return null


func is_target_close( target: CharacterBody2D ) -> bool:
	return (target.global_position - rope_line_2d.global_position).length() < max_rope_distance
