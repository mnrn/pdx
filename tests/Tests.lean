
import Lean
import LSpec
import PokeConvert

open Lean LSpec

def loadPokemon : IO (Array RawPokemon) := do
  let input ← IO.FS.readFile "data/pokemon-raw.json"

  let json ← match Json.parse input with
    | .ok j => pure j
    | .error err => throw <| IO.userError err

  match (fromJson? json : Except String (Array RawPokemon)) with
  | .ok ps => pure ps
  | .error err => throw <| IO.userError err

def lookupPoke
    (ps : Array RawPokemon)
    (slug : String) : Option (String × Array Nat) := do

  let raw ← ps.find? (fun p => p.name == slug)
  let poke ← (toPoke raw).toOption

  return (poke.name, #[
    poke.stats.h,
    poke.stats.a,
    poke.stats.b,
    poke.stats.c,
    poke.stats.d,
    poke.stats.s
  ])

def pokemonTests (ps : Array RawPokemon) : TestSeq :=
  group "Pokemon" (
    test "Cresselia" (
      lookupPoke ps "cresselia" =
        some ("クレセリア", #[120, 70, 110, 75, 120, 85])
    ) ++
    test "Exeggutor" (
      lookupPoke ps "exeggutor" =
        some ("ナッシー", #[95, 95, 85, 125, 75, 55])
    ) ++
    test "Alolan Exeggutor" (
      lookupPoke ps "exeggutor-alola" =
        some ("ナッシー（アローラのすがた）", #[95, 105, 85, 125, 75, 45])
    ) ++
    test "Tapu Lele" (
      lookupPoke ps "tapu-lele" =
        some ("カプ・テテフ", #[70, 85, 75, 130, 115, 95])
    ) ++
    test "Mega Mawile" (
      lookupPoke ps "mawile-mega" =
        some ("メガクチート", #[50, 105, 125, 55, 95, 50])
    ) ++
    test "Ogerpon" (
      lookupPoke ps "ogerpon" =
        some ("オーガポン（みどりのめん）", #[80, 120, 84, 60, 96, 110])
    ) ++
    test "Mew" (
      lookupPoke ps "mew" =
        some ("ミュウ", #[100, 100, 100, 100, 100, 100])
    )
  )

def main : IO UInt32 := do
  let pokemons ← loadPokemon
  lspecIO (.ofList [("Pokemon", [pokemonTests pokemons])]) []
