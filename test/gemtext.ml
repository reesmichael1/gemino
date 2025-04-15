open Gemmo

let gemline = Alcotest.testable Gemtext.Line.pp Gemtext.Line.equal

let test_simple_text () =
  Alcotest.(check (list gemline))
    "same list"
    (Gemtext.of_string "hello world!")
    [ Gemtext.Line.Text "hello world!" ]

let test_multiple_lines_not_compressed () =
  Alcotest.(check (list gemline))
    "same list"
    (Gemtext.of_string "line 1\n\n\nline 2")
    [ Gemtext.Line.Text "line 1"; Text ""; Text ""; Text "line 2" ]

let tests =
  let open Alcotest in
  [
    test_case "single text line parsed correctly" `Quick test_simple_text;
    test_case "multiple lines are separated correctly" `Quick
      test_multiple_lines_not_compressed;
  ]
