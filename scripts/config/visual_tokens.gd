class_name VisualTokens
extends RefCounted

# V0.2 UI trial: Scheme B "constant bright Core + dual-channel Glow"
# (artifact: Bounce Lite 活力视觉编码). Ball and Paddle share the 189° center hue.
# Trail (Velocity channel) keeps the frozen 1.75r profile and full-Vitality color.
# The whole client area is the world; its ground is the former panel color,
# so earlier contrast figures stay valid.
const WORLD_BACKGROUND := Color("171c26")
const TEXT_PRIMARY := Color("ffffff")
const TEXT_SECONDARY := Color("aaafbb")
const BALL_HUE := 189.0 / 360.0
# Paddle: a darker member of the Ball's center color; energy given to the Ball
# dims it toward PADDLE_DIM. The Paddle has no other visual layer.
const PADDLE_IDLE := Color("80a2a8")
const PADDLE_DIM := Color("36494c")
const GLOW_RADIUS := 1.75
const GLOW_ENVELOPE_MIN := 1.12
const GLOW_ENVELOPE_MAX := 1.95
const GLOW_ALPHA_MIN := 0.18
const GLOW_ALPHA_MAX := 0.80
const GLOW_TEXTURE_STEPS := 48
const TRAIL_INTERVAL := 0.085
const TRAIL_MAX_GHOSTS := 4
const TRAIL_MIN_SPACING := 18.0
const FEEDBACK_TAU := 0.055
static var _glow_texture: GradientTexture2D
static var _envelope_textures := {}


static func core_color(vitality: float) -> Color:
	var v := clampf(vitality, 0.0, 1.0)
	return Color.from_hsv(BALL_HUE, lerpf(0.22, 0.10, v), lerpf(0.82, 1.0, v))


static func glow_color(vitality: float) -> Color:
	return Color.from_hsv(BALL_HUE, lerpf(0.60, 0.95, vitality), lerpf(0.55, 1.0, vitality))


static func glow_alpha(vitality: float) -> float:
	return lerpf(GLOW_ALPHA_MIN, GLOW_ALPHA_MAX, clampf(vitality, 0.0, 1.0))


static func glow_envelope(vitality: float) -> float:
	return lerpf(GLOW_ENVELOPE_MIN, GLOW_ENVELOPE_MAX, clampf(vitality, 0.0, 1.0))


# Alpha profile outside the Core: peak at the circle edge, zero at the envelope.
static func glow_profile(radius: float, envelope: float) -> float:
	return pow(1.0 - clampf((radius - 1.0) / maxf(envelope - 1.0, 0.001), 0.0, 1.0), 1.6)


static func radial_texture() -> GradientTexture2D:
	if _glow_texture == null:
		_glow_texture = _build_texture(GLOW_RADIUS)
	return _glow_texture


static func glow_texture(envelope: float) -> GradientTexture2D:
	var t := clampf((envelope - GLOW_ENVELOPE_MIN) / (GLOW_ENVELOPE_MAX - GLOW_ENVELOPE_MIN), 0.0, 1.0)
	var key := roundi(t * GLOW_TEXTURE_STEPS)
	if not _envelope_textures.has(key):
		var quantized := lerpf(GLOW_ENVELOPE_MIN, GLOW_ENVELOPE_MAX, float(key) / GLOW_TEXTURE_STEPS)
		_envelope_textures[key] = _build_texture(quantized)
	return _envelope_textures[key]


static func _build_texture(envelope: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for index in range(129):
		var offset := float(index) / 128.0
		offsets.append(offset)
		colors.append(Color(1, 1, 1, glow_profile(offset * envelope, envelope)))
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture
