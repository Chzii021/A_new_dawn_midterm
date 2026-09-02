extends Node2D
## Standalone room: deliberately does not modify quests, NPCs or global scene state.
signal battle_started(boss: Node2D)
signal battle_finished
signal exit_requested

@export var boss_scene: PackedScene
@export var preview_scene: PackedScene
@export var preview_hint: String = "WASD move / Room preview (no boss)"
@export_file("*.tscn") var return_scene: String = ""

var battle_active: bool = false
var battle_completed: bool = false
var active_boss: Node2D
var _leaving: bool = false
var _preview: Node2D
var _player_failed: bool = false

@onready var player: CharacterBody2D = $Actors/Player
@onready var gate_shape: CollisionShape2D = $EntranceGate/CollisionShape2D
@onready var hint: Label = $HUD/Hint

func _ready() -> void:
	player.position = $PlayerSpawn.position
	BossRoute.travel_failed.connect(_on_route_failed)
	# Configure only this player instance; leave the shared player scene untouched.
	for child in player.get_children():
		if child is Camera2D:
			child.enabled = false
	$RoomCamera.make_current()
	_fit_camera()
	get_viewport().size_changed.connect(_fit_camera)
	_set_gate(false)
	$BattleTrigger.body_entered.connect(_on_arena_entered)
	$ExitArea.body_entered.connect(_on_exit_entered)
	$ExitArea.body_exited.connect(_on_exit_left)
	var retry: Button = get_node_or_null("ResultUI/Panel/VBox/Retry")
	if retry != null:
		retry.pressed.connect(_retry_battle)
	if preview_scene != null and boss_scene == null:
		var preview_instance: Node = preview_scene.instantiate()
		if preview_instance is Node2D:
			_preview = preview_instance as Node2D
			_preview.position = $BossSpawn.position
			$Actors.add_child(_preview)
		else:
			preview_instance.free()
	_show_default_hint()

func _fit_camera() -> void:
	var available: Vector2 = get_viewport_rect().size
	# Leave space above for health/status and below for the existing hotbar.
	var fit: float = maxf(0.1, minf((available.x - 24.0) / 576.0, (available.y - 80.0) / 352.0))
	$RoomCamera.zoom = Vector2.ONE * fit
	$RoomCamera.offset = Vector2(0, 8.0 / fit)

func _on_arena_entered(body: Node2D) -> void:
	if body == player:
		start_battle.call_deferred()

func start_battle() -> void:
	if battle_active or battle_completed or _player_failed or boss_scene == null:
		return
	var instance: Node = boss_scene.instantiate()
	if not instance is Node2D:
		instance.free()
		push_warning("Boss scene must have a Node2D root. Entrance remains open.")
		return
	active_boss = instance as Node2D
	if is_instance_valid(_preview):
		_preview.queue_free()
	active_boss.position = $BossSpawn.position
	# Connect before adding, so a boss may emit defeated from its own _ready().
	if active_boss.has_signal("defeated"):
		active_boss.connect("defeated", finish_battle)
	if active_boss.has_signal("health_changed"):
		active_boss.connect("health_changed", _update_boss_health)
	if active_boss.has_signal("phase_changed"):
		active_boss.connect("phase_changed", _on_boss_phase_changed)
	if active_boss.has_method("set_target"):
		active_boss.set_target(player)
	battle_active = true
	_set_gate(true)
	hint.text = "Entrance sealed — defeat the boss"
	$Actors.add_child(active_boss)
	battle_started.emit(active_boss)

## Connect a custom boss death signal here if it does not expose defeated().
func finish_battle() -> void:
	if not battle_active:
		return
	battle_active = false
	battle_completed = true
	_set_gate(false)
	hint.text = "Room cleared — entrance unlocked"
	battle_finished.emit()
	var title: Label = get_node_or_null("HUD/BossHealth/Title")
	if title != null:
		title.text = "FOREST GUARDIAN — DEFEATED"

func _physics_process(_delta: float) -> void:
	if battle_active and player.hp <= 0 and not _player_failed:
		_player_failed = true
		battle_active = false
		player.velocity = Vector2.ZERO
		player.process_mode = Node.PROCESS_MODE_DISABLED
		if is_instance_valid(active_boss) and active_boss.has_method("stop_combat"):
			active_boss.stop_combat()
		_set_gate(false)
		hint.text = "You fell — try again"
		var panel: Control = get_node_or_null("ResultUI/Panel")
		if panel != null:
			panel.show()
			$ResultUI/Panel/VBox/Retry.grab_focus()

func _update_boss_health(current: int, maximum: int) -> void:
	var box: Control = get_node_or_null("HUD/BossHealth")
	if box == null:
		return
	box.show()
	$HUD/BossHealth/Bar.max_value = maximum
	$HUD/BossHealth/Bar.value = current

func _on_boss_phase_changed(_phase: int) -> void:
	hint.text = "Guardian enraged — faster attacks!"
	var title: Label = get_node_or_null("HUD/BossHealth/Title")
	if title != null:
		title.text = "FOREST GUARDIAN — ENRAGED"

func _retry_battle() -> void:
	if not _player_failed or _leaving:
		return
	_leaving = true
	global.player_health = global.player_max_health
	_retry_deferred.call_deferred()

func _retry_deferred() -> void:
	var error: Error = get_tree().reload_current_scene()
	if error != OK:
		_leaving = false
		hint.text = "Retry failed — reopen this scene with F6"

func _set_gate(closed: bool) -> void:
	gate_shape.set_deferred("disabled", not closed)
	$RoomArt.gate_closed = closed
	$RoomArt.queue_redraw()

func _on_exit_entered(body: Node2D) -> void:
	if body == player and not battle_active:
		hint.text = "SPACE — leave room" if not return_scene.is_empty() else "Test room — exit destination not connected yet"

func _on_exit_left(body: Node2D) -> void:
	if body == player:
		_show_default_hint()

func _show_default_hint() -> void:
	if _player_failed:
		hint.text = "You fell — try again"
	elif battle_active:
		hint.text = "Entrance sealed — defeat the boss"
	elif battle_completed:
		hint.text = "Room cleared — entrance unlocked"
	elif boss_scene == null:
		hint.text = preview_hint
	else:
		hint.text = "Walk into the arena to begin"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not battle_active and not _leaving and not _player_failed:
		if $ExitArea.overlaps_body(player):
			get_viewport().set_input_as_handled()
			exit_requested.emit()
			if return_scene.is_empty():
				hint.text = "Set Return Scene in the Inspector to connect this exit"
				return
			_leaving = true
			_leave_room.call_deferred()

func _leave_room() -> void:
	if return_scene == BossRoute.TRAIL:
		_leaving = BossRoute.travel(return_scene, BossRoute.TRAIL_RETURN)
		return
	var error: Error = get_tree().change_scene_to_file(return_scene)
	if error != OK:
		_leaving = false
		hint.text = "Could not open exit scene — check Return Scene"
		push_warning("Boss room exit failed: %s" % error_string(error))

func _on_route_failed(_path: String) -> void:
	_leaving = false
	hint.text = "Could not open the forest path — try again"
