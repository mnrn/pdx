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

def Sufficient
    (dataset : List RawPokemon)
    (features : RawPokemon → FormFeatures)
    (kind : RawPokemon → Option FormProperties) : Prop :=
  ∀ p ∈ dataset, ∀ q ∈ dataset,
    features p = features q → kind p = kind q

theorem insufficient_of_collision
    (dataset : List RawPokemon)
    (features : RawPokemon → FormFeatures)
    (kind : RawPokemon → Option FormProperties)
    (p q : RawPokemon)
    (hp : p ∈ dataset)
    (hq : q ∈ dataset)
    (heq : features p = features q)
    (hne : kind p ≠ kind q) :
    ¬ Sufficient dataset features kind := by
  intro hs
  exact hne (hs p hp q hq heq)

def NameDeterminesStats (dataset : List Poke) : Prop :=
  ∀ p ∈ dataset, ∀ q ∈ dataset,
    p.name = q.name → p.stats = q.stats

theorem name_ne_of_stats_ne
    (dataset : List Poke)
    (h : NameDeterminesStats dataset)
    (p q : Poke)
    (hp : p ∈ dataset)
    (hq : q ∈ dataset)
    (hs : p.stats ≠ q.stats) :
    p.name ≠ q.name := by
  intro hn
  exact hs (h p hp q hq hn)


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

#eval do
  let content ← IO.FS.readFile "data/pokemon-raw.json"
  let .ok json := Lean.Json.parse content
    | throw (IO.userError "JSON parse failed")
  let .ok pokemon := (Lean.fromJson? json : Except String (Array RawPokemon))
    | throw (IO.userError "JSON decode failed")

  let mut seen : Std.HashMap String (Stats × String) := {}
  let mut duplicates := 0
  let mut collisions := 0
  let mut failures := 0

  for raw in pokemon do
    match toPoke raw with
    | .error err =>
        failures := failures + 1
        IO.println s!"ERROR: {err}"
    | .ok poke =>
        match seen.get? poke.name with
        | none =>
            seen := seen.insert poke.name (poke.stats, raw.name)
        | some (stats, original) =>
            duplicates := duplicates + 1
            IO.println s!"{poke.name}: {original} vs {raw.name}"
            if stats ≠ poke.stats then
              collisions := collisions + 1
              IO.println s!"  STATS DIFFER: {repr stats} vs {repr poke.stats}"

  IO.println s!"Name duplicates: {duplicates}"
  IO.println s!"Stats collisions: {collisions}"
  IO.println s!"Conversion failures: {failures}"
