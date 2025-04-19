open Base

type success_reply = { mimetype : Mrmime.Content_type.t; body : string }
type input_kind = Normal of string | Sensitive of string
type redirect_reply = Temporary of string | Permanent of string

type permfail_reply =
  | General of string option
  | NotFound of string option
  | Gone of string option
  | ProxyRefused of string option
  | BadRequest of string option

type t =
  | Input of input_kind
  | Success of success_reply
  | Redirect of redirect_reply
  | Tempfail
  | Permfail of permfail_reply
  | Auth

val of_reply : string -> t Or_error.t
val validate_url : string -> Uri.t Or_error.t
