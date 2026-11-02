import Lean
import PokeData

open Lean

private def exceptionalName (name : String) : Option String :=
  match name with
  | "marowak-totem" =>
    some "ガラガラ（アローラのすがた・ぬし）"
  | "raticate-totem-alola" =>
      some "ラッタ（アローラのすがた・ぬし）"
  | "minior-red-meteor" =>
      some "メテノ（りゅうせいのすがた・あかいろのコア）"
  | "minior-orange-meteor" =>
      some "メテノ（りゅうせいのすがた・だいだいいろのコア）"
  | "minior-yellow-meteor" =>
      some "メテノ（りゅうせいのすがた・きいろのコア）"
  | "minior-green-meteor" =>
      some "メテノ（りゅうせいのすがた・みどりいろのコア）"
  | "minior-blue-meteor" =>
      some "メテノ（りゅうせいのすがた・みずいろのコア）"
  | "minior-indigo-meteor" =>
      some "メテノ（りゅうせいのすがた・あおいろのコア）"
  | "minior-violet-meteor" =>
      some "メテノ（りゅうせいのすがた・むらさきいろのコア）"
  | "darmanitan-galar-zen" =>
      some "ヒヒダルマ（ガラルのすがた・ダルマモード）"
  | "tauros-paldea-combat-breed" =>
      some "ケンタロス（パルデアのすがた・コンバットしゅ）"
  | "tauros-paldea-blaze-breed" =>
      some "ケンタロス（パルデアのすがた・ブレイズしゅ）"
  | "tauros-paldea-aqua-breed" =>
      some "ケンタロス（パルデアのすがた・ウォーターしゅ）"
  | "magearna-original-mega" =>
      some "メガマギアナ（５００ねんまえのいろ）"
  | "tatsugiri-curly-mega" =>
      some "メガシャリタツ（そったすがた）"
  | "tatsugiri-droopy-mega" =>
      some "メガシャリタツ（たれたすがた）"
  | "tatsugiri-stretchy-mega" =>
      some "メガシャリタツ（のびたすがた）"
  | "zygarde-10-power-construct" =>
      some "ジガルデ（１０％フォルム・スワームチェンジ）"
  | "zygarde-50-power-construct" =>
      some "ジガルデ（５０％フォルム・スワームチェンジ）"
  | "meowstic-male-mega" =>
      some "メガニャオニクス（オス）"
  | "meowstic-female-mega" =>
      some "メガニャオニクス（メス）"
  | "mimikyu-totem-disguised" =>
      some "ミミッキュ（ぬし・ばけたすがた）"
  | "mimikyu-totem-busted" =>
      some "ミミッキュ（ぬし・ばれたすがた）"
  | _ => none

def resolveName (p : RawPokemon) : Except String String := do
  if let some name := exceptionalName p.name then
    return name

  let some species := p.pokemonspecy.pokemonspeciesnames[0]?
    | throw s!"Missing Japanese name: {p.name}"

  if p.pokemonforms.any (fun f => f.form_name == "totem") then
    return s!"{species.name}（ぬし）"
  if p.pokemonforms.any (fun f => f.form_name == "starter") then
    return s!"{species.name}（相棒）"
  if p.pokemonforms.any (fun f => f.form_name == "battle-bond") then
    return s!"{species.name}（きずなへんげ）"

  let forms := p.pokemonforms.toList.flatMap
    (fun f => f.pokemonformnames.toList)

  let providedName := (forms.find? (fun f => !f.pokemon_name.isEmpty)).map (·.pokemon_name)
  let formName := (forms.find? (fun f => !f.name.isEmpty)).map (·.name)
  let isMega := p.pokemonforms.any (·.is_mega)

  let composedName :=
    if isMega then formName
    else formName.map fun name => s!"{species.name}（{name}）"

  return (providedName <|> composedName).getD species.name

def getStat (p : RawPokemon) (id : Nat) : Except String Nat :=
  match p.pokemonstats.toList.filter (fun s => s.stat_id == id) with
  | [s] => .ok s.base_stat
  | [] => .error s!"Missing stat {id}: {p.name}"
  | _ => .error s!"Duplicate stat {id}: {p.name}"

def toPoke (p : RawPokemon) : Except String Poke := do
  if p.pokemonstats.size != 6 then
    throw s!"Invalid stats count: {p.name}"

  let name ← resolveName p

  let h ← getStat p 1
  let a ← getStat p 2
  let b ← getStat p 3
  let c ← getStat p 4
  let d ← getStat p 5
  let s ← getStat p 6

  return ⟨name, ⟨h, a, b, c, d, s⟩⟩
