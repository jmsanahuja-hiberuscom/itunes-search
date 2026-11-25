import SwiftUI

/// Carátula cuadrada (1:1) sobre `AsyncImage`: placeholder con `music.note`,
/// fade-in al cargar y símbolo de fallback si la descarga falla.
/// Es decorativa: el texto que la acompaña ya describe el álbum, así que se oculta a VoiceOver.
struct ArtworkView: View {
    let url: URL?
    var cornerRadius: CGFloat = CornerRadius.small
    var elevation: Elevation = .subtle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Palette.placeholderFill
            .aspectRatio(1, contentMode: .fit)
            .overlay { image }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .elevation(elevation)
            .accessibilityHidden(true)
    }

    private var image: some View {
        AsyncImage(
            url: url,
            transaction: Transaction(animation: reduceMotion ? nil : .easeIn(duration: 0.25))
        ) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            case .failure:
                symbol("exclamationmark.triangle")
            default:
                symbol("music.note")
            }
        }
    }

    /// El símbolo ocupa un 40 % del lado, sea cual sea el tamaño de la carátula.
    private func symbol(_ name: String) -> some View {
        GeometryReader { proxy in
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Palette.placeholderSymbol)
                .frame(width: proxy.size.width * 0.4, height: proxy.size.height * 0.4)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

#Preview("Placeholder y fallo") {
    HStack(spacing: Spacing.m) {
        ArtworkView(url: nil)
            .frame(width: Metrics.rowArtwork)
        ArtworkView(url: URL(string: "invalid://artwork"))
            .frame(width: Metrics.rowArtwork)
        ArtworkView(url: nil, cornerRadius: CornerRadius.large, elevation: .prominent)
            .frame(width: Metrics.rowArtwork * 2)
    }
    .padding(Spacing.l)
}

#Preview("Oscuro", traits: .sizeThatFitsLayout) {
    ArtworkView(url: nil, cornerRadius: CornerRadius.large, elevation: .prominent)
        .frame(width: Metrics.rowArtwork * 3)
        .padding(Spacing.l)
        .background(Palette.background)
        .preferredColorScheme(.dark)
}
