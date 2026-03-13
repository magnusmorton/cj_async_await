package async_await_examples_test

internal import std.unittest.*
import std.unittest.testmacro.*

@Test
public class AsyncAwaitExampleTest {
    @TestCase
    func directAsyncCallReturnsFuture(): Unit {
        let future = fetchValue(39)
        @Assert(future.get(), 40)
    }

    @TestCase
    func awaitChainsAsyncCalls(): Unit {
        let future = computeValue(40)
        @Assert(future.get(), 42)
    }

    @TestCase
    func asyncLetBindsAwaitableFuture(): Unit {
        let future = computeWithAsyncLet(20)
        @Assert(future.get(), 43)
    }

    @TestCase
    func awaitSupportsMemberCalls(): Unit {
        let future = memberAndGenericValue(1)
        @Assert(future.get(), 11)
    }

    @TestCase
    func genericAsyncFunctionStillReturnsFuture(): Unit {
        let future = passthrough<Int64>(99)
        @Assert(future.get(), 99)
    }
}
