import Foundation
import Testing
@testable import Presentation

/// Comprueba que cada clave del design system está traducida a es y en,
/// leyendo las tablas compiladas del bundle (independiente del idioma del Mac).
struct LocalizationTests {
    private static let designSystemKeys = [
        "skeleton.loading.results",
        "state.error.title",
        "state.error.retry",
        "state.error.retry.alt",
    ]

    @Test(arguments: ["es", "en"], designSystemKeys)
    func keyIsTranslated(language: String, key: String) throws {
        let path = try #require(
            Bundle.module.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language),
            "Missing \(language) strings table"
        )
        let table = try #require(NSDictionary(contentsOfFile: path) as? [String: String])
        let value = try #require(table[key], "Missing \(language) translation for \(key)")
        #expect(!value.isEmpty)
    }
}
