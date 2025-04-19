open Base

type success_reply = { mimetype : Mrmime.Content_type.t; body : string }
type input_kind = Normal of string | Sensitive of string

type t =
  | Input of input_kind
  | Success of success_reply
  | Redirect
  | Tempfail
  | Permfail
  | Auth

val of_reply : string -> t Or_error.t
val validate_url : string -> Uri.t Or_error.t
