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

    func insert(_ value: Value, for key: Key) {
        entries[key] = Entry(value: value, expiresAt: now().addingTimeInterval(ttl))
    }
}
