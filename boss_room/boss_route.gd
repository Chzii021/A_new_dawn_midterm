extends Node
## Reads completed main-quest state; never completes quests on the player's behalf.
signal access_changed(unlocked: bool)
signal travel_failed(path: String)

const TRAIL := "res://boss_room/forest_path.tscn"
const ARENA := "res://boss_room/forest_boss_room.tscn"
const VILLAGE := "res://scenes/village.tscn"
const WORLD := "res://scenes/world.tscn"
const VILLAGE_ENTRY := Vector2(24, 24)
const WORLD_RETURN := Vector2(585, 252)
const VILLAGE_RETURN := Vector2(360, 318)
const TRAIL_START := Vector2(160, 450)
const TRAIL_RETURN := Vector2(160, 114)

var boss_unlocked: bool = false
var travelling: bool = false
var _destination: String = ""
var _spawn: Vector2 = Vector2.INF

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	QuestManager.quest_state_changed.connect(_sync_quest_access)
	_sync_quest_access()

func _sync_quest_access() -> void:
	set_boss_unlocked(QuestManager.get_quest_state("craft_sword") == QuestManager.COMPLETED)

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
			player.global_position = (scene as Node2D).to_global(_spawn)
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
