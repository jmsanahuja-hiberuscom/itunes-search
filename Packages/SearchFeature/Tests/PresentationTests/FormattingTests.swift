import Domain
import Foundation
import Testing
@testable import Presentation

struct FormattingTests {
    private let en = Locale(identifier: "en_US")
    private let utc = Date(timeIntervalSince1970: 1_653_868_800) // 2022-05-30 UTC

    @Test func durationIsShownAsMinutesAndSeconds() {
        #expect(Formatting.duration(.seconds(192), locale: en) == "3:12")
    }

    @Test func spokenDurationUsesWideUnitsNeverClockFormat() {
        let spoken = Formatting.spokenDuration(.seconds(192), locale: en)
        #expect(spoken.contains("3 minutes"))
        #expect(spoken.contains("12 seconds"))
        #expect(!spoken.contains(":"))
    }

    @Test func metadataJoinsYearAndGenre() {
        let album = Album(id: 1, title: "T", artistName: "A", genre: "Pop", releaseDate: utc)
        #expect(Formatting.metadata(for: album, locale: en) == "2022 · Pop")
    }

    @Test func metadataIsNilWithoutYearNorGenre() {
        let album = Album(id: 1, title: "T", artistName: "A")
        #expect(Formatting.metadata(for: album, locale: en) == nil)
    }

    @Test func priceUsesCurrencyCodeWhenAvailable() {
        #expect(Formatting.price(9.99, currency: "USD", locale: en) == "$9.99")
    }

    @Test func trackLabelIncludesNumberNameAndSpokenDuration() {
        let track = Track(id: 1, number: 3, name: "Song", duration: .seconds(192))
        let label = Formatting.trackAccessibilityLabel(for: track, locale: en)
        #expect(label.contains("3"))
        #expect(label.contains("Song"))
        #expect(label.contains("12"))
    }

    @Test func albumLabelContainsTitleArtistYearAndGenre() {
        let album = Album(id: 1, title: "Motomami", artistName: "Rosalía", genre: "Pop", releaseDate: utc)
        let label = Formatting.albumAccessibilityLabel(for: album, locale: en)
        for part in ["Motomami", "Rosalía", "2022", "Pop"] {
            #expect(label.contains(part))
        }
    }
}
