class_name PoissonDiskSampler 
extends RefCounted
## Generates evenly-spaced 2D points with Bridson's Poisson-disk algorithm.
##
## Self-contained and project-agnostic — depends only on Godot built-ins, so the file can be
## dropped into any project that needs blue-noise point distribution (scatter, spawn points,
## foliage, patrol nodes…). Configure spacing on the instance, then call [method sample] with a
## bounds rectangle and a [RandomNumberGenerator]. Pass an optional [code]accepts[/code]
## [Callable] ([code]func(p: Vector2) -> bool[/code]) to clip the cloud to an arbitrary shape;
## omit it to fill the whole rectangle.
##
## [codeblock lang=gdscript]
##     var sampler := PoissonDiskSampler.new(48.0)
##     var rng := RandomNumberGenerator.new()
##     var points := sampler.sample(Rect2(0, 0, 400, 300), rng)
## [/codeblock]

## How many random tries [method _seed_point] makes before giving up on an initial point.
const _MAX_SEED_TRIES: int = 64
## Sentinel for "no valid point found".
const _INVALID_POINT: Vector2 = Vector2(INF, INF)

## Minimum distance between any two points — the Poisson radius.
var min_distance: float = 48.0
## Candidate samples tried around each active point before it is retired (Bridson k).
var attempts: int = 30
## Hard ceiling on points produced. [code]0[/code] = unlimited.
var max_points: int = 0

func _init(p_min_distance: float = 48.0, p_attempts: int = 30, p_max_points: int = 0) -> void:
	min_distance = p_min_distance
	attempts = p_attempts
	max_points = p_max_points

#region Public API
## Samples points within [param bounds] using [param rng] for determinism. When [param accepts]
## is a valid [Callable] ([code]func(p: Vector2) -> bool[/code]), only points it approves are
## kept, clipping the cloud to any shape. Returns the points in [param bounds]'s coordinate space.
func sample(bounds: Rect2, rng: RandomNumberGenerator, accepts: Callable = Callable()) -> Array[Vector2]:
	var samples: Array[Vector2] = []
	if min_distance <= 0.0:
		push_error("PoissonDiskSampler: min_distance must be greater than 0.")
		return samples

	var r: float = min_distance
	var cell: float = r / sqrt(2.0)
	var cols: int = maxi(int(ceil(bounds.size.x / cell)), 1)
	var rows: int = maxi(int(ceil(bounds.size.y / cell)), 1)
	var grid: PackedInt32Array = PackedInt32Array()
	grid.resize(cols * rows)
	grid.fill(-1)

	var active: Array[int] = []
	var first: Vector2 = _seed_point(bounds, rng, accepts)
	if first == _INVALID_POINT:
		push_warning("PoissonDiskSampler: could not place a seed point inside the bounds.")
		return samples

	samples.append(first)
	active.append(0)
	grid[_cell_index(first, bounds, cols, cell)] = 0

	while not active.is_empty() and not _at_cap(samples.size()):
		var a: int = rng.randi_range(0, active.size() - 1)
		var origin: Vector2 = samples[active[a]]
		var placed: bool = false

		for _i in attempts:
			var angle: float = rng.randf() * TAU
			var dist: float = rng.randf_range(r, 2.0 * r)
			var cand: Vector2 = origin + Vector2(cos(angle), sin(angle)) * dist
			if not bounds.has_point(cand):
				continue
			if accepts.is_valid() and not accepts.call(cand):
				continue
			if _has_neighbor(cand, samples, grid, bounds, cols, rows, cell, r):
				continue
			samples.append(cand)
			active.append(samples.size() - 1)
			grid[_cell_index(cand, bounds, cols, cell)] = samples.size() - 1
			placed = true
			if _at_cap(samples.size()):
				break

		if not placed:
			active.remove_at(a)
	return samples
#endregion

#region Private Helpers
## True once [param count] has reached [member max_points] (ignored when it is 0).
func _at_cap(count: int) -> bool:
	return max_points > 0 and count >= max_points


## Rejection-samples [param bounds] for an accepted initial point, or [constant _INVALID_POINT].
func _seed_point(bounds: Rect2, rng: RandomNumberGenerator, accepts: Callable) -> Vector2:
	for _i in _MAX_SEED_TRIES:
		var pt: Vector2 = bounds.position + Vector2(
			rng.randf() * bounds.size.x,
			rng.randf() * bounds.size.y,
		)
		if not accepts.is_valid() or accepts.call(pt):
			return pt
	return _INVALID_POINT


## Flattened background-grid index for [param pt] within [param bounds].
func _cell_index(pt: Vector2, bounds: Rect2, cols: int, cell: float) -> int:
	var gx: int = int((pt.x - bounds.position.x) / cell)
	var gy: int = int((pt.y - bounds.position.y) / cell)
	return gx + gy * cols


## True when any existing sample lies within [param r] of [param pt] (scans the ±2 cell window).
func _has_neighbor(pt: Vector2, samples: Array[Vector2], grid: PackedInt32Array,
		bounds: Rect2, cols: int, rows: int, cell: float, r: float) -> bool:
	var gx: int = int((pt.x - bounds.position.x) / cell)
	var gy: int = int((pt.y - bounds.position.y) / cell)
	for y in range(maxi(gy - 2, 0), mini(gy + 3, rows)):
		for x in range(maxi(gx - 2, 0), mini(gx + 3, cols)):
			var s: int = grid[x + y * cols]
			if s != -1 and samples[s].distance_to(pt) < r:
				return true
	return false
#endregion
