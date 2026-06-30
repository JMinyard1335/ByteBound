@tool
class_name PathfinderRegion
extends NavigationRegion2D
## A [NavigationRegion2D] that scatters evenly-spaced points across its navigable area.
##
## Drives a [PoissonDiskSampler], clipped to the baked [NavigationPolygon], to build an
## unordered cloud of points no closer than [member PoissonSettings.min_distance]. Spacing and
## cloud size are tuned through the assigned [member distribution] resource. A consumer (the
## [Pathfinder]) later carves an ordered path from a subset of these points.

## Spacing / cloud-size tuning. Required — [method generate_points] errors out when unset.
@export var distribution: PoissonSettings:
	set(value):
		distribution = value
		update_configuration_warnings()
		_refresh_preview()
## Editor-only: regenerate and draw the cloud so spacing can be previewed.
@export var debug_draw: bool = false:
	set(value):
		debug_draw = value
		_refresh_preview()

## Baked polygons cached as point arrays for the duration of one generation.
var _polys: Array[PackedVector2Array] = []
## Global-space cloud cached for the editor preview.
var _preview_points: PackedVector2Array = PackedVector2Array()

#region Engine Methods
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if not _is_baked():
		warnings.append("Bake a NavigationPolygon so generated points have a region.")
	if distribution == null:
		warnings.append("Assign a PoissonSettings resource to Distribution.")
	return warnings


func _draw() -> void:
	if not (Engine.is_editor_hint() and debug_draw):
		return
	for pt in _preview_points:
		draw_circle(to_local(pt), 3.0, Color.CYAN)
#endregion

#region Public API
## Returns an evenly-spaced cloud of points in global (world) space, sampled from the navigable
## area. Pass an [param rng] for caller-controlled determinism; otherwise one is seeded from
## [member PoissonSettings.seed]. Returns an empty array when the region is unbaked or unset.
func generate_points(rng: RandomNumberGenerator = null) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	if distribution == null:
		push_error("PathfinderRegion needs a PoissonSettings resource on 'distribution'.")
		return result
	if not _is_baked():
		push_error("PathfinderRegion: navigation_polygon is missing or not baked.")
		return result

	if rng == null:
		rng = RandomNumberGenerator.new()
		if distribution.seed >= 0:
			rng.seed = distribution.seed
		else:
			rng.randomize()

	_cache_polys()
	var sampler := PoissonDiskSampler.new(
		distribution.min_distance, 
		distribution.attempts, 
		distribution.max_points
	)
	var local: Array[Vector2] = sampler.sample(_navigable_bounds(), rng, _is_navigable)
	_polys.clear()

	if local.size() < distribution.min_points:
		var msg: String = "PathfinderRegion generated %d points, below min_points %d."
		push_warning(msg % [local.size(), distribution.min_points])

	for pt in local:
		result.append(to_global(pt))
	return result
#endregion

#region Private Helpers
## True when a NavigationPolygon is present and has baked geometry to sample from.
func _is_baked() -> bool:
	return navigation_polygon != null and navigation_polygon.get_polygon_count() > 0


## Caches every baked polygon as a point array so [method _is_navigable] stays cheap.
func _cache_polys() -> void:
	_polys.clear()
	var verts: PackedVector2Array = navigation_polygon.get_vertices()
	for i in navigation_polygon.get_polygon_count():
		var poly: PackedVector2Array = PackedVector2Array()
		for idx in navigation_polygon.get_polygon(i):
			poly.append(verts[idx])
		_polys.append(poly)


## The local-space AABB covering all baked vertices.
func _navigable_bounds() -> Rect2:
	var verts: PackedVector2Array = navigation_polygon.get_vertices()
	var bounds: Rect2 = Rect2(verts[0], Vector2.ZERO)
	for i in range(1, verts.size()):
		bounds = bounds.expand(verts[i])
	return bounds


## Predicate for [PoissonDiskSampler]: true when [param local_pt] sits inside any baked polygon
## (holes already excluded by baking).
func _is_navigable(local_pt: Vector2) -> bool:
	for poly in _polys:
		if Geometry2D.is_point_in_polygon(local_pt, poly):
			return true
	return false


## Rebuilds the editor preview cloud and requests a redraw. No-op outside the editor.
func _refresh_preview() -> void:
	if not Engine.is_editor_hint():
		return
	_preview_points = PackedVector2Array()
	if debug_draw and distribution != null and _is_baked():
		_preview_points = generate_points()
	queue_redraw()
#endregion
