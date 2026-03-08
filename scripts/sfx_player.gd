extends Node

const LARGE_CRACK = "LARGE_CRACK"
const MEDIUM_CRACK = "MEDIUM_CRACK"
const SMALL_CRACK = "SMALL_CRACK"
const WHISTLE_001 = "WHISTLE_001"
const SPLASH = "SPLASH"
const BEEP = "BEEP"
const ALARM = "ALARM"
const POWER_DOWN_004 = "POWER_DOWN_004"

# list of sounds to be used with play_random, a sound will be selected at random
# from list of options for given key
const SFX_RANDOM = {

}

# dictionary of single sounds to be used with play(...)
var SFX = {
	LARGE_CRACK: preload("uid://cumv1nggix6rd"),
	MEDIUM_CRACK: preload("uid://bralnp66yibet"),
	SMALL_CRACK: preload("uid://d3uwiroejo4k6"),
	WHISTLE_001: preload("uid://b0gn4685rxalr"),
	POWER_DOWN_004: preload("uid://d3h2h0y3pktyq"),
	SPLASH:  preload("uid://v16ehjo80fs0"),
	ALARM: preload("uid://cavcvuc454m8k"), 
	BEEP: preload("uid://cev0m4sxj5f16")
}

var mute: bool = false:
	set(_mute): 
		mute = _mute
		var audio_bus_idx: int = AudioServer.get_bus_index('SFX')
		AudioServer.set_bus_mute(audio_bus_idx, mute)


func play( sound_key: String ) -> void:
	if SFX.has(sound_key):
		play_stream( SFX[sound_key] )
	else:
		print("SfxPlayer: Invalid sound key for play - " + sound_key)


func play_to_node( sound_key: String, parent: Node ) -> void:
	if SFX.has(sound_key):
		play_stream( SFX[sound_key], parent)
	else:
		print("SfxPlayer: Invalid sound key for play - " + sound_key)


func play_random( group: String) -> void:
	var sfx_list: Array = SFX_RANDOM.get(group)
	if sfx_list and sfx_list.size() > 0:
		play_stream( sfx_list.pick_random() )
	else:
		print("SfxPlayer: Invalid sound group for play_random: " + group)


func play_stream(sound_to_play: AudioStream, parent: Node = null ) -> void:
	# do nothing if sfx off, dont waste performance playing unheard sounds
	if mute:
		return
		
	# create a new audio player and put it in the scene
	# if you forgot to add_child() to incklude it in a scene
	# your sound will not play 
	var stream = AudioStreamPlayer.new()
	if parent == null:
		get_tree().get_current_scene().add_child(stream)
	else:
		parent.add_child(stream)
	# tell it to start playing the sound we chose
	stream.bus = "SFX"
	stream.stream = sound_to_play
	stream.play() 
	# wait for "finished" signal so we can know when it is done
	await stream.finished
	# delete sound player from scene so finished players dont simply continue to pile up
	stream.queue_free()
