extends Node

const SAVE_PATH := "user://savegame.cfg"
const WORLD_SCENE := "res://scenes/world.tscn"
const VILLAGE_SCENE := "res://scenes/village.tscn"
const OPENING_STORY_SCENE := "res://scenes/opening_story.tscn"

var game_active := false
var _loaded_position := Vector2.ZERO
var _has_loaded_position := false


func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)
	get_tree().node_added.connect(_on_node_added)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func start_new_game() -> void:
	_reset_runtime_state()
	game_active = true
	_has_loaded_position = false
	save_game()
	get_tree().change_scene_to_file(OPENING_STORY_SCENE)


func load_game() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	global.current_scene = str(config.get_value("player", "scene", "world"))
	global.player_health = int(config.get_value("player", "health", 100))
	global.player_max_health = int(config.get_value("player", "max_health", 100))
	_loaded_position = config.get_value("player", "position", Vector2(global.player_start_posx, global.player_start_posy))
	_has_loaded_position = true
	global.game_first_loading = false
	global.plant_states = config.get_value("world", "plants", {})
	global.seedling_states = config.get_value("world", "seedlings", {})
	global.collectible_states = config.get_value("world", "collectibles", {})
	global.repair_states = config.get_value("world", "repairs", {})
	global.pond_states = config.get_value("world", "ponds", {})
	global.well_states = config.get_value("world", "wells", {})
	global.npc_states = config.get_value("world", "npcs", {})
	_load_inventory(config.get_value("inventory", "slots", []))
	game_active = true
	var scene_path := VILLAGE_SCENE if global.current_scene == "ciff_side" else WORLD_SCENE
	get_tree().change_scene_to_file(scene_path)
	return true


func save_game() -> void:
	if not game_active:
		return
	var player = PlayerManager.player
	if is_instance_valid(player):
		global.player_health = player.hp
		_loaded_position = player.global_position
		_has_loaded_position = true
	var config := ConfigFile.new()
	config.set_value("save", "version", 1)
	config.set_value("player", "scene", global.current_scene)
	config.set_value("player", "health", global.player_health)
	config.set_value("player", "max_health", global.player_max_health)
	config.set_value("player", "position", _loaded_position)
	config.set_value("world", "plants", global.plant_states)
	config.set_value("world", "seedlings", global.seedling_states)
	config.set_value("world", "collectibles", global.collectible_states)
	config.set_value("world", "repairs", global.repair_states)
	config.set_value("world", "ponds", global.pond_states)
	config.set_value("world", "wells", global.well_states)
	config.set_value("world", "npcs", global.npc_states)
	config.set_value("inventory", "slots", _serialize_inventory())
	config.save(SAVE_PATH)


func _reset_runtime_state() -> void:
	global.current_scene = "world"
	global.transition_scene = false
	global.game_first_loading = true
	global.player_health = 100
	global.player_max_health = 100
	global.plant_states.clear()
	global.seedling_states.clear()
	global.collectible_states.clear()
	global.repair_states.clear()
	global.pond_states.clear()
	global.well_states.clear()
	global.npc_states.clear()
	for slot in _inventory().slots:
		slot.item = null
		slot.amount = 0
	_inventory().update.emit()


func _inventory():
	return load("res://inventory/playerinv.tres")


func _serialize_inventory() -> Array:
	var result: Array = []
	for slot in _inventory().slots:
		result.append({"item": slot.item.resource_path if slot.item else "", "amount": slot.amount})
	return result


func _load_inventory(data: Array) -> void:
	var inventory = _inventory()
	for i in inventory.slots.size():
		var saved: Dictionary = data[i] if i < data.size() else {}
		var item_path := str(saved.get("item", ""))
		inventory.slots[i].item = load(item_path) if not item_path.is_empty() else null
		inventory.slots[i].amount = int(saved.get("amount", 0))
	inventory.update.emit()


func _on_node_added(node: Node) -> void:
	if _has_loaded_position and node is player_2:
		node.call_deferred("set_global_position", _loaded_position)
		_has_loaded_position = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
