module Serialize : sig
  val gemtext_lines : Gemtext.t -> Yojson.Safe.t
  val error : string -> Yojson.Safe.t
end
