@tool
class_name Pathfinder
extends NavigationAgent2D
## Drop-in patrol agent: builds a route over a [PathfinderRegion] and steers a body along it.
##
## Add this as a direct child of a [Node2D] body (per level, so its [member region] can be set in
## the editor), assign a [PathfinderRegion], and call [method begin]. It owns a [PathfinderMapper]
## for the route + cursor, uses [NavigationAgent2D] navigation to reach each waypoint, and emits
## the per-frame velocity through [signal steering] — it never moves the body itself, so the
## consumer decides how to apply it (e.g. wire [signal steering] to
## [method LocomotionComponent.steer]). This keeps the addon free of any game-specific movement
## code.
##
## [codeblock lang=gdscript]
##     # On the body that owns the Pathfinder + a LocomotionComponent:
##     func _ready() -> void:
##         pather.steering.connect(locomotion.steer)
##         pather.begin()
## [/codeblock]

## Emitted once a fresh route has been carved (on [method begin]/[method regenerate]).
signal route_built(path: PathfinderSet)
## Emitted when the cursor advances to a new waypoint [param point] (route position, not a
## NavigationAgent2D path point — those use the inherited [signal NavigationAgent2D.waypoint_reached]).
signal route_advanced(point: Vector2)
## Emitted every physics frame while running with the velocity the body should apply this frame
## (the avoidance-adjusted velocity when [member NavigationAgent2D.avoidance_enabled]). Zeroed by
## [method stop].
signal steering(velocity: Vector2)

## Region routes are carved from. Required — [method begin] errors out when unset.
@export var region: PathfinderRegion:
	set(value):
		region = value
		update_configuration_warnings()

@export_category("Route")
## How the cursor behaves at the end of the route.
@export var path_type: PathfinderMapper.PathType = PathfinderMapper.PathType.LOOP
## Minimum waypoints in a route. Distinct from the region's cloud size.
@export_range(2, 10, 1) var min_points: int = 2
## Maximum waypoints in a route. Distinct from the region's cloud size.
@export_range(11, 100, 1) var max_points: int = 11
## Requested route length; clamped to [member min_points]..[member max_points] when carved.
@export_range(2, 100, 1) var route_points: int = 11

@export_category("Movement")
## Patrol speed fed to navigation/avoidance. Honoured by flyers; walkers use their own MoveStats.
@export var speed: float = 60.0

var _mapper: PathfinderMapper
var _running: bool = false
# True once the agent has begun navigating toward the current waypoint; gates arrival so the
# first frame (before the navigation map syncs) does not count as "already reached".
var _navigating: bool = false
var _body: Node2D

#region Engine Methods
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_body = get_parent() as Node2D
	assert(_body, "Pathfinder must be a child of a Node2D (the body it steers).")
	velocity_computed.connect(_on_velocity_computed)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _running:
		return
	if _mapper == null or _mapper.size() == 0:
		return

	if is_navigation_finished():
		if _navigating:
			_arrive()
		return

	_navigating = true
	var to_next: Vector2 = get_next_path_position() - _body.global_position
	var desired: Vector2 = to_next.normalized() * speed if not to_next.is_zero_approx() else Vector2.ZERO
	if avoidance_enabled:
		set_velocity(desired)
	else:
		steering.emit(desired)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray()
	if region == null:
		warnings.append("Assign a PathfinderRegion to Region so routes have somewhere to sample.")
	if not (get_parent() is Node2D):
		warnings.append("Pathfinder must be a child of a Node2D (the body it steers).")
	return warnings
#endregion

#region Public API
## Carves a route from the body's current position and starts steering along it.
func begin() -> void:
	if region == null:
		push_error("Pathfinder: no region assigned.")
		return

	_ensure_mapper()
	var route: PathfinderSet = _mapper.create_path(route_points, _body.global_position)
	if route.is_empty():
		push_warning("Pathfinder: carved an empty route; nothing to patrol.")
		_running = false
		return

	route_built.emit(route)
	target_position = _mapper.current_point()
	_navigating = false
	_running = true


## Halts patrolling and tells the body to stop.
func stop() -> void:
	_running = false
	steering.emit(Vector2.ZERO)


## Resumes a previously-built route without re-carving it.
func resume() -> void:
	if _mapper != null and _mapper.size() > 0:
		_running = true


## Re-carves the route from the body's current position, keeping the running state.
func regenerate() -> void:
	if _mapper == null:
		begin()
		return
	var route: PathfinderSet = _mapper.create_path(route_points, _body.global_position)
	route_built.emit(route)
	target_position = _mapper.current_point()
	_navigating = false


## True while the agent is actively patrolling.
func is_running() -> bool:
	return _running
#endregion

#region Signal Handlers
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	steering.emit(safe_velocity)
#endregion

#region Private Helpers
## Creates the mapper or refreshes it from the current exports.
func _ensure_mapper() -> void:
	if _mapper == null:
		_mapper = PathfinderMapper.new(region, path_type, min_points, max_points)
		return
	_mapper.region = region
	_mapper.path_type = path_type
	_mapper.min_points = min_points
	_mapper.max_points = max_points


## Advances the cursor to the next waypoint and aims the agent at it.
func _arrive() -> void:
	var pt: Vector2 = _mapper.next_point()
	target_position = pt
	_navigating = false
	route_advanced.emit(pt)
#endregion
