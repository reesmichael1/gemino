open Base

module Line = struct
  type t =
    | Text of string
    | Link of { url : Uri.t; name : string option }
    | Heading
    | ListItem
    | Quote
    | PreformatToggle
  [@@deriving show, eq]
end

type t = Line.t list

module Combs = struct
  open Angstrom

  let maybe_whitespace = take_while Char.is_whitespace
  let not_whitespace c = not (Char.is_whitespace c)

  let link =
    string "=>" *> maybe_whitespace *> take_while1 not_whitespace >>= fun url ->
    peek_char >>= fun next ->
    match next with
    | None -> return @@ Line.Link { url = Uri.of_string url; name = None }
    | Some _ ->
        take_while1 Char.is_whitespace *> take_while1 (fun _ -> true)
        >>= fun name ->
        return @@ Line.Link { url = Uri.of_string url; name = Some name }

  let run_link = parse_string ~consume:All link
end

module Parser = struct
  type state = Normal | Preformatted

  let line_kind l =
    if String.is_prefix ~prefix:"=>" l then
      Line.Link { url = Uri.of_string ""; name = None }
    else if String.is_prefix ~prefix:"```" l then PreformatToggle
    else if String.is_prefix ~prefix:"#" l then Heading
    else if String.is_prefix ~prefix:"* " l then ListItem
    else if String.is_prefix ~prefix:">" l then Quote
    else Text ""

  let line_parser state l =
    match line_kind l with
    | Line.Text _ -> (state, Ok (Some (Line.Text l)))
    | Line.PreformatToggle -> (
        match state with
        | Normal -> (Preformatted, Ok None)
        | Preformatted -> (Normal, Ok None))
    | Line.Link _ -> (
        match Combs.run_link l with
        | Ok link -> (state, Ok (Some link))
        | Error _ ->
            ( state,
              Or_error.error_s
                [%message "invalid link encountered while parsing"] ))
    | _ -> failwith "todo!"

  let run str =
    let open Or_error.Let_syntax in
    let lines = String.split_lines str in
    let%bind parsed =
      List.folding_map ~init:Normal ~f:line_parser lines |> Or_error.all
    in
    Ok (List.filter_map ~f:Fn.id parsed)
end

let of_string = Parser.run
