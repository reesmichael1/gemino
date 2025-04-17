open Base

type url_opts = { url : string }
type t = Close | LoadUrl of url_opts

val to_yojson : t -> Yojson.Safe.t
val of_yojson : Yojson.Safe.t -> t Or_error.t
