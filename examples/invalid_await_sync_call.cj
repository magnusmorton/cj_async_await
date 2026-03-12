package examples.invalid_sync_call

import cj_async_await.*

func syncValue(): Int64 {
    return 3
}

main() {
    let value = @await(syncValue())
    println(value)
}
