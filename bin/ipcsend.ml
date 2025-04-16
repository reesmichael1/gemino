open Base
open Eio.Std
module Write = Eio.Buf_write
module Read = Eio.Buf_read

let addr = `Unix "/run/user/1000/gemmo.sock"

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let msg = { Gemmo.Types.msg = Gemmo.Types.Msg.Close } in
  let json = Gemmo.Types.to_yojson msg in
  let str = Yojson.Safe.to_string ~std:true json in
  let sock = Eio.Net.connect ~sw (Eio.Stdenv.net env) addr in
  Write.with_flow sock @@ fun w ->
  Write.string w str;
  Write.string w "\n";
  traceln "wrote to the socket";
  let reply = Read.(parse_exn take_all) sock ~max_size:100 in
  traceln "got reply: %s" reply
