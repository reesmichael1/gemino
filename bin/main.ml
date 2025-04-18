open Base
open Cmdliner
open Eio.Std

let addr = `Unix "/run/user/1000/gemmo.sock"

let get_contents_and_serialize uri =
  let open Or_error.Let_syntax in
  let%bind contents = Gemmo.Net.load_uri uri in
  let%bind response = Gemmo.Gemini.of_reply contents in
  match response with
  | Gemmo.Gemini.Success r -> (
      match (r.mimetype.ty, r.mimetype.subty) with
      | `Text, `Ietf_token "gemini" ->
          let%bind lines = Gemmo.Gemtext.of_string r.body in
          let response = Gemmo.Ipc.Serialize.gemtext_lines lines in
          Ok response
      | _ -> Or_error.error_s [%message "mimetype not supported yet"])
  | _ -> Or_error.error_s [%message "response kind not supported yet"]

let err_response = Gemmo.Ipc.Serialize.error

let handle_client res flow addr =
  let open Or_error.Let_syntax in
  traceln "Accepted connection at %a" Eio.Net.Sockaddr.pp addr;
  let from_client = Eio.Buf_read.of_flow ~max_size:100 flow in
  let line = Eio.Buf_read.line from_client in
  traceln "Received: %S" line;
  let json = Yojson.Safe.from_string line in
  let%bind msg = Gemmo.Msg.of_yojson json in
  match msg with
  | Gemmo.Msg.LoadUrl { url } ->
      (match get_contents_and_serialize @@ Uri.of_string url with
      | Ok resp -> Eio.Flow.copy_string (Yojson.Safe.to_string resp) flow
      | Error err ->
          Eio.Flow.copy_string
            (Yojson.Safe.to_string @@ err_response @@ Error.to_string_hum err)
            flow);
      Ok ()
  | Close ->
      Eio.Flow.copy_string "goodbye!" flow;
      Eio.Promise.resolve res ();
      Ok ()

let server_run sock =
  let stop, resolver = Eio.Promise.create ~label:"server_stop" () in
  Eio.Net.run_server sock
    (fun flow addr -> Or_error.ok_exn @@ handle_client resolver flow addr)
    ~stop
    ~on_error:(traceln "Error handling connection: %a" Fmt.exn)

let run =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let sock = Eio.Net.listen ~sw ~backlog:5 (Eio.Stdenv.net env) addr in
  server_run sock

let cmd_run =
  let doc = "Browse pages in Geminispace" in
  let man =
    [ `S Manpage.s_bugs; `P "Email bug reports to <mrees@noeontheend.com>" ]
  in
  let info = Cmd.info "gemmo" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info Term.(const run)

let () = Stdlib.exit (Cmd.eval cmd_run)
