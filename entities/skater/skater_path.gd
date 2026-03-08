extends Path2D
class_name SkaterPath


@onready var path_follow_2d: PathFollow2D = $PathFollow2D

var skater: Skater = null
var progress_over_time: float = 0
var time_for_path: float = 0


func _process(delta: float) -> void:
	#if progress_over_time >= 1.0:
		
		
	progress_over_time = min( progress_over_time + delta, 1.0 )
	path_follow_2d.progress_ratio = progress_over_time/time_for_path 
	

## Add the skater who will be using this path
func add_skater( new_skater: Skater ) -> void:
	skater = new_skater
	path_follow_2d.add_child(new_skater)
	curve.add_point( Vector2.ZERO )
	curve.add_point( get_next_targeet( ) )
	set_path_time()
	
	
func set_path_time() -> void:
	time_for_path = 100 / skater.speed
	progress_over_time = 0
	
	
func get_next_targeet() -> Vector2:
	if skater.state == Skater.SkaterState.ENTERING:
		skater.state = Skater.SkaterState.SKATING
		return Vector2(-100,0)
	return Vector2.ZERO
