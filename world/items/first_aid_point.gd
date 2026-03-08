extends Node2D
class_name FirstAidPoint

@onready var patients: Node2D = $Patients
@onready var highlight_circle: HighlightCircle = $HighlightCircle


func _process(delta: float) -> void:
	for child in patients.get_children():
		child.look_at(global_position)
		child.position = child.position.move_toward	( Vector2.ZERO, 50 * delta )
		if child.position.length() < 5:
			GameManager.total_rescues += 1
			child.queue_free()
			
	# if there are people being toweed show we can come here
	highlight_circle.visible = GameManager.player.get_towee_count()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.state == Skater.SkaterState.TOWING:
		body.reparent(patients)
		
