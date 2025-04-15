open Base
open Gemmo

let gemline = Alcotest.testable Gemtext.Line.pp Gemtext.Line.equal

let parse_text s =
  match Gemtext.of_string s with
  | Ok l -> l
  | Error msg -> Alcotest.fail (Error.to_string_hum msg)

let test_simple_text () =
  Alcotest.(check (list gemline))
    "same list"
    [ Gemtext.Line.Text "hello world!" ]
    (parse_text "hello world!")

let test_multiple_lines_not_compressed () =
  Alcotest.(check (list gemline))
    "same list"
    [ Gemtext.Line.Text "line 1"; Text ""; Text ""; Text "line 2" ]
    (parse_text "line 1\n\n\nline 2")

let test_link_line () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.Link
        { url = Uri.of_string "gemini://example.org/"; name = None };
    ]
    (parse_text "=> gemini://example.org/")

let test_link_name () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.Link
        {
          url = Uri.of_string "gemini://example.org/";
          name = Some "An example link";
        };
    ]
    (parse_text "=> gemini://example.org/ An example link")

let test_link_spacing () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.Link
        {
          url = Uri.of_string "gopher://example.org:70/1";
          name = Some "A gopher link";
        };
    ]
    (parse_text "=>          gopher://example.org:70/1        A gopher link")

let tests =
  let open Alcotest in
  [
    test_case "single text line parsed correctly" `Quick test_simple_text;
    test_case "multiple lines are separated correctly" `Quick
      test_multiple_lines_not_compressed;
    test_case "simple link with no name" `Quick test_link_line;
    test_case "simple link with name" `Quick test_link_name;
    test_case "more complicated link" `Quick test_link_spacing;
  ]
