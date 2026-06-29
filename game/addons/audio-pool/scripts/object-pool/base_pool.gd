@abstract
class_name BaseAudioPool
extends IAudioPool
## Shared pooling for [IAudioPool].
##
## Reuses player nodes between sounds: a player is configured from an
## [AudioPoolStream], played, and reclaimed when it finishes (one-shots) or is
## stopped (looping). Concrete pools supply the player type ([method _create_player])
## and how to position it ([method _apply_position]).

## Max players the pool will create before dropping requests.
const MAX_NODES: int = 512

var _container: Node          # the node the players live under in the tree
var _free: Array[Node] = []   # idle players ready to reuse
var _active: Array[Node] = [] # players currently playing
var _tokens: Dictionary[Node, int] = {} # generation per active player
var _next_token: int = 1      # next generation to hand out

## Wires the pool to the [param container] node its players are parented under.
func init(container: Node) -> void:
	_container = container

func play(stream: AudioPoolStream, at: Variant = null) -> Node:
	var player := _acquire()
	if player == null:
		push_warning("AudioPool at capacity (%d); dropped '%s'" % [MAX_NODES, stream.stream_name])
		return null
	_tokens[player] = _next_token
	_next_token += 1
	player.stream = stream.stream
	_apply_loop(stream.stream, not stream.one_shot)
	player.bus = stream.audio_bus
	player.volume_db = stream.volume_db()
	player.pitch_scale = stream.pitch_scale
	_apply_position(player, at)
	_apply_attenuation(player, stream)
	_active.append(player)
	player.play()
	return player

func stop(player: Node) -> void:
	if player == null or not _active.has(player):
		return
	player.stop()
	_release(player)

func clear() -> void:
	for p in _active + _free:
		_stop_player(p)
		p.free()
	_active.clear()
	_free.clear()
	_tokens.clear()
	return


## The generation token of [param player], or 0 if it is not currently active.
func token_of(player: Node) -> int:
	return _tokens.get(player, 0)


## Repositions an active [param player] using the concrete pool's placement.
func move(player: Node, at: Variant) -> void:
	if _active.has(player):
		_apply_position(player, at)

func _acquire() -> Node:
	if not _free.is_empty():
		return _free.pop_back()
	if _active.size() + _free.size() >= MAX_NODES:
		return null
	var player := _create_player()
	player.finished.connect(_on_finished.bind(player))  # one-shots reclaim themselves
	_container.add_child(player)
	return player

func _release(player: Node) -> void:
	if not _active.has(player):
		return
	_active.erase(player)
	_tokens.erase(player)  # invalidate any outstanding handle for this player
	_free.append(player)

func _on_finished(player: Node) -> void:
	_release(player)
	return

# Honors AudioPoolStream.one_shot by setting loop on the stream resource. A looping
# stream never emits `finished`, so it stays active until an explicit stop().
func _apply_loop(audio: AudioStream, should_loop: bool) -> void:
	if audio is AudioStreamWAV:
		var wav: AudioStreamWAV = audio as AudioStreamWAV
		if not should_loop:
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
			return
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		# A WAV not imported as looping has loop_end == 0, which loops nothing.
		# Fall back to the whole sample so one_shot = false actually loops.
		if wav.loop_end <= wav.loop_begin:
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif audio is AudioStreamOggVorbis:
		(audio as AudioStreamOggVorbis).loop = should_loop
	elif audio is AudioStreamMP3:
		(audio as AudioStreamMP3).loop = should_loop


func _stop_player(player: Node) -> void:
	if player is AudioStreamPlayer:
		(player as AudioStreamPlayer).stop()
		return
	if player is AudioStreamPlayer2D:
		(player as AudioStreamPlayer2D).stop()
		return
	if player is AudioStreamPlayer3D:
		(player as AudioStreamPlayer3D).stop()
	return

@abstract func _create_player() -> Node
@abstract func _apply_position(player: Node, at: Variant) -> void

# Applies positional falloff (e.g. max_distance) from the stream. No-op by default
# so non-positional (global) pools ignore it; positional pools override.
func _apply_attenuation(_player: Node, _stream: AudioPoolStream) -> void:
	pass
