package examples.invalid_async_var_binding

import cj_async_await.*

@async
func fetchValue(base: Int64): Int64 {
    return base + 1
}

@async
main(): Int64 {
    @async var value: Int64 = fetchValue(1)
    return @await(value)
}
