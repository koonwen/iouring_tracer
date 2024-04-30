open Ctypes
include Defs.Bindings (Defs_generated)

type event
let struct_event : event structure typ = structure "event"
let ( -: ) ty label = field struct_event label ty
let pid = int -: "pid"
let tid = int -: "tid"
let probe = probe_t -: "probe"
let probe_id = int -: "probe_id"
let span = span_t -: "span"
let ktime_ns = uint64_t -: "ktime_ns"
let comm = array task_comm_len char -: "comm"
let _ = seal struct_event

let char_array_as_string a =
  let len = CArray.length a in
  let b = Buffer.create len in
  try
    for i = 0 to len -1 do
      let c = CArray.get a i in
      if c = '\x00' then raise Exit else Buffer.add_char b c
    done;
    Buffer.contents b
  with Exit -> Buffer.contents b
