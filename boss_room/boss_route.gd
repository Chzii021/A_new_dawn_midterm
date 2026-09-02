extends Node
## Route-only session state. Deliberately does not read or modify any quests.
signal access_changed(unlocked: bool)
signal travel_failed(path: String)

const TRAIL := "res://boss_room/forest_path.tscn"
const ARENA := "res://boss_room/forest_boss_room.tscn"
const VILLAGE := "res://scenes/village.tscn"
const VILLAGE_RETURN := Vector2(360, 318)
const TRAIL_START := Vector2(160, 450)
const TRAIL_RETURN := Vector2(160, 114)

var boss_unlocked: bool = false
var travelling: bool = false
var _destination: String = ""
var _spawn: Vector2 = Vector2.INF

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)

func set_boss_unlocked(value: bool) -> void:
	if boss_unlocked != value:
		boss_unlocked = value
		access_changed.emit(value)

func travel(path: String, spawn: Vector2 = Vector2.INF) -> bool:
	if travelling or not ResourceLoader.exists(path):
		return false
	# The gate is also enforced here, not only by its visual/collision.
	if path == ARENA and not boss_unlocked:
		return false
	travelling = true
	_destination = path
	_spawn = spawn
	_perform_travel.call_deferred()
	return true

func _perform_travel() -> void:
	global.transition_scene = false
	var error: Error = get_tree().change_scene_to_file(_destination)
	if error != OK:
		var failed_path: String = _destination
		_clear_travel()
		travel_failed.emit(failed_path)
		push_warning("Forest route could not open: " + failed_path)

func _on_scene_changed() -> void:
	if not travelling:
		return
	var scene: Node = get_tree().current_scene
	if scene != null and scene.scene_file_path == _destination and _spawn.is_finite():
		var player = PlayerManager.player
		if is_instance_valid(player) and scene.is_ancestor_of(player):
			player.global_position = _spawn
			player.velocity = Vector2.ZERO
			var camera: Camera2D = get_viewport().get_camera_2d()
			if camera != null:
				camera.reset_smoothing()
				camera.force_update_scroll()
	_clear_travel()

func _clear_travel() -> void:
	travelling = false
	_destination = ""
	_spawn = Vector2.INF
