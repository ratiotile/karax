# Need to split off from karax.nim for static compile
type
  RouterData* = ref object ## information that is passed to the 'renderer' callback
    hashPart*: cstring     ## the hash part of the URL for routing.