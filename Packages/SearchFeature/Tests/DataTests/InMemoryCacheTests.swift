import Foundation
import Testing
@testable import Data

struct InMemoryCacheTests {
    private func makeSUT(ttl: TimeInterval = 180) -> (InMemoryCache<String, Int>, TestClock) {
        let clock = TestClock()
        return (InMemoryCache(ttl: ttl, now: { clock.now }), clock)
    }

    @Test func defaultTTLIsThreeMinutes() {
        #expect(InMemoryCache<String, Int>.defaultTTL == 180)
    }

    @Test func returnsValueBeforeTTL() async {
        let (sut, clock) = makeSUT()
        await sut.insert(1, for: "a")
        clock.advance(by: 179)
        #expect(await sut.value(for: "a") == 1)
    }

    @Test func expiresExactlyAtTTL() async {
        let (sut, clock) = makeSUT()
        await sut.insert(1, for: "a")
        clock.advance(by: 180)
        #expect(await sut.value(for: "a") == nil)
    }

    @Test func expiresAfterTTL() async {
        let (sut, clock) = makeSUT()
        await sut.insert(1, for: "a")
        clock.advance(by: 181)
        #expect(await sut.value(for: "a") == nil)
    }

    @Test func expiredEntryStaysGoneEvenIfClockWentBack() async {
        let (sut, clock) = makeSUT()
        await sut.insert(1, for: "a")
        clock.advance(by: 200)
        #expect(await sut.value(for: "a") == nil)
        clock.advance(by: -200)
        #expect(await sut.value(for: "a") == nil)
    }

    @Test func differentKeysDoNotMix() async {
        let (sut, _) = makeSUT()
        await sut.insert(1, for: "a")
        await sut.insert(2, for: "b")
        #expect(await sut.value(for: "a") == 1)
        #expect(await sut.value(for: "b") == 2)
        #expect(await sut.value(for: "c") == nil)
    }

    @Test func reinsertingRenewsExpiration() async {
        let (sut, clock) = makeSUT()
        await sut.insert(1, for: "a")
        clock.advance(by: 120)
        await sut.insert(2, for: "a")
        clock.advance(by: 120)
        #expect(await sut.value(for: "a") == 2)
        clock.advance(by: 60)
        #expect(await sut.value(for: "a") == nil)
    }

    @Test func respectsCustomTTL() async {
        let (sut, clock) = makeSUT(ttl: 10)
        await sut.insert(1, for: "a")
        clock.advance(by: 10)
        #expect(await sut.value(for: "a") == nil)
    }
}
