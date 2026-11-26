import Domain
import Foundation

/// Mapeo `Error → mensaje para el usuario`. Vive en Presentation porque
/// el texto localizado es una decisión de UI, no de dominio.
enum UserMessage {
    static func message(for error: any Error) -> String {
        switch error as? DomainError {
        case .network:
            String(localized: "error.network", bundle: .module)
        case .decoding:
            String(localized: "error.decoding", bundle: .module)
        case .notFound:
            String(localized: "error.notFound", bundle: .module)
        case .unknown, nil:
            String(localized: "error.unknown", bundle: .module)
        }
    }
}
