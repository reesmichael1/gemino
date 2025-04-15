let () =
  let open Alcotest in
  run "Gemmo" [ ("gemtext", Gemtext.tests) ]
