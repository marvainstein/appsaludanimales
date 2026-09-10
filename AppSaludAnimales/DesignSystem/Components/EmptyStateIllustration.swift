import SwiftUI

/// Dibujo para una pantalla que todavía no tiene nada.
///
/// Son las pantallas del primer día, y son la primera impresión completa de la
/// app. Hoy eran cajas de texto gris apiladas: correctas, informativas y
/// tristes.
///
/// **Estos dibujos son los definitivos**, decidido en septiembre de 2026 después
/// de mirarlos en el teléfono. Se habían anotado como provisorios cuando eran
/// formas puestas para ver dónde iba la ilustración y de qué tamaño, pero dos
/// cosas cambiaron esa etiqueta.
///
/// La huella dejó de ser un relleno: usa `PawPath`, la misma geometría que el
/// ícono de la app y que el membrete del PDF. No es un dibujo esperando a otro
/// mejor, es la marca dibujada una sola vez y usada en tres lugares.
///
/// Y las pantallas, miradas de verdad, no se ven vacías: la de bienvenida se ve
/// una sola vez, la de carga está completa, y la del primer día tiene su dibujo,
/// su título y su explicación. Encargar ilustraciones a alguien cuesta plata en
/// una app que va a ser gratis para siempre, y no había un problema que
/// resolvieran. Si alguna vez alguien dice que estas pantallas se sienten frías,
/// el encargo está escrito en docs/ilustraciones.md.
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
    ///
    /// La forma sale de `PawPath`, que es la misma que dibuja el membrete del
    /// PDF. Los dedos y la almohadilla van del mismo tono porque en el ícono
    /// son del mismo color: con la almohadilla más clara se leían como dos
    /// dibujos pegados en vez de una huella.
    private func drawPaw(in context: inout GraphicsContext, size: CGSize) {
        let unit = min(size.width, size.height)
        let ink = GraphicsContext.Shading.color(Palette.accent.opacity(0.55))

        context.fill(Path(PawPath.pad(side: unit)), with: ink)

        for toe in PawPath.toes(side: unit) {
            context.fill(Path(toe), with: ink)
        }
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
