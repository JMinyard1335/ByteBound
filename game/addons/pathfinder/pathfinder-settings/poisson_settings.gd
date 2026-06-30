class_name PoissonSettings extends Resource
## Tunable configuration for a [PathfinderRegion]'s point distribution.
##
## Pure data driving Bridson Poisson-disk sampling. Save presets as [code].tres[/code]
## (e.g. [code]defaultDistribution.tres[/code]) and assign one per region instance.

@export_category("Spacing")
## Minimum distance (px) between any two generated points — the Poisson radius.
@export var min_distance: float = 48.0
## Candidate samples tried around each active point before it is retired (Bridson k).
@export_range(8, 64, 1) var attempts: int = 30

@export_category("Cloud Size")
## Floor on generated points; a warning is pushed if spacing/region can't reach it.
@export var min_points: int = 24
## Hard ceiling; sampling stops once this many points exist (guards huge regions).
@export var max_points: int = 256

@export_category("Determinism")
## RNG seed. [code]-1[/code] randomizes each call; otherwise clouds are reproducible.
@export var seed: int = -1
