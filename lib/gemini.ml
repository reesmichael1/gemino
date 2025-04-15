open Base

type success_reply = { mimetype : string; body : string }

type t =
  | Input
  | Success of success_reply
  | Redirect
  | Tempfail
  | Permfail
  | Auth

module Parser = struct
  open Angstrom

  let not_space c = not (Char.is_whitespace c)

  let success =
    string "20 " *> take_while1 not_space >>= fun mimetype ->
    string "\r\n" *> take_while (fun _ -> true) >>= fun body ->
    return (Success { mimetype; body })

  let gem_reply = success

  let parse contents =
    match parse_string ~consume:All gem_reply contents with
    | Ok reply -> Ok reply
    | Error msg ->
        Or_error.error_s
          [%message "could not parse reply from server" (msg : string)]
end

let of_reply = Parser.parse
