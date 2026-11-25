import Domain
import Foundation

/// Marcador de la capa Data. Se sustituye por el cliente HTTP y la caché en la fase 3.
public enum DataModule {
    public static let name = "Data"
    public static let domain = DomainModule.name
}
