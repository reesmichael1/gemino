open Base

module Line : sig
  module HeadingLevel : sig
    type t = Top | Sub | SubSub [@@deriving show, equal]
  end

  type t =
    | Text of string
    | Link of { url : Uri.t; name : string option }
    | Heading of { level : HeadingLevel.t; text : string }
    | ListItem of string option
    (* Use string instead of string option for Quote 
     * since it's reasonable to quote an empty line *)
    | Quote of string
    | PreformatToggle of string option
  [@@deriving show, equal]
end

type t = Line.t list

val of_string : string -> t Or_error.t
