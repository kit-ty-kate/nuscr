open! Core_kernel
open Syntax
open Err
open Gtype
open Ltype
open Efsm

let set_filename (fname : string) (lexbuf : Lexing.lexbuf) =
  lexbuf.Lexing.lex_curr_p <-
    {lexbuf.Lexing.lex_curr_p with Lexing.pos_fname= fname} ;
  lexbuf

let parse fname (ch : In_channel.t) : scr_module =
  let lexbuf = set_filename fname (Lexing.from_channel ch) in
  try Parser.scr_module Lexer.token lexbuf with
  | Lexer.LexError msg -> uerr (LexerError msg)
  | Parser.Error ->
      let err_interval =
        (Lexing.lexeme_start_p lexbuf, Lexing.lexeme_end_p lexbuf)
      in
      uerr (ParserError err_interval)
  | e -> Err.Violation ("Found a problem:" ^ Exn.to_string e) |> raise

let validate_exn (ast : scr_module) ~verbose : unit =
  let show ~f ~sep xs =
    (* only show if verbose is on *)
    if verbose then String.concat ~sep (List.map ~f xs) |> print_endline
    else ()
  in
  let protocols = ast.protocols in
  let g_types =
    List.map
      ~f:(fun p -> (global_type_of_protocol p, p.value.roles))
      protocols
  in
  let g_types =
    List.map ~f:(fun (g, roles) -> (normal_form g, roles)) g_types
  in
  show ~sep:"\n" ~f:(fun (g, _) -> show_global_type g) g_types ;
  let l_types =
    List.map
      ~f:(fun (g, roles) -> List.map ~f:(project g roles) roles)
      g_types
  in
  show ~sep:"\n"
    ~f:(fun ls -> String.concat ~sep:"\n" (List.map ~f:show_local_type ls))
    l_types ;
  let efsmss = List.map ~f:(List.map ~f:conv_ltype) l_types in
  show ~sep:"\n"
    ~f:(fun efsms ->
      String.concat ~sep:"\n" (List.map ~f:(fun (_, g) -> show_efsm g) efsms))
    efsmss

let enumerate (ast : scr_module) : (string * string) list =
  let protocols = ast.protocols in
  let roles p =
    let {value= {name; roles; _}; _} = p in
    List.map ~f:(fun role -> (name, role)) roles
  in
  List.concat_map ~f:(fun p -> roles p) protocols

let project_role ast name role : local_type =
  let gp = List.find_exn ~f:(fun gt -> gt.value.name = name) ast.protocols in
  let roles = gp.value.roles in
  let gt = global_type_of_protocol gp in
  project gt roles role

let generate_fsm ast name role =
  let lt = project_role ast name role in
  conv_ltype lt