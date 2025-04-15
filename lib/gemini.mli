open Base

type success_reply = { mimetype : string; body : string }

type t =
  | Input
  | Success of success_reply
  | Redirect
  | Tempfail
  | Permfail
  | Auth

val of_reply : string -> t Or_error.t
