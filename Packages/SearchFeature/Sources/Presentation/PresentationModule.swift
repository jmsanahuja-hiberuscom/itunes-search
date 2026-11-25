import Domain
import Foundation

/// Marcador de la capa Presentation. Se sustituye por los ViewModels y vistas en las fases 4 y 5.
public enum PresentationModule {
    public static let name = "Presentation"
    public static let domain = DomainModule.name
}
