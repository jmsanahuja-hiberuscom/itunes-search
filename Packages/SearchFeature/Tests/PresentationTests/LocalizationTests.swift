import Foundation
import Testing

/// El catálogo de strings es la fuente de verdad: cada clave debe estar traducida
/// a es y en, y no puede quedar ninguna sin revisar. Se lee el `.xcstrings` fuente
/// (ruta relativa a este fichero), independiente del idioma del Mac.
struct LocalizationTests {
    private static let languages = ["es", "en"]

    private struct Catalog: Decodable {
        struct Entry: Decodable {
            struct Localization: Decodable {
                struct Unit: Decodable { let state: String?, value: String? }
                struct Variations: Decodable { let plural: [String: Wrapper]? }
                struct Wrapper: Decodable { let stringUnit: Unit }
                let stringUnit: Unit?
                let variations: Variations?
            }
            let localizations: [String: Localization]?
        }
        let strings: [String: Entry]
    }

    private static func loadCatalog() throws -> Catalog {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // PresentationTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // SearchFeature
            .appending(path: "Sources/Presentation/Resources/Localizable.xcstrings")
        return try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
    }

    @Test func catalogIsNotEmpty() throws {
        #expect(try !Self.loadCatalog().strings.isEmpty)
    }

    @Test(arguments: languages)
    func everyKeyIsTranslated(language: String) throws {
        for (key, entry) in try Self.loadCatalog().strings {
            let localization = try #require(
                entry.localizations?[language], "Missing \(language) translation for \(key)"
            )
            let units = [localization.stringUnit].compactMap { $0 }
                + (localization.variations?.plural?.values.map(\.stringUnit) ?? [])
            #expect(!units.isEmpty, "No string unit for \(key) [\(language)]")
            for unit in units {
                #expect(unit.state == "translated", "\(key) [\(language)] is not translated")
                #expect(unit.value?.isEmpty == false, "\(key) [\(language)] is empty")
            }
        }
    }
}
