import PokeData
import PokeConvert

inductive FormKind where
  | formVariant
  | regional
  | mega
  | primal
  | totem
  | starter
  deriving DecidableEq, Repr

abbrev FormProperties := List FormKind

structure FormFeatures where
  isMega       : Bool
  isDefault    : Bool
  isBattleOnly : Bool
  deriving DecidableEq, Repr

private def exceptionalForm
    (name : String) : Option (Option FormProperties) :=
  match name with
  | "marowak-totem" =>
    some (some [.regional, .totem])
  | "mimikyu-totem-disguised"
  | "mimikyu-totem-busted" =>
      some (some [.formVariant, .totem])
  | "pikachu-alola-cap" =>
      some (some [.formVariant])
  | "zygarde-10-power-construct"
  | "zygarde-50-power-construct" =>
      some none
  | _ => none

def classifyForm (p : RawPokemon) : Option FormProperties := Id.run do
  if let some result := exceptionalForm p.name then
    return result

  let parts := p.name.splitOn "-"
  let regions := ["alola", "galar", "hisui", "paldea"]

  let isRegional := regions.any (fun r => parts.contains r)
  let isMega := p.pokemonforms.any (·.is_mega)
  let isPrimal := parts.contains "primal"
  let isTotem := parts.contains "totem"
  let isStarter := parts.contains "starter"
  let isBattleBond := p.name.endsWith "-battle-bond"
  let isOwnTempo := p.name.endsWith "-own-tempo"

  let hasNamedForm := p.pokemonforms.any (fun f =>
    f.pokemonformnames.any (fun n => !n.name.isEmpty))

  let isPureRegional :=
    isRegional && p.pokemonforms.all
      (fun f => regions.contains f.form_name)

  let isformVariant :=
    hasNamedForm &&
    !isPureRegional &&
    !isMega && !isPrimal &&
    !isStarter && !isBattleBond && !isOwnTempo

  let mut kinds : FormProperties := []

  if isRegional then kinds := .regional :: kinds
  if isformVariant then kinds := .formVariant :: kinds
  if isMega then kinds := .mega :: kinds
  if isPrimal then kinds := .primal :: kinds
  if isTotem then kinds := .totem :: kinds
  if isStarter then kinds := .starter :: kinds

  if kinds.isEmpty && !p.is_default then
    return none

  return some kinds.reverse

def formFeatures (p : RawPokemon) : FormFeatures :=
  { isMega := p.pokemonforms.any (·.is_mega)
    isDefault := p.is_default
    isBattleOnly := p.pokemonforms.any (·.is_battle_only) }

def Reconstructable
    (dataset : List RawPokemon)
    (features : RawPokemon → FormFeatures)
    (target : RawPokemon → Option FormProperties) : Prop :=
  ∃ recover : FormFeatures → Option FormProperties,
    ∀ p ∈ dataset, recover (features p) = target p

theorem unreconstructable_of_collision
    (dataset : List RawPokemon)
    (features : RawPokemon → FormFeatures)
    (target : RawPokemon → Option FormProperties)
    (p q : RawPokemon)
    (hp : p ∈ dataset)
    (hq : q ∈ dataset)
    (heq : features p = features q)
    (hne : target p ≠ target q) :
    ¬ Reconstructable dataset features target := by
  rintro ⟨recover, hr⟩
  apply hne
  calc
    target p = recover (features p) := (hr p hp).symm
    _ = recover (features q) := congrArg recover heq
    _ = target q := hr q hq


#eval do
  let content ← IO.FS.readFile "data/pokemon-raw.json"
  let .ok json := Lean.Json.parse content
    | throw (IO.userError "JSON parse failed")
  let .ok pokemon := (Lean.fromJson? json : Except String (Array RawPokemon))
    | throw (IO.userError "JSON decode failed")

  for kind in #[FormKind.formVariant, .regional, .mega, .primal,
                .totem, .starter] do
    let selected := pokemon.filter fun p =>
      match classifyForm p with
      | some kinds => kinds.contains kind
      | none => false
    IO.println s!"{repr kind}: {selected.size}"

  let normal := pokemon.filter fun p =>
    classifyForm p == some []
  IO.println s!"Normal: {normal.size}"

  let unknown := pokemon.filter fun p =>
    (classifyForm p).isNone
  IO.println s!"Unclassified: {unknown.size}"

  for p in unknown do
    let ja := match resolveName p with
      | .ok name => name
      | .error err => s!"ERROR: {err}"
    IO.println s!"{p.name}: {ja}"

  for p in pokemon do
    if let some kinds := classifyForm p then
      if kinds.length > 1 then
        IO.println s!"{p.name}: {repr kinds}"

  let some p := pokemon.toList.find?
      (fun (p : RawPokemon) => p.name == "marowak-totem")
    | throw (IO.userError "Marowak not found")

  let some q := pokemon.toList.find?
      (fun (q : RawPokemon) => q.name == "gumshoos-totem")
    | throw (IO.userError "Gumshoos not found")

  IO.println s!"Same features: {decide (formFeatures p = formFeatures q)}"
  IO.println s!"Different classifications: {decide (classifyForm p ≠ classifyForm q)}"
