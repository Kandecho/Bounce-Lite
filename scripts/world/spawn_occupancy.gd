extends RefCounted
## Only visible core envelopes participate. Providers retain their own safety rules.
var _providers: Array[Dictionary] = []

func register(provider: Object, participates: bool = true) -> void:
	unregister(provider)
	_providers.append({"provider": weakref(provider), "participates": participates})

func unregister(provider: Object) -> void:
	for index in range(_providers.size()-1,-1,-1):
		var current = _providers[index].provider.get_ref()
		if current == null or current == provider: _providers.remove_at(index)

func is_clear(bounds: Rect2, requester: Object = null, snapshots: Dictionary = {}) -> bool:
	# Explicit opt-out is symmetric, but does not bypass a provider's boundary,
	# Ball/Paddle checks, same-family shape checks, or actual exit collider checks.
	for entry in _providers:
		if entry.provider.get_ref() == requester and not entry.participates: return true
	for index in range(_providers.size()-1,-1,-1):
		var entry: Dictionary = _providers[index]
		var provider = entry.provider.get_ref()
		if provider == null:
			_providers.remove_at(index)
			continue
		if provider == requester or not entry.participates: continue
		if not provider.has_method("entity_envelopes"): continue
		var envelopes: Array = provider.snapshot_envelopes(snapshots[provider]) if snapshots.has(provider) else provider.entity_envelopes()
		for envelope in envelopes:
			if bounds.intersects(envelope): return false
	return true

func snapshots_clear(snapshots: Dictionary) -> bool:
	for provider in snapshots:
		for envelope in provider.snapshot_envelopes(snapshots[provider]):
			if not is_clear(envelope,provider,snapshots): return false
	return true
