(* Generator for bpftrace files *)

[@@@warning "-27"]
(*
All available function entry points

kfunc:vmlinux:io_uring_alloc_task_context
kfunc:vmlinux:io_uring_cancel_generic
kfunc:vmlinux:io_uring_clean_tctx
kfunc:vmlinux:io_uring_cmd
kfunc:vmlinux:io_uring_cmd_do_in_task_lazy
kfunc:vmlinux:io_uring_cmd_done
kfunc:vmlinux:io_uring_cmd_import_fixed
kfunc:vmlinux:io_uring_cmd_prep
kfunc:vmlinux:io_uring_cmd_prep_async
kfunc:vmlinux:io_uring_cmd_work
kfunc:vmlinux:io_uring_del_tctx_node
kfunc:vmlinux:io_uring_destruct_scm
kfunc:vmlinux:io_uring_drop_tctx_refs
kfunc:vmlinux:io_uring_get_opcode
kfunc:vmlinux:io_uring_get_socket
kfunc:vmlinux:io_uring_mmap
kfunc:vmlinux:io_uring_mmu_get_unmapped_area
kfunc:vmlinux:io_uring_poll
kfunc:vmlinux:io_uring_release
kfunc:vmlinux:io_uring_setup
kfunc:vmlinux:io_uring_show_fdinfo
kfunc:vmlinux:io_uring_try_cancel_requests
kfunc:vmlinux:io_uring_unreg_ringfd
rawtracepoint:io_uring_complete
rawtracepoint:io_uring_cqe_overflow
rawtracepoint:io_uring_cqring_wait
rawtracepoint:io_uring_create
rawtracepoint:io_uring_defer
rawtracepoint:io_uring_fail_link
rawtracepoint:io_uring_file_get
rawtracepoint:io_uring_link
rawtracepoint:io_uring_local_work_run
rawtracepoint:io_uring_poll_arm
rawtracepoint:io_uring_queue_async_work
rawtracepoint:io_uring_register
rawtracepoint:io_uring_req_failed
rawtracepoint:io_uring_short_write
rawtracepoint:io_uring_submit_req
rawtracepoint:io_uring_task_add
rawtracepoint:io_uring_task_work_run
*)

module Builtins : sig
  type t = string
  val time : t
  val printf: string -> t
end = struct
  type t = string
  let time = "time('[%H:%M:%S]: ')"
  let printf = Printf.sprintf "printf('%s')"
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

open Format

let pp_fun ~fun_name ~lines =
  let pp_line ppf = fprintf ppf "\t%s;" in
  asprintf "%s {@,%a@,}@." fun_name
    (pp_print_list ~pp_sep:pp_print_newline pp_line)
    lines

let pp_program ppf ~fun_list =
  let pp_sep ppf () = fprintf ppf "\n\n" in
  fprintf ppf "@[<v>%a@]@." (pp_print_list ~pp_sep pp_print_string) fun_list

let entry text =
  let lines =
    Builtins.[time; printf text] in
  pp_fun ~fun_name:"BEGIN" ~lines

let gen =
  Out_channel.with_open_bin "bpfgen.bt" (fun oc ->
      let ppf = formatter_of_out_channel oc in
      pp_program ppf ~fun_list:[ entry "Tracing IO_uring kprobes...\n" ])
