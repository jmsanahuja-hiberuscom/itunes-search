import Domain
import SwiftUI

/// Detalle de álbum: hero, información y canciones. En horizontal, dos columnas.
struct AlbumDetailView: View {
    @State private var viewModel: AlbumDetailViewModel

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: AlbumDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            // Con texto de accesibilidad, dos columnas en horizontal no caben: una sola columna.
            if verticalSizeClass == .compact && !dynamicTypeSize.isAccessibilitySize {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .background(Palette.background)
        .navigationTitle(viewModel.album.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if let url = loadedDetail?.storeURL {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: url,
                        subject: Text(viewModel.album.title),
                        message: Text(verbatim: "\(viewModel.album.title) · \(viewModel.album.artistName)")
                    )
                    .accessibilityIdentifier("share-button")
                }
            }
        }
        .motionSafeAnimation(value: viewModel.state)
        .task { await viewModel.load() }
    }

    private var loadedDetail: AlbumDetail? {
        if case .loaded(let detail) = viewModel.state { detail } else { nil }
    }

    // MARK: - Layouts

    private var portraitLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                AlbumHero(album: viewModel.album, widthFraction: 0.7)
                details
            }
            .padding(Spacing.m)
        }
    }

    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                AlbumHero(album: viewModel.album, widthFraction: 0.8)
                    .padding(Spacing.m)
            }
            ScrollView {
                details.padding(Spacing.m)
            }
        }
    }

    @ViewBuilder
    private var details: some View {
        switch viewModel.state {
        case .idle, .loading, .empty:
            SkeletonDetail()
        case .loaded(let detail):
            VStack(alignment: .leading, spacing: Spacing.l) {
                if let url = detail.storeURL {
                    OpenInAppleMusicButton(url: url)
                }
                InfoSection(detail: detail)
                TracksSection(tracks: detail.tracks)
            }
            .transition(.opacity)
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.retry() }
            }
        }
    }
}

// MARK: - Subviews

private struct AlbumHero: View {
    let album: Album
    let widthFraction: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: Spacing.m) {
            ArtworkView(url: album.artworkURL, cornerRadius: CornerRadius.large, elevation: .prominent)
                .containerRelativeFrame(.horizontal) { width, _ in
                    min(width * widthFraction, Metrics.heroArtworkMax)
                }
            VStack(spacing: Spacing.xxs) {
                Text(album.title)
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(album.artistName)
                    .font(.title3)
                    .foregroundStyle(.tint)
                if let metadata = Formatting.headerMetadata(for: album) {
                    Text(metadata)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct OpenInAppleMusicButton: View {
    let url: URL

    var body: some View {
        Link(destination: url) {
            Label {
                Text("detail.openInAppleMusic", bundle: .module)
            } icon: {
                Image(systemName: "arrow.up.forward.app")
            }
            .frame(maxWidth: .infinity, minHeight: Metrics.minTapTarget)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("open-apple-music")
        .accessibilityInputLabels([
            String(localized: "detail.openInAppleMusic", bundle: .module),
            "Apple Music",
        ])
    }
}

private struct SectionHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title, bundle: .module)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct InfoSection: View {
    let detail: AlbumDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: "detail.info.title")
            VStack(alignment: .leading, spacing: Spacing.s) {
                if let price = detail.price {
                    row("detail.info.price", Formatting.price(price, currency: detail.currency))
                }
                if let date = detail.album.releaseDate {
                    row("detail.info.releaseDate", date.formatted(date: .long, time: .omitted))
                }
                if let country = detail.country {
                    row("detail.info.country", country)
                }
                if let copyright = detail.copyright {
                    row("detail.info.copyright", copyright)
                }
            }
            .cardStyle()
        }
    }

    private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
        LabeledContent {
            Text(value)
        } label: {
            Text(title, bundle: .module)
        }
    }
}

private struct TracksSection: View {
    let tracks: [Track]

    @ScaledMetric(relativeTo: .body) private var numberWidth = Spacing.l

    var body: some View {
        if !tracks.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SectionHeader(title: "detail.tracks.title")
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(tracks) { track in
                        TrackRow(track: track, numberWidth: numberWidth)
                    }
                }
                .cardStyle()
            }
        }
    }
}

/// Fila de canción. Con tamaños de accesibilidad la duración pasa debajo del título
/// para que ninguno de los dos se trunque.
private struct TrackRow: View {
    let track: Track
    let numberWidth: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                        number
                        Text(track.name)
                    }
                    duration
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    number
                    Text(track.name)
                    Spacer(minLength: Spacing.xs)
                    duration
                }
            }
        }
        .font(.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Formatting.trackAccessibilityLabel(for: track))
    }

    private var number: some View {
        Text(track.number, format: .number)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .frame(minWidth: numberWidth, alignment: .trailing)
    }

    @ViewBuilder
    private var duration: some View {
        if let duration = track.duration {
            Text(Formatting.duration(duration))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

private struct SkeletonDetail: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ForEach(0..<4, id: \.self) { _ in
                Text(verbatim: "Placeholder information row")
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .skeleton(label: "skeleton.loading.detail", identifier: "loading-skeleton")
    }
}

#if DEBUG
@MainActor
private func previewDetail(
    useCase: some GetAlbumDetailUseCase = PreviewGetAlbumDetail()
) -> some View {
    NavigationStack {
        AlbumDetailView(
            viewModel: AlbumDetailViewModel(album: PreviewData.album, getAlbumDetail: useCase)
        )
    }
}

#Preview("Detalle · iPhone SE (3.ª gen)", traits: .fixedLayout(width: 375, height: 667)) { previewDetail() }
#Preview("Detalle · iPhone 16", traits: .fixedLayout(width: 393, height: 852)) { previewDetail() }
#Preview("Detalle · iPhone 16 Pro Max", traits: .fixedLayout(width: 440, height: 956)) { previewDetail() }
#Preview("Detalle · oscuro") { previewDetail().preferredColorScheme(.dark) }
#Preview("Detalle · accesibilidad 3") {
    previewDetail().environment(\.dynamicTypeSize, .accessibility3)
}
#Preview("Detalle · horizontal", traits: .landscapeLeft) { previewDetail() }
#Preview("Detalle · horizontal · accesibilidad 5", traits: .landscapeLeft) {
    previewDetail().environment(\.dynamicTypeSize, .accessibility5)
}
#Preview("Detalle · oscuro · accesibilidad 5") {
    previewDetail().preferredColorScheme(.dark).environment(\.dynamicTypeSize, .accessibility5)
}
#Preview("Detalle · cargando") { previewDetail(useCase: PreviewNeverFinishes()) }
#Preview("Detalle · error") {
    previewDetail(useCase: PreviewGetAlbumDetail(result: .failure(.network)))
}
#endif
