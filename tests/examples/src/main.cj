package async_await_examples_test

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
func computeWithAsyncLet(base: Int64): Int64 {
    @async let first: Int64 = fetchValue(base)
    @async let second: Int64 = fetchValue(base + 1)
    return @await(first) + @await(second)
}

class Worker {
    @async
    func fetch(offset: Int64): Int64 {
        return offset + 10
    }
}

@async
func passthrough<T>(value: T): T {
    return value
}

@async
func memberAndGenericValue(offset: Int64): Int64 {
    let worker = Worker()
    let fetched = @await(worker.fetch(offset))
    return @await(passthrough<Int64>(fetched))
}
