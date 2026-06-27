extends Node
## Orchestrates short cutscenes: freezes the player, pans the camera to focus a
## point, holds, then restores the camera and resumes control.
##
## Decoupled via [SignalHub]: raises [signal SignalHub.actors_freeze_requested] and
## [signal SignalHub.cutscene_started] / [signal SignalHub.cutscene_ended]. Trigger a
## cutscene with [method play].

## Seconds spent panning the camera to and back from the focus point.
const PAN_TIME: float = 0.4

var _active: bool = false

#region Public API
## True while a cutscene is playing. Use to suppress overlapping triggers.
func is_active() -> bool:
	return _active

## Plays a cutscene focused on [param focus]: freezes the player, pans the camera to
## [param focus], holds for [param hold] seconds, then pans back and resumes control.
## Re-entrant calls while a cutscene is active are ignored.
func play(focus: Node2D, hold: float = 1.0) -> void:
	if _active:
		return
	assert(focus, "CutsceneManager.play: focus (Node2D) not set")
	_active = true
	SignalHub.cutscene_started.emit()
	SignalHub.actors_freeze_requested.emit(true)

	var cam: Camera2D = _player_camera()
	var origin: Vector2 = Vector2.ZERO
	if cam:
		origin = cam.global_position
		cam.set_physics_process(false) # stop the follow loop while we drive it
		await _pan(cam, focus.global_position)

	await get_tree().create_timer(hold).timeout

	if cam:
		await _pan(cam, origin)
		cam.set_physics_process(true)

	SignalHub.actors_freeze_requested.emit(false)
	SignalHub.cutscene_ended.emit()
	_active = false
#endregion

#region Private Helpers
func _pan(cam: Camera2D, to: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(cam, "global_position", to, PAN_TIME)
	await tween.finished

func _player_camera() -> Camera2D:
	var player: Player = get_tree().get_first_node_in_group("Player") as Player
	if player:
		return player.camera
	return null
#endregion
