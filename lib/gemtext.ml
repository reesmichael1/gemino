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
    | Preformatted of { alt : string option; lines : string list }
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

module Markers = struct
  type t = Text | Link | Heading | ListItem | Quote | PreformatToggle
end

module Parser = struct
  type state =
    | Normal
    | Preformatted of { alt : string option; lines : string list }

  let line_kind l =
    if String.is_prefix ~prefix:"=>" l then Markers.Link
    else if String.is_prefix ~prefix:"```" l then PreformatToggle
    else if String.is_prefix ~prefix:"#" l then Heading
    else if String.is_prefix ~prefix:"* " l then ListItem
    else if String.is_prefix ~prefix:">" l then Quote
    else Text

  let preformatted_line_parser len ix alt lines l =
    match line_kind l with
    | Markers.PreformatToggle ->
        (Normal, Some (Ok (Line.Preformatted { alt; lines })))
    | _ ->
        (* If we're at the last line, then return the active block *)
        if ix = len - 1 then
          ( Preformatted { alt; lines = lines @ [ l ] },
            Some (Ok (Line.Preformatted { alt; lines = lines @ [ l ] })) )
        else (Preformatted { alt; lines = lines @ [ l ] }, None)

  let normal_line_parser len ix l =
    match line_kind l with
    | Markers.Text -> (Normal, Some (Ok (Line.Text l)))
    | Link -> (
        match Combs.run_link l with
        | Ok link -> (Normal, Some (Ok link))
        | Error _ ->
            ( Normal,
              Some
                (Or_error.error_s
                   [%message "invalid link encountered while parsing"]) ))
    | ListItem ->
        let maybe_body = String.drop_prefix l 2 in
        let body =
          if String.length maybe_body > 0 then Some maybe_body else None
        in
        (Normal, Some (Ok (ListItem body)))
    | Quote -> (Normal, Some (Ok (Quote (String.drop_prefix l 1))))
    | Heading ->
        let trim s n = String.drop_prefix s n |> String.strip in
        let build s = function
          | Line.HeadingLevel.Top as level ->
              Line.Heading { level; text = trim s 1 }
          | Sub as level -> Heading { level; text = trim s 2 }
          | SubSub as level -> Heading { level; text = trim s 3 }
        in
        if String.is_prefix ~prefix:"###" l then
          (Normal, Some (Ok (build l SubSub)))
        else if String.is_prefix ~prefix:"##" l then
          (Normal, Some (Ok (build l Sub)))
        else (Normal, Some (Ok (build l Top)))
    | PreformatToggle ->
        let maybe_alt = String.drop_prefix l 3 in
        let alt =
          if String.length maybe_alt > 0 then Some maybe_alt else None
        in
        (* If the last line also happens to be a preformat entry line,
         * then we need to include that preformatted block. *)
        if ix = len - 1 then
          ( Preformatted { alt; lines = [] },
            Some (Ok (Preformatted { alt; lines = [] })) )
        else (Preformatted { alt; lines = [] }, None)

  let line_parser len ix state line =
    match state with
    | Normal -> normal_line_parser len ix line
    | Preformatted { alt; lines } ->
        preformatted_line_parser len ix alt lines line

  let run str =
    let lines = String.split_lines str in
    (* Pass the index and length along to keep track of whether we're at the last line or not 
     * (which becomes relevant when dealing with preformatted blocks) *)
    List.folding_mapi ~init:Normal ~f:(line_parser @@ List.length lines) lines
    |> List.filter_opt |> Or_error.all
end

let of_string = Parser.run
