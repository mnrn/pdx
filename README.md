# pdx

`pdx` converts Pokémon data retrieved from [PokéAPI](https://pokeapi.co/) into a compact JSON dataset containing Japanese names and base stats. The converter, validation logic, and formal proofs are written in **Lean 4**.

Data fetching currently uses a **fish** script and a GraphQL query; HTTP/GraphQL fetching is not implemented in Lean.

## Requirements

- Lean 4 and Lake (using the project's `lean-toolchain`)
- fish, curl, and jq (only needed to refresh the source data)

Lake manages the [LSpec](https://github.com/argumentcomputer/LSpec) test dependency.

## Usage

Run the commands below from the repository root.

### 1. Source data

A snapshot of `data/pokemon-raw.json` is committed to the repository so builds and tests can use a fixed dataset. To refresh it from PokéAPI, run:

```fish
fish scripts/fetch_pokeapi.fish
```

The script runs `graphql/pokeapi.gql`, fetches paginated results, and writes the merged response to `data/pokemon-raw.json`. Individual pages are cached under `data/pages/`.

### 2. Convert to JSON

```fish
lake build
lake exe pdx
```

The converter reads `data/pokemon-raw.json` and writes `data/poke.json`.

Example output:

```json
[
  {
    "name": "メガリザードンＸ",
    "stats": {
      "h": 78,
      "a": 130,
      "b": 111,
      "c": 130,
      "d": 85,
      "s": 100
    }
  }
]
```

The six stat keys correspond to HP, Attack, Defense, Special Attack, Special Defense, and Speed. JSON object key order is not significant.

## Tests

Run the [LSpec](https://github.com/argumentcomputer/LSpec) suite:

```fish
lake test
```

The suite includes individual conversion regression tests and dataset-wide checks that:

- Every source record converts successfully.
- Japanese names are unique (`NameUnique`).

These checks run against the committed source-data snapshot. They verify these specific properties of that dataset, not the correctness of every naming or form-classification decision.

The generated GitHub Actions workflow runs the project's Lake checks in CI.

## Formal proofs

Build the Lean proof modules with:

```fish
lake build PdxProofs
```

The proof modules include:

- `NameUnique` and `NameDeterminesStats`, together with a proof that unique names imply that equal names determine equal stats.
- `Reconstructable` and `unreconstructable_of_collision`, which show that a classification cannot be recovered from selected features if two records have the same features but different target classifications.

These are general theorems about the definitions. Dataset-wide LSpec checks are separate executable validations; they do not by themselves establish a kernel-checked proof about the contents of the JSON file.

## Project layout

```text
app/       Lean CLI entry point
src/       Data types and conversion logic
proofs/    Definitions and formal proofs
tests/     LSpec regression and dataset tests
graphql/   PokéAPI GraphQL query
scripts/   fish data-fetching script
data/      Source-data snapshot and generated JSON
```

## Notes

- Different Pokémon records, including alternate forms, may have different base stats. Conversion therefore operates on Pokémon records rather than species alone.
- Japanese names may require combining a species name with form information. Special cases are handled with explicit naming rules.
- Form classification is heuristic and includes exceptions. It is not a formally verified mapping of every Pokémon form.
