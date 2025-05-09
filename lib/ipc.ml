open Base
open Ppx_yojson_conv_lib.Yojson_conv.Primitives

module FrontendMsg = struct
  type url_opts = { url : string } [@@deriving of_yojson]
  type input_opts = { url : string; input : string } [@@deriving of_yojson]
  type linkclick_opts = { url : string; path : string } [@@deriving of_yojson]

  type t =
    | Close
    | LoadUrl of url_opts
    | UserInput of input_opts
    | LinkClick of linkclick_opts

  let load_url_p l =
    match List.Assoc.find ~equal:String.equal l "loadUrl" with
    | Some s -> Some (LoadUrl (url_opts_of_yojson s))
    | None -> None

  let input_p l =
    match List.Assoc.find ~equal:String.equal l "userInput" with
    | Some s -> Some (UserInput (input_opts_of_yojson s))
    | None -> None

  let linkclick_p l =
    match List.Assoc.find ~equal:String.equal l "linkClick" with
    | Some s -> Some (LinkClick (linkclick_opts_of_yojson s))
    | None -> None

  let of_yojson (json : Yojson.Safe.t) : t Or_error.t =
    let err = Or_error.error_s [%message "unrecognized JSON from frontend"] in
    match json with
    | `String s -> (
        match s with
        | "appExit" -> Ok Close
        | _ ->
            Or_error.error_s
              [%message "unrecognized JSON string literal" (s : string)])
    | `Assoc l -> (
        (* Try each `Assoc parser until we find one that matches (or error out if we don't find any) *)
        match
          List.find_map ~f:(fun p -> p l) [ load_url_p; input_p; linkclick_p ]
        with
        | Some res -> Ok res
        | None -> err)
    | _ -> err
end

module Serialize = struct
  let h_level = function
    | Gemtext.Line.HeadingLevel.Top -> `Int 1
    | Gemtext.Line.HeadingLevel.Sub -> `Int 2
    | Gemtext.Line.HeadingLevel.SubSub -> `Int 3

  let status_wrapper num content = `Assoc ([ ("status", `Int num) ] @ content)

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
        let scheme = Uri.scheme url |> Option.value ~default:"gemini" in
        `Assoc
          [
            ( "link",
              `Assoc
                [
                  ("url", `String (Uri.to_string url));
                  ("name", name);
                  ("scheme", `String scheme);
                ] );
          ]

  let gemtext_lines uri lines =
    let rec aux acc = function
      | [] ->
          (* Don't return the explicit port unless it's non-standard *)
          let uri =
            Uri.to_string
            @@
            match Uri.port uri with
            | Some 1965 -> Uri.with_port uri None
            | _ -> uri
          in
          status_wrapper 20
            [
              ("lines", `List (List.rev acc));
              ("mime", `String "text/gemini");
              ("url", `String uri);
            ]
      | l :: rest -> aux (gemtext_line l :: acc) rest
    in
    aux [] lines

  let gemini uri =
    let open Or_error.Let_syntax in
    let msg_fmt = function
      | Some m -> ("msg", `String m)
      | None -> ("msg", `Null)
    in
    let failmsg kind desc num msg =
      Ok
        (`Assoc
           [
             ("status", `Int num);
             (kind, `Assoc [ ("kind", `String desc); msg_fmt msg ]);
           ])
    in
    function
    | Gemini.Success r -> (
        match (r.mimetype.ty, r.mimetype.subty) with
        | `Text, `Ietf_token "gemini" ->
            let%bind lines = Gemtext.of_string r.body in
            let response = gemtext_lines uri lines in
            Ok response
        | _ -> Or_error.error_s [%message "mimetype not supported yet"])
    | Input i ->
        let kind, p, num =
          match i with
          | Normal p -> (("kind", `String "normal"), p, 10)
          | Sensitive p -> (("kind", `String "sensitive"), p, 11)
        in
        let uri = Uri.to_string uri in
        Ok
          (status_wrapper num
             [
               ( "input",
                 `Assoc [ kind; ("prompt", `String p); ("url", `String uri) ] );
             ])
    | Permfail f -> (
        let failmsg = failmsg "permfail" in
        match f with
        | Gemini.General msg -> failmsg "general" 50 msg
        | NotFound msg -> failmsg "notfound" 51 msg
        | Gone msg -> failmsg "gone" 52 msg
        | ProxyRefused msg -> failmsg "proxyrequestrefused" 53 msg
        | BadRequest msg -> failmsg "badrequest" 59 msg)
    | Tempfail f -> (
        let failmsg = failmsg "tempfail" in
        match f with
        | Gemini.Unspecified msg -> failmsg "unspecified" 40 msg
        | ServerUnavailable msg -> failmsg "serverunavailable" 41 msg
        | CgiError msg -> failmsg "cgierror" 42 msg
        | ProxyError msg -> failmsg "proxyerror" 43 msg
        | SlowDown msg -> failmsg "slowdown" 44 msg)
    | Redirect m -> (
        let redirmsg desc url =
          Ok
            (`Assoc
               [
                 ( "redirect",
                   `Assoc [ ("kind", `String desc); ("dest", `String url) ] );
               ])
        in
        match m with
        | Temporary url -> redirmsg "temporary" url
        | Permanent url -> redirmsg "permanent" url)
    | Auth -> Or_error.error_s [%message "auth responses not yet implemented"]

  let error err = `Assoc [ ("error", `String err) ]
end
