class_name PlayerJump extends PlayerState
## JUMP STATE — applies the jump impulse on entry; multi-jumps or dashes, then falls.

const PLAYER_JUMP: AudioPoolStream = preload("res://Assets/Audio/pool-streams/playerJump.tres")

@export_category("Transitions")
@export var fall_state: FSMState
@export var jump_state: FSMState
@export var dash_state: FSMState

func enter() -> void:
	super()
	motion.jump()
	AudioPool.play(PLAYER_JUMP, player.global_position)

func process_input(_event: InputEvent) -> FSMState:
	if motion.can_jump() and get_jump_input():
		return jump_state
	if check_dash_conditions():
		return dash_state
	return null

func process_physics(_delta: float) -> FSMState:
	motion.move(input.input_horizontal)
	motion.set_fast_fall(get_fastfall_input())
	if player.velocity.y > 0:
		return fall_state
	return null
