package examples.invalid_async_let_missing_type

import cj_async_await.*

@async
func fetchValue(base: Int64): Int64 {
    return base + 1
}

@async
main(): Int64 {
    @async let value = fetchValue(1)
    return @await(value)
}
