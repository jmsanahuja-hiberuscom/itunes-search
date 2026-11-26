import Presentation

/// Anunciador falso: guarda los mensajes en lugar de hablarlos con VoiceOver.
@MainActor
final class MockAnnouncer: AccessibilityAnnouncer {
    private(set) var messages: [String] = []

    func announce(_ message: String) {
        messages.append(message)
    }
}
