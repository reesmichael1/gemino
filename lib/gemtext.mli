open Base

module Line : sig
  type t =
    | Text of string
    | Link of { url : Uri.t; name : string option }
    | Heading
    | ListItem
    | Quote
    | PreformatToggle
  [@@deriving show, equal]
end

type t = Line.t list

val of_string : string -> t Or_error.t
