# iTunes Search

App iOS (SwiftUI, Swift 6, iOS 17, solo iPhone) para buscar álbumes y ver su detalle.

<img src="docs/images/search-empty.png" alt="Pantalla de búsqueda" width="240">

## API elegida

[iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/): pública, sin clave ni registro.

- Búsqueda: `https://itunes.apple.com/search?media=music&entity=album&term=<query>`
- Detalle: `https://itunes.apple.com/lookup?id=<id>&entity=song`

## Cómo ejecutarla

Requisitos: Xcode 16 o superior.

1. Abrir `iTunesSearch.xcodeproj`.
2. Elegir el esquema `iTunesSearch` y un simulador iPhone con iOS 17 o superior.
3. Run (`Cmd+R`).

Para probar sin depender de la API, lanzar con el argumento `-UITestMockData` (en el esquema: Edit Scheme > Run > Arguments): usa datos locales.

## Tests

```bash
# Domain y Data (rápidos, sin simulador)
cd Packages/SearchFeature && swift test --filter "DomainTests|DataTests"

# Todos los tests unitarios (plan iTunesSearch)
xcodebuild test -project iTunesSearch.xcodeproj -scheme iTunesSearch \
  -testPlan iTunesSearch -destination 'platform=iOS Simulator,name=iPhone 16'
```

Los tests unitarios no usan red ni `sleep`: el reloj de la caché y el debounce se inyectan.

## Arquitectura

Paquete local `Packages/SearchFeature` con tres targets, cada uno con su target de tests:

| Capa | Contenido | Depende de |
|---|---|---|
| `Domain` | Entidades, protocolos de repositorio, casos de uso | nada |
| `Data` | Cliente HTTP, DTOs y mappers, repositorio, caché | `Domain` |
| `Presentation` | ViewModels y vistas SwiftUI | `Domain` |

`Presentation` no puede importar `Data`: el compilador lo impide. Quien conecta las capas es el composition root de la app (`App/CompositionRoot.swift`).

## Decisiones principales

**Cancelación.** `SearchViewModel` guarda la `Task` de la búsqueda en curso. Cada cambio de texto cancela la anterior antes de lanzar la nueva (con un debounce de 300 ms), y una tarea cancelada nunca escribe su resultado en el estado, aunque el caso de uso lo haya devuelto. Hay un test determinista que lo comprueba sin esperas reales.

**Caché.** Caché en memoria por query (normalizada), con TTL de 3 minutos, dentro de `Data`.
- Si hay una entrada válida, se devuelve sin llamar a la red.
- Si ha expirado, se pide a la red y se actualiza la caché.
- Es un `actor` para serializar accesos concurrentes y recibe el reloj por inyección, así los tests de expiración no esperan tiempo real.

**Estados de pantalla.** Inicial, cargando, vacío, error (con reintento) y resultados, modelados con un único `ViewState`.

**Accesibilidad y localización.** Dynamic Type hasta `accessibility5`, Reducir movimiento y VoiceOver; textos en español e inglés en un único String Catalog. La app no usa materiales ni transparencias, así que Reducir transparencia no tiene nada que adaptar.
