import Foundation

/// Caché en memoria con TTL.
///
/// Es un `actor` para serializar el acceso desde búsquedas concurrentes. El reloj se
/// inyecta (`now`) para poder testear la expiración sin esperas reales.
actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {
    static var defaultTTL: TimeInterval { 180 }

    private struct Entry {
        let value: Value
        let expiresAt: Date
    }

    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private var entries: [Key: Entry] = [:]

    init(ttl: TimeInterval = InMemoryCache.defaultTTL, now: @escaping @Sendable () -> Date = Date.init) {
        self.ttl = ttl
        self.now = now
    }

    /// Devuelve `nil` si no existe o ha expirado (y en ese caso elimina la entrada).
    func value(for key: Key) -> Value? {
        guard let entry = entries[key] else { return nil }
        guard now() < entry.expiresAt else {
            entries[key] = nil
            return nil
        }
        return entry.value
    }

    /// Al insertar se purgan todas las entradas caducadas, para que las queries que
    /// no se vuelven a pedir no se queden en memoria durante toda la sesión.
    func insert(_ value: Value, for key: Key) {
        let current = now()
        entries = entries.filter { current < $0.value.expiresAt }
        entries[key] = Entry(value: value, expiresAt: current.addingTimeInterval(ttl))
    }

    /// Número de entradas guardadas (las caducadas cuentan hasta que se purgan). Para tests.
    var count: Int { entries.count }
}
