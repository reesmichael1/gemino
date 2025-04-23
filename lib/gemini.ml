open Base

type success_reply = { mimetype : Mrmime.Content_type.t; body : string }

type tempfail_reply =
  | Unspecified of string option
  | ServerUnavailable of string option
  | CgiError of string option
  | ProxyError of string option
  | SlowDown of string option

type permfail_reply =
  | General of string option
  | NotFound of string option
  | Gone of string option
  | ProxyRefused of string option
  | BadRequest of string option

(* TODO: Verify that the input prompts are required *)
type input_kind = Normal of string | Sensitive of string
type redirect_reply = Temporary of string | Permanent of string

type t =
  | Input of input_kind
  | Success of success_reply
  | Redirect of redirect_reply
  | Tempfail of tempfail_reply
  | Permfail of permfail_reply
  | Auth

module Parser = struct
  (* TODO: Mimic the BNF exactly *)
  open Angstrom

  let newline = string "\r\n"

  let success =
    string "20 " *> Mrmime.Content_type.Decoder.content >>= fun mimetype ->
    newline *> take_while (fun _ -> true) >>= fun body ->
    return (Success { mimetype; body })

  let tempfail =
    let tempfail_gen num kind =
      string (Printf.sprintf "%d " num)
      *> take_while (fun c -> Char.(c <> '\r'))
      >>= fun msg ->
      string "\r\n"
      *>
      if String.length msg = 0 then return (Tempfail (kind None))
      else return (Tempfail (kind (Some msg)))
    in
    string "4"
    *> (tempfail_gen 0 (fun m -> Unspecified m)
       <|> tempfail_gen 1 (fun m -> ServerUnavailable m)
       <|> tempfail_gen 2 (fun m -> CgiError m)
       <|> tempfail_gen 3 (fun m -> ProxyError m)
       <|> tempfail_gen 4 (fun m -> SlowDown m))

  let permfail =
    let permfail_gen num kind =
      string (Printf.sprintf "%d " num)
      *> take_while (fun c -> Char.(c <> '\r'))
      >>= fun msg ->
      string "\r\n"
      *>
      if String.length msg = 0 then return (Permfail (kind None))
      else return (Permfail (kind (Some msg)))
    in
    string "5"
    *> (permfail_gen 0 (fun m -> General m)
       <|> permfail_gen 1 (fun m -> NotFound m)
       <|> permfail_gen 2 (fun m -> Gone m)
       <|> permfail_gen 3 (fun m -> ProxyRefused m)
       <|> permfail_gen 9 (fun m -> BadRequest m))

  (* *Technically* we should take until we match on \r\n, but I'm having trouble making that work *)
  let input_normal =
    string "0 " *> take_while1 (fun c -> Char.(c <> '\r')) >>= fun prompt ->
    string "\r\n" *> return (Input (Normal prompt))

  let input_sensitive =
    string "1 " *> take_while1 (fun c -> Char.(c <> '\r')) >>= fun prompt ->
    string "\r\n" *> return (Input (Sensitive prompt))

  let redirect_temp =
    string "0 " *> take_while1 (fun c -> Char.(c <> '\r')) >>= fun url ->
    string "\r\n" *> return (Redirect (Temporary url))

  let redirect_perm =
    string "1 " *> take_while1 (fun c -> Char.(c <> '\r')) >>= fun url ->
    string "\r\n" *> return (Redirect (Permanent url))

  let input = string "1" *> (input_normal <|> input_sensitive)
  let redirect = string "3" *> (redirect_temp <|> redirect_perm)
  let gem_reply = success <|> input <|> permfail <|> redirect <|> tempfail

  let parse contents =
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
