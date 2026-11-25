import Domain
import Foundation

/// Formateo y textos accesibles de álbumes y canciones. Aislado de las vistas para poder testearlo.
enum Formatting {
    /// «3:12», para mostrar en pantalla.
    static func duration(_ duration: Duration, locale: Locale = .current) -> String {
        duration.formatted(Duration.TimeFormatStyle(pattern: .minuteSecond).locale(locale))
    }

    /// «3 minutos, 12 segundos», para VoiceOver (nunca «3:12»).
    static func spokenDuration(_ duration: Duration, locale: Locale = .current) -> String {
        duration.formatted(.units(allowed: [.minutes, .seconds], width: .wide).locale(locale))
    }

    static func year(of date: Date, locale: Locale = .current) -> String {
        date.formatted(.dateTime.year().locale(locale))
    }

    /// «2022 · Reguetón», o nil si no hay ninguno de los dos datos.
    static func metadata(for album: Album, locale: Locale = .current) -> String? {
        let parts = [album.releaseDate.map { year(of: $0, locale: locale) }, album.genre].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// «Género · año · N canciones», para la cabecera del detalle.
    static func headerMetadata(for album: Album, locale: Locale = .current) -> String? {
        var parts = [album.genre, album.releaseDate.map { year(of: $0, locale: locale) }].compactMap { $0 }
        if let count = album.trackCount {
            parts.append(String(localized: "detail.trackCount \(count)", bundle: .module))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// «Un Verano Sin Ti, de Bad Bunny, 2022, Reguetón».
    static func albumAccessibilityLabel(for album: Album, locale: Locale = .current) -> String {
        let format = String(localized: "album.row.accessibilityLabel", bundle: .module)
        let base = String(format: format, album.title, album.artistName)
        guard let metadata = metadata(for: album, locale: locale) else { return base }
        return base + ", " + metadata.replacingOccurrences(of: " · ", with: ", ")
    }

    /// «Pista 3, Título, 3 minutos, 12 segundos».
    static func trackAccessibilityLabel(for track: Track, locale: Locale = .current) -> String {
        let format = String(localized: "track.accessibilityLabel", bundle: .module)
        let base = String(format: format, track.number, track.name)
        guard let duration = track.duration else { return base }
        return base + ", " + spokenDuration(duration, locale: locale)
    }

    static func price(_ price: Decimal, currency: String?, locale: Locale = .current) -> String {
        if let currency {
            return price.formatted(.currency(code: currency).locale(locale))
        }
        return price.formatted(.number.locale(locale))
    }
}
