@tool
class_name SentryDrone
extends Enemy
## A floating sentry that flies straight along its patrol path.
##
## Carries a [FlyComponent] instead of walk/gravity movers, so its [LocomotionComponent] applies
## the full 2D velocity its [Pathfinder] steers with — moving freely toward each waypoint instead
## of walking under gravity.
