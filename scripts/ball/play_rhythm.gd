extends RefCounted

# Input facts grant one opportunity; this object never owns a moving body.
var qualification_seconds := 12.0
var input_age := 1000.0
var pause_elapsed := 0.0
var continuation_available := false

func note_input(distance: float) -> void:
	if distance < 1.0:
		return
	input_age = 0.0
	continuation_available = true

func consume() -> void:
	continuation_available = false
	pause_elapsed = 0.0

func advance(delta: float, physically_settled: bool) -> bool:
	input_age += maxf(delta, 0.0)
	if input_age > qualification_seconds:
		continuation_available = false
	if not physically_settled:
		pause_elapsed = 0.0
		return false
	pause_elapsed += maxf(delta, 0.0)
	if not continuation_available or input_age > qualification_seconds or pause_elapsed < 0.9:
		return false
	continuation_available = false
	pause_elapsed = 0.0
	return true
