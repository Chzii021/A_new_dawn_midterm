extends CharacterBody2D
## Self-contained boss. Uses the existing HitBox/HurtBox contract, without quest dependencies.
signal defeated
signal health_changed(current: int, maximum: int)
signal phase_changed(phase: int)

const ROOT_EFFECT: PackedScene = preload("res://boss_room/root_eruption.tscn")

enum BossState { INTRO, CHASE, WINDUP, STRIKE, RECOVER, DEFEATED, STOPPED }
enum Attack { SWEEP, ROOTS }

@export_range(1, 500, 1) var max_health: int = 24
@export var move_speed: float = 64.0
@export var sweep_damage: int = 10
@export var roots_damage: int = 15
@export var sweep_radius: float = 54.0
@export_range(30.0, 180.0) var sweep_angle_degrees: float = 120.0
@export var roots_radius: float = 34.0

var target: CharacterBody2D
var health: int
var state: BossState = BossState.INTRO
var attack: Attack = Attack.SWEEP
var phase: int = 1
var state_time: float = 0.0
var state_duration: float = 0.7
var attacks_started: int = 0
var damage_cooldown: float = 0.0
var attack_center: Vector2
var facing: Vector2 = Vector2.DOWN
var attack_direction: Vector2 = Vector2.DOWN
var _defeat_emitted: bool = false
var _flash_time: float = 0.0
var _attack_resolved: bool = false
var _root_effect: Node2D
var _exhausted: bool = false

@onready var visual: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var hit_box: HitBox = $HitBox
@onready var damage_source: HurtBox = $DamageSource

func set_target(value: CharacterBody2D) -> void:
	target = value

func _ready() -> void:
	health = max_health
	attack_center = global_position
	hit_box.Damaged.connect(_receive_hit)
	_build_animations()
	animation.play("idle")
	health_changed.emit(health, max_health)
	if target == null and is_instance_valid(PlayerManager.player):
		target = PlayerManager.player

func _physics_process(delta: float) -> void:
	state_time += delta
	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	_flash_time = maxf(0.0, _flash_time - delta)
	if state != BossState.DEFEATED:
		visual.modulate = Color(1.8, 0.6, 0.35) if _flash_time > 0.0 else Color.WHITE
		sprite.position = Vector2(sin(_flash_time * 100.0) * 2.0 if _flash_time > 0.0 else 0.0, -38.0)
	if state == BossState.DEFEATED:
		if state_time >= 1.1 and not _defeat_emitted:
			_defeat_emitted = true
			$Shadow.hide()
			defeated.emit()
		queue_redraw()
		return
	if state == BossState.STOPPED:
		return
	if not is_instance_valid(target) or target.hp <= 0:
		stop_combat()
		return
	velocity = Vector2.ZERO
	match state:
		BossState.INTRO:
			if state_time >= state_duration:
				_enter(BossState.CHASE)
		BossState.CHASE:
			var direction: Vector2 = global_position.direction_to(target.global_position)
			if direction.length_squared() > 0.0:
				facing = direction
				sprite.flip_h = direction.x > 0.0
			var distance: float = to_local(target.global_position).length()
			if distance < 42.0 or (attacks_started % 3 == 2 and distance < 170.0):
				_begin_attack()
			else:
				velocity = direction * move_speed * (1.23 if phase == 2 else 1.0)
				animation.speed_scale = 1.23 if phase == 2 else 1.0
				move_and_slide()
		BossState.WINDUP:
			if state_time >= state_duration:
				_enter(BossState.STRIKE, 0.24)
				animation.play("sweep" if attack == Attack.SWEEP else "roots")
				# Apply the impact pose on the same tick as damage, not next render.
				animation.advance(0.0)
				if attack == Attack.ROOTS and is_instance_valid(_root_effect):
					_root_effect.show()
					_root_effect.erupt()
				_apply_attack()
		BossState.STRIKE:
			if state_time >= state_duration:
				_begin_recovery()
		BossState.RECOVER:
			if state_time >= state_duration:
				_enter(BossState.CHASE)
	queue_redraw()

func _enter(next: BossState, duration: float = 0.0) -> void:
	_exhausted = false
	state = next
	state_time = 0.0
	state_duration = duration
	animation.speed_scale = 1.0
	if next == BossState.CHASE:
		animation.play("walk")

func _begin_attack() -> void:
	_attack_resolved = false
	attack = Attack.ROOTS if attacks_started % 3 == 2 else Attack.SWEEP
	attacks_started += 1
	# Telegraph position is locked now, never follows the player during the windup.
	var world_direction: Vector2 = facing.normalized() if not facing.is_zero_approx() else Vector2.DOWN
	attack_direction = (to_local(global_position + world_direction) - to_local(global_position)).normalized()
	attack_center = target.global_position if attack == Attack.ROOTS else global_position
	var duration: float = 1.15 if attack == Attack.ROOTS else 0.85
	_enter(BossState.WINDUP, duration * (0.8 if phase == 2 else 1.0))
	var clip: String = "root_windup" if attack == Attack.ROOTS else "windup"
	animation.play(clip)
	animation.speed_scale = animation.get_animation(clip).length / state_duration
	if attack == Attack.ROOTS:
		_root_effect = ROOT_EFFECT.instantiate()
		# Keep the warning-stage art hidden; reveal roots only on the damage tick.
		_root_effect.hide()
		_root_effect.configure(state_duration, roots_radius)
		get_parent().add_child(_root_effect)
		# Match the exact basis used by the ground footprint, including room scale.
		_root_effect.global_transform = Transform2D(global_transform.x, global_transform.y, attack_center)

func _begin_recovery() -> void:
	# Choose once per recovery; crossing half health does not restart the timer.
	var tired: bool = health * 2 <= max_health
	var duration: float = (1.0 if attack == Attack.ROOTS else 0.6) if tired else 0.8
	_enter(BossState.RECOVER, duration)
	_exhausted = tired
	velocity = Vector2.ZERO
	var clip: String = "root_recover" if attack == Attack.ROOTS else "recover"
	animation.play(clip if tired else clip + "_normal")

func _point_in_attack(point: Vector2) -> bool:
	# Drawing and hit tests share local space, including non-uniform parent scale.
	var offset: Vector2 = to_local(point) - to_local(attack_center)
	if attack == Attack.ROOTS:
		return offset.length() <= roots_radius
	# No circular padding behind the boss: telegraph and damage share this sector.
	return offset.length() <= sweep_radius and (offset.is_zero_approx() or offset.normalized().dot(attack_direction) >= cos(deg_to_rad(sweep_angle_degrees * 0.5)))

func _apply_attack() -> void:
	if state != BossState.STRIKE or _attack_resolved or not is_instance_valid(target) or target.hp <= 0:
		return
	_attack_resolved = true
	if not _point_in_attack(target.global_position) or target.invulnerble:
		return
	# Reject damage through environmental collision, even when inside the attack circle.
	var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 16, [get_rid()])
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	damage_source.damage = roots_damage if attack == Attack.ROOTS else sweep_damage
	target.hit_box.TakeDamage(damage_source)
	# The original player does not emit player_damage; avoid changing its shared state machine.
	# Grant local invulnerability and visual feedback without triggering its incomplete stun state.
	if target.hp > 0:
		target.make_invulnerble(0.6)
		target.effect_animationt_player.play("damaged")

func _receive_hit(source: HurtBox) -> void:
	if state in [BossState.DEFEATED, BossState.STOPPED] or damage_cooldown > 0.0:
		return
	if not is_instance_valid(target) or source != target.hurt_box or not source.monitoring:
		return
	if source.damage <= 0:
		return
	damage_cooldown = 0.32
	_flash_time = 0.17
	health = maxi(0, health - source.damage)
	health_changed.emit(health, max_health)
	if health == 0:
		_die()
	elif phase == 1 and health * 2 <= max_health:
		phase = 2
		phase_changed.emit(phase)

func _die() -> void:
	_enter(BossState.DEFEATED)
	velocity = Vector2.ZERO
	_cancel_effect()
	$Feet.set_deferred("disabled", true)
	hit_box.set_deferred("monitorable", false)
	hit_box.set_deferred("monitoring", false)
	visual.modulate = Color.WHITE
	sprite.position = Vector2(0, -38)
	animation.play("death")
	queue_redraw()

func stop_combat() -> void:
	if state == BossState.DEFEATED:
		return
	_enter(BossState.STOPPED)
	velocity = Vector2.ZERO
	_cancel_effect()
	animation.play("idle")
	queue_redraw()

func _draw() -> void:
	if state == BossState.RECOVER:
		if _exhausted:
			_draw_exhaustion()
		return
	# No ground telegraph during windup; actual attack effects remain visible.
	if state != BossState.STRIKE:
		return
	var center: Vector2 = to_local(attack_center)
	var radius: float = roots_radius if attack == Attack.ROOTS else sweep_radius
	var color := Color("e5a64e") if attack == Attack.SWEEP else Color("adce6b")
	if attack == Attack.SWEEP:
		var half_angle: float = deg_to_rad(sweep_angle_degrees * 0.5)
		var start: float = attack_direction.angle() - half_angle
		var finish: float = attack_direction.angle() + half_angle
		var points := PackedVector2Array([center])
		for i in range(33):
			points.append(center + Vector2.from_angle(lerpf(start, finish, i / 32.0)) * radius)
		draw_colored_polygon(points, Color(color, 0.32))
		draw_line(center, points[1], color, 1.5)
		draw_line(center, points[-1], color, 1.5)
		draw_arc(center, radius, start, finish, 32, color, 1.5)
		var fade: float = 1.0 - clampf(state_time / state_duration, 0, 1)
		# Whole sector hits once at impact; do not imply a delayed moving hitbox.
		draw_arc(center, radius - 3, start, finish, 32, Color(Color("fff1b3"), fade), 5)
		return
	draw_circle(center, radius, Color(color, 0.3))

func _draw_exhaustion() -> void:
	var color := Color("8ce5f2")
	var remaining: float = 1.0 - clampf(state_time / maxf(state_duration, 0.001), 0, 1)
	draw_arc(Vector2.ZERO, 21, 0, TAU, 40, Color(color, 0.65), 1.5)
	# Readable even when the boss is small: sweat drops + explicit counter cue.
	for side in [-1.0, 1.0]:
		var drop := Vector2(side * 17, -55 + fmod(state_time * 16 + side * 3, 10))
		draw_colored_polygon(PackedVector2Array([drop + Vector2(0, -4), drop + Vector2(-2, 1), drop + Vector2(2, 1)]), color)
	var font: Font = ThemeDB.fallback_font
	var caption: String = "EXHAUSTED"
	var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_rect(Rect2(-width / 2 - 3, -88, width + 6, 17), Color(0.02, 0.07, 0.08, 0.9))
	draw_string(font, Vector2(-width / 2, -77), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)
	draw_line(Vector2(-22, -71), Vector2(22, -71), Color("233d42"), 2)
	draw_line(Vector2(-22, -71), Vector2(-22 + 44 * remaining, -71), color, 2)

func _cancel_effect() -> void:
	if is_instance_valid(_root_effect):
		_root_effect.queue_free()
	_root_effect = null

func _build_animations() -> void:
	var library := AnimationLibrary.new()
	_add_frames(library, "idle", 1.3, true, [2])
	_add_frames(library, "walk", 0.60, true, [0, 1, 2, 3, 4, 5])
	_add_frames(library, "windup", 0.85, false, [6, 7, 8, 9])
	_add_frames(library, "root_windup", 1.15, false, [12, 13, 14, 15, 16])
	_add_frames(library, "sweep", 0.24, false, [10, 11])
	_add_frames(library, "roots", 0.24, false, [17])
	_add_frames(library, "recover", 0.72, true, [18, 19, 20, 21, 22, 23])
	_add_frames(library, "root_recover", 0.72, true, [18, 19, 20, 21, 22, 23])
	_add_frames(library, "recover_normal", 0.45, false, [11, 6, 2])
	_add_frames(library, "root_recover_normal", 0.45, false, [17, 16, 12, 2])
	_add_frames(library, "death", 1.1, false, [24, 25, 26, 27, 28, 29])
	var idle: Animation = library.get_animation("idle")
	# Reuse the reset track: duplicate scale tracks are added together by the mixer.
	var breath: int = idle.find_track("Visuals:scale", Animation.TYPE_VALUE)
	idle.track_insert_key(breath, 0.0, Vector2.ONE)
	idle.track_insert_key(breath, 0.65, Vector2(1.0, 0.985))
	idle.track_insert_key(breath, 1.3, Vector2.ONE)
	# Continuous sub-pixel motion between discrete drawings, with feet anchored.
	var walk: Animation = library.get_animation("walk")
	var bob: int = walk.find_track("Visuals:position", Animation.TYPE_VALUE)
	for i in range(5):
		walk.track_insert_key(bob, i * 0.15, Vector2(0, -0.6 if i % 2 else 0.0))
	for title in ["recover", "root_recover"]:
		var tired: Animation = library.get_animation(title)
		var heave: int = tired.find_track("Visuals:scale", Animation.TYPE_VALUE)
		tired.track_insert_key(heave, 0.0, Vector2.ONE)
		tired.track_insert_key(heave, 0.36, Vector2(1.0, 0.985))
		tired.track_insert_key(heave, 0.72, Vector2.ONE)
	var death: Animation = library.get_animation("death")
	var fade: int = death.add_track(Animation.TYPE_VALUE)
	death.track_set_path(fade, "Visuals:modulate")
	death.track_insert_key(fade, 0.0, Color.WHITE)
	death.track_insert_key(fade, 0.75, Color(0.8, 0.8, 0.8, 1.0))
	death.track_insert_key(fade, 1.1, Color(0.5, 0.5, 0.5, 0.0))
	animation.add_animation_library("", library)

func _add_frames(library: AnimationLibrary, title: String, duration: float, loop: bool, frames: Array) -> void:
	var clip := Animation.new()
	clip.length = duration
	clip.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var track: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, "Visuals/Sprite2D:frame")
	clip.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
	for i in range(frames.size()):
		clip.track_insert_key(track, duration * i / float(frames.size()), frames[i])
	# Reset the old pose transform whenever a new clip starts.
	for property in ["position", "rotation", "scale"]:
		var reset: int = clip.add_track(Animation.TYPE_VALUE)
		clip.track_set_path(reset, "Visuals:" + property)
		var value: Variant = Vector2.ONE if property == "scale" else (0.0 if property == "rotation" else Vector2.ZERO)
		clip.track_insert_key(reset, 0.0, value)
	library.add_animation(title, clip)
