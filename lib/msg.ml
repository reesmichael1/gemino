open Base
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

type url_opts = { url : string } [@@deriving yojson]
type t = Close | LoadUrl of url_opts

let to_yojson msg : Yojson.Safe.t =
  match msg with
  | Close -> `Assoc [ ("kind", `String "close"); ("args", `List []) ]
  | LoadUrl s -> `Assoc [ ("loadUrl", yojson_of_url_opts s) ]

let of_yojson (json : Yojson.Safe.t) : t Or_error.t =
  match json with
  | `String s -> (
      match s with
      | "appExit" -> Ok Close
      | _ ->
          Or_error.error_s
            [%message "unrecognized JSON string literal" (s : string)])
  | `Assoc l -> (
      match List.Assoc.find ~equal:String.equal l "loadUrl" with
      | Some s -> Ok (LoadUrl (url_opts_of_yojson s))
      | None -> Or_error.error_s [%message "todo"])
  | _ -> failwith "todo"
