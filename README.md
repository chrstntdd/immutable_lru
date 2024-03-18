# immutable_lru

[![Package Version](https://img.shields.io/hexpm/v/immutable_lru)](https://hex.pm/packages/immutable_lru)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/immutable_lru/)

```sh
gleam add immutable_lru
```
```gleam
import immutable_lru

pub fn main() {
  let c =
    immutable_lru.new(10)
    |> immutable_lru.set("1", ["first"])
    |> immutable_lru.set("2", ["second"])
    |> immutable_lru.set("3", ["third"])

  let val =
    c
    |> immutable_lru.get("3")
    |> result.map(with: fn(x) {
      let #(_, val) = x
      val
    })
  // val == ["third"]
}
```

Further documentation can be found at <https://hexdocs.pm/immutable_lru>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
