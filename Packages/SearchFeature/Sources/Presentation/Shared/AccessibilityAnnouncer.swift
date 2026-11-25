import SwiftUI

/// Abstracción para anunciar mensajes a VoiceOver. Permite sustituirla por un mock en tests.
@MainActor
public protocol AccessibilityAnnouncer: Sendable {
    func announce(_ message: String)
}

/// Implementación real: publica un `AccessibilityNotification.Announcement`.
public struct SystemAccessibilityAnnouncer: AccessibilityAnnouncer {
    public init() {}

    public func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }
}
