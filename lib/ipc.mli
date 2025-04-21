open Base

module FrontendMsg : sig
  type url_opts = { url : string }
  type input_opts = { url : string; input : string }
  type t = Close | LoadUrl of url_opts | UserInput of input_opts

  val of_yojson : Yojson.Safe.t -> t Or_error.t
end

module Serialize : sig
  val gemini : Gemini.t -> Yojson.Safe.t Or_error.t
  val error : string -> Yojson.Safe.t
end
