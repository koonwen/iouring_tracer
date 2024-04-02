external bpf_uring_trace : (unit -> unit) -> unit = "caml_ml_bpf_uring_trace"

let write_ev : int -> unit = fun _i -> failwith "Not implemented"
[@@warning "-32"]

let spawn () =
  let t =
    Thread.create bpf_uring_trace (fun () ->
        Printf.printf "hello from callback")
  in
  Thread.join t
