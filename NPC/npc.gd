extends CharacterBody2D

@export_category("NPC ID")
@export var npc_id: String = "village_npc_01"

var collision_waiting: bool = false
var collision_cooldown: float = 0.0

@export var escape_distance: float = 60.0
@export var collision_idle_time: float = 5.0
@export var collision_cooldown_time: float = 1.0

# =====================================================
# QUEST
# =====================================================

@export_category("Quest")
@export var quest_id: String = "repair_craft_table"
@export var npc_name: String = "ชาวบ้าน"


# =====================================================
# MOVEMENT
# =====================================================

@export_category("Movement")

@export var move_speed: float = 35.0

# เดินได้ห่างจากจุดเกิด
@export var wander_radius: float = 100.0

# เดินเล่นรวมกี่วินาทีก่อนกลับบ้าน
@export var wander_duration: float = 20.0

# พักที่บ้าน
@export var home_wait_time: float = 5.0

# เดินแต่ละช่วงกี่วินาทีก่อนหยุด Idle
@export var walk_time_min: float = 2.0
@export var walk_time_max: float = 5.0

# Idle ระหว่างเดิน
@export var idle_time_min: float = 1.0
@export var idle_time_max: float = 3.0

@export var start_idle_time: float = 60

@export_category("Dialogue")
@export var npc_portrait: Texture2D

# =====================================================
# PLAYER
# =====================================================

var player: player_2 = null
var player_near: bool = false


# =====================================================
# MOVEMENT STATE
# =====================================================

var start_position: Vector2
var target_position: Vector2

var is_talking: bool = false
var returning_home: bool = false

var waiting_at_home: bool = false
var is_idle: bool = false

var wander_time: float = 0.0
var home_wait_timer: float = 0.0

var movement_timer: float = 0.0
var idle_timer: float = 0.0



# =====================================================
# NODES
# =====================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var quest_mark: Label = $QuestMark
@onready var talk_hint: Label = $TalkHint


# =====================================================
# READY
# =====================================================
func _ready() -> void:
	start_position = global_position
	target_position = start_position

	quest_mark.visible = false
	talk_hint.visible = false

	# เช็กว่า NPC ตัวนี้เคยยืนเริ่มต้นไปแล้วหรือยัง
	var has_started: bool = global.npc_states.get(
		npc_id,
		false
	)

	if not has_started:
		# ครั้งแรกเท่านั้น
		is_idle = true
		idle_timer = start_idle_time

		velocity = Vector2.ZERO
		play_idle_animation()

		# จำไว้ว่าเคยผ่านช่วงเริ่มต้นแล้ว
		global.npc_states[npc_id] = true

	else:
		# กลับเข้าแมพใหม่ ไม่ต้องยืนเริ่มต้นอีก
		is_idle = false
		start_new_walk()

	update_quest_mark()

# =====================================================
# PROCESS
# =====================================================

func _process(delta: float) -> void:
	update_quest_mark()


	# =========================================
	# คุยอยู่
	# =========================================

	if is_talking:
		velocity = Vector2.ZERO
		play_idle_animation()
		return


	# =========================================
	# Player กด E
	# =========================================

	if player_near:
		if Input.is_action_just_pressed("interact_npc"):
			talk_to_npc()
			return


	# =========================================
	# กำลังรอหลังชน
	# =========================================

	if collision_waiting:
		velocity = Vector2.ZERO
		play_idle_animation()
		return


	# =========================================
	# รออยู่ที่บ้าน
	# =========================================

	if waiting_at_home:
		home_wait_timer -= delta

		velocity = Vector2.ZERO
		play_idle_animation()

		if home_wait_timer <= 0.0:
			waiting_at_home = false
			wander_time = 0.0

			start_new_walk()

		return


	# =========================================
	# Idle ระหว่างเดิน
	# =========================================

	if is_idle:

		idle_timer -= delta

		velocity = Vector2.ZERO

		play_idle_animation()


		if idle_timer <= 0.0:

			is_idle = false

			choose_new_wander_target()

			movement_timer = randf_range(
				walk_time_min,
				walk_time_max
			)


		return


	# =========================================
	# เดินเล่น
	# =========================================

	if not returning_home:
		wander_time += delta
		movement_timer -= delta


		# ถึงเวลาหยุดพักระหว่างเดิน
		if movement_timer <= 0.0:
			start_idle()

			return


		# เดินเล่นครบเวลาแล้ว → กลับบ้าน
		if wander_time >= wander_duration:
			returning_home = true
			target_position = start_position


	move_npc()

func _physics_process(delta: float) -> void:

	if collision_cooldown > 0.0:
		collision_cooldown -= delta


	if is_talking:
		velocity = Vector2.ZERO
		return


	if is_idle:
		velocity = Vector2.ZERO
		return


	if waiting_at_home:
		velocity = Vector2.ZERO
		return


	if collision_waiting:
		velocity = Vector2.ZERO
		return


	move_and_slide()


	# =========================================
	# ตรวจ Collision
	# =========================================

	if collision_cooldown > 0.0:
		return


	if get_slide_collision_count() <= 0:
		return


	var collision: KinematicCollision2D = (
		get_slide_collision(0)
	)


	if collision == null:
		return


	handle_collision(collision)

# =====================================================
# เดิน
# =====================================================

func move_npc() -> void:

	var distance: float = (
		global_position.distance_to(
			target_position
		)
	)


	# =========================================
	# ถึง Target
	# =========================================

	if distance < 5.0:

		velocity = Vector2.ZERO


		# =====================================
		# เพิ่งเดินหนี Object สำเร็จ
		# =====================================

		if escape_distance:

			escape_distance = false


			# ถ้าก่อนหน้านี้กำลังกลับบ้าน
			if returning_home:

				target_position = (
					start_position
				)

				return


			# ถ้าเดินเล่นอยู่
			start_idle()

			return


		# =====================================
		# กลับถึงบ้าน
		# =====================================

		if returning_home:

			if (
				global_position.distance_to(
					start_position
				)
				< 5.0
			):

				returning_home = false
				waiting_at_home = true

				home_wait_timer = (
					home_wait_time
				)

				global_position = (
					start_position
				)

				play_idle_animation()

				return


		# =====================================
		# เดินถึงจุดสุ่ม
		# =====================================

		start_idle()

		return


	# =========================================
	# เดินไปหา Target
	# =========================================

	var dir: Vector2 = (
		global_position.direction_to(
			target_position
		)
	)


	velocity = (
		dir
		* move_speed
	)


	play_walk_animation(dir)

# =====================================================
# เริ่มเดินรอบใหม่
# =====================================================

func start_new_walk() -> void:

	is_idle = false

	choose_new_wander_target()

	movement_timer = randf_range(
		walk_time_min,
		walk_time_max
	)


# =====================================================
# เริ่ม Idle
# =====================================================

func start_idle() -> void:

	is_idle = true
	velocity = Vector2.ZERO


	idle_timer = randf_range(
		idle_time_min,
		idle_time_max
	)


	play_idle_animation()

# =====================================================
# สุ่มจุดเดิน
# =====================================================

func choose_new_wander_target() -> void:

	var random_offset := Vector2(
		randf_range(
			-wander_radius,
			wander_radius
		),
		randf_range(
			-wander_radius,
			wander_radius
		)
	)


	target_position = (
		start_position
		+ random_offset
	)

func handle_collision(
	collision: KinematicCollision2D
) -> void:

	if collision_waiting:
		return


	if escape_distance:
		return


	collision_waiting = true
	velocity = Vector2.ZERO

	play_idle_animation()


	# =========================================
	# ทิศที่ออกจาก Object
	# =========================================

	var collision_normal: Vector2 = (
		collision.get_normal()
	)


	if collision_normal == Vector2.ZERO:
		collision_normal = (
			Vector2.LEFT.rotated(
				randf_range(
					0.0,
					TAU
				)
			)
		)


	# =========================================
	# จุดสำหรับเดินหนี
	# =========================================

	var escape_position: Vector2 = (
		global_position
		+ collision_normal
		* escape_distance
	)


	print(
		"NPC ชน Object → Idle ",
		collision_idle_time,
		" วินาที"
	)


	# =========================================
	# Idle หลังชน
	# =========================================

	await get_tree().create_timer(
		collision_idle_time
	).timeout


	collision_waiting = false


	# คุยอยู่ก็ยังไม่ต้องเดิน
	if is_talking:
		return


	# =========================================
	# เริ่มเดินหนี Object
	# =========================================

	escape_distance = true

	collision_cooldown = (
		collision_cooldown_time
	)


	target_position = escape_position


	movement_timer = randf_range(
		walk_time_min,
		walk_time_max
	)


	is_idle = false
	
# =====================================================
# PLAYER เข้าใกล้
# =====================================================

func _on_chat_detection_area_body_entered(
	body: Node2D
) -> void:

	if body is player_2:

		player = body
		player_near = true

		talk_hint.visible = true

		update_quest_mark()


# =====================================================
# PLAYER ออก
# =====================================================

func _on_chat_detection_area_body_exited(
	body: Node2D
) -> void:

	if body == player:

		player = null
		player_near = false

		talk_hint.visible = false
		quest_mark.visible = false

func talk_to_npc() -> void:

	if is_talking:
		return


	is_talking = true

	velocity = Vector2.ZERO

	play_talk_animation()


	# =========================================
	# หา Quest ปัจจุบัน
	# =========================================

	var quest: Dictionary = (
		QuestManager.get_current_quest()
	)


	# =========================================
	# ทำทุก Quest จบแล้ว
	# =========================================

	if quest.is_empty():

		await DialogueUI.message(
			npc_name,
			"Thank you for everything!",
			npc_portrait
		)

		is_talking = false

		play_idle_animation()

		return


	var quest_id: String = (
		quest["id"]
	)


	var state: int = (
		QuestManager.get_quest_state(
			quest_id
		)
	)


	# =========================================
	# ยังไม่รับ Quest
	# =========================================

	if state == QuestManager.NOT_STARTED:

		var accepted: bool = (
			await DialogueUI.ask(
				npc_name,
				quest["start_text"],
				npc_portrait
			)
		)


		if accepted:

			QuestManager.start_current_quest()


	# =========================================
	# กำลังทำ Quest
	# =========================================

	elif state == QuestManager.ACTIVE:

		var text: String = (
			quest["active_text"]
		)


		var target: int = (
			quest.get(
				"target",
				1
			)
		)


		# Quest ที่มี Progress
		if target > 1:

			var progress: int = (
				QuestManager.get_progress(
					quest_id
				)
			)


			text += (
				"\n\nProgress: "
				+ str(progress)
				+ "/"
				+ str(target)
			)


		await DialogueUI.message(
			npc_name,
			text,
			npc_portrait
		)


	# =========================================
	# ทำเสร็จแล้ว
	# =========================================

	elif (
		state
		== QuestManager.READY_TO_TURN_IN
	):

		await DialogueUI.message(
			npc_name,
			quest["complete_text"],
			npc_portrait
		)


		# Quest ปัจจุบันจบ
		QuestManager.complete_current_quest()


		# =====================================
		# มี Quest ต่อ
		# =====================================

		var next_quest: Dictionary = (
			QuestManager.get_current_quest()
		)


		if not next_quest.is_empty():

			var accepted: bool = (
				await DialogueUI.ask(
					npc_name,
					next_quest["start_text"],
					npc_portrait
				)
			)


			if accepted:

				QuestManager.start_current_quest()


		else:

			await DialogueUI.message(
				npc_name,
				"Thank you for everything!",
				npc_portrait
			)


	update_quest_mark()


	is_talking = false

	play_idle_animation()

func update_quest_mark() -> void:

	if not player_near:

		quest_mark.visible = false

		return


	var quest: Dictionary = (
		QuestManager.get_current_quest()
	)


	if quest.is_empty():

		quest_mark.visible = false

		return


	var quest_id: String = (
		quest["id"]
	)


	var state: int = (
		QuestManager.get_quest_state(
			quest_id
		)
	)


	match state:

		QuestManager.NOT_STARTED:

			quest_mark.text = "!"
			quest_mark.visible = true


		QuestManager.ACTIVE:

			quest_mark.visible = false


		QuestManager.READY_TO_TURN_IN:

			quest_mark.text = "?"
			quest_mark.visible = true


		QuestManager.COMPLETED:

			quest_mark.visible = false
# =====================================================
# WALK ANIMATION
# =====================================================

func play_walk_animation(
	dir: Vector2
) -> void:

	if abs(dir.y) > abs(dir.x):

		if dir.y > 0:

			animated_sprite.flip_h = false
			animated_sprite.play(
				"walk_front"
			)

		else:

			animated_sprite.flip_h = false
			animated_sprite.play(
				"walk_back"
			)

	else:

		if dir.x > 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false


		animated_sprite.play(
			"walk_side"
		)


# =====================================================
# IDLE
# =====================================================

func play_idle_animation() -> void:

	animated_sprite.play(
		"idle_front"
	)


# =====================================================
# TALK
# =====================================================

func play_talk_animation() -> void:

	animated_sprite.flip_h = false

	animated_sprite.play(
		"talk_front"
	)
