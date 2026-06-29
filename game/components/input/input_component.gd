class_name InputComponent extends Node
## Handles Player Input 
##
## This componet should only be added to game objects te player wants to control
## Constanly pools for left and right input every frame and assigns it to [member InputComponent.input_horizontal]

@export_category("Movement Keys")
## The key to move the player left
@export var left_key: StringName = &"left"
## The key to move the player right
@export var right_key: StringName = &"right"
## the key to make the player dash
@export var dash_key: StringName = &"dash"
## the key to make the player jump
@export var jump_key: StringName = &"jump"
## the key to make the player crouch
@export var crouch_key: StringName = &"crouch"
## the key to make the player dive to the ground quickly
@export var fastfall_key: StringName = &"dive"
## the key to aim up, e.g. to opt into climbing a staircase
@export var up_key: StringName = &"up"

@export_category("Action Keys")
## the key to throw objects in the game
@export var throw_key: StringName = &"throw"
## the key to interact with items in the game
@export var interact_key: StringName = &"interact"

@export_category("Other")
## The key that will pause the game
@export var pause_key: StringName = &"pause"


## either -1.0, 0.0, 1.0, used to determine which way the player should travel
var input_horizontal: float = 0.0

## When false all gameplay input is ignored: [member input_horizontal] reads 0 and
## the gameplay getters return false. Pause ([method get_paused]) stays live so the
## player can still pause during a freeze/cutscene.
var enabled: bool = true


# checks every frame if input was given
func _process(_delta: float) -> void:
	input_horizontal = Input.get_axis(left_key, right_key) if enabled else 0.0


## True if the player wants to jump
func get_jump() -> bool:
	return enabled and Input.is_action_just_pressed(jump_key)


## True if the player wants to move left or right
func get_move() -> bool:
	return get_left() or get_right()


## True if the player wants to move left
func get_left() -> bool:
	return enabled and Input.is_action_pressed(left_key)


## True if the player wants to move right
func get_right() -> bool:
	return enabled and Input.is_action_pressed(right_key)


## True if the player wants to fast fall
func get_fast_fall() -> bool:
	return enabled and Input.is_action_pressed(fastfall_key)


## True if the player wants to aim up (e.g. take a staircase)
func get_up() -> bool:
	return enabled and Input.is_action_pressed(up_key)


## True if the player wants to dash
func get_dash() -> bool:
	return enabled and Input.is_action_pressed(dash_key)


## True if the player wants to crouch
func get_crouch() -> bool:
	return enabled and Input.is_action_pressed(crouch_key)


## True if the player has request to pause the game
func get_paused() -> bool:
	return Input.is_action_just_pressed(pause_key)


## True if the player wants to interact
func get_interact() -> bool:
	return enabled and Input.is_action_pressed(interact_key)


## True if the player wants to throw an object
func get_throw() -> bool:
	return enabled and Input.is_action_just_pressed(throw_key)
