class_name PathfinderSet
extends RefCounted
## An ordered, indexed set of [Vector2] points.
##
## Backs a [PathfinderMapper] route: entries keep insertion order and can be addressed by index,
## but a point can not appear twice.

## Returned by [method peek]/[method pop] when an index is out of bounds.
const INVALID_POINT: Vector2 = Vector2(INF, INF)

var point_set: Array[Vector2] = []


## Appends [param point] unless it is already present.
func push(point: Vector2) -> void:
	if not point_set.has(point):
		point_set.append(point)


## Removes and returns the point at [param idx], or [constant INVALID_POINT] if out of bounds.
func pop(idx: int) -> Vector2:
	if not _in_bounds(idx):
		return INVALID_POINT

	var rv: Vector2 = point_set.get(idx)
	point_set.remove_at(idx)
	return rv


## Returns the point at [param idx] without removing it, or [constant INVALID_POINT] if out of bounds.
func peek(idx: int) -> Vector2:
	if not _in_bounds(idx):
		return INVALID_POINT

	return point_set.get(idx)


## Returns [code]true[/code] when [param point] is already in the set.
func has(point: Vector2) -> bool:
	return point_set.has(point)


## Returns the number of points in the set.
func size() -> int:
	return point_set.size()


func is_empty() -> bool:
	return point_set.is_empty()


## Removes every point.
func clear() -> void:
	point_set.clear()


func _in_bounds(idx: int) -> bool:
	return idx >= 0 and idx < size()
