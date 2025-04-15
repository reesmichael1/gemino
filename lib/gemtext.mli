module Line : sig
  type t =
    | Text of string
    | Link
    | Heading
    | ListItem
    | Quote
    | PreformatToggle
  [@@deriving show, equal]
end

type t = Line.t list

val of_string : string -> t
