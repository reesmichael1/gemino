open Base

module Line = struct
  module HeadingLevel = struct
    type t = Top | Sub | SubSub [@@deriving show, equal]
  end

  type t =
    | Text of string
    | Link of { url : Uri.t; name : string option }
    | Heading of { level : HeadingLevel.t; text : string }
    | ListItem of string option
    | Quote of string
    | PreformatToggle of string option
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
    else if String.is_prefix ~prefix:"```" l then PreformatToggle None
    else if String.is_prefix ~prefix:"#" l then
      Heading { level = Line.HeadingLevel.Top; text = "" }
    else if String.is_prefix ~prefix:"* " l then ListItem None
    else if String.is_prefix ~prefix:">" l then Quote ""
    else Text ""

  let preformatted_line_parser l =
    match line_kind l with
    | Line.PreformatToggle _ -> (Normal, Ok (Line.PreformatToggle None))
    | _ -> (Preformatted, Ok (Line.Text l))

  let normal_line_parser l =
    match line_kind l with
    | Line.Text _ -> (Normal, Ok (Line.Text l))
    | PreformatToggle _ ->
        let maybe_alt = String.drop_prefix l 3 in
        let alt =
          if String.length maybe_alt > 0 then Some maybe_alt else None
        in
        (Preformatted, Ok (PreformatToggle alt))
    | Link _ -> (
        match Combs.run_link l with
        | Ok link -> (Normal, Ok link)
        | Error _ ->
            ( Normal,
              Or_error.error_s
                [%message "invalid link encountered while parsing"] ))
    | ListItem _ ->
        let maybe_body = String.drop_prefix l 2 in
        let body =
          if String.length maybe_body > 0 then Some maybe_body else None
        in
        (Normal, Ok (ListItem body))
    | Quote _ -> (Normal, Ok (Quote (String.drop_prefix l 1)))
    | Heading _ ->
        let trim s n = String.drop_prefix s n |> String.strip in
        let build s = function
          | Line.HeadingLevel.Top as level ->
              Line.Heading { level; text = trim s 1 }
          | Sub as level -> Heading { level; text = trim s 2 }
          | SubSub as level -> Heading { level; text = trim s 3 }
        in
        if String.is_prefix ~prefix:"###" l then (Normal, Ok (build l SubSub))
        else if String.is_prefix ~prefix:"##" l then (Normal, Ok (build l Sub))
        else (Normal, Ok (build l Top))

  let line_parser state line =
    match state with
    | Normal -> normal_line_parser line
    | Preformatted -> preformatted_line_parser line

  let run str =
    let lines = String.split_lines str in
    List.folding_map ~init:Normal ~f:line_parser lines |> Or_error.all
end

let of_string = Parser.run
