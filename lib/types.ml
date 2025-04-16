open Base

module Msg = struct
  type t = Close | Duplicate of string
end

type t = { msg : Msg.t }

let to_yojson msg : Yojson.Safe.t =
  match msg.msg with
  | Msg.Close -> `Assoc [ ("kind", `String "close"); ("args", `List []) ]
  | Duplicate s ->
      `Assoc [ ("kind", `String "duplicate"); ("args", `List [ `String s ]) ]

let of_yojson (json : Yojson.Safe.t) : t =
  let open Yojson.Safe.Util in
  let kind = json |> member "kind" |> to_string in
  let args = json |> member "args" |> to_list |> List.map ~f:to_string in
  match kind with
  | "close" -> { msg = Msg.Close }
  | "duplicate" -> { msg = Msg.Duplicate (List.nth_exn args 0) }
  | _ -> failwith "invalid JSON"
