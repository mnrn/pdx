import PokeData
import PokeConvert

abbrev NameUnique (dataset : List Poke) : Prop :=
  (dataset.map (·.name)).Nodup

def NameDeterminesStats (dataset : List Poke) : Prop :=
  ∀ p ∈ dataset, ∀ q ∈ dataset,
    p.name = q.name → p.stats = q.stats

theorem name_determines_stats_of_name_unique
    (dataset : List Poke) :
    NameUnique dataset → NameDeterminesStats dataset := by
  intro h p hp q hq hn

  let R (a b : Poke) : Prop :=
    a.name = b.name → a.stats = b.stats

  have hpair : List.Pairwise R dataset :=
    List.Pairwise.of_map (fun p : Poke => p.name)
      (fun a b hne heq => (hne heq).elim) h

  have hflip : List.Pairwise (flip R) dataset :=
    hpair.imp (fun hab hba => (hab hba.symm).symm)

  exact (List.Pairwise.forall_of_forall_of_flip
    (fun a _ => by intro _; rfl) hpair hflip hp hq) hn

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
