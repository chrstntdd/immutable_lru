import gleeunit
import gleeunit/should
import gleam/list
import gleam/result
import immutable_lru

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn set_has_smoke_test() {
  let c =
    immutable_lru.new(10)
    |> immutable_lru.set("1", ["first"])
    |> immutable_lru.set("2", ["second"])
    |> immutable_lru.set("3", ["third"])

  c
  |> immutable_lru.has("3")
  |> should.be_true

  c
  |> immutable_lru.has("🤩")
  |> should.be_false
}

pub fn set_get_test() {
  let c =
    immutable_lru.new(10)
    |> immutable_lru.set("1", ["first"])
    |> immutable_lru.set("2", ["second"])
    |> immutable_lru.set("3", ["third"])

  c
  |> immutable_lru.get("3")
  |> result.map(with: fn(x) {
    let #(_, val) = x
    val
  })
  |> should.equal(Ok(["third"]))
}

pub fn clear_test() {
  let c =
    immutable_lru.new(10)
    |> immutable_lru.set("1", "a")
    |> immutable_lru.set("2", "b")
    |> immutable_lru.set("3", "c")

  let #(c, val) =
    c
    |> immutable_lru.get("3")
    |> result.unwrap(#(immutable_lru.new(0), ""))

  val
  |> should.equal("c")

  let c = immutable_lru.clear(c)

  ["1", "2", "3"]
  |> list.all(satisfying: fn(key) { immutable_lru.has(c, key) })
  |> should.be_false
}

pub fn cache_eviction_test() {
  let c =
    immutable_lru.new(3)
    |> immutable_lru.set("a", 1)
    |> immutable_lru.set("b", 2)
    |> immutable_lru.set("c", 3)
    |> immutable_lru.set("d", 4)
    |> immutable_lru.set("e", 5)
    |> immutable_lru.set("f", 6)

  // Filled up
  ["a", "b", "c", "d", "e", "f"]
  |> list.all(satisfying: fn(key) { immutable_lru.has(c, key) })
  |> should.be_true

  // Trigger the stales to be evicted by filling past 2n keys
  let c =
    c
    |> immutable_lru.set("g", 7)

  c
  |> immutable_lru.has("g")
  |> should.be_true

  // Verify all purged
  ["a", "b", "c"]
  |> list.all(satisfying: fn(key) { immutable_lru.has(c, key) })
  |> should.be_false

  let #(c, val) = immutable_lru.get_exn(c, "e")

  val
  |> should.equal(5)

  ["d", "e", "f", "g"]
  |> list.all(satisfying: fn(key) { immutable_lru.has(c, key) })
  |> should.be_true

  let #(c, _) = immutable_lru.get_exn(c, "d")

  ["g", "e", "d", "f"]
  |> list.all(satisfying: fn(key) { immutable_lru.has(c, key) })
  |> should.be_true

  let c =
    c
    |> immutable_lru.set("a", 1)

  ["a", "g", "e", "d"]
  |> list.all(satisfying: fn(key) { immutable_lru.has(c, key) })
  |> should.be_true

  c
  |> immutable_lru.has("f")
  |> should.be_false
}
