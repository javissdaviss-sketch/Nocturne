extends RefCounted
## Preserve all player shadow settings and the default Forward+ paths. Native
## Native paired comparisons identified these exact interior key lights as
## the source of scanline-like self-shadowing. Keep them as emitting fills
## only in Compatibility. Other lamps and the directional cast normally.
const PROVEN_GL_FILLS := ["0:-1:0","0:1:0","0:-1:360","0:1:360","1:-1:990","1:1:990"]

static func proved_role(room: Dictionary) -> bool:
 var start: float = room.lo
 if absf(start-roundf(start))>0.001: return false
 return "%d:%d:%d"%[room.car,room.side,roundi(start)] in PROVEN_GL_FILLS

static func allows(light: Light3D, enabled: bool, renderer: String) -> bool:
 return enabled and not (renderer=="gl_compatibility" and light.get_meta("gl_room_key_fill",false))
