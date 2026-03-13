# async/await macros for the Cangjie Programming language
This package adds experimental `async` and `await` support to Cangjie using
macros. The purpose of this is to experiment with LLMs and macro code.

## Import
```cangjie
import cj_async_await.*
```

## Semantics
`@async` is a function decorator.

```cangjie
@async
func fetch(): Int64 {
    return 42
}
```

desugars to:

```cangjie
func fetch(): Future<Int64> {
    return spawn {
        return 42
    }
}
```

`@await(call)` is expression sugar for calling `.get()` on the result of a
future-producing call or bound future expression.

```cangjie
let value = @await(fetch())
```

desugars to:

```cangjie
let value = fetch().get()
```

`@async let` gives Swift-like binding sugar for the future returned by an
`@async` function call. The declared type is the eventual value type, and the
macro rewrites it to `Future<T>`.

```cangjie
@async let value: Int64 = fetch()
let resolved = @await(value)
```

desugars to:

```cangjie
let value: Future<Int64> = fetch()
let resolved = value.get()
```

`@async main` is special-cased so you can write an async entrypoint without
exposing `Future<_>` from `main`.

```cangjie
@async
main(): Int64 {
    return @await(fetch())
}
```

desugars to:

```cangjie
main(): Int64 {
    return spawn {
        return fetch().get()
    }.get()
}
```

## Current limitations
- `@async` requires an explicit return type.
- `@async let` requires an explicit value type and a single binding name.
- `@await` only supports future-producing calls and bound future expressions.
- This is blocking `Future.get()` sugar, not a full structured-concurrency
  runtime.
- Direct calls are allowed. Sync code can call an `@async` function directly
  and handle the returned `Future<T>` itself.
- Because `@async` functions already return `Future<T>`, `@async let` is sugar
  for binding that future, not a separate child-task runtime.

## Examples
Compile examples after building the macro package:

- `examples/smoke_async_main.cj`
- `examples/member_and_generic_await.cj`

Negative fixtures are also included under `examples/` to exercise macro
diagnostics and type-check failures.

## Tests
Positive example behavior is covered by a dedicated test package under
`tests/examples`. Negative example behavior is covered by a compile-fail
harness under `tests/compile_fail`.

Run everything with:

```bash
./tests/run.sh
```

Or run one half:

```bash
./tests/run.sh unit
./tests/run.sh compile-fail
```
