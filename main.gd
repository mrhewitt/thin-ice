extends Node2D

@export var game_scene: PackedScene

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var background_texture_rect: TextureRect = $CanvasLayer/BackgroundTextureRect
@onready var title_label: Label = $CanvasLayer/TitleLabel
@onready var menu_container: VBoxContainer = $CanvasLayer/MenuContainer
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

var game: LakeView


func _ready() -> void:
	MusicPlayer.play_theme()
	
	background_texture_rect.modulate.a = 0
	title_label.modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(background_texture_rect, "modulate:a", 1.0, 1)
	tween.parallel().tween_property(title_label, "modulate:a", 1.0, 1) 
	tween.tween_interval(2.0)
	tween.tween_property(title_label, "modulate:a", 0.0, 1)
	await tween.finished
	
	show_menu()
	
	
func show_menu() -> void:
	menu_container.visible = true
	title_label.visible = false


func _on_play_button_pressed() -> void:
	GameManager.round_number = 0
	GameManager.total_deaths = 0
	GameManager.total_rescues = 0
	
	await fade_out()
	canvas_layer.visible = false
#	fade_rect.visible = false
	
	game = game_scene.instantiate()
	game.game_over.connect(_on_game_over)
#	game.modulate.a = 0
	add_child(game)
	
	fade_in()	


func _on_game_over() -> void:
	await fade_out()
	canvas_layer.visible = true
	MusicPlayer.play_theme()
	if is_instance_valid(game): game.queue_free()
	await fade_in()
	
	
func fade_out() -> void:
	fade_rect.modulate.a = 0
	fade_rect.visible = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1, 1)
	await tween.finished
	fade_rect.visible = false


func fade_in() -> void:
	fade_rect.modulate.a = 1
	fade_rect.visible = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0, 1)
	await tween.finished
	fade_rect.visible = false
	
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()
