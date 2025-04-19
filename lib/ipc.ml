open Base
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module FrontendMsg = struct
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
end

module Serialize = struct
  let h_level = function
    | Gemtext.Line.HeadingLevel.Top -> `Int 1
    | Gemtext.Line.HeadingLevel.Sub -> `Int 2
    | Gemtext.Line.HeadingLevel.SubSub -> `Int 3

  let gemtext_line = function
    | Gemtext.Line.Text t -> `Assoc [ ("text", `String t) ]
    | ListItem (Some l) -> `Assoc [ ("list", `String l) ]
    | ListItem None -> `Assoc [ ("list", `Null) ]
    | Quote q -> `Assoc [ ("quote", `String q) ]
    | Preformatted { alt; lines } ->
        let alt = match alt with Some s -> `String s | None -> `Null in
        let lines = List.map ~f:(fun s -> `String s) lines in
        `Assoc [ ("pre", `Assoc [ ("alt", alt); ("lines", `List lines) ]) ]
    | Heading { level; text } ->
        `Assoc
          [
            ( "heading",
              `Assoc [ ("level", h_level level); ("text", `String text) ] );
          ]
    | Link { url; name } ->
        let name = match name with Some s -> `String s | None -> `Null in
        `Assoc
          [
            ( "link",
              `Assoc [ ("url", `String (Uri.to_string url)); ("name", name) ] );
          ]

  let gemtext_lines lines =
    let rec aux acc = function
      | [] ->
          `Assoc
            [
              ( "content",
                `Assoc
                  [
                    ("lines", `List (List.rev acc));
                    ("status", `Int 20);
                    ("mime", `String "text/gemini");
                  ] );
            ]
      | l :: rest -> aux (gemtext_line l :: acc) rest
    in
    aux [] lines

  let gemini =
    let open Or_error.Let_syntax in
    function
    | Gemini.Success r -> (
        match (r.mimetype.ty, r.mimetype.subty) with
        | `Text, `Ietf_token "gemini" ->
            let%bind lines = Gemtext.of_string r.body in
            let response = gemtext_lines lines in
            Ok response
        | _ -> Or_error.error_s [%message "mimetype not supported yet"])
    | Gemini.Input i ->
        let kind, p =
          match i with
          | Normal p -> (("kind", `String "normal"), p)
          | Sensitive p -> (("kind", `String "sensitive"), p)
        in
        Ok (`Assoc [ ("input", `Assoc [ kind; ("prompt", `String p) ]) ])
    | Gemini.Permfail f -> (
        let msg_fmt = function
          | Some m -> ("msg", `String m)
          | None -> ("msg", `Null)
        in
        let failmsg descr msg =
          Ok
            (`Assoc
               [ ("permfail", `Assoc [ ("kind", `String descr); msg_fmt msg ]) ])
        in
        match f with
        | Gemini.General msg -> failmsg "general" msg
        | NotFound msg -> failmsg "notfound" msg
        | Gone msg -> failmsg "gone" msg
        | ProxyRefused msg -> failmsg "proxyrequestrefused" msg
        | BadRequest msg -> failmsg "badrequest" msg)
    | _ -> Or_error.error_s [%message "response kind not supported yet"]

  let error err = `Assoc [ ("error", `String err) ]
end
