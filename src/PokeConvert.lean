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
  pokemonformnames : Array RawFormName
  deriving FromJson, Repr

structure RawStat where
  stat_id   : Nat
  base_stat : Nat
  deriving FromJson, Repr

structure RawPokemon where
  id           : Nat
  name         : String
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
  deriving ToJson, Repr

structure Poke where
  name  : String
  stats : Stats
  deriving ToJson, Repr


def japaneseName (p : RawPokemon) : Except String String := do
  let some species := p.pokemonspecy.pokemonspeciesnames[0]?
    | throw s!"Missing Japanese name: {p.name}"

  let forms := p.pokemonforms.toList.flatMap
    (fun f => f.pokemonformnames.toList)

  let fullName := (forms.find? (fun f => !f.pokemon_name.isEmpty)).map (·.pokemon_name)
  let formName := (forms.find? (fun f => !f.name.isEmpty)).map (·.name)
  let isMega := p.pokemonforms.any (·.is_mega)

  let composed := formName.map fun name =>
    if isMega || name.startsWith "ゲンシ" then
      name
    else
      s!"{species.name}（{name}）"

  return (fullName <|> composed).getD species.name


def getStat (p : RawPokemon) (id : Nat) : Except String Nat :=
  match p.pokemonstats.toList.filter (fun s => s.stat_id == id) with
  | [s] => .ok s.base_stat
  | [] => .error s!"Missing stat {id}: {p.name}"
  | _ => .error s!"Duplicate stat {id}: {p.name}"

def toPoke (p : RawPokemon) : Except String Poke := do
  if p.pokemonstats.size != 6 then
    throw s!"Invalid stats count: {p.name}"

  let name ← japaneseName p

  let h ← getStat p 1
  let a ← getStat p 2
  let b ← getStat p 3
  let c ← getStat p 4
  let d ← getStat p 5
  let s ← getStat p 6

  return ⟨name, ⟨h, a, b, c, d, s⟩⟩
