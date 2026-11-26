import Domain
import Foundation
import Testing
@testable import Data

struct URLSessionHTTPClientTests {
    @Test(arguments: [200, 201, 204, 299])
    func successStatusCodesPass(_ code: Int) throws {
        try URLSessionHTTPClient.validate(statusCode: code)
    }

    @Test func notFoundMapsToNotFound() {
        #expect(throws: DomainError.notFound) {
            try URLSessionHTTPClient.validate(statusCode: 404)
        }
    }

    @Test(arguments: [301, 400, 403, 429, 500, 503])
    func otherStatusCodesMapToNetwork(_ code: Int) {
        #expect(throws: DomainError.network) {
            try URLSessionHTTPClient.validate(statusCode: code)
        }
    }

    @Test func urlErrorCancelledBecomesCancellationError() {
        let mapped = URLSessionHTTPClient.map(URLError(.cancelled))
        #expect(mapped is CancellationError)
    }

    @Test func otherURLErrorsBecomeNetwork() {
        let mapped = URLSessionHTTPClient.map(URLError(.notConnectedToInternet))
        #expect(mapped as? DomainError == .network)
    }

    @Test func cancellationErrorPassesThrough() {
        #expect(URLSessionHTTPClient.map(CancellationError()) is CancellationError)
    }

    /// Con un `URLSession` real: cancelar la `Task` detiene la petición en vuelo
    /// y el cliente termina con `CancellationError`, no con un error de red.
    @Test(.timeLimit(.minutes(1)))
    func cancellingTheTaskStopsTheRequestInFlight() async {
        let url = URL(string: "https://hanging.test/\(UUID().uuidString)")!
        let (started, signalStarted) = AsyncStream.makeStream(of: Void.self)
        let (stopped, signalStopped) = AsyncStream.makeStream(of: Void.self)
        HangingURLProtocol.register(for: url, .init(
            onStart: { signalStarted.yield() },
            onStop: { signalStopped.yield() }
        ))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HangingURLProtocol.self]
        let sut = URLSessionHTTPClient(session: URLSession(configuration: configuration))

        let task = Task { try await sut.data(for: URLRequest(url: url)) }
        for await _ in started { break }   // la petición ya está en vuelo
        task.cancel()
        for await _ in stopped { break }   // la red recibió el stop

        await #expect(throws: CancellationError.self) { try await task.value }
    }
}
