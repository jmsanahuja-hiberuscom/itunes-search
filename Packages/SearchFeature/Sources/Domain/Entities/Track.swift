import Foundation

public struct Track: Identifiable, Equatable, Sendable {
    public let id: Int
    public let number: Int
    public let name: String
    public let duration: Duration?

    public init(id: Int, number: Int, name: String, duration: Duration? = nil) {
        self.id = id
        self.number = number
        self.name = name
        self.duration = duration
    }
}
