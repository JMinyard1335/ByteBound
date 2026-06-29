@tool
class_name SentryDrone
extends Enemy
## A floating sentry that flies straight along its patrol path.
##
## Overrides the base ground seam so the drone moves freely in 2D toward each
## patrol waypoint instead of walking under gravity. Its [LocomotionComponent]
## carries no movers — it just slides the velocity set here.

## Speed (px/s) the drone flies along its patrol route.
@export var fly_speed: float = 60.0

func patrol_steer_to(target: Vector2) -> void:
	var direction: Vector2 = (target - global_position).normalized()
	velocity = direction * fly_speed
	if not is_zero_approx(direction.x):
		dir = int(signf(direction.x))
	return

func patrol_has_reached(target: Vector2, tol: float) -> bool:
	return global_position.distance_to(target) <= tol

func patrol_stop() -> void:
	velocity = Vector2.ZERO
	return
