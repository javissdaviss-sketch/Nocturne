extends RefCounted
## Original authored case. All records are replayable and never consumed.
const CLUES = {
 "cup": {"title":"The last cup", "place":"07 · Dining lounge", "kind":"PHYSICAL EVIDENCE", "text":"A violet crystalline ring clings to the inside of Elias Vale’s cup. The tea in the pot is clear. Someone treated this cup, not the whole table.", "detail":"Residue · violet crystals · single serving", "point":[-88,83,1250]},
 "chemical": {"title":"A bitter little bottle", "place":"07 · Service cabinet", "kind":"PHYSICAL EVIDENCE", "text":"A bottle of Vesper-9 pesticide. Violet crystals crust its neck, matching the cup. Its issue label reads: M. SABLE, HOSPITALITY. The bottle sits in the steward’s private service cabinet.", "detail":"VESPER-9 / issued to M. Sable", "point":[121,49,1460]},
 "ledger": {"title":"The hidden ledger", "place":"08 · Dispatch compartment", "kind":"PHYSICAL EVIDENCE", "text":"Payments for protected orchid cuttings. Every shipment is signed M. Sable. The final entry says: ‘Vale has noticed. Close the account before the next station.’", "detail":"Unauthorized sales · M. Sable · final entry", "point":[-100,80,2235]},
 "note": {"title":"A promise to report", "place":"06 · Vale’s writing desk", "kind":"PHYSICAL EVIDENCE", "text":"‘Mara — I know what leaves this train in your service crates. Return the cuttings, or I bring your ledger to the inspector at dawn. — Elias.’ A note written before his death.", "detail":"An ultimatum addressed to Mara", "point":[-102,77,285]},
 "label": {"title":"The torn shipment label", "place":"08 · Potting bench", "kind":"PHYSICAL EVIDENCE", "text":"A torn label reads ‘LIVING SPECIMENS · hospitality dispatch · M. Sable’. Its serial number, OR-031, matches a missing protected orchid. The same leaf/moon/drop symbols mark the dispatch lock.", "detail":"OR-031 · sequence: LEAF → MOON → DROP", "point":[102,80,1905]},
 "log": {"title":"An inconvenient alibi", "place":"06 · Maintenance terminal", "kind":"PHYSICAL EVIDENCE", "text":"The sealed maintenance log places engineer Ivo Chen at the rear axle from 22:10 to 22:36. Vale’s tea was served at 22:24. The blackout was a scheduled test, not an escape.", "detail":"22:10–22:36 · rear axle · authenticated", "point":[102,89,655]}
}
const TALKS = {
 "steward": {"title":"Mara Sable · the steward", "place":"07 · Dining lounge", "kind":"OVERHEARD", "text":"MARA: ‘Mr Vale insisted on his own cup. I prepared it myself, at twenty-four past ten.’\nATTENDANT: ‘And the conservatory crates?’\nMARA: ‘Hospitality business. Leave them alone.’", "detail":"Served the cup · controls hospitality dispatch", "point":[95,112,1150]},
 "botanist": {"title":"Dr Lian Moss · the botanist", "place":"08 · Conservatory", "kind":"OVERHEARD", "text":"LIAN: ‘Yes, we argued. Elias wanted the orchids returned to the wild. I wanted to keep them alive here. Then we found cuttings missing. He promised he would find who was selling them.’", "detail":"An argument over conservation, not the sales", "point":[90,110,2110]},
 "engineer": {"title":"Ivo Chen · the engineer", "place":"06 · Residential carriage", "kind":"OVERHEARD", "text":"IVO: ‘Everyone blames the blackout. I was under the rear axle for half an hour. My terminal signed every check. Ask Mara why she needed her cabinet locked during dinner.’", "detail":"Check the maintenance terminal nearby", "point":[90,108,530]}
}
const PROPS = {
 "body": {"title":"A quiet table", "place":"07 · Dining lounge", "kind":"OBSERVATION", "text":"Elias Vale lies beneath a linen cover. A cup stands beside him. No overturned furniture, no sign of a struggle. The other residents keep their voices low.", "point":[-85,70,1350]},
 "pastry": {"title":"A feast, at your scale", "place":"07 · Dining lounge", "kind":"OBSERVATION", "text":"A croissant towers above you like a golden hillside. Butter, sugar, and the faint scent of cardamom. Even on a night like this, the dining car smells like home.", "point":[-95,78,1050]},
 "photo": {"title":"A home that moves", "place":"06 · Residential carriage", "kind":"OBSERVATION", "text":"An old photograph: the twelve-carriage train beside a tropical coast. A handwritten caption reads ‘Our first monsoon aboard the Nocturne.’ Plants crowd the windows even then.", "point":[-102,77,470]},
 "orchid": {"title":"The ghost orchid", "place":"08 · Conservatory", "kind":"OBSERVATION", "text":"Translucent petals, each larger than your wings. The botanical tag says PROTECTED. Three stems have fresh cuts. A strange absence in a room so full of life.", "point":[-100,82,2020]},
 "latch": {"title":"The service release", "place":"07 · Inside the cable duct", "kind":"PUZZLE", "text":"A thin power cable disappears through a tiny opening below the cabinet. At its end is a feather-light emergency contact. Land beside it and bridge the contact to release the service door.", "point":[104,11,1460]},
 "dispatch": {"title":"The dispatch lock", "place":"08 · Conservatory", "kind":"PUZZLE", "text":"Three botanical symbols secure the dispatch drawer. The torn shipment label on the potting bench should give their order.", "point":[-100,83,2220]}
}
const ESSENTIAL = ["cup", "chemical", "ledger", "note", "label", "log"]
static func record(id: String) -> Dictionary:
 if CLUES.has(id): return CLUES[id]
 if TALKS.has(id): return TALKS[id]
 return PROPS.get(id, {})
static func solved(suspect: int, motive: int, evidence: Array) -> bool:
 return suspect == 0 and motive == 0 and evidence.has("cup") and evidence.has("chemical") and evidence.has("ledger") and evidence.has("note")
