class_name Skater extends CharacterBody2D
##

const WATER_SPLASH_SFX = preload("uid://jtwlrgr0vtyj")

const MIN_DISTANCE_TO_TARGET = 5

## Emitted when this skater wants to go home, given main script a chance
## to decide if thats ok, and to tell it where to go
signal wants_to_leave(skater: Skater)

enum SkaterState { ENTERING, SKATING, STUCK, EXITING, TOWING, DROWNING }
enum SkaterDirection { CLOCKWISE, ANTICLOCKWISE }

@export var base_speed: float = 50
@export var full_rotation_speed: float = 2.5
@export var speech_bubble_scene: PackedScene
@export var drown_time: float = 10.0
@export var min_skate_time: float = 20.0
@export var max_skate_time: float = 40.0

@onready var timer: Timer = $Timer

@onready var speed: float = base_speed
@onready var target_rotation: float = rotation
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var target_line_2d: Line2D = $TargetLine2D
@onready var angle_line_2d: Line2D = $AngleLine2D
@onready var sprite_2d: Sprite2D = $Sprite2D

var state: SkaterState = SkaterState.ENTERING

var circle_direction: SkaterDirection = SkaterDirection.CLOCKWISE
var last_hole: HoleCrack = null
var has_call_for_help: bool = false

var target_point: Vector2
var turn_speed: float


func _ready() -> void:
	GameManager.whistle_blown.connect( _on_whistle )
	
	# start out heading left
	rotation = PI
	target_rotation = PI
	target_point = global_position - Vector2(250,0)
	
	# pick a random color
	sprite_2d.frame = randi_range(0,sprite_2d.hframes-1)
	
	# set how long we will be on the ice for
	timer.start( randf_range(min_skate_time,max_skate_time))
	
	
func _process(_delta: float) -> void:
	match state:
		SkaterState.STUCK:
			if not has_call_for_help and timer.time_left < drown_time * 0.3:
				has_call_for_help = true
				call_for_help(true)
		SkaterState.DROWNING: pass
		_: check_for_hole()
	

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
					SoundPlayer.play(WATER_SPLASH_SFX)
					call_for_help()
					timer.start(drown_time)
				return
				
		# been dragged out hole so clear it in so we can fall into it again
		last_hole = null


func _physics_process(delta: float) -> void:
	match state:
		SkaterState.ENTERING: do_entry_movement()
		SkaterState.EXITING: do_skating_movement(delta)
		SkaterState.SKATING: do_skating_movement(delta)
		
		
func do_entry_movement() -> void:
	velocity = transform.x * speed
	move_and_slide()
	if (target_point - global_position).length() < MIN_DISTANCE_TO_TARGET:
		state = SkaterState.SKATING


func do_skating_movement(delta: float) -> void:
	
	# last minure hack, sometimes for some reason a skater gets stuck in
	# loop at eadge of home base when round ends, this just removes it as we are out of time to fix properly 
	if state == SkaterState.EXITING and global_position.x > 1160:
		queue_free()
		return

	# are we close enough to target?
	if (target_point - global_position).length() < 5:
		if state == SkaterState.EXITING:
			# we are leaving , so head off to right instead unless already off screen in which case queue_free
			if global_position.x > 1160:
				queue_free()
				return
			else:
				# head off screen now we are at the marker
				target_point = Vector2(1180, global_position.y)
		else:
			target_point = Vector2( randf_range(100,1000), randf_range(80,600) )
			turn_speed = randf_range( full_rotation_speed/4, full_rotation_speed/2 )
		
	target_rotation = global_position.angle_to_point(target_point)
	rotation = rotate_toward(rotation, target_rotation, turn_speed * delta)
	
	#target_line_2d.points = [global_position, target_point]
	#angle_line_2d.points = [global_position, global_position + (Vector2(cos(target_rotation),sin(target_rotation)) * 50)]
	
	velocity = transform.x * speed
	move_and_slide()
		
		
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


func go_home( home_marker: Vector2 ) -> void:
	# cannot go home if towed or in hole, so jsut remove
	if state == SkaterState.STUCK or state == SkaterState.TOWING:
		queue_free()
	else:
		target_point = home_marker
		# go home 2x as fast so player doesnt wait so long
		speed *= 2	
		turn_speed = full_rotation_speed
		state = SkaterState.EXITING
	

func _on_whistle() -> void:
	# whistle has been blown, turn around if we are in normal skating mode
	if state == SkaterState.SKATING:
		target_rotation = rotation + PI
		turn_speed = full_rotation_speed
		target_point = global_position + (Vector2(cos(target_rotation),sin(target_rotation)) * 50)
		#turning = true
		#reversing = true


func _on_timer_timeout() -> void:
	#if state == SkaterState.ENTERING:
	#	state = SkaterState.SKATING
		# set a random time to skate for before heading back in
	#	timer.start( randf_range(5.0, 10.0) )
	if state == SkaterState.STUCK:
		# we drowned ... 
		drown()
	else:
		pass		# we dont chosoe to leave now, round based play only leave at tend	
	#	wants_to_leave.emit(self)
