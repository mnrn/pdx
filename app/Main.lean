import Lean
import PokeConvert

open Lean

def main : IO Unit := do
  let input ← IO.FS.readFile "data/pokemon-raw.json"

  let json ← match Json.parse input with
    | .ok j => pure j
    | .error err => throw <| IO.userError err

  let pokemons ←
    match (fromJson? json : Except String (Array RawPokemon)) with
    | .ok ps => pure ps
    | .error err => throw <| IO.userError err

  IO.println s!"Decoded {pokemons.size} Pokémon"

  let pokes ← match pokemons.mapM toPoke with
    | .ok ps => pure ps
    | .error err => throw <| IO.userError err

  IO.FS.writeFile "data/poke.json" (toJson pokes).pretty
  IO.println s!"Converted {pokes.size} Pokémon"
