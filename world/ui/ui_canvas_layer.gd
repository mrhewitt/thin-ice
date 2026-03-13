extends CanvasLayer
class_name UICanvasLayer

const HALF_CHARGE_SFX = preload("uid://dx72o2i50w0f")
const LOW_CHARGE_ALAWM = preload("uid://cv01bt2vy7hm8")

@onready var skaters_rescued_label: Label = %SkatersRescuedLabel
@onready var charge_progress_bar: TextureProgressBar = %ChargeProgressBar
@onready var alert_label: Label = $AlertLabel
@onready var game_over_panel: TextureRect = $GameOverPanel
@onready var time_label: Label = %TimeLabel
@onready var round_label: Label = %RoundLabel
@onready var round_complete_label: Label = $RoundCompleteLabel
@onready var round_start_label: Label = $RoundStartLabel


var last_charge_level: float = 1


func _ready() -> void:
	GameManager.zambonie_charge.connect( _on_charge_updated )
	GameManager.towline_full.connect( _on_towline_full )
	
	
func _process(_delta: float) -> void:
	skaters_rescued_label.text = "Rescues: %s" % GameManager.total_rescues
	#towing_label.text = "Towing %s / %s" % [ GameManager.player.get_towee_count(), GameManager.player.towing_capacity ]
	round_label.text = "Round %s" % GameManager.round_number
	
	time_label.text = "Time %s" % floor(GameManager.time_survived)
	
	
func game_over( reason: GameManager.GameOverCondition ) -> void:
	game_over_panel.visible = true
	match reason:
		GameManager.GameOverCondition.RUN_FLAT: show_alert("Out Of Power!")
		GameManager.GameOverCondition.LIVES_LOST: show_alert("3 Drownings!")
		GameManager.GameOverCondition.FELL_IN_HOLE: show_alert("You Drowned!")
	
	
func show_round_complete() -> void:
	round_complete_label.visible = true

	
func show_round_start() -> void:
	round_complete_label.visible = false
	
	round_start_label.text = "ROUND %s" % GameManager.round_number
	round_start_label.visible = true	
	round_start_label.modulate.a = 1
	TweenHelper.fadeout( round_start_label, 1, 1 )

	
func _on_towline_full() -> void:
	show_alert("Towline Full!!")
	
	
func show_alert(msg: String)-> void:
	alert_label.visible = true
	alert_label.text = msg
	alert_label.modulate.a = 1.0
	alert_label.rotation = 0
	
	var tween = create_tween()
	tween.tween_property(alert_label,"rotation_degrees",5,0.1)
	tween.tween_property(alert_label,"rotation_degrees",-5,0.1)
	tween.tween_property(alert_label,"rotation_degrees",5,0.1)
	tween.tween_property(alert_label,"rotation_degrees",-5,0.1)
	tween.tween_property(alert_label,"rotation_degrees",5,0.1)
	tween.tween_property(alert_label,"rotation_degrees",-5,0.1)
	tween.tween_property(alert_label,"rotation_degrees",0,0.1)
	tween.tween_property(alert_label, "modulate:a", 0.0, 1)
	tween.tween_property(alert_label, "visible", false, 0)
	
	
func _on_charge_updated(charge: float) -> void:
	if last_charge_level > 0.5 and charge < 0.5 and charge > 0.25:
		show_alert("50% Charge!")
		SoundPlayer.play(HALF_CHARGE_SFX)
	if last_charge_level > 0.25 and charge < 0.25:
		show_alert("LOW CHARGE!!")
		SoundPlayer.play(LOW_CHARGE_ALAWM)
	last_charge_level = charge
	charge_progress_bar.value = 100 * charge
