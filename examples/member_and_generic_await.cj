package examples.member_generic

import cj_async_await.*

class Worker {
    @async
    func fetch(offset: Int64): Int64 {
        return offset + 10
    }
}

@async
func id<T>(value: T): T {
    return value
}

@async
main(): Int64 {
    let worker = Worker()
    let member = @await(worker.fetch(1))
    let generic = @await(id<Int64>(member))
    return generic
}
