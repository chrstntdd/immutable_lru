import gleam/dict
import gleam/result

/// A dictionary of keys and values that follows the least recently updated
/// cache replacement policy.
///
/// Any type can be used for the keys and values of a dict, but all the keys
/// must be of the same type and all the values must be of the same type.
///
/// There is no guarantee of ordering of the collection.
///
pub opaque type LruCache(k, v) {
  LruCache(
    active: dict.Dict(k, v),
    stale: dict.Dict(k, v),
    max: Int,
    key_count: Int,
  )
}

/// Creates a new empty cache that will have at most 2n entries and will be 
/// immutably updated with the LRU policy.
///
/// ```gleam
///  let c =
///    new(10)
///    |> set("a", 1)
///    |> set("b", 2)
///    |> set("c", 3)
///  let #(c, val) = {
///    case get(c, "a") {
///      Ok(pairs) -> pairs
///      Error(_) -> panic as "whoops"
///    }
///  }
///  let t = val == 1
///  // t == True
/// ```
///
pub fn new(max: Int) -> LruCache(k, v) {
  let active = dict.new()
  let stale = dict.new()
  LruCache(active, stale, max, 0)
}

/// Retrieve a value from the cache as a Result
///
/// Returns a tuple to allow for further reads from the updated cache
/// 
///
/// ## Examples
///
/// ```gleam
/// new()
///  let c =
///    new(10)
///    |> set("a", 1)
///    |> set("b", 2)
///    |> set("c", 3)
///  let #(c, val) = {
///    case get(c, "a") {
///      Ok(pairs) -> pairs
///      Error(_) -> panic as "whoops"
///    }
///  }
///  let t = val == 1
///  // t == True
/// ```
///
pub fn get(c: LruCache(k, v), key: k) -> Result(#(LruCache(k, v), v), Nil) {
  case c {
    LruCache(active, stale, _, _) -> {
      let value_from_active =
        active
        |> dict.get(key)
        |> result.map(with: fn(val) { #(c, val) })
      let value_from_stale =
        stale
        |> dict.get(key)
        |> result.map(with: fn(val) { #(keep(c, key, val), val) })

      result.or(value_from_active, value_from_stale)
    }
  }
}

/// Retrieve a value from the cache or panic
///
/// Returns a tuple to allow for further reads from the updated cache
/// 
///
/// ## Examples
///
/// ```gleam
/// new()
///  let c =
///    new(10)
///    |> set("a", 1)
///    |> set("b", 2)
///    |> set("c", 3)
///  let #(c, val) = get_exn(c, "a")
///  let t = val == 1
///  // t == True
/// ```
///
pub fn get_exn(c: LruCache(k, v), key: k) -> #(LruCache(k, v), v) {
  case get(c, key) {
    Ok(pair) -> pair
    _ -> panic as "key not found in cache"
  }
}

fn keep(c: LruCache(k, v), key: k, value: v) {
  case c {
    LruCache(active, stale, max, key_count) -> {
      let key_count = key_count + 1
      let parts = case key_count > max {
        True -> {
          #(dict.new(), active, 1)
        }
        False -> {
          #(active, stale, key_count)
        }
      }
      let active = dict.insert(parts.0, key, value)
      LruCache(active, parts.1, max, parts.2)
    }
  }
}

/// Add an entry into the cache
///
///
/// ## Examples
///
/// ```gleam
/// new()
///  let c =
///    new(10)
///    |> set("a", 1)
///    |> set("b", 2)
///    |> set("c", 3)
///  let #(c, val) = get_exn(c, "a")
///  let t = val == 1
///  // t == True
/// ```
///
pub fn set(c: LruCache(k, v), key: k, value: v) -> LruCache(k, v) {
  case c {
    LruCache(active, stale, max, key_count) -> {
      case dict.has_key(active, key) {
        True -> {
          let next_active = dict.insert(active, key, value)
          LruCache(next_active, stale, max, key_count)
        }
        False -> {
          keep(c, key, value)
        }
      }
    }
  }
}

/// Check for membership in the cache
///
///
/// ## Examples
///
/// ```gleam
/// new()
/// |> set("a", 1)
/// |> set("b", 2)
/// |> has("b")
/// // -> True
/// ```
///
pub fn has(c: LruCache(k, v), key: k) -> Bool {
  case c {
    LruCache(active, stale, _, _) -> {
      result.or(
        active
          |> dict.get(key),
        stale
          |> dict.get(key),
      )
      |> result.is_ok
    }
  }
}

/// Clear all entries in the cache. 
///
/// The `max` of the cache is reused.
///
///
/// ## Examples
///
/// ```gleam
///  let c =
///    new(10)
///    |> set("1", "a")
///    |> set("2", "b")
///    |> set("3", "c")
///
///  let is_mem = has(c, "3")
///  // is_mem == True
///
///  let c = clear(c)
///
///  let is_mem = has(c, "3")
///  // is_mem == False
/// ```
///
pub fn clear(c: LruCache(k, v)) -> LruCache(k, v) {
  case c {
    LruCache(_, _, max, _) -> {
      new(max)
    }
  }
}
