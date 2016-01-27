(** {2} Layouts *)

(** The representation of record types. ['s] is usually a phantom type.
    Two interfaces are provided for creating layouts, in [Unsafe] and [Safe].
*)
type 's layout

(** A field of type ['a] within a ['s layout]. *)
type ('a,'s) field
  [@@deprecated "Please use Field.t instead"]

(** Get the name of the field (as passed to [field]). *)
val field_name : ('a, 's) field -> string
  [@@deprecated "Please use Field.name instead"]

(** Get the type of the field (as passed to [field]). *)
val field_type : ('a, 's) field -> 'a Type.t
  [@@deprecated "Please use Field.typ instead"]

(** Create a new layout with the given name. *)
val declare : string -> 's layout
  [@@deprecated "This function has been moved to Record.Unsafe"]

(** Add a field to a layout. This modifies the layout and returns the field. *)
val field: 's layout -> string -> 'a Type.t -> ('a,'s) field
  [@@deprecated "This function has been moved to Record.Unsafe"]

(** Make the layout unmodifiable. It is necessary before constructing values. *)
val seal : 's layout -> unit
  [@@deprecated "This function has been moved to Record.Unsafe"]

(** Raised by [field] or [seal] if layout has already been sealed. *)
exception ModifyingSealedStruct of string

(** Get the name that was given to a layout. *)
val layout_name : 's layout -> string
  [@@deprecated "This function has been moved to Record.Unsafe"]

(** Get the unique identifier given to a layout. *)
val layout_id: 's layout -> 's Polid.t
  [@@deprecated "This function has been moved to Record.Unsafe"]

(** {2} Records *)

(** The representation of record values. *)
type 's t =
  {
    layout: 's layout;
    content: 's content;
  }
and 's content

(** Allocate a record of a given layout, with all fields initially unset. *)
val make: 's layout -> 's t
  [@@deprecated "This function has been moved to Record.Unsafe"]

(** Get the layout of a record. *)
val get_layout : 'a t -> 'a layout

(** Get the [Type.t] representation of a layout. *)
val layout_type : 'a layout -> 'a t Type.t
  [@@deprecated "This function has been moved to Record.Util"]

(** Shortcut to build a layout with no fields. *)
val declare0 : name:string -> 's layout
  [@@deprecated "This function has been moved in Record.Util"]

(** Shortcut to build a layout with 1 field. *)
val declare1 : name:string
            -> f1_name:string
            -> f1_type:'a Type.t
            -> ('s layout * ('a, 's) field)
            [@@deprecated "This function has been moved in Record.Util"]

(** Shortcut to build a layout with 2 fields. *)
val declare2 : name:string
            -> f1_name:string
            -> f1_type:'a1 Type.t
            -> f2_name:string
            -> f2_type:'a2 Type.t
            -> ('s layout * ('a1, 's) field * ('a2, 's) field)
            [@@deprecated "This function has been moved in Record.Util"]

(** Shortcut to build a layout with 3 fields. *)
val declare3 : name:string
            -> f1_name:string
            -> f1_type:'a1 Type.t
            -> f2_name:string
            -> f2_type:'a2 Type.t
            -> f3_name:string
            -> f3_type:'a3 Type.t
            -> ('s layout * ('a1, 's) field * ('a2, 's) field
                          * ('a3, 's) field)
            [@@deprecated "This function has been moved in Record.Util"]

(** Shortcut to build a layout with 4 fields. *)
val declare4 : name:string
            -> f1_name:string
            -> f1_type:'a1 Type.t
            -> f2_name:string
            -> f2_type:'a2 Type.t
            -> f3_name:string
            -> f3_type:'a3 Type.t
            -> f4_name:string
            -> f4_type:'a4 Type.t
            -> ('s layout * ('a1, 's) field * ('a2, 's) field
                          * ('a3, 's) field * ('a4, 's) field)
            [@@deprecated "This function has been moved in Record.Util"]

(** Raised by [make] when the corresponding layout has not been sealed. *)
exception AllocatingUnsealedStruct of string

(** Get the value of a field. *)
val get: 's t -> ('a,'s) field -> 'a

(** Set the value of a field. *)
val set: 's t -> ('a,'s) field -> 'a -> unit

(** Raised by [get] if the field was not set. *)
exception UndefinedField of string

(** {3} Type converters *)
module Type : sig
  (**
     How to convert a type to and from JSON.
  *)
  type 'a t

  val name : 'a t -> string
  val of_yojson : 'a t -> (Yojson.Safe.json -> [ `Ok of 'a | `Error of string ])
  val to_yojson : 'a t -> ('a -> Yojson.Safe.json)

  (** Declare a new type. *)
  val make:
    name: string ->
    to_yojson: ('a -> Yojson.Safe.json) ->
    of_yojson: (Yojson.Safe.json -> [ `Ok of 'a | `Error of string ]) ->
    unit -> 'a t

  (** Declare a new type that marshal/unmarshal to strings. *)
  val make_string:
    name: string ->
    to_string: ('a -> string) ->
    of_string: (string -> [ `Ok of 'a | `Error of string ]) ->
    unit -> 'a t

  (** How to represent exceptions. *)
  val exn: exn t

  (** Raised by [exn.of_json] *)
  exception UnserializedException of string

  (** How to represent [unit]. *)
  val unit: unit t

  (** How to represent [string]. *)
  val string: string t

  (** How to represent [int]. *)
  val int: int  t

  (** Build a representation of a list. *)
  val list: 'a t -> 'a list t

  (** Build a representation of a couple.
      The labels identify the elements, not their types.
   *)
  val product_2: string -> 'a t -> string -> 'b t -> ('a * 'b) t

  (** Build a ['b] type which has the same JSON encoding as the ['a] type from
      conversion functions [read] and [write]. *)
  val view : name:string -> read:('a -> [`Ok of 'b | `Error of string]) -> write:('b -> 'a) -> 'a t -> 'b t
end

module Field : sig
  (** A field of type ['a] within a ['s layout]. *)
  type ('a,'s) t = ('a, 's) field

  (** Get the name of the field (as passed to [field]). *)
  val name : ('a, 's) field -> string

  (** Get the type of the field (as passed to [field]). *)
  val ftype : ('a, 's) field -> 'a Type.t
end

(** {3} Unsafe interface *)
module Unsafe : sig
  (** The [Unsafe.declare] function returns a ['s layout], which is only safe
      when ['s] is only instanciated once in this context.

      @see <https://github.com/cryptosense/records/pull/8> for discussion
   *)

  (** Create a new layout with the given name. *)
  val declare : string -> 's layout

  (** Add a field to a layout. This modifies the layout and returns the field. *)
  val field: 's layout -> string -> 'a Type.t -> ('a,'s) field

  (** Make the layout unmodifiable. It is necessary before constructing values. *)
  val seal : 's layout -> unit

  (** Allocate a record of a given layout, with all fields initially unset. *)
  val make: 's layout -> 's t

  (** Get the name that was given to a layout. *)
  val layout_name : 's layout -> string

  (** Get the unique identifier given to a layout. *)
  val layout_id: 's layout -> 's Polid.t
end

(** {3} Safe interface *)
module Safe :
sig
  (**
     This interface is similar to [Unsafe] except that the phantom type normally
     passed to [declare] is generated by a functor. This has the other advantage
     of making the [layout] argument implicit in the output module.
  *)

  module type LAYOUT =
  sig
    type s

    (** A value representing the layout. *)
    val layout : s layout

    (** Add a field to the layout. This modifies the layout and returns the field. *)
    val field : string -> 'a Type.t -> ('a, s) field

    (** Make the layout unmodifiable. It is necessary before constructing values. *)
    val seal : unit -> unit

    (** The name that was given to the layout. *)
    val layout_name : string

    (** The unique identifier given to a layout. *)
    val layout_id : s Polid.t

    (** Allocate a record of the layout, with all fields initially unset. *)
    val make : unit -> s t
  end

  (** Create a new layout with the given name. *)
  val declare : string -> (module LAYOUT)
end

(** {2} Miscellaneous *)

(** Convert a record to JSON. *)
val to_json: 'a t -> Yojson.Basic.json
  [@@deprecated "Use to_yojson instead"]

(** Convert a JSON value into a given schema. *)
val of_json: 'a layout -> Yojson.Basic.json -> 'a t
  [@@deprecated "Use of_yojson instead"]

(** Convert a record to JSON. *)
val to_yojson: 'a t -> Yojson.Safe.json

(** Convert a JSON value into a given schema. *)
val of_yojson: 'a layout -> Yojson.Safe.json -> [`Ok of 'a t|`Error of string]

module Util : sig
  (** Get the [Type.t] representation of a layout. *)
  val layout_type : 'a layout -> 'a t Type.t

  (** Shortcut to build a layout with no fields. *)
  val declare0 : name:string -> 's layout

  (** Shortcut to build a layout with 1 field. *)
  val declare1 : name:string
              -> f1_name:string
              -> f1_type:'a Type.t
              -> ('s layout * ('a, 's) field)

  (** Shortcut to build a layout with 2 fields. *)
  val declare2 : name:string
              -> f1_name:string
              -> f1_type:'a1 Type.t
              -> f2_name:string
              -> f2_type:'a2 Type.t
              -> ('s layout * ('a1, 's) field * ('a2, 's) field)

  (** Shortcut to build a layout with 3 fields. *)
  val declare3 : name:string
              -> f1_name:string
              -> f1_type:'a1 Type.t
              -> f2_name:string
              -> f2_type:'a2 Type.t
              -> f3_name:string
              -> f3_type:'a3 Type.t
              -> ('s layout * ('a1, 's) field * ('a2, 's) field
                            * ('a3, 's) field)

  (** Shortcut to build a layout with 4 fields. *)
  val declare4 : name:string
              -> f1_name:string
              -> f1_type:'a1 Type.t
              -> f2_name:string
              -> f2_type:'a2 Type.t
              -> f3_name:string
              -> f3_type:'a3 Type.t
              -> f4_name:string
              -> f4_type:'a4 Type.t
              -> ('s layout * ('a1, 's) field * ('a2, 's) field
                            * ('a3, 's) field * ('a4, 's) field)
end

(** Equality predicate. *)
val equal: 'a layout -> 'b layout -> ('a, 'b) Polid.equal

(** Print the JSON representation of a record to a formatter. *)
val format: Format.formatter -> 'a t -> unit
