class_name plant extends Node2D
@export var health: int = 1
@onready var audio: AudioStreamPlayer2D = $Sound

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HitBox.Damaged.connect(TakeDamage)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func TakeDamage(hurt_box: HurtBox) -> void:
	health -= hurt_box.damage
	audio.play()
	await audio.finished
	if health <= 0:
		queue_free()
