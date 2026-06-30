# Pathfinder Component

The pathfinder component can be given to a CharacterBody2D and allows that body to uses a 
NavigationRegion2D to allow the character body to path around the game world.

This component is a tool script and looks for the required navigation nodes and emits a warning
in the editor similar to Area2D's with out a collision shape. Since we do not care if it is a 
Path2D or a NavigationRegion2D we simply look for a node called `PathfinderRegion` this repersents the area
a path is created from.


```
CharacterBody2D
 | --- NavigationAgent2D (if using NavigationRegion2D)
 | --- PathfinderComponent
          | --- PathfinderRegion
```

## API

- `create_path(int)`: Carves an ordered route of up to `int` waypoints from the region's cloud,
  stores it, and resets the cursor to the start. Returns the `PathfinderSet`.
- `next_point()`: Advances the cursor one waypoint (per `path_type`) and returns the new current
  point. **Mutating.**
- `previous_point()`: Steps the cursor back one waypoint and returns the new current point.
  **Mutating.**
- `current_point()`: Returns the waypoint the cursor currently points at, without moving it.
  **Non-mutating.**
- `clear_path()`: Removes all points from the path and resets the cursor.

Empty-route calls and out-of-bounds peeks return `PathfinderSet.INVALID_POINT` (`(INF, INF)`).


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

The sampling itself lives in `utils/poisson_disk_sampler.gd` (`PoissonDiskSampler`) — a
project-agnostic `RefCounted` that runs Bridson's algorithm over a `Rect2`, optionally clipped
by a `func(p: Vector2) -> bool` predicate. The region just supplies the navigable bounds, its
`_is_navigable` predicate, and converts the result to world space; the sampler can be reused
anywhere points are needed.

The cloud is intentionally larger than a route. `PathfinderBase.create_path()` takes a random
subset of it, then **nearest-neighbour orders** that subset into a coherent meandering route.
Route size is bounded by the `min_points`/`max_points` exports **on the PathfinderBase** — these
are distinct from the `PoissonSettings.min_points`/`max_points` that bound the *cloud*.

## Traversing a path

The route is **waypoints only**. `PathfinderBase` does not move the body and does not query
navigation — it just hands out points and advances a cursor. How the body travels *between* two
waypoints (routing around obstacles) is the consumer's job, handled by a `NavigationAgent2D` on
the target. The agent takes **one** `target_position` at a time, so the loop is:

```gdscript
agent.target_position = pathfinder.current_point()
# each physics frame:
if agent.is_navigation_finished():
    pathfinder.next_point()                  # advances the cursor per path_type
    agent.target_position = pathfinder.current_point()
else:
    steer_body_toward(agent.get_next_path_position())
```

`path_type` controls what `next_point()` does at the end of the route:

- `LOOP`: wrap back to the start.
- `PONG`: reverse direction and walk back towards the start.
- `RAND`: carve a fresh random route.
