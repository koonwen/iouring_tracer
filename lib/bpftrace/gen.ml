(* Generator for bpftrace files *)

module Builtins : sig
  type t = string

  val time : t
  val printf : string -> string list -> t
end = struct
  type t = string

  let time = "time(\"[%H:%M:%S]\")"

  let printf fmt args =
    let open Format in
    match args with
    | [] -> sprintf "printf(\"%s\")" fmt
    | l ->
        let args = String.concat ", " l in
        sprintf "printf(\"%s\", %s)" fmt args
end

open Format

let pp_fun ~name ~lines =
  let pp_line ppf = fprintf ppf "\t%s;" in
  asprintf "%s {@,%a@,}@." name
    (pp_print_list ~pp_sep:pp_print_newline pp_line)
    lines

let pp_program ppf ~fun_list =
  let pp_sep ppf () = fprintf ppf "\n\n" in
  fprintf ppf "@[<v>%a@]@." (pp_print_list ~pp_sep pp_print_string) fun_list

let entry text =
  let lines = Builtins.[ time; printf text [] ] in
  pp_fun ~name:"BEGIN" ~lines

[@@@warning "-39"]

module Intermediate = struct
  type types =
    | Void
    | Bool
    | Char
    | Unsigned of ints
    | Signed of ints
    | Struct of string * args
    | Ptr of types
    | Array of types

  and ints = Int | Int8 | Int16 | Int32 | Int64 | Long | LongLong | Size_t
  [@@deriving show { with_path = false }]

  and args = (types * string) list

  type spec = { probe : string; domain : string; name : string; args : args }
  type t = spec list

  let rec fmt_spec type' =
    let fmt_int_spec = function
      | Signed Int | Signed Int8 | Signed Int16 -> "%d"
      | Unsigned Int | Unsigned Int8 | Unsigned Int16 -> "%u"
      | Signed Int32 | Signed Int64 | Signed Long | Signed Size_t -> "%ld"
      | Unsigned Int32 | Unsigned Int64 | Unsigned Long | Unsigned Size_t ->
          "%lu"
      | Signed LongLong -> "%lld"
      | Unsigned LongLong -> "%llu"
      | _ -> failwith "Not passed an int type"
    in
    match type' with
    | Bool -> "%b"
    | Char -> "%c"
    | (Unsigned _ | Signed _) as t -> fmt_int_spec t
    | Struct (_, _) -> failwith "Not implemented"
    | Void | Ptr _ | Array _ -> "0x%llx"

  let transpile_function { probe; domain; name; args } =
    let fullname = sprintf "%s:%s:%s" probe domain name in
    let fmt_types =
      List.map (fun (ty, _) -> fmt_spec ty) args |> String.concat ", "
    in
    let fmt = fmt_types ^ "\\n" in
    let arg_names = List.map (fun (_, name) -> sprintf "args->%s" name) args in
    pp_fun ~name:fullname ~lines:Builtins.[ time; printf fmt arg_names ]

  let handleable imd =
    let can_handle spec =
      let handleable_args =
        List.filter
          (fun (t, _) -> match t with Struct _ -> false | _ -> true)
          spec.args
      in
      { spec with args = handleable_args }
    in
    List.map can_handle imd

  let transpile_program (imd : t) =
    let handleable = handleable imd in
    List.map transpile_function handleable

  let write_program (imd : t) oc =
    let ppf = Format.formatter_of_out_channel oc in
    let handleable = handleable imd in
    List.iter
      (fun i -> Format.fprintf ppf "%s\n" (transpile_function i))
      handleable
end

module Kprobes = struct
  (* kprobe:io_uring_alloc_task_context
     kprobe:io_uring_cancel_generic
     kprobe:io_uring_clean_tctx
     kprobe:io_uring_cmd
     kprobe:io_uring_cmd_do_in_task_lazy
     kprobe:io_uring_cmd_done
     kprobe:io_uring_cmd_import_fixed
     kprobe:io_uring_cmd_prep
     kprobe:io_uring_cmd_prep_async
     kprobe:io_uring_cmd_work
     kprobe:io_uring_del_tctx_node
     kprobe:io_uring_destruct_scm
     kprobe:io_uring_drop_tctx_refs
     kprobe:io_uring_get_opcode
     kprobe:io_uring_get_socket
     kprobe:io_uring_mmap
     kprobe:io_uring_mmu_get_unmapped_area
     kprobe:io_uring_poll
     kprobe:io_uring_release
     kprobe:io_uring_setup
     kprobe:io_uring_show_fdinfo
     kprobe:io_uring_try_cancel_requests
     kprobe:io_uring_unreg_ringfd
     kprobe:io_uring_validate_mmap_request.isra.
  *)
  (* let io_uring_setup f = Builtins.(f printf) *)
end

module Tracepoints = struct
  (* tracepoint:io_uring:io_uring_complete
     tracepoint:io_uring:io_uring_cqe_overflow
     tracepoint:io_uring:io_uring_cqring_wait
     tracepoint:io_uring:io_uring_create
     tracepoint:io_uring:io_uring_defer
     tracepoint:io_uring:io_uring_fail_link
     tracepoint:io_uring:io_uring_file_get
     tracepoint:io_uring:io_uring_link
     tracepoint:io_uring:io_uring_local_work_run
     tracepoint:io_uring:io_uring_poll_arm
     tracepoint:io_uring:io_uring_queue_async_work
     tracepoint:io_uring:io_uring_register
     tracepoint:io_uring:io_uring_req_failed
     tracepoint:io_uring:io_uring_short_write
     tracepoint:io_uring:io_uring_submit_req
     tracepoint:io_uring:io_uring_task_add
     tracepoint:io_uring:io_uring_task_work_run
  *)
end

module Syscalls = struct
  let prefix = "tracepoint:syscalls:"
  (* let sys_enter_io_uring_enter nr fd to_submit min_complete flags argp argsz *)
  (*
tracepoint:syscalls:sys_enter_io_uring_enter
     int __syscall_nr
     unsigned int fd
     u32 to_submit
     u32 min_complete
     u32 flags
     const void * argp
     size_t argsz

tracepoint:syscalls:sys_enter_io_uring_register
     int __syscall_nr
     unsigned int fd
     unsigned int opcode
     void * arg
     unsigned int nr_args

tracepoint:syscalls:sys_enter_io_uring_setup
     int __syscall_nr
     u32 entries
     struct io_uring_params * params

tracepoint:syscalls:sys_exit_io_uring_enter
     int __syscall_nr
     long ret

tracepoint:syscalls:sys_exit_io_uring_register
     int __syscall_nr
     long ret

tracepoint:syscalls:sys_exit_io_uring_setup
     int __syscall_nr
     long ret
*)

  let fun_name f_name =
    let rec aux = function
      | [] -> failwith "Bad name"
      | [ name ] -> name
      | _h :: t -> aux t
    in
    aux (String.split_on_char '.' f_name)

  let sys_exit_io_uring_enter lines =
    let name = prefix ^ fun_name __FUNCTION__ in
    pp_fun ~name ~lines
end

let gen imd =
  Out_channel.with_open_bin "bpfgen.bt" (fun oc ->
      let ppf = formatter_of_out_channel oc in
      let fun_list =
        entry "Tracing IO_uring ..." :: Intermediate.transpile_program imd
      in
      pp_program ppf ~fun_list)
