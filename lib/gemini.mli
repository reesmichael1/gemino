open Base

type success_reply = { mimetype : Mrmime.Content_type.t; body : string }

type t =
  | Input
  | Success of success_reply
  | Redirect
  | Tempfail
  | Permfail
  | Auth

val of_reply : string -> t Or_error.t
val validate_url : string -> Uri.t Or_error.t
