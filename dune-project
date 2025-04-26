(lang dune 3.17)

(name gemmo)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Michael Rees <mrees@noeontheend.com>")

(maintainers "Michael Rees <mrees@noeontheend.com>")

(license GPL-3.0-or-later)

; (documentation https://url/to/documentation)

(package
 (name gemmo)
 (synopsis "A Gemini browser")
 (description "A browser for the Gemini protocol")
 (depends
  ocaml
  (alcotest :with-test)
  angstrom
  base
  cmdliner
  domain-name
  eio
  mirage-crypto-rng
  mrmime
  re
  tls
  tls-eio
  uri
  ppx_deriving
  ppx_jane
  ppx_let
  ppx_yojson_conv)
 (tags
  ("gemini" "browser")))
