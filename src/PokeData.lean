import Lean

open Lean

structure RawSpeciesName where
  name : String
  deriving FromJson, Repr

structure RawSpecies where
  pokemonspeciesnames : Array RawSpeciesName
  deriving FromJson, Repr

structure RawFormName where
  name         : String
  pokemon_name : String
  deriving FromJson, Repr

structure RawForm where
  is_mega          : Bool
  is_battle_only   : Bool
  form_name        : String
  pokemonformnames : Array RawFormName
  deriving FromJson, Repr

structure RawStat where
  stat_id   : Nat
  base_stat : Nat
  deriving FromJson, Repr

structure RawPokemon where
  id           : Nat
  name         : String
  is_default   : Bool
  pokemonstats : Array RawStat
  pokemonspecy : RawSpecies
  pokemonforms : Array RawForm
  deriving FromJson, Repr

structure Stats where
  h : Nat
  a : Nat
  b : Nat
  c : Nat
  d : Nat
  s : Nat
  deriving ToJson, Repr, DecidableEq

structure Poke where
  name  : String
  stats : Stats
  deriving ToJson, Repr
