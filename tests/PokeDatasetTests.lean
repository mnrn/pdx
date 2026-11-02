
import Lean
import LSpec
import PokeConvert
import PokeConversionProofs

open Lean LSpec

def datasetTests (ps : Array RawPokemon) : TestSeq :=
  let converted := ps.toList.map toPoke
  let pokes := converted.filterMap (·.toOption)

  group "Dataset" (
    test "All records convert" (
      pokes.length == ps.size
    ) ++
    test "Japanese names are unique" (
      decide (NameUnique pokes)
    )
  )
