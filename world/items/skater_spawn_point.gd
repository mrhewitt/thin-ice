extends Node2D
class_name SkaterSpawnPoint

## Emitted when a new group of skaters are entering the lake
signal skaters_spawned( skaters: Array[Skater] )

@export var home_marker: Marker2D
@export var skater_scene: PackedScene

@onready var timer: Timer = $Timer


func _ready() -> void:
	start()


func spawn_skaters() -> void:
	var skaters: Array[Skater]
	var x_offset: int = 32
	for i in range( randi_range(2,6) ):
		var skater: Skater = skater_scene.instantiate()
		skater.global_position = home_marker.global_position + Vector2(x_offset,0)
		skaters.append(skater)
		x_offset += 32
	skaters_spawned.emit( skaters )
	
	
func start() -> void:
	timer.start( randf_range(1.0,3.0) )
	
	
func stop() -> void:
	timer.stop()
	

func _on_timer_timeout() -> void:
	spawn_skaters()
	timer.start( randf_range(10.0,20.0) )
