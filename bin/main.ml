open Base
open Cmdliner
open Eio.Std

let addr = `Unix "/run/user/1000/gemmo.sock"

let get_contents_and_serialize net uri =
  let open Or_error.Let_syntax in
  let%bind contents = Gemmo.Net.load_uri net uri in
  let%bind response = Gemmo.Gemini.of_reply contents in
  let%bind answer = Gemmo.Ipc.Serialize.gemini uri response in
  Ok answer

let err_response msg = Yojson.Safe.to_string @@ Gemmo.Ipc.Serialize.error msg

let error_handler flow = function
  | Ok () -> ()
  | Error err ->
      Eio.Flow.copy_string (err_response @@ Error.to_string_hum err) flow;
      ()

let is_absolute_url s =
  (* From https://stackoverflow.com/questions/10687099/ *)
  let re = Re.Str.regexp "^(?:[a-z+]+:)?//" in
  Re.Str.string_match re s 0

let handle_client net res flow addr =
  let open Or_error.Let_syntax in
  traceln "Accepted connection at %a" Eio.Net.Sockaddr.pp addr;
  let from_client = Eio.Buf_read.of_flow ~max_size:Int.max_value flow in
  let line = Eio.Buf_read.line from_client in
  traceln "Received: %S" line;
  let json = Yojson.Safe.from_string line in
  let%bind msg = Gemmo.Ipc.FrontendMsg.of_yojson json in
  match msg with
  | Gemmo.Ipc.FrontendMsg.LoadUrl { url } ->
      let%bind uri = Gemmo.Gemini.validate_url url in
      let%bind resp = get_contents_and_serialize net uri in
      Eio.Flow.copy_string (Yojson.Safe.to_string resp) flow;
      Ok ()
  | UserInput { input; url } ->
      let%bind uri = Gemmo.Gemini.validate_url url in
      let uri = Uri.with_query uri [ (input, []) ] in
      let%bind resp = get_contents_and_serialize net uri in
      Eio.Flow.copy_string (Yojson.Safe.to_string resp) flow;
      Ok ()
  | LinkClick { url; path } ->
      let%bind uri =
        if is_absolute_url path then Gemmo.Gemini.validate_url path
        else
          let%bind uri = Gemmo.Gemini.validate_url url in
          (* The path that comes from the link is a relative path,
           * so we replace the last component with the new path *)
          let base_path =
            Uri.path uri |> String.split ~on:'/' |> List.drop_last_exn
            |> String.concat ~sep:"/"
          in
          let path = base_path ^ "/" ^ path in
          Ok (Uri.with_path uri path)
      in
      let%bind resp = get_contents_and_serialize net uri in
      Eio.Flow.copy_string (Yojson.Safe.to_string resp) flow;
      Ok ()
  | Close ->
      Eio.Flow.copy_string "goodbye!" flow;
      Eio.Promise.resolve res ();
      Ok ()

let server_run net sock =
  let stop, resolver = Eio.Promise.create ~label:"server_stop" () in
  Eio.Net.run_server sock
    (fun flow addr ->
      error_handler flow @@ handle_client net resolver flow addr)
    ~stop
    ~on_error:(traceln "Error handling connection: %a" Fmt.exn)

let run =
  Mirage_crypto_rng_unix.use_default ();
  Eio_main.run @@ fun env ->
  let net = Eio.Stdenv.net env in
  Eio.Switch.run @@ fun sw ->
  let sock = Eio.Net.listen ~sw ~backlog:5 net addr in
  server_run net sock

let cmd_run =
  let doc = "Browse pages in Geminispace" in
  let man =
    [ `S Manpage.s_bugs; `P "Email bug reports to <mrees@noeontheend.com>" ]
  in
  let info = Cmd.info "gemmo" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info Term.(const run)

let () = Stdlib.exit (Cmd.eval cmd_run)
