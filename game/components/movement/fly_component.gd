class_name FlyComponent
extends MovementComponent
## Applies a controller-set 2D velocity directly, for gravity-free flying bodies.
##
## A flyer carries this instead of [WalkComponent]/[GravityComponent]: a controller (an AI's
## [Pathfinder], say) sets [member velocity] each frame through
## [method LocomotionComponent.steer], and this writes it straight onto the body so the
## locomotion's single move_and_slide carries it out.

## Desired world velocity for this frame, set by the controller. Zeroed to stop.
var velocity: Vector2 = Vector2.ZERO


func apply(body: CharacterBody2D, _delta: float) -> void:
	body.velocity = velocity
