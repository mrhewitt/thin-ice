extends Node

enum GameOverCondition { RUN_FLAT, LIVES_LOST, FELL_IN_HOLE }

## Number of skters that must drown to trigger game over condition
const DEATHS_TO_LOOSE = 3

## Emitted when the players blows his whistle
signal whistle_blown

## Emitted when the zombonies charge state is changed
signal zambonie_charge( delta: float )

signal towline_full

## Emitted when a game over condition is met
signal game_over( reason: GameOverCondition )


const ROUNDS = [
	{
		skaters = 6,
		fishers = 1,
		min_ice_form_time = 5,
		max_ice_form_time = 10,
		round_time = 30,
		crack_advance_time = 5
	},
	{
		skaters = 10,
		fishers = 2,
		min_ice_form_time = 5,
		max_ice_form_time = 15,
		round_time = 60,
		crack_advance_time = 5
	},	
	{
		skaters = 10,
		fishers =3,
		min_ice_form_time = 5,
		max_ice_form_time = 10,
		round_time = 60,
		crack_advance_time = 4
	},	
	{
		skaters = 15,
		fishers = 4,
		min_ice_form_time = 5,
		max_ice_form_time = 10,
		round_time = 70,
		crack_advance_time = 4
	},
	{
		skaters = 15,
		fishers = 5,
		min_ice_form_time = 2.5,
		max_ice_form_time = 10,
		round_time = 80,
		crack_advance_time = 3
	},
	{
		skaters = 20,
		fishers = 6,
		min_ice_form_time = 2.5,
		max_ice_form_time = 10,
		round_time = 90,
		crack_advance_time = 3
	},
]


var total_rescues: int = 0

var total_deaths: int = 0:
	set(deaths):
		total_deaths = deaths
		if total_deaths >= DEATHS_TO_LOOSE:
			game_over.emit( GameOverCondition.LIVES_LOST )

## Number of seconds you survived for
var time_survived: float = 0

var round_number: int = 0
	
var player: Player = null
