open Base

module Line = struct
  type t =
    | Text of string
    | Link
    | Heading
    | ListItem
    | Quote
    | PreformatToggle
  [@@deriving show, eq]
end

type t = Line.t list

module Parser = struct
  type state = Normal | Preformatted

  let line_kind l =
    if String.is_prefix ~prefix:"=>" l then Line.Link
    else if String.is_prefix ~prefix:"```" l then PreformatToggle
    else if String.is_prefix ~prefix:"#" l then Heading
    else if String.is_prefix ~prefix:"* " l then ListItem
    else if String.is_prefix ~prefix:">" l then Quote
    else Text ""

  let line_parser state l =
    match line_kind l with
    | Line.Text _ -> (Normal, Some (Line.Text l))
    | Line.PreformatToggle -> (
        match state with
        | Normal -> (Preformatted, None)
        | Preformatted -> (Normal, None))
    | _ -> failwith "todo!"

  let run str =
    let lines = String.split_lines str in
    List.folding_map ~init:Normal ~f:line_parser lines
    |> List.filter_map ~f:Fn.id
end

let of_string = Parser.run
