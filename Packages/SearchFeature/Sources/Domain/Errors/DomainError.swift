import Foundation

public enum DomainError: Error, Equatable, Sendable {
    case network
    case decoding
    case notFound
    case unknown
}
