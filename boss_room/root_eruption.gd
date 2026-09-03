extends Node2D
## Cosmetic only. The boss resolves damage once; this effect never deals extra damage.
var windup: float = 1.15
var radius: float = 34.0
var age: float = 0.0
var erupted: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func configure(duration: float, attack_radius: float) -> void:
	windup = maxf(duration, 0.1)
	radius = attack_radius

func _ready() -> void:
	sprite.scale = Vector2.ONE * radius * 2.0 / 164.0
	sprite.frame = 0
	sprite.modulate.a = 0.65

func erupt() -> void:
	erupted = true
	age = 0.0
	if is_node_ready():
		sprite.frame = 2
		sprite.modulate.a = 1.0

func _process(delta: float) -> void:
	age += delta
	if not erupted:
		sprite.frame = 0 if age < windup * 0.65 else 1
		return
	# Grow, peak, twist, retreat, disperse. Frame timing is independent of damage checks.
	var stages := [2, 3, 4, 5, 6, 7]
	sprite.frame = stages[mini(int(age / 0.13), stages.size() - 1)]
	sprite.modulate.a = 1.0 - clampf((age - 0.65) / 0.3, 0.0, 1.0)
	if age >= 0.95:
		queue_free()
