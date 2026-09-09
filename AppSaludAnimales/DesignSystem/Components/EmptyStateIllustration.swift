import SwiftUI

/// Dibujo para una pantalla que todavía no tiene nada.
///
/// Son las pantallas del primer día, y son la primera impresión completa de la
/// app. Hoy eran cajas de texto gris apiladas: correctas, informativas y
/// tristes.
///
/// **Estos dibujos son provisorios.** Están hechos con formas geométricas para
/// que se vea dónde va la ilustración y de qué tamaño, y para poder revisarlo en
/// el teléfono en vez de imaginárselo. Cuando existan las ilustraciones de
/// verdad, se reemplaza este archivo y nada más.
///
/// Son decorativos: todo lo que dicen está en el texto de al lado, así que las
/// tecnologías asistivas los ignoran.
struct EmptyStateIllustration: View {
    enum Kind {
        /// El primer día, cuando no hay absolutamente nada cargado.
        case firstDay
        /// El historial sin registros.
        case history
        /// El peso sin mediciones.
        case weight
    }

    let kind: Kind

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 132

    var body: some View {
        Canvas { context, canvasSize in
            switch kind {
            case .firstDay: drawPaw(in: &context, size: canvasSize)
            case .history: drawPages(in: &context, size: canvasSize)
            case .weight: drawLine(in: &context, size: canvasSize)
            }
        }
        .frame(width: size, height: size)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    // MARK: - Los dibujos

    /// La misma huella del ícono, en el tono suave del acento.
    private func drawPaw(in context: inout GraphicsContext, size: CGSize) {
        let unit = min(size.width, size.height)
        let fill = GraphicsContext.Shading.color(Palette.accentSoft)
        let toes = GraphicsContext.Shading.color(Palette.accent.opacity(0.55))

        // Angosta y con los dedos largos, como la pata de una galga. Con los
        // dedos cortos y separados parece la huella de un oso.
        // Las mismas proporciones que el ícono de la app: los dos dedos del
        // medio bien juntos y adelante, los de las puntas más abajo y afuera.
        let toeRects = [
            CGRect(x: 0.16, y: 0.28, width: 0.13, height: 0.24),
            CGRect(x: 0.35, y: 0.13, width: 0.14, height: 0.28),
            CGRect(x: 0.51, y: 0.13, width: 0.14, height: 0.28),
            CGRect(x: 0.71, y: 0.28, width: 0.13, height: 0.24)
        ]

        for rect in toeRects {
            context.fill(Path(ellipseIn: scaled(rect, by: unit)), with: toes)
        }

        let pad = CGRect(x: 0.28, y: 0.50, width: 0.44, height: 0.40)
        context.fill(
            Path(roundedRect: scaled(pad, by: unit), cornerRadius: unit * 0.20),
            with: fill
        )
    }

    /// Tres hojas apiladas, apenas corridas: lo que se va juntando.
    private func drawPages(in context: inout GraphicsContext, size: CGSize) {
        let unit = min(size.width, size.height)
        let shades = [0.35, 0.55, 1.0]

        for (index, shade) in shades.enumerated() {
            let offset = Double(index) * 0.07
            let rect = CGRect(x: 0.18 + offset, y: 0.16 + offset, width: 0.5, height: 0.62)

            context.fill(
                Path(roundedRect: scaled(rect, by: unit), cornerRadius: unit * 0.06),
                with: .color(Palette.accentSoft.opacity(shade))
            )
        }
    }

    /// Una línea con sus puntos: lo que va a dibujar el peso cuando haya datos.
    private func drawLine(in context: inout GraphicsContext, size: CGSize) {
        let unit = min(size.width, size.height)
        let points = [(0.14, 0.66), (0.36, 0.46), (0.58, 0.56), (0.84, 0.32)]
            .map { CGPoint(x: $0.0 * unit, y: $0.1 * unit) }

        var line = Path()
        line.addLines(points)

        context.stroke(
            line,
            with: .color(Palette.accent.opacity(0.55)),
            style: StrokeStyle(lineWidth: unit * 0.045, lineCap: .round, lineJoin: .round)
        )

        for point in points {
            let radius = unit * 0.045
            let dot = CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.fill(Path(ellipseIn: dot), with: .color(Palette.accent.opacity(0.55)))
        }
    }

    private func scaled(_ rect: CGRect, by unit: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX * unit,
            y: rect.minY * unit,
            width: rect.width * unit,
            height: rect.height * unit
        )
    }
}
