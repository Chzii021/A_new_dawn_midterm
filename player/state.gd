class_name State extends Node
static var player: player_2
static var state_machine: PLaterStateMachine

func _ready():
	pass 

func init() -> void:
	pass

func Enter() -> void:
	pass

func Exit() -> void:
	pass

func Process( _delta : float) -> State:
	return null

func Physics(_delta : float) -> State:
	return null

func HandleInput( _event: InputEvent) -> State:
	return null
