extends Node

const LEGACY_SAVE_PATH := "user://savegame.cfg"
const SAVE_PATH_FORMAT := "user://savegame_slot_%d.cfg"
const SLOT_COUNT := 3
const WORLD_SCENE := "res://scenes/world.tscn"
const VILLAGE_SCENE := "res://scenes/village.tscn"
const OPENING_STORY_SCENE := "res://scenes/opening_story.tscn"

var game_active := false
var active_slot := 1
var _loaded_position := Vector2.ZERO
var _has_loaded_position := false
var _load_destination := ""


func _ready() -> void:
	_migrate_legacy_save()
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)
	get_tree().scene_changed.connect(_on_scene_changed)


func _save_path(slot: int) -> String:
	return SAVE_PATH_FORMAT % clampi(slot, 1, SLOT_COUNT)


func has_save(slot: int = 0) -> bool:
	if slot > 0:
		return FileAccess.file_exists(_save_path(slot))
	for index in range(1, SLOT_COUNT + 1):
		if FileAccess.file_exists(_save_path(index)):
			return true
	return false


func get_slot_info(slot: int) -> Dictionary:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return {"exists": false, "slot": slot}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {"exists": false, "slot": slot, "corrupt": true}
	return {
		"exists": true,
		"slot": slot,
		"scene": str(config.get_value("player", "scene", "world")),
		"health": int(config.get_value("player", "health", 100)),
		"saved_at": str(config.get_value("save", "saved_at", "Existing save"))
	}


func delete_save(slot: int) -> bool:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return true
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error == OK and active_slot == slot:
		game_active = false
	return error == OK


func start_new_game(slot: int = 1) -> void:
	active_slot = clampi(slot, 1, SLOT_COUNT)
	_reset_runtime_state()
	game_active = true
	_has_loaded_position = false
	save_game()
	get_tree().change_scene_to_file(OPENING_STORY_SCENE)


func load_game(slot: int = 1) -> bool:
	active_slot = clampi(slot, 1, SLOT_COUNT)
	var config := ConfigFile.new()
	if config.load(_save_path(active_slot)) != OK:
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
	QuestManager.load_save_data(config.get_value("quests", "data", {}))
	_load_inventory(config.get_value("inventory", "slots", []))
	game_active = true
	_load_destination = _scene_for_save(global.current_scene)
	# A running boss encounter is not serialized. Resume safely outside its gate.
	if global.current_scene == "forest_boss_room":
		_loaded_position = BossRoute.TRAIL_RETURN
	global.transition_scene = false
	var error := get_tree().change_scene_to_file(_load_destination)
	if error != OK:
		_has_loaded_position = false
		_load_destination = ""
		game_active = false
	return error == OK

func _scene_for_save(scene_id: String) -> String:
	match scene_id:
		"village", "ciff_side": return VILLAGE_SCENE
		"forest_path", "forest_boss_room": return BossRoute.TRAIL
		"boss_room": return "res://boss_room/boss_room.tscn"
	return WORLD_SCENE


func save_game() -> void:
	if not game_active:
		return
	_capture_player_position()
	var config := ConfigFile.new()
	config.set_value("save", "version", 1)
	config.set_value("save", "slot", active_slot)
	config.set_value("save", "saved_at", Time.get_datetime_string_from_system(false, true))
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
	config.set_value("quests", "data", QuestManager.get_save_data())
	config.set_value("inventory", "slots", _serialize_inventory())
	config.save(_save_path(active_slot))


func _migrate_legacy_save() -> void:
	if FileAccess.file_exists(LEGACY_SAVE_PATH) and not FileAccess.file_exists(_save_path(1)):
		var copy_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(LEGACY_SAVE_PATH),
			ProjectSettings.globalize_path(_save_path(1))
		)
		if copy_error == OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))


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
	QuestManager.reset_progress()
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


func _capture_player_position() -> void:
	var player = PlayerManager.player
	if is_instance_valid(player):
		global.player_health = player.hp
		_loaded_position = player.global_position
	# Saving must never arm a teleport on the next map transition.

func _on_scene_changed() -> void:
	if not _has_loaded_position:
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != _load_destination:
		return
	var player = PlayerManager.player
	if is_instance_valid(player) and scene.is_ancestor_of(player):
		player.global_position = _loaded_position
		player.velocity = Vector2.ZERO
		var camera := get_viewport().get_camera_2d()
		if camera != null:
			camera.reset_smoothing()
			camera.force_update_scroll()
	_has_loaded_position = false
	_load_destination = ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
