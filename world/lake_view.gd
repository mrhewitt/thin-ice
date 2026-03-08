extends Node2D
class_name LakeView

signal game_over

@export var hole_scene: PackedScene
@export var ice_fisher_scene: PackedScene

@onready var cracks: Node2D = $Cracks
@onready var skater_spawn_point: SkaterSpawnPoint = $SkaterSpawnPoint
@onready var skater_list: Node2D = $SkaterList
@onready var player: Player = $Player
@onready var ui_canvas_layer: UICanvasLayer = $UICanvasLayer
@onready var player_marker_2d: Marker2D = $PlayerMarker2D

## Timer for controlling when the next ice crack appears under a skater
@onready var ice_timer: Timer = $IceTimer
## Timer controlling when next ice-fisher arrives
@onready var fisher_timer: Timer = $FisherTimer
@onready var round_timer: Timer = $RoundTimer

var skater_limit: int = 10
var min_crack_form_time: float = 10
var max_crack_form_time: float = 20
var max_ice_fishers: int = 0
var crack_advance_time: float = 5.0

var round_complete: bool = false
var end_on_no_stuck: bool = false


func _ready() -> void:
	MusicPlayer.play_game_track()
	
	skater_spawn_point.skaters_spawned.connect( _on_new_skaters )
	GameManager.player = player
	GameManager.game_over.connect( _on_game_over )
	start_round()
	
	
func _process(_delta: float) -> void:
	# if round is complete wait till all skaters are gone then move on
	if round_complete and get_tree().get_node_count_in_group(Groups.GROUP_SKATERS) == 0:
		start_round()
	
	if end_on_no_stuck:
		# if there is still someone drowing keep going
		for skater in get_tree().get_nodes_in_group(Groups.GROUP_SKATERS):
			if skater.state == Skater.SkaterState.DROWNING:
				return
		
		# if being toweed keep going
		if player.get_towee_count():
			return
		
		_on_round_timer_timeout()
		
		
func start_round() -> void:	
	GameManager.round_number += 1
	GameManager.total_deaths = 0
	ui_canvas_layer.show_round_start()
	
	round_complete = false
	end_on_no_stuck = false
	
	player.charge = 1
	player.speed = 0
	player.rotation = PI/2
	player.global_position = player_marker_2d.global_position
	player.state = Player.PlayerState.NORMAL
	
	var round_info = GameManager.ROUNDS[GameManager.round_number-1]
	round_timer.start( round_info.round_time )
	skater_limit = round_info.skaters
	min_crack_form_time = round_info.min_ice_form_time
	max_crack_form_time = round_info.max_ice_form_time
	max_ice_fishers = round_info.fishers
	crack_advance_time = round_info.crack_advance_time 
	
	skater_spawn_point.start()
	start_ice_fisher_timer(null)
	start_ice_timer()


func add_ice_fisher_hole( ice_fisher: IceFisher ) -> void:
	var hole_instance:HoleCrack = hole_scene.instantiate()
	hole_instance.auto_crack_speed = 0.4		# crack automatically 1 crack per 0.4 seconds
	hole_instance.hole_radius = hole_instance.min_hole_radius		# smallest size
	hole_instance.global_position = ice_fisher.global_position + Vector2(hole_instance.hole_radius/2 + 16,0).rotated(ice_fisher.rotation)
	cracks.add_child(hole_instance)


func start_ice_fisher_timer( ice_fisher: IceFisher ) -> void:
	if not round_complete:
		# horrible hack!! if being towed when he leaves then reduce the max fishers
		# this is a hack as i added increasing fishers to round sifficult in last minutes
		# so just a quick fix for this, but ice_fisher was always an arugment as its always
		# good to try to provide info and context to subscriber, so it made it trivial to hack!
		if ice_fisher and ice_fisher.state == Skater.SkaterState.TOWING:
			max_ice_fishers -= 1
		# only start if not already running, another fisher may have already started it
		if fisher_timer.is_stopped():
			fisher_timer.start( randf_range(10,20) )
	
	
func start_ice_timer() -> void:
	ice_timer.start( randf_range(min_crack_form_time,max_crack_form_time) )
	

func clear_level() -> void:
	skater_spawn_point.stop()
	fisher_timer.stop()
	round_timer.stop()
	ice_timer.stop()
	for skater in get_tree().get_nodes_in_group(Groups.GROUP_SKATERS):
		skater.queue_free()
	for fisher in get_tree().get_nodes_in_group(Groups.GROUP_FISHERS):
		fisher.queue_free()
	for crack in get_tree().get_nodes_in_group(Groups.GROUP_CRACKS):
		crack.queue_free()


func _on_new_skaters( skaters: Array[Skater] ) -> void:
	for skater in skaters:
		if get_tree().get_node_count_in_group(Groups.GROUP_SKATERS) < skater_limit:
			# we handle the request for a skater to leave, partly so we can tell
			# him where to go and partly so we can if need be later add restrictions
			# based on state of the game
			skater.wants_to_leave.connect( _on_skater_exiting )
			skater_list.add_child(skater)
		else:
			return


##
func _on_skater_exiting( skater: Skater ) -> void:
	skater.go_home( skater_spawn_point.home_marker.global_position )
	
	
func _on_game_over( reason: GameManager.GameOverCondition ) -> void:
	ui_canvas_layer.game_over(reason)
	player.state = Player.PlayerState.STOPPING
	clear_level()
	await get_tree().create_timer(3)
	game_over.emit()
	

## Ice timer determines if a skater creates a new crack in the ice
func _on_ice_timer_timeout() -> void:
	var skaters: Array[Skater]
	for skater in get_tree().get_nodes_in_group(Groups.GROUP_SKATERS):
		if skater.state == Skater.SkaterState.SKATING:
			skaters.append(skater)
	
	# if there are no skating skaters then leave it till next check
	if skaters.size() > 0:
		var skater: Skater = skaters.pick_random()
		var hole_instance:HoleCrack = hole_scene.instantiate()
		hole_instance.auto_crack_speed = crack_advance_time
		hole_instance.global_position = skater.global_position
		cracks.add_child(hole_instance)
	
	start_ice_timer()


## fisher timer exits when we must spawn ice fishers
## for jam release just spawn random amount to max_ice_fishers
## this is not a great mechaic but i ran out of time
func _on_fisher_timer_timeout() -> void:
	# we can spawn up to max less the total currently in the field
	var max_spawnable = max_ice_fishers- get_tree().get_node_count_in_group(Groups.GROUP_FISHERS)
	if max_spawnable > 0:
		for i in range(randi_range(1,max_spawnable)):
			var fisher_instance = ice_fisher_scene.instantiate()
			fisher_instance.create_hole.connect( add_ice_fisher_hole )
			fisher_instance.left_the_lake.connect( start_ice_fisher_timer )
			add_child(fisher_instance)


func _on_round_timer_timeout() -> void:
	
	# this is also terrible, but minutes before release!
	# its feels ugly ending the round when there are ppl in water so make a rule
	# to not end the round until there are no drowning npcs
	for skater in get_tree().get_nodes_in_group(Groups.GROUP_SKATERS):
		if skater.state == Skater.SkaterState.DROWNING:
			end_on_no_stuck = true
			return
	
	# lets do same if any ppl are being towed, must drop off to end round
	if player.get_towee_count():
		end_on_no_stuck = true
		return

	skater_spawn_point.stop()
	fisher_timer.stop()
	player.state = Player.PlayerState.STOPPING
	
	round_complete = true
	ui_canvas_layer.show_round_complete()
	for crack in get_tree().get_nodes_in_group(Groups.GROUP_CRACKS):
		crack.queue_free()
	for skater in get_tree().get_nodes_in_group(Groups.GROUP_SKATERS):
		skater.go_home( skater_spawn_point.home_marker.global_position )
	for fisher in get_tree().get_nodes_in_group(Groups.GROUP_FISHERS):
		fisher.go_home(  )
	

func _on_player_sinking() -> void:
	skater_spawn_point.stop()
	fisher_timer.stop()
	ice_timer.stop()
	round_timer.stop()
