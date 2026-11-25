import Data
import Domain
import Presentation

/// Único sitio que conoce las tres capas. El grafo real de dependencias se monta en la fase 5.
enum CompositionRoot {
    static let layers = [DomainModule.name, DataModule.name, PresentationModule.name]
}
