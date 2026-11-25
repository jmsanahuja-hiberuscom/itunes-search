import Foundation
import os

enum DataLogger {
    static let network = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SearchFeature",
        category: "network"
    )
}
