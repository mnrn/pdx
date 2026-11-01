# pdx

`pdx` converts Pokémon data retrieved from [PokéAPI](https://pokeapi.co/) into a compact JSON dataset containing Japanese names and base stats. The conversion is implemented in **Lean 4**.

The current workflow uses a **fish** script and a GraphQL query to fetch data. HTTP/GraphQL fetching has not yet been implemented in Lean.

## Requirements

- Lean 4 and Lake (using the project's `lean-toolchain`)
- fish
- curl
- jq

Lake manages the LSpec test dependency.

## Usage

Run the following commands from the repository root.

### 1. Fetch data

```fish
fish scripts/fetch_pokeapi.fish
```

The script executes `graphql/pokeapi.gql` against the PokéAPI GraphQL endpoint, fetches paginated results and saves the merged response to `data/pokemon-raw.json`. Individual pages are cached under `data/pages/`.

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

The six stat keys correspond to **HP, Attack, Defense, Special Attack, Special Defense and Speed**, respectively. JSON object key order is not significant.

## Tests

```fish
lake test
```

Tests use [LSpec](https://github.com/argumentcomputer/LSpec) and the downloaded `data/pokemon-raw.json`. Run the fetch step before testing on a fresh checkout.

## Tests

Run the regression tests using LSpec:

```sh
lake test
```

## Project layout

```text
app/       Lean CLI entry point
src/       Data types and conversion logic
tests/     LSpec regression tests
graphql/   PokéAPI GraphQL query
scripts/   fish fetch script
data/      Downloaded and generated JSON (local data)
```

## Notes

- Pokémon forms can have different base stats, so the conversion processes individual Pokémon records rather than species alone.
- Japanese names sometimes require combining a species name with a form name. Mega Evolutions and other special forms require separate naming rules.
- Name conversion is currently rule-based; the seven regression cases do not establish correctness for every Pokémon form.
- Raw API responses and generated datasets are intended to remain local rather than be committed to Git.
