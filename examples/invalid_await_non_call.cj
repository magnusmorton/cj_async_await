package examples.invalid_non_call_await

import cj_async_await.*

main() {
    let value = @await(1 + 2)
    println(value)
}
