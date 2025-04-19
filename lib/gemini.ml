open Base

type success_reply = { mimetype : Mrmime.Content_type.t; body : string }

(* TODO: Verify that the input prompts are required *)
type input_kind = Normal of string | Sensitive of string

type t =
  | Input of input_kind
  | Success of success_reply
  | Redirect
  | Tempfail
  | Permfail
  | Auth

module Parser = struct
  open Angstrom

  let newline = string "\r\n"

  let success =
    string "20 " *> Mrmime.Content_type.Decoder.content >>= fun mimetype ->
    newline *> take_while (fun _ -> true) >>= fun body ->
    return (Success { mimetype; body })

  (* *Technically* we should take until we match on \r\n, but I'm having trouble making that work *)
  let input_normal =
    string "0 " *> take_while1 (fun c -> Char.(c <> '\r')) >>= fun prompt ->
    string "\r\n" *> return (Input (Normal prompt))

  let input_sensitive =
    string "1 " *> take_while1 (fun c -> Char.(c <> '\r')) >>= fun prompt ->
    string "\r\n" *> return (Input (Sensitive prompt))

  let input = string "1" *> (input_normal <|> input_sensitive)
  let gem_reply = success <|> input

  let parse contents =
    Eio.Std.traceln "%S" contents;
    match parse_string ~consume:All gem_reply contents with
    | Ok reply -> Ok reply
    | Error msg ->
        Or_error.error_s
          [%message "could not parse reply from server" (msg : string)]
end

let of_reply = Parser.parse

let is_invalid_scheme = function
  | None | Some "gemini" -> false
  | Some _ -> true

let validate_url url_s =
  let uri = Uri.of_string url_s in
  (* TODO: IP addresses SHOULD NOT be used for authority *)
  if Option.is_some @@ Uri.userinfo uri then
    Or_error.error_s [%message "userinfo should not be set in the URI"]
  else if List.length @@ String.to_list url_s > 1024 then
    Or_error.error_s [%message "URI should be at most 1024 bytes"]
  else if is_invalid_scheme @@ Uri.scheme uri then
    Or_error.error_s [%message "invalid URI scheme"]
  else
    let port = Option.value ~default:1965 (Uri.port uri) in
    let path = if String.length (Uri.path uri) = 0 then "/" else Uri.path uri in
    let scheme = Option.value ~default:"gemini" (Uri.scheme uri) in
    Ok
      (Uri.with_uri ~port:(Some port) ~scheme:(Some scheme) ~path:(Some path)
         ~fragment:None uri)
