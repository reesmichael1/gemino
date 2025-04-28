let () =
  let open Alcotest in
  run "Gemino" [ ("gemtext", Gemtext.tests) ]
