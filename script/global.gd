extends Node

var player_current_attack = false
var player_attack_id = 0

var current_scene = "world"
var transition_scene = false

var player_exit_village_posx = 585
var player_exit_village_posy = 252
var player_start_posx = 14
var player_start_posy = 28

var game_first_loading = true

var player_health: int = 100
var player_max_health: int = 100

var plant_states: Dictionary = {}
var seedling_states: Dictionary = {}
var collectible_states: Dictionary = {}

var repair_states: Dictionary = {}

var pond_states: Dictionary = {}
var well_states: Dictionary = {}
var npc_states: Dictionary = {}

var dialogue_open: bool = false
var near_crafting_table: bool = false

var house_states: Dictionary = {}


func finish_changescenes():
	if transition_scene == true:
		transition_scene = false
		if current_scene == "world":
			current_scene = "ciff_side"
		else:
			current_scene = "world"
