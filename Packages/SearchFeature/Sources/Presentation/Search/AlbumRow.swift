import Domain
import SwiftUI

/// Fila de resultado. Un único elemento para VoiceOver; con tamaños de accesibilidad
/// el artwork pasa encima del texto y el título deja de truncarse.
struct AlbumRow: View {
    let album: Album

    @ScaledMetric(relativeTo: .body) private var artworkSize = Metrics.rowArtwork
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        AdaptiveStack {
            ArtworkView(url: album.artworkURL)
                .frame(width: artworkSize)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(album.title)
                    .font(.headline)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                Text(album.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let metadata = Formatting.metadata(for: album) {
                    Text(metadata)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Formatting.albumAccessibilityLabel(for: album))
        .accessibilityHint(Text("album.row.accessibilityHint", bundle: .module))
    }
}

#if DEBUG
#Preview("Fila") {
    AlbumRow(album: PreviewData.album)
        .padding(Spacing.m)
}

#Preview("Fila · oscuro · accesibilidad 3") {
    AlbumRow(album: PreviewData.album)
        .padding(Spacing.m)
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
