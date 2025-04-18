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

let test_preformat_no_alt () =
  Alcotest.(check (list gemline))
    "same list"
    [ Gemtext.Line.Preformatted { alt = None; lines = [] } ]
    (parse_text "```")

let test_preformat_alt () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.Preformatted
        { alt = Some "demonstration of alt text"; lines = [] };
    ]
    (parse_text "```demonstration of alt text")

let test_list_items () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.ListItem (Some "item 1");
      ListItem None;
      ListItem (Some "item 3");
    ]
    (parse_text "* item 1\n* \n* item 3")

let test_quote_lines () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.Quote "this is a quoted line"; Quote ""; Quote " and another";
    ]
    (parse_text ">this is a quoted line\n>\n> and another")

let test_heading_lines () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.Heading
        { level = Gemtext.Line.HeadingLevel.Top; text = "heading" };
      Heading { level = Sub; text = "sub-heading" };
      Heading { level = SubSub; text = "sub-sub-heading" };
    ]
    (parse_text "# heading\n##sub-heading\n###    sub-sub-heading")

let test_preformatted_content () =
  Alcotest.(check (list gemline))
    "same list"
    [
      Gemtext.Line.Preformatted
        {
          alt = None;
          lines = [ "=> not a link"; "# nor a heading"; "* nor a list" ];
        };
    ]
    (parse_text "```\n=> not a link\n# nor a heading\n* nor a list")

let tests =
  let open Alcotest in
  [
    test_case "single text line parsed correctly" `Quick test_simple_text;
    test_case "multiple lines are separated correctly" `Quick
      test_multiple_lines_not_compressed;
    test_case "simple link with no name" `Quick test_link_line;
    test_case "simple link with name" `Quick test_link_name;
    test_case "more complicated link" `Quick test_link_spacing;
    test_case "preformat toggle with no alt text" `Quick test_preformat_no_alt;
    test_case "preformat toggle with alt text" `Quick test_preformat_alt;
    test_case "list items" `Quick test_list_items;
    test_case "quote lines" `Quick test_quote_lines;
    test_case "heading lines" `Quick test_heading_lines;
    test_case "content inside preformatted block" `Quick
      test_preformatted_content;
  ]
