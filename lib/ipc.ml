open Base

module Serialize = struct
  let h_level = function
    | Gemtext.Line.HeadingLevel.Top -> `Int 1
    | Gemtext.Line.HeadingLevel.Sub -> `Int 2
    | Gemtext.Line.HeadingLevel.SubSub -> `Int 3

  let gemtext_line = function
    | Gemtext.Line.Text t -> `Assoc [ ("text", `String t) ]
    | ListItem (Some l) -> `Assoc [ ("list", `String l) ]
    | ListItem None -> `Assoc [ ("list", `Null) ]
    | Quote q -> `Assoc [ ("quote", `String q) ]
    | Preformatted { alt; lines } ->
        let alt = match alt with Some s -> `String s | None -> `Null in
        let lines = List.map ~f:(fun s -> `String s) lines in
        `Assoc [ ("pre", `Assoc [ ("alt", alt); ("lines", `List lines) ]) ]
    | Heading { level; text } ->
        `Assoc
          [
            ( "heading",
              `Assoc [ ("level", h_level level); ("text", `String text) ] );
          ]
    | Link { url; name } ->
        let name = match name with Some s -> `String s | None -> `Null in
        `Assoc
          [
            ( "link",
              `Assoc [ ("url", `String (Uri.to_string url)); ("name", name) ] );
          ]

  let gemtext_lines lines =
    let rec aux acc = function
      | [] ->
          `Assoc
            [
              ( "content",
                `Assoc
                  [
                    ("lines", `List (List.rev acc));
                    ("status", `Int 20);
                    ("mime", `String "text/gemini");
                  ] );
            ]
      | l :: rest -> aux (gemtext_line l :: acc) rest
    in
    aux [] lines

  let error err = `Assoc [ ("error", `String err) ]
end
