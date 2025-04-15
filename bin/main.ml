open Base
open Cmdliner

let path =
  let doc = "$(docv) is the URI to load" and docv = "URI" in
  Arg.(required & pos 0 (some string) None & info [] ~doc ~docv)

let run path = Or_error.ok_exn @@ Gemmo.Browser.show path

let cmd_run =
  let doc = "Browse pages in Geminispace" in
  let man =
    [ `S Manpage.s_bugs; `P "Email bug reports to <mrees@noeontheend.com>" ]
  in
  let info = Cmd.info "gemmo" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info Term.(const run $ path)

let () =
  Mirage_crypto_rng_unix.use_default ();
  Stdlib.exit (Cmd.eval cmd_run)
