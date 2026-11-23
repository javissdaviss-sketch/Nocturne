extends RefCounted
## Player-observed case details only. No expected pairs or grading.
const MACROS := {
 "cup": {
  "focus":Vector3(-89.90,82.74,1246.45),
  "eyes":[Vector3(-86,89,1252),Vector3(-86.5,90.5,1250),Vector3(-88,91,1251)],
  "label":"Inner rim","description":"Violet angular flakes cling just above the liquid."
 },
 "chemical": {
  "focus":Vector3(121,49.53,1458.17),
  "eyes":[Vector3(119,53.5,1451),Vector3(120,54.5,1448.8),Vector3(121,53,1450)],
  "label":"Bottle neck","description":"A flat violet shard with smaller chips sits below the cap. The issue stamp reads SABLE."
 }
}

const ORDER := ["cup","chemical","note","ledger","label","log"]
const FIELD := {
 "cup":{"feature":"Inner rim","words":"Angular violet flakes cling just above the liquid.","graphic":"fragments"},
 "chemical":{"feature":"Bottle neck and issue stamp","words":"Flat violet shard with smaller chips. The stamp reads SABLE.","graphic":"fragments"},
 "note":{"feature":"Handwritten lines","words":"“Mara” · “Return the cuttings” · signed Elias.","graphic":"inscription"},
 "ledger":{"feature":"Ledger entry","words":"M. Sable · “Vale has noticed.”","graphic":"inscription"},
 "label":{"feature":"Shipment marking","words":"“LIVING SPECIMENS” · OR-031.","graphic":"inscription"},
 "log":{"feature":"Authenticated terminal entry","words":"AXLE 12 · I. CHEN · 22:10–22:36.","graphic":"inscription"}
}
