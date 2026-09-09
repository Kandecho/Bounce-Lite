class_name VisualTokens
extends RefCounted

# Frozen visual_spec.md sections 8.3, 8.5 and 11.4; no theme switching.
const DARK_WINDOW := Color("242b37")
const DARK_PANEL := Color("171c26")
const DARK_PANEL_BORDER := Color("3a4350")
const TEXT_PRIMARY := Color("ffffff")
const TEXT_SECONDARY := Color("aaafbb")
const PADDLE_IDLE := Color("45786e")
const PADDLE_FLASH := Color("6fe0be")
const PADDLE_DISTURBANCE := Color("e6fff6")
const BALL_HUE := 189.0 / 360.0
const GLOW_RADIUS := 1.75
const TRAIL_INTERVAL := 0.085
const TRAIL_MAX_GHOSTS := 4
const TRAIL_MIN_SPACING := 18.0
const FEEDBACK_TAU := 0.055
static var _glow_texture: GradientTexture2D


static func core_color(vitality: float) -> Color:
	return Color.from_hsv(BALL_HUE, lerpf(0.42, 0.58, vitality), lerpf(0.42, 1.0, vitality))


static func glow_color(vitality: float) -> Color:
	return Color.from_hsv(BALL_HUE, lerpf(0.60, 0.95, vitality), lerpf(0.55, 1.0, vitality))


static func radial_texture() -> GradientTexture2D:
	if _glow_texture != null:
		return _glow_texture
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for index in range(129):
		var offset := float(index) / 128.0
		var radius := offset * GLOW_RADIUS
		var alpha := pow(1.0 - clampf((radius - 1.0) / 0.75, 0.0, 1.0), 1.6)
		offsets.append(offset)
		colors.append(Color(1, 1, 1, alpha))
	gradient.offsets = offsets
	gradient.colors = colors
	_glow_texture = GradientTexture2D.new()
	_glow_texture.gradient = gradient
	_glow_texture.width = 256
	_glow_texture.height = 256
	_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	_glow_texture.fill_from = Vector2(0.5, 0.5)
	_glow_texture.fill_to = Vector2(1.0, 0.5)
	return _glow_texture
