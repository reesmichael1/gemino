open Base
open Eio.Std

let addr = `Unix "/run/user/1000/gemmo.sock"

let handle_client res flow addr =
  traceln "Accepted connection at %a" Eio.Net.Sockaddr.pp addr;
  let from_client = Eio.Buf_read.of_flow ~max_size:100 flow in
  let line = Eio.Buf_read.line from_client in
  traceln "Received: %S" line;
  let json = Yojson.Safe.from_string line in
  let msg = Gemmo.Types.of_yojson json in
  match msg.msg with
  | Gemmo.Types.Msg.Duplicate s -> Eio.Flow.copy_string (s ^ " " ^ s) flow
  | Close ->
      Eio.Flow.copy_string "goodbye!" flow;
      Eio.Promise.resolve res ()

let server_run sock =
  let stop, resolver = Eio.Promise.create ~label:"server_stop" () in
  Eio.Net.run_server sock (handle_client resolver) ~stop
    ~on_error:(traceln "Error handling connection: %a" Fmt.exn)

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let sock = Eio.Net.listen ~sw ~backlog:5 (Eio.Stdenv.net env) addr in
  server_run sock
