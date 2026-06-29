class_name AudioHandle
extends RefCounted
## A safe reference to a sound playing on a pooled audio player.
##
## [AudioPool.play] returns one of these instead of the raw player [Node]. Pooled
## players are recycled between sounds, so a stored player reference can silently
## end up controlling a different sound. A handle captures the player plus a
## generation token taken at play time, so [method is_valid] reports
## [code]false[/code] once the player has been reclaimed or reused, even if the
## [Node] still exists.
##
## On failure [AudioPool.play] returns an already-invalid handle (never
## [code]null[/code]), so callers can query it without null checks.

#region Private Members
var _player: Node                # the AudioStreamPlayer-family node
var _token: int                  # generation captured when the player was acquired
var _stream: AudioPoolStream     # the stream this handle started
#endregion

#region Public Members
## The [AudioPoolStream] this handle started, or [code]null[/code] once invalid.
var stream: AudioPoolStream:
	get: return _stream if is_valid() else null
#endregion


#region Public API
## Builds a handle for [param player] acquired at [param token] playing
## [param stream]. Used by [AudioPool]; prefer [AudioPool.play] elsewhere.
static func create(player: Node, token: int, stream: AudioPoolStream) -> AudioHandle:
	var handle: AudioHandle = AudioHandle.new()
	handle._player = player
	handle._token = token
	handle._stream = stream
	return handle


## [code]true[/code] while this handle still controls its original sound. Becomes
## [code]false[/code] once the player finishes, is stopped, or is reused.
func is_valid() -> bool:
	return AudioPool.is_active(_player, _token)


## [code]true[/code] if the sound is valid and currently audible.
func is_playing() -> bool:
	return AudioPool.is_playing(_player, _token)


## Repositions a positional sound while it plays. No-op for global sounds or once
## invalid. [param at] is a [Vector2] (2D) or [Vector3] (3D).
func move_to(at: Variant) -> void:
	if is_valid():
		AudioPool.move(_player, at)


## Stops the sound and returns its player to the pool. No-op once invalid, so a
## stale handle can never stop a player that was recycled for another sound.
func stop() -> void:
	if is_valid():
		AudioPool.stop(_player)
#endregion
