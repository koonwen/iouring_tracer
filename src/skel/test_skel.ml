open Bindings
open Ctypes

let handle_print : Skel_driver.handler =
 fun _ctx data _sz ->
  let event = !@(from_voidp Struct_event.t data) in
  let pid = getf event Struct_event.pid |> Int64.of_int in
  let tid = getf event Struct_event.tid |> Int64.of_int in
  let comm = getf event Struct_event.comm |> char_array_as_string in
  let ts = getf event Struct_event.ts |> Unsigned.UInt64.to_int64 in
  Printf.printf "[%Ld] %Ld:%Ld (%s)" ts pid tid comm;
  0

let () = Skel_driver.run [ handle_print ]
