open Base

val load_uri : [> 'a Eio.Net.ty ] Eio.Resource.t -> Uri.t -> string Or_error.t
