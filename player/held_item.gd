extends Node2D
## Cosmetic attachment only: uses item textures, never changes hitboxes or inventory.
var item_name := ""
var sprite := Sprite2D.new()
var owner_player: Node2D
var bucket := false

func _ready() -> void:
	owner_player = get_parent()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	add_child(sprite)
	hide()

func set_item(item: InvItem) -> void:
	item_name = item.name if item != null else ""
	sprite.texture = item.texture if item != null else null
	bucket = item_name in ["bucket", "bucket_water"]
	visible = item_name in ["sword", "axe", "bucket", "bucket_water"] and sprite.texture != null
	if not visible:
		return
	var dimensions := sprite.texture.get_size()
	# Grip points measured on the existing icons; scale by source resolution.
	var grip := Vector2(0.5, 0.36) if bucket else Vector2(0.25, 0.75)
	if item_name == "axe":
		# Axe handle runs toward bottom-right, opposite to the sword icon.
		grip = Vector2(0.73, 0.78)
	sprite.position = -dimensions * grip
	sprite.scale = Vector2.ONE * (16.0 if bucket else 27.0) / maxf(dimensions.x, dimensions.y)
	sprite.position *= sprite.scale
	_update_pose()

func _process(_delta: float) -> void:
	if not item_name.is_empty():
		_update_pose()

func _update_pose() -> void:
	if sprite.texture == null or not item_name in ["sword", "axe", "bucket", "bucket_water"]:
		hide()
		return
	visible = owner_player.hp > 0
	if not visible: return
	var body: AnimatedSprite2D = owner_player.animated_sprite
	var direction: Vector2 = owner_player.cardinal_direction
	var side := -1.0 if direction == Vector2.LEFT else 1.0
	var back := direction == Vector2.UP
	position = Vector2(side * 8, -10)
	if back: position = Vector2(8, -13)
	if item_name == "axe":
		# Side-facing sprites show the near hand behind the body center.
		position = Vector2(-2 * side, -3) if direction.x != 0 else Vector2(6, -4)
		if back: position = Vector2(-6, -5)
	z_index = -1 if back else 1
	scale = Vector2(side, 1)
	rotation = 0.0
	modulate = body.modulate
	var clip := String(body.animation)
	var count := body.sprite_frames.get_frame_count(body.animation)
	var progress := (float(body.frame) + body.frame_progress) / maxf(count, 1)
	var angle := 0.0 if bucket else -35.0
	if item_name == "axe": angle = 135.0
	if clip.begins_with("walk"):
		var swing := sin(progress * TAU)
		position.y += swing * 0.7
		angle += swing * (8.0 if bucket else 12.0)
	elif clip.begins_with("attack") and not bucket:
		# Follow the existing attack clip: raise, swing, settle. Damage unchanged.
		var arc := lerpf(-95, 65, clampf(progress / 0.65, 0, 1))
		if progress > 0.65: arc = lerpf(65, -35, (progress - 0.65) / 0.35)
		angle = arc
		if item_name == "axe": angle += 170.0
		position += direction * sin(progress * PI) * 4
	rotation_degrees = angle * side
