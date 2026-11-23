extends RefCounted
## Original authored case. All records are replayable and never consumed.
const CRATE_ORIGIN := Vector3(-133,0.3,2421)
const CRATE_TAG_OFFSET := Vector3(-4.5,10.1,11)
const CRATE_TAG_POINT := CRATE_ORIGIN+CRATE_TAG_OFFSET
const NURSERY_SENSOR_POINT := Vector3(377,49,2075.8)
const NIGHT_RELAY_POINT := Vector3(108.5,84.45,292.5)
const CLUES = {
 "cup": {"title":"The last cup", "place":"07 · Dining lounge", "kind":"PHYSICAL EVIDENCE", "text":"A violet crystalline ring clings to the inside of Elias Vale’s cup. The tea in the pot is clear. Someone treated this cup, not the whole table.", "detail":"Residue · violet crystals · single serving", "point":[-88,83,1250]},
 "chemical": {"title":"A bitter little bottle", "place":"07 · Service cabinet", "kind":"PHYSICAL EVIDENCE", "text":"A bottle of Vesper-9 pesticide. Violet crystals crust its neck, the same colour as the residue in the cup. Its issue label reads: M. SABLE, HOSPITALITY. The bottle sits in the steward’s private service cabinet.", "detail":"VESPER-9 / issued to M. Sable", "point":[121,49,1460]},
 "ledger": {"title":"The hidden ledger", "place":"08 · Dispatch compartment", "kind":"PHYSICAL EVIDENCE", "text":"Payments for protected orchid cuttings. Every shipment is signed M. Sable. The final entry says: ‘Vale has noticed. Close the account before the next station.’", "detail":"Unauthorized sales · M. Sable · final entry", "point":[-100,80,2235]},
 "note": {"title":"A promise to report", "place":"06 · Vale’s writing desk", "kind":"PHYSICAL EVIDENCE", "text":"‘Mara — I know what leaves this train in your service crates. Return the cuttings, or I bring your ledger to the inspector at dawn. — Elias.’ A note written before his death.", "detail":"An ultimatum addressed to Mara", "point":[-102,77,285]},
 "label": {"title":"The torn shipment label", "place":"08 · Potting bench", "kind":"PHYSICAL EVIDENCE", "text":"A torn label reads ‘LIVING SPECIMENS · hospitality dispatch · M. Sable’. Its serial number, OR-031, matches a missing protected orchid. The same leaf/moon/drop symbols mark the dispatch lock.", "detail":"OR-031 · sequence: LEAF → MOON → DROP", "point":[102,80,1905]},
 "log": {"title":"The maintenance timeline", "place":"06 · Maintenance terminal", "kind":"PHYSICAL EVIDENCE", "text":"The maintenance terminal has rear-axle checks signed by engineer Ivo Chen from 22:10 to 22:36. Vale’s tea was served at 22:24. The blackout was a scheduled test, not an escape.", "detail":"22:10–22:36 · rear axle · authenticated", "point":[102,89,655]}
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
 "nursery_sensor": {"title":"Night propagation check","place":"08 · Live Reserve","kind":"SERVICE PANEL","text":"TEMP 21°C, STEADY · RESERVOIR FULL · AIRFLOW 0. The nursery lamps stay off until the circulation check passes. The service relay is in Crew Berth (06).","point":[NURSERY_SENSOR_POINT.x,NURSERY_SENSOR_POINT.y,NURSERY_SENSOR_POINT.z]},
 "night_relay": {"title":"Night service relay","place":"06 · Crew Berth","kind":"SERVICE RADIO","text":"The Nocturne’s old service relay still works. Select a circuit, then send one test pulse.","point":[NIGHT_RELAY_POINT.x,NIGHT_RELAY_POINT.y,NIGHT_RELAY_POINT.z]},
 "crate_tag": {"title":"On the back of a seed tag", "place":"08 · Inside the seed crate", "kind":"OBSERVATION", "text":"A paper tag is turned inward so it won’t catch on the trolley. On the back: ‘Turn the trays when you get in. The little ones lean toward the light. — L.’ Even tonight, someone remembers the plants.", "detail":"A small routine aboard the Nocturne", "point":[CRATE_TAG_POINT.x,CRATE_TAG_POINT.y,CRATE_TAG_POINT.z]},
 "latch": {"title":"The service release", "place":"07 · Inside the cable duct", "kind":"PUZZLE", "text":"A thin power cable disappears through a tiny opening below the cabinet. At its end is a feather-light emergency contact. Follow the cable into the gap. Hover close, then bridge the contact to release the service door.", "point":[104,11,1460]},
 "dispatch": {"title":"The dispatch lock", "place":"08 · Conservatory", "kind":"PUZZLE", "text":"Three botanical symbols secure the dispatch drawer. The torn shipment label on the potting bench should give their order.", "point":[-100,83,2220]}
}
const RAIN_POSTS = {
 "rain_06": {"title":"A question from Nell","place":"06 · Corridor beside the sleeper suite","kind":"THE RAIN POST","text":"I was born on this train. Mum says the first rain off the sea sounds different. How do you tell? Please leave your answer where I can reach it. Nell, 06.","detail":"Written in a careful school hand.","point":[-50.85,105,280]},
 "rain_07": {"title":"Rosa’s reply","place":"07 · Corridor by the service end","kind":"THE RAIN POST","text":"Like a handful of rice going into a tin. Listen outside the winter garden after the tea trolley stops. You don’t have to go in. Rosa, 07.","detail":"The back of a tea-service card.","point":[50.85,105,1415]},
 "rain_08": {"title":"The answer, at the glass","place":"08 · Corridor beyond the seed archive door","kind":"THE RAIN POST","text":"I heard it. Not like the rain by my bed at all. I stayed for the next shower so I’d remember. Nell, 06.","detail":"The fold is softened where it’s been opened.","point":[-50.85,105,2310]}
}
const JOURNAL_ONLY = {
 "nursery_restored": {"title":"A light left on","place":"08 · Live Reserve","kind":"OBSERVATION","text":"The Nocturne’s residents keep tiny promises to people they may never meet.","detail":"Temperature steady. Reservoir full. Air moving."},
 "seed_return_ready": {"title":"One seed for the shore","place":"08 · Seed archive","kind":"OBSERVATION","text":"One tide iris seed is ready for the marsh nursery by the old ferry stop. The tray is marked for the next shore delivery.","detail":"Tide iris · return cradle ready"}
}
const ESSENTIAL = ["cup", "chemical", "ledger", "note", "label", "log"]
static func record(id: String) -> Dictionary:
 if CLUES.has(id): return CLUES[id]
 if TALKS.has(id): return TALKS[id]
 if PROPS.has(id): return PROPS[id]
 if RAIN_POSTS.has(id): return RAIN_POSTS[id]
 return JOURNAL_ONLY.get(id,{})
static func solved(suspect: int, motive: int, evidence: Array) -> bool:
 return suspect == 0 and motive == 0 and evidence.has("cup") and evidence.has("chemical") and evidence.has("ledger") and evidence.has("note")
