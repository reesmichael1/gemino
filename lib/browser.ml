open Base

let is_invalid_scheme = function
  | None | Some "gemini" -> false
  | Some _ -> true

let show path =
  let uri = Uri.of_string path in
  (* TODO: IP addresses cannot be used for authority *)
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
    Stdlib.print_endline contents;
    Ok ()
