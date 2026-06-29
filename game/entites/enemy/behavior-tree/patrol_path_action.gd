@tool
class_name PatrolPathAction
extends EnemyBTAction
## Patrols the enemy back and forth along its child [Path2D] waypoints.
##
## Sequences the waypoints captured by the [Enemy] (ping-ponging at the ends) and
## delegates the actual motion to the enemy's patrol seam, so the same action
## drives both walking and flying enemies.

## Distance (px) within which a waypoint counts as reached.
@export var arrive_distance: float = 4.0

var _index: int = 0
var _step: int = 1

func before_run(actor: Node, _blackboard: Blackboard) -> void:
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return
	_index = 0
	_step = 1
	return

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return FAILURE

	var points: PackedVector2Array = enemy.get_patrol_waypoints()
	if points.size() < 2:
		enemy.patrol_stop()
		return SUCCESS

	_index = clampi(_index, 0, points.size() - 1)
	var target: Vector2 = points[_index]
	if enemy.patrol_has_reached(target, arrive_distance):
		_advance(points.size())
		target = points[_index]

	enemy.patrol_steer_to(target)
	return RUNNING

func interrupt(actor: Node, blackboard: Blackboard) -> void:
	super(actor, blackboard)
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return
	enemy.patrol_stop()
	return

func after_run(actor: Node, _blackboard: Blackboard) -> void:
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return
	enemy.patrol_stop()
	return

func _advance(count: int) -> void:
	var next: int = _index + _step
	if next < 0 or next >= count:
		_step = -_step
		next = _index + _step
	_index = next
	return
