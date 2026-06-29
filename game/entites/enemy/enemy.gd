@tool
class_name Enemy
extends BaseCharacter
## Shared base for every AI enemy.
##
## Every enemy requires a child [Path2D] that describes its patrol route. The
## curve's points are captured into fixed world-space waypoints at spawn (the
## path itself rides along with the body, so it can't be followed live). A
## [PatrolPathAction] in the child [BeehaveTree] walks the body between those
## waypoints by calling the patrol seam below.
##
## The base seam ([method patrol_steer_to], [method patrol_has_reached],
## [method patrol_stop]) drives a ground walker through its [LocomotionComponent].
## Flying enemies ([SentryDrone]) override it to move freely in 2D.

## Owns the body's movement and is its sole mover/slider. Controllers (the
## behavior tree) set intent through this component, never sliding the body.
@export var locomotion: LocomotionComponent

## The patrol route, captured from the child [Path2D] at spawn. World space.
var patrol_waypoints: PackedVector2Array = PackedVector2Array()

var _patrol_path: Path2D

#region Engine Methods
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	super._ready()
	assert(locomotion, "Enemy: locomotion (LocomotionComponent) not set")
	_patrol_path = _find_patrol_path()
	assert(_patrol_path, "Enemy: a child Path2D is required to define the patrol route")
	_capture_waypoints()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var path: Path2D = _find_patrol_path()
	if path == null:
		warnings.append("An enemy needs a child Path2D to define its patrol route.")
	elif path.curve == null or path.curve.point_count < 2:
		warnings.append("The patrol Path2D needs at least 2 points.")
	return warnings
#endregion

#region Public API
## The patrol route in world space, captured from the child [Path2D] at spawn.
func get_patrol_waypoints() -> PackedVector2Array:
	return patrol_waypoints


## Drives one frame of movement toward [param target] (world space). The base
## walks horizontally toward the target's x; flyers override for full 2D motion.
func patrol_steer_to(target: Vector2) -> void:
	var direction: float = signf(target.x - global_position.x)
	if direction != 0.0:
		dir = int(direction)
	locomotion.move(direction)


## True when [param target] is within [param tol] of this enemy. The base uses
## horizontal distance (gravity handles the vertical); flyers override for 2D.
func patrol_has_reached(target: Vector2, tol: float) -> bool:
	return absf(target.x - global_position.x) <= tol


## Cancels this frame's patrol movement intent.
func patrol_stop() -> void:
	locomotion.stop()
#endregion

#region Private Helpers
func _find_patrol_path() -> Path2D:
	for child in get_children():
		if child is Path2D:
			return child as Path2D
	return null


func _capture_waypoints() -> void:
	patrol_waypoints = PackedVector2Array()
	var curve: Curve2D = _patrol_path.curve
	if curve == null or curve.point_count == 0:
		push_warning("%s: patrol Path2D has no points." % name)
		return
	for i in range(curve.point_count):
		patrol_waypoints.append(_patrol_path.to_global(curve.get_point_position(i)))
#endregion
