@tool
extends Node2D
const GATE_ART: Texture2D = preload("res://boss_room/assets/forest_gate_pixel_v1.png")
const SEAL_ART: Texture2D = preload("res://boss_room/assets/forest_root_seal_v1.png")
## A local entrance marker: never writes quest state or completes objectives.
enum Destination { TRAIL, BOSS, VILLAGE }
@export var destination: Destination = Destination.TRAIL
var locked: bool = false
var _hint: Label

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	BossRoute.access_changed.connect(_refresh_lock)
	BossRoute.travel_failed.connect(_travel_failed)
	_refresh_lock(BossRoute.boss_unlocked)
	var canvas := CanvasLayer.new()
	canvas.layer = 3
	add_child(canvas)
	_hint = Label.new()
	_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hint.offset_left = 142
	_hint.offset_right = -8
	_hint.offset_top = 9
	_hint.offset_bottom = 30
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_font_size_override("font_size", 7)
	_hint.add_theme_color_override("font_color", Color("f0d9a1"))
	_hint.add_theme_color_override("font_shadow_color", Color("081514"))
	_hint.add_theme_constant_override("shadow_offset_x", 1)
	_hint.add_theme_constant_override("shadow_offset_y", 1)
	canvas.add_child(_hint)
	_hint.hide()

func _refresh_lock(_unlocked: bool) -> void:
	locked = destination == Destination.BOSS and not BossRoute.boss_unlocked
	$Barrier/Shape.set_deferred("disabled", not locked)
	queue_redraw()

func player_near() -> bool:
	var player = PlayerManager.player
	return is_instance_valid(player) and player.hp > 0 and player.global_position.distance_to(global_position + Vector2(0, 16)) <= 34.0

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _hint == null:
		return
	_hint.visible = player_near() and not global.dialogue_open
	if _hint.visible:
		if locked:
			_hint.text = "SEALED — complete the main story first"
		else:
			_hint.text = ["SPACE — enter the forest path", "SPACE — enter the guardian arena", "SPACE — return to the village"][destination]

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or event.is_echo() or global.dialogue_open:
		return
	if event.is_action_pressed("interact") and player_near():
		get_viewport().set_input_as_handled()
		try_enter()

func try_enter() -> bool:
	if not player_near() or global.dialogue_open:
		return false
	if destination == Destination.BOSS and not BossRoute.boss_unlocked:
		return false
	match destination:
		Destination.TRAIL:
			return BossRoute.travel(BossRoute.TRAIL, BossRoute.TRAIL_START)
		Destination.BOSS:
			return BossRoute.travel(BossRoute.ARENA)
		Destination.VILLAGE:
			return BossRoute.travel(BossRoute.VILLAGE, BossRoute.VILLAGE_RETURN)
	return false

func _travel_failed(_path: String) -> void:
	if _hint != null and player_near():
		_hint.text = "Could not open the path — try again"

func _draw() -> void:
	# Transparent artwork shares the existing post and barrier footprints.
	draw_texture_rect(GATE_ART, Rect2(-60, -74, 120, 80), false)
	var font: Font = ThemeDB.fallback_font
	var title: String = ["FOREST PATH", "GUARDIAN", "VILLAGE"][destination]
	var text_width: float = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 5).x
	draw_string(font, Vector2(-text_width / 2, -54), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("f3df9b"))
	if locked or (Engine.is_editor_hint() and destination == Destination.BOSS):
		draw_texture_rect(SEAL_ART, Rect2(-28, -22, 56, 25), false)
