extends RefCounted
## Pure ambience blend for eavesdropping; never edits user volume preferences.
const FADE_SECONDS := 0.20
const TRAIN_GAIN_DURING_LISTEN := 0.62
const WING_GAIN_DURING_LISTEN := 0.36
var blend := 0.0

func step(listening: bool, delta: float) -> void:
 blend = move_toward(blend,1.0 if listening else 0.0,maxf(0.0,delta)/FADE_SECONDS)

func gains(train_volume: float, wing_volume: float, wing_context: float) -> Vector2:
 var eased := smoothstep(0.0,1.0,blend)
 return Vector2(
  train_volume*lerpf(1.0,TRAIN_GAIN_DURING_LISTEN,eased),
  wing_volume*wing_context*lerpf(1.0,WING_GAIN_DURING_LISTEN,eased)
 )
