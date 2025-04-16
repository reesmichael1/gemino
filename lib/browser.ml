open Base

let is_invalid_scheme = function
  | None | Some "gemini" -> false
  | Some _ -> true

let render =
  let open Or_error.Let_syntax in
  function
  | Gemini.Success { mimetype; body } -> (
      match (mimetype.ty, mimetype.subty) with
      | `Text, `Ietf_token "gemini" ->
          let%bind lines = Gemtext.of_string body in
          List.iter
            ~f:(fun l -> Stdlib.print_endline @@ Gemtext.Line.show l)
            lines;
          Ok ()
      | _ ->
          Stdlib.print_endline body;
          Ok ())
  | _ -> Or_error.error_s [%message "response type not yet supported"]

let show path =
  let open Or_error.Let_syntax in
  let uri = Uri.of_string path in
  (* TODO: IP addresses SHOULD NOT be used for authority *)
  if Option.is_some @@ Uri.userinfo uri then
    Or_error.error_s [%message "userinfo should not be set in the URI"]
  else if List.length @@ String.to_list path > 1024 then
    Or_error.error_s [%message "URI should be at most 1024 bytes"]
  else if is_invalid_scheme @@ Uri.scheme uri then
    Or_error.error_s [%message "invalid URI scheme"]
  else
    let port = Option.value ~default:1965 (Uri.port uri) in
    let path = if String.length (Uri.path uri) = 0 then "/" else Uri.path uri in
    let scheme = Option.value ~default:"gemini" (Uri.scheme uri) in
    let uri =
      Uri.with_uri ~port:(Some port) ~scheme:(Some scheme) ~path:(Some path)
        ~fragment:None uri
    in
    let contents = Or_error.ok_exn @@ Net.load_uri uri in
    let%bind reply = Gemini.of_reply contents in

    render reply
