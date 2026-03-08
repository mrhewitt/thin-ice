extends Node2D
class_name HoleCrack

## how many radial lines there are (so 1 every 10 degrees)
const TOTAL_CRACKS = 10

@export_group("Size Properties")

@export var min_hole_radius: float = 16
@export var max_hole_radius: float = 32
@export var hole_radius: float = 0

@export_group("Cracking Properties")

## How fast does one skater standing in the middle cause next crack to appear measured in seconds
## i.e if set to 1 and a skater remained on center of crack for 1 second it would move to next crack level
@export var rate_of_cracking: float = 1

## how fast player heals crack, if set to 1 and player is over crack for 1 seconds it will shrink a level
@export var rate_of_repair: float = 0.5

## How many times the crack will expand between start and finish
@export var crack_stages: int = 4

@export var crack_speed_curve: Curve

## If not zero ice will crack even if no skaters are near by, speer per seconds for each crack
@export var auto_crack_speed: float = 0

@export_group("Color Properties")

@export var water_color: Color 
@export var crack_color: Color 	
@export var outline_color: Color

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var timer: Timer = $Timer
@onready var crack_stage: int = crack_stages

var crack_lines: Array[Line2D]
var current_radius: float 
var crack_progress: float = 0
var hole_polygon: Polygon2D 
var is_a_hole: bool = false
var progress_bar_tween: Tween = null


func _ready() -> void:
	#points_on_edge = create_crack_edge_points(hole_radius)
	#line_2d.polygon = points_on_edge
	create_crack()
	
	
func _process(delta: float) -> void:
	if not is_a_hole:

		# if the player is over the hole, fix the crack somewhere
		# if it shrinks completely then remove it
		var distance := (GameManager.player.global_position - global_position).length()
		# player can heal a crack only if we are quite close to it, but not smaller than half size or it becomes a pain to align
		if distance < max( current_radius * 1.25, max_hole_radius/2):
			# cracks heal linearly, it doesnt matter how far we are
			crack_progress -= rate_of_repair * delta
			
			if crack_progress < 0:
				# shirnk a level, if returns true then crack is gone
				if shrink_crack():
					queue_free()
					return
					
			# show a bar so player can see...
			if progress_bar_tween != null:
				progress_bar_tween.kill()
			progress_bar.visible = true
			progress_bar.modulate.a = 1.0
			progress_bar.position = global_position - Vector2(32,hole_radius) 	
			progress_bar.value = (((crack_stages - crack_stage) + crack_progress) / crack_stages) * 100
			
		elif progress_bar.visible and (progress_bar_tween == null or not progress_bar_tween.is_running()):
			progress_bar_tween = create_tween()
			progress_bar_tween.tween_interval(0.5)
			progress_bar_tween.tween_property(progress_bar,"modulate:a",0.0,0.5)
			progress_bar_tween.tween_property(progress_bar,"visible",false,0)

		# check all skaters in range, and for each skater move the crack
		# state on toward the next level
		for skater in get_tree().get_nodes_in_group(Groups.GROUP_SKATERS):
			# skaters will cause ice to crack out to 25% of final hole radius at all times
			var max_crackble_distance := hole_radius * 1.25
			distance = (skater.global_position - global_position).length()			
			if distance < max_crackble_distance:
			#	print( "Distance to center ", distance, " of ", max_crackble_distance )

				# get how much of the total crack rate will be applied beased on how close we
				# are to the center, rate of craching increases as we get into center
				var create_rate_adj := crack_speed_curve.sample( 1.0-clampf(distance/max_crackble_distance,0,1) )
				var crack_rate = rate_of_cracking * create_rate_adj * delta
				crack_progress += crack_rate
				#print("Curve sample ", 1.0-clampf(distance/max_crackble_distance,0,1), " Adj is ", create_rate_adj )
				#print("Crack rate is ", crack_rate, " and progress ", crack_progress)
				# if crack has moved to next stage expand the cracks
				if crack_progress >= 1.0:
					expand_crack()


				
				
func is_in_hole( global_point: Vector2 ) -> bool:
	var offset_to_hole_center: Vector2 = global_position - global_point
	return Geometry2D.is_point_in_polygon( offset_to_hole_center, hole_polygon.polygon )
	

func create_crack() -> void:
	# if no fixed radius set make a hole somewhere in the allowed range
	if hole_radius == 0:
		hole_radius = randf_range(min_hole_radius, max_hole_radius)
	
	current_radius = hole_radius/crack_stage
	var points = create_crack_edge_points(current_radius)
	for p in points:
		var line: Line2D = Line2D.new()
		line.default_color = crack_color
		line.points = [ Vector2.ZERO, p ]
		line.width = 1
		crack_lines.append(line)
		add_child(line)
	if auto_crack_speed:	
		timer.start(auto_crack_speed)	

	SfxPlayer.play( SfxPlayer.SMALL_CRACK )
	
	
func shrink_crack() -> bool:
	crack_stage += 1
	# "reverse" crack progress, as new crack level is almost full
	crack_progress += 1.0
	if crack_stage > crack_stages:
		# gone right back to below smallest level so remove
		return true
	
	# remove last point in all crack lines so it shrinks
	for i in crack_lines.size():
		crack_lines[i].remove_point( crack_lines[i].points.size() - 1 )
	
	return false
	
	
func expand_crack() -> void:
	crack_stage -= 1
	if crack_stage == 0:
		SfxPlayer.play( SfxPlayer.LARGE_CRACK )
		become_a_hole()
	else:
		SfxPlayer.play( SfxPlayer.MEDIUM_CRACK )
		# made no progress yet on this crack
		crack_progress = 0	
		current_radius = hole_radius/crack_stage
		var points = create_crack_edge_points(current_radius)
		for i in range(points.size()):
			crack_lines[i].add_point( points[i] )


func become_a_hole() -> void:
	# get outer point on each line around the "circle
	var points: Array[Vector2]
	for line in crack_lines:
		points.append( line.points[line.points.size()-1] )
	points.append( points[0] )		# close the loop
		
	# create a polygon around the outer edges of the line
	hole_polygon = Polygon2D.new()
	hole_polygon.color = water_color
	hole_polygon.polygon = points
	add_child(hole_polygon)
	
	# outline the polygon
	var outline = Line2D.new()
	outline.points = points
	outline.width = 2
	outline.default_color = outline_color
	add_child(outline)
	
	# remove all loines now it is a hole
	for line in crack_lines:
		line.queue_free()
		
	timer.stop()
	is_a_hole = true
	
	# enter group of holes so skaters can fall into us
	add_to_group( Groups.GROUP_HOLES )
	


func create_crack_edge_points( radius: float ) -> Array[Vector2]:
	var points: Array[Vector2]
	var angle:float = randf_range((PI/180)*5, (PI/180)*20)
	if randf() < 0.5:
		angle *= -1
	var min_radius := radius * 0.9
	for i in range(TOTAL_CRACKS):		# put a point every 30 degrees
		points.append( Vector2(cos(angle), sin(angle)) * (min_radius + randf_range(0,radius*0.2)) ) 
		angle += (2*PI)/TOTAL_CRACKS
	#points.append( points[0] )
	return points
	

func _on_timer_timeout() -> void:
	expand_crack()
