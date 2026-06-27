class_name InputComponent extends Node
## Handles Player Input 
##
## This componet should only be added to game objects te player wants to control
## Constanly pools for left and right input every frame and assigns it to [member InputComponent.input_horizontal]

## either -1.0, 0.0, 1.0
var input_horizontal: float = 0.0

## When false all gameplay input is ignored: [member input_horizontal] reads 0 and
## the gameplay getters return false. Pause ([method get_paused]) stays live so the
## player can still pause during a freeze/cutscene.
var enabled: bool = true

# checks every frame if input was given
func _process(_delta: float) -> void:
	input_horizontal = Input.get_axis("ui_left", "ui_right") if enabled else 0.0

func get_jump() -> bool:
	return enabled and Input.is_action_just_pressed("ui_accept")

func get_move() -> bool:
	return get_left() or get_right()

func get_left() -> bool:
	return enabled and Input.is_action_pressed("ui_left")

func get_right() -> bool:
	return enabled and Input.is_action_pressed("ui_right")

func get_fast_fall() -> bool:
	return enabled and Input.is_action_pressed("ui_down")

func get_dash() -> bool:
	return enabled and Input.is_action_pressed("dash")

func get_crouch() -> bool:
	return enabled and Input.is_action_pressed("crouch")

func get_paused() -> bool:
	return Input.is_action_just_pressed("ui_cancel")

func get_interact() -> bool:
	return enabled and Input.is_action_pressed("interact")

func get_throw() -> bool:
	return enabled and Input.is_action_just_pressed("throw")
