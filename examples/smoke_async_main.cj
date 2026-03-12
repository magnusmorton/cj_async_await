package examples.smoke

import cj_async_await.*

@async
func fetchValue(base: Int64): Int64 {
    return base + 1
}

@async
func computeValue(base: Int64): Int64 {
    let first = @await(fetchValue(base))
    let second = @await(fetchValue(first))
    return second
}

@async
main(): Int64 {
    let future = fetchValue(39)
    let direct = future.get()
    let nested = @await(computeValue(direct))
    return nested
}
