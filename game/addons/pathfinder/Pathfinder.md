# Pathfinder Component

The Pathfinder is a `NavigationAgent2D` you drop onto a body (a `Node2D`) so it can patrol
around the game world. It carves a route over a `PathfinderRegion`, walks the body from waypoint
to waypoint, and hands you a steering velocity each frame — it never moves the body itself, so the
consumer decides how to apply it.

This component is a tool script and emits a warning in the editor (similar to an Area2D without a
collision shape) when it is missing what it needs: a `PathfinderRegion` to sample from, or a
`Node2D` parent to steer.

The `PathfinderRegion` is its own `NavigationRegion2D` node somewhere in the scene. You assign it
to the Pathfinder's `region` export in the editor — it is not a child of the Pathfinder.

```
Node2D                     # the body being steered
 | --- Pathfinder          # NavigationAgent2D, region export points at the region below
 | --- LocomotionComponent # (or whatever applies the steering velocity)

PathfinderRegion           # NavigationRegion2D, lives elsewhere in the scene
```

## API

- `begin()`: Carves a route from the body's current position and starts steering along it. Errors
  out if no `region` is assigned.
- `stop()`: Halts patrolling and tells the body to stop (emits a zero `steering` velocity).
- `resume()`: Resumes a previously-built route without re-carving it.
- `regenerate()`: Re-carves the route from the body's current position, keeping the running state.
- `is_running()`: True while the agent is actively patrolling.

Signals:

- `route_built(path: PathfinderSet)`: a fresh route was carved (on `begin()`/`regenerate()`).
- `route_advanced(point: Vector2)`: the cursor moved to a new waypoint.
- `steering(velocity: Vector2)`: emitted every physics frame with the velocity the body should
  apply this frame. Wire this to your movement code.

## Creating a path

When creating a path the `PathfinderRegion` is in charge of generating points via a poisson
distribution, evenly spread within the navigable area of its baked `NavigationPolygon`.

- `PathfinderRegion.generate_points()` returns an unordered `PackedVector2Array` of points in
  global (world) space, no two closer than the configured minimum distance.
- The distribution is tuned by a `PoissonSettings` resource assigned to the region's
  `distribution` property: `min_distance` (spacing), `attempts`, `min_points`/`max_points`
  (cloud size) and `seed` (determinism). Cloud size is intentionally larger than a path — the
  pathfinder carves a path from a subset of the cloud.

Set `debug_draw` on the region to preview the cloud in the editor.

The sampling itself lives in `pathfinder-sampler/poisson_disk_sampler.gd` (`PoissonDiskSampler`)
— a project-agnostic `RefCounted` that runs Bridson's algorithm over a `Rect2`, optionally
clipped by a `func(p: Vector2) -> bool` predicate. The region just supplies the navigable bounds,
its `_is_navigable` predicate, and converts the result to world space; the sampler can be reused
anywhere points are needed.

The cloud is intentionally larger than a route. The Pathfinder owns a `PathfinderMapper` that
takes a random subset of the cloud, then **nearest-neighbour orders** that subset into a coherent
meandering route. Route size is bounded by the `min_points`/`max_points` exports **on the
Pathfinder** — these are distinct from the `PoissonSettings.min_points`/`max_points` that bound
the *cloud*.

## Traversing a path

The Pathfinder uses its inherited `NavigationAgent2D` to route between waypoints (around
obstacles) and emits the per-frame velocity through the `steering` signal. It does **not** move
the body — wire `steering` to your locomotion and apply it yourself:

```gdscript
func _ready() -> void:
    pathfinder.steering.connect(locomotion.steer)
    pathfinder.begin()
```

Under the hood the route is **waypoints only**. The `PathfinderMapper` hands out points and
advances a cursor; the Pathfinder aims the navigation agent at the current waypoint and, once it
arrives, advances the cursor to the next one.

`path_type` controls what happens at the end of the route:

- `LOOP`: wrap back to the start.
- `PONG`: reverse direction and walk back towards the start.
- `RAND`: carve a fresh random route.
