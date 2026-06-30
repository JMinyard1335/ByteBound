class_name PathfinderMapper
extends RefCounted
## Carves an ordered route from a [PathfinderRegion]'s point cloud and walks a cursor over it.
##
## Owned by a [Pathfinder]; not a scene node. Draws a random subset from the region's cloud,
## orders it greedily nearest-neighbour into a route, and exposes a cursor whose end-of-route
## behaviour is governed by [member path_type].

## How the cursor behaves once the end of the route is reached.[br]
## [b]LOOP[/b]: wrap back to the start.[br]
## [b]PONG[/b]: reverse direction and walk back towards the start.[br]
## [b]RAND[/b]: carve a fresh random route.
enum PathType {
	LOOP,
	PONG,
	RAND,
}

## The region routes are carved from.
var region: PathfinderRegion
## How the cursor behaves at the end of the route.
var path_type: PathType = PathType.LOOP
## Minimum number of waypoints in a route. Distinct from [PoissonSettings]'s cloud size.
var min_points: int = 2
## Maximum number of waypoints in a route. Distinct from [PoissonSettings]'s cloud size.
var max_points: int = 11

## The ordered set of waypoints the cursor moves between.
var path: PathfinderSet = PathfinderSet.new()

# Index of the waypoint the cursor currently points at; -1 when the route is empty.
var _current_idx: int = -1
# Direction the cursor steps in; only flips for [constant PathType.PONG].
var _step: int = 1
# Drives subset selection and the start point.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(p_region: PathfinderRegion = null, p_type: PathType = PathType.LOOP,
		p_min: int = 2, p_max: int = 11) -> void:
	region = p_region
	path_type = p_type
	min_points = p_min
	max_points = p_max
	_rng.randomize()

#region Public API
## Carves an ordered route of up to [param count] waypoints (clamped to
## [member min_points]..[member max_points]) from [member region]'s cloud, stores it in
## [member path], and resets the cursor to the start. When [param start] is a real point the
## route is ordered nearest-neighbour from it; otherwise a random start is chosen. Returns the
## new route.
func create_path(count: int, start: Vector2 = PathfinderSet.INVALID_POINT) -> PathfinderSet:
	path = PathfinderSet.new()
	_current_idx = -1
	_step = 1
	if region == null:
		push_warning("PathfinderMapper: no region assigned; returning an empty path.")
		return path

	var cloud: PackedVector2Array = region.generate_points()
	if cloud.is_empty():
		push_warning("PathfinderMapper: region produced no points.")
		return path

	var n: int = clampi(count, min_points, max_points)
	n = mini(n, cloud.size())

	var subset: Array[Vector2] = _random_subset(cloud, n)
	_order_nearest_neighbor(subset, start)
	_current_idx = 0 if not path.is_empty() else -1
	return path


## Advances the cursor one waypoint (honouring [member path_type]) and returns the new current
## point, or [constant PathfinderSet.INVALID_POINT] when the route is empty.
func next_point() -> Vector2:
	if path.is_empty():
		return PathfinderSet.INVALID_POINT
	_advance()
	return current_point()


## Steps the cursor back one waypoint and returns the new current point, or
## [constant PathfinderSet.INVALID_POINT] when the route is empty.
func previous_point() -> Vector2:
	if path.is_empty():
		return PathfinderSet.INVALID_POINT
	_retreat()
	return current_point()


## Returns the waypoint the cursor currently points at without moving it, or
## [constant PathfinderSet.INVALID_POINT] when the route is empty.
func current_point() -> Vector2:
	if path.is_empty():
		return PathfinderSet.INVALID_POINT
	return path.peek(_current_idx)


## Empties the route and resets the cursor.
func clear_path() -> void:
	path.clear()
	_current_idx = -1
	_step = 1


## Number of waypoints in the current route.
func size() -> int:
	return path.size()
#endregion

#region Private Helpers
## Returns [param count] points drawn from [param cloud] without replacement.
func _random_subset(cloud: PackedVector2Array, count: int) -> Array[Vector2]:
	var pool: Array[Vector2] = []
	for pt: Vector2 in cloud:
		pool.append(pt)

	var subset: Array[Vector2] = []
	for _i in count:
		var idx: int = _rng.randi_range(0, pool.size() - 1)
		subset.append(pool[idx])
		pool.remove_at(idx)
	return subset


## Orders [param subset] into a route by repeatedly hopping to the nearest unused point, then
## pushes the result into [member path]. Starts nearest [param start] when it is a real point.
func _order_nearest_neighbor(subset: Array[Vector2], start: Vector2) -> void:
	if subset.is_empty():
		return

	var first: int = _start_index(subset, start)
	var current: Vector2 = subset[first]
	subset.remove_at(first)
	path.push(current)

	while not subset.is_empty():
		var nearest: int = 0
		var best: float = current.distance_squared_to(subset[0])
		for i in range(1, subset.size()):
			var d: float = current.distance_squared_to(subset[i])
			if d < best:
				best = d
				nearest = i
		current = subset[nearest]
		subset.remove_at(nearest)
		path.push(current)


## Index in [param subset] of the point nearest [param start], or a random index when
## [param start] is [constant PathfinderSet.INVALID_POINT].
func _start_index(subset: Array[Vector2], start: Vector2) -> int:
	if start == PathfinderSet.INVALID_POINT:
		return _rng.randi_range(0, subset.size() - 1)

	var nearest: int = 0
	var best: float = start.distance_squared_to(subset[0])
	for i in range(1, subset.size()):
		var d: float = start.distance_squared_to(subset[i])
		if d < best:
			best = d
			nearest = i
	return nearest


## Steps the cursor forward one waypoint, honouring [member path_type] at the end.
func _advance() -> void:
	var count: int = path.size()
	match path_type:
		PathType.LOOP:
			_current_idx = (_current_idx + 1) % count
		PathType.PONG:
			var next: int = _current_idx + _step
			if next < 0 or next >= count:
				_step = -_step
				next = _current_idx + _step
			_current_idx = clampi(next, 0, count - 1)
		PathType.RAND:
			if _current_idx + 1 >= count:
				create_path(count)
			else:
				_current_idx += 1


## Steps the cursor back one waypoint (LOOP wraps; PONG/RAND clamp at the start).
func _retreat() -> void:
	var count: int = path.size()
	if path_type == PathType.LOOP:
		_current_idx = (_current_idx - 1 + count) % count
		return
	_current_idx = maxi(_current_idx - 1, 0)
#endregion
