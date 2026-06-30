@tool
class_name PatrolPathAction
extends EnemyBTAction
## Patrols the enemy by driving its [Pathfinder].
##
## Starts the enemy's [Pathfinder] on entry and stops it on exit. The Pathfinder self-steers each
## frame (through its steering signal, wired to the locomotion by [Enemy]), so this action only
## has to keep it running — the same action drives both walking and flying enemies.

func before_run(actor: Node, _blackboard: Blackboard) -> void:
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return
	enemy.pather.begin()

func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return FAILURE
	if not enemy.pather.is_running():
		return FAILURE
	return RUNNING

func interrupt(actor: Node, blackboard: Blackboard) -> void:
	super(actor, blackboard)
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return
	enemy.pather.stop()

func after_run(actor: Node, _blackboard: Blackboard) -> void:
	var enemy: Enemy = get_enemy(actor)
	if enemy == null:
		return
	enemy.pather.stop()
