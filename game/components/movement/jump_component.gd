class_name JumpComponent extends MovementComponent
## Vertical jump impulses, including multi-jump.
##
## The controller calls [method jump]; the air-jump counter resets automatically
## on landing. [member stats] supplies jump height and max jumps.

@export var stats: MoveStats

var jumps_used: int = 0

func apply(body: CharacterBody2D, _delta: float) -> void:
	_reset_if_grounded(body)

## True if another jump is allowed right now.
func can_jump() -> bool:
	return jumps_used < stats.max_jumps

## Applies a jump impulse to [param body] (scaled for air jumps). No-op when no
## jumps remain, so coyote/buffer paths can never exceed [member MoveStats.max_jumps].
func jump(body: CharacterBody2D) -> void:
	# A buffered jump fires on the first grounded frame, before this step's apply()
	# runs (the FSM updates before the locomotion), so refresh the budget here too.
	_reset_if_grounded(body)
	if not can_jump():
		return
	if jumps_used == 0:
		body.velocity.y = stats.jump_height
	else:
		body.velocity.y = stats.jump_height * stats.multi_jump_height_multiplier
	jumps_used += 1

## Restores the jump budget once landed, but not on the frame we launch upward.
func _reset_if_grounded(body: CharacterBody2D) -> void:
	if body.is_on_floor() and body.velocity.y >= 0.0:
		jumps_used = 0
