import Domain

extension Album {
    static func fixture(id: Int = 1, title: String = "Motomami") -> Album {
        Album(id: id, title: title, artistName: "Rosalía")
    }
}
