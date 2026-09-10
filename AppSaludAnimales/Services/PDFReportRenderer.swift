import Foundation
import UIKit

/// Genera el PDF del resumen.
///
/// Dibuja texto de verdad, no una captura de pantalla: el resultado se puede
/// seleccionar, copiar y buscar, y las tecnologías asistivas pueden leerlo. El
/// orden de dibujo es el orden de lectura.
enum PDFReportRenderer {
    /// A4, que es el tamaño con el que se imprime acá.
    static let pageSize = CGSize(width: 595.2, height: 841.8)
    static let margin: CGFloat = 48

    /// El membrete, arriba a la derecha y por encima de todo lo demás.
    ///
    /// Este papel termina en la mano de un veterinario, muchas veces impreso y
    /// muchas veces junto a otros. Que diga de dónde salió es lo que lo vuelve
    /// reconocible la segunda vez, y es la única forma de difusión que la app
    /// tiene sin molestar a nadie: aparece en un papel que alguien eligió
    /// compartir.
    ///
    /// Devuelve dónde termina, para que el contenido arranque abajo. Antes se
    /// dibujaba a la misma altura que el nombre del animal y los dos quedaban
    /// pisándose en el borde de la hoja.
    private static func drawLetterhead(in bounds: CGRect) -> CGFloat {
        let prefix = String(localized: "Informe generado por")
        let name = String(localized: "Estela")
        let tagline = String(localized: "La historia de su salud en un solo lugar")
        let invitation = String(localized: "Descargala gratis en el App Store")

        let prefixFont = UIFont.systemFont(ofSize: 11, weight: .regular)
        let nameFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let taglineFont = UIFont.systemFont(ofSize: 9, weight: .regular)

        let prefixAttributes: [NSAttributedString.Key: Any] = [
            .font: prefixFont,
            .foregroundColor: UIColor.darkGray
        ]

        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: brand
        ]

        let taglineAttributes: [NSAttributedString.Key: Any] = [
            .font: taglineFont,
            .foregroundColor: UIColor.darkGray
        ]

        let invitationAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
            .foregroundColor: UIColor.gray
        ]

        let prefixSize = (prefix as NSString).size(withAttributes: prefixAttributes)
        let nameSize = (name as NSString).size(withAttributes: nameAttributes)
        let taglineSize = (tagline as NSString).size(withAttributes: taglineAttributes)
        let invitationSize = (invitation as NSString).size(withAttributes: invitationAttributes)

        let paw: CGFloat = 15
        let gap: CGFloat = 5
        let right = bounds.maxX - margin
        let top = margin
        let lineWidth = prefixSize.width + gap + paw + gap + nameSize.width
        var x = right - lineWidth

        // Todo apoyado en la misma línea de base: el prefijo es más chico que
        // el nombre, así que sin esto flotaría.
        (prefix as NSString).draw(
            at: CGPoint(x: x, y: top + nameFont.ascender - prefixFont.ascender),
            withAttributes: prefixAttributes
        )
        x += prefixSize.width + gap

        drawPaw(at: CGPoint(x: x, y: top + (nameSize.height - paw) / 2), side: paw)
        x += paw + gap

        (name as NSString).draw(at: CGPoint(x: x, y: top), withAttributes: nameAttributes)

        let taglineY = top + nameSize.height + 1
        (tagline as NSString).draw(
            at: CGPoint(x: right - taglineSize.width, y: taglineY),
            withAttributes: taglineAttributes
        )

        // La única invitación que la app hace, y la hace en un papel que alguien
        // eligió compartir. Más chica y más gris que el lema: está para quien
        // sostiene la hoja y se pregunta de dónde salió, no para interrumpir a
        // quien la está leyendo por otra cosa.
        let invitationY = taglineY + taglineSize.height + 3
        (invitation as NSString).draw(
            at: CGPoint(x: right - invitationSize.width, y: invitationY),
            withAttributes: invitationAttributes
        )

        return invitationY + invitationSize.height
    }

    /// La huella del ícono, dibujada con las mismas formas que la ilustración
    /// de las pantallas vacías.
    ///
    /// Se dibuja en vez de usar un símbolo del sistema porque el símbolo salía
    /// como un cuadrado lleno en el PDF, y porque la huella de la app no es la
    /// de Apple.
    private static func drawPaw(at origin: CGPoint, side: CGFloat) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()
        context.translateBy(x: origin.x, y: origin.y)
        context.setFillColor(brand.cgColor)

        context.addPath(PawPath.pad(side: side))

        for toe in PawPath.toes(side: side) {
            context.addPath(toe)
        }

        context.fillPath()
        context.restoreGState()
    }

    /// El terracota de la app, en el mismo valor que PaletteValues.
    private static let brand = UIColor(red: 0xA0 / 255, green: 0x47 / 255, blue: 0x2C / 255, alpha: 1)

    static func render(_ report: HealthReport) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(report.companionName) · \(report.periodDescription)",
            kCGPDFContextCreator as String: String(localized: "Estela")
        ]

        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        return renderer.pdfData { context in
            let writer = PageWriter(context: context, bounds: bounds)
            writer.beginPage()
            writer.moveBelow(drawLetterhead(in: bounds), padding: 28)

            writer.draw(report.companionName, style: .title)
            writer.draw(report.subtitle, style: .subtitle)
            writer.draw(report.periodDescription, style: .subtitle)
            writer.draw(
                String(localized: "Generado el \(DateDescription.absolute(report.generatedOn))"),
                style: .caption
            )

            for section in report.sections {
                writer.space(20)
                writer.draw(section.title, style: .heading)

                for line in section.lines {
                    writer.draw(line.text, style: .body)

                    if let detail = line.detail, !detail.isEmpty {
                        writer.draw(detail, style: .detail)
                    }

                    writer.space(6)
                }
            }

            writer.space(24)
            writer.draw(
                String(localized: "Este resumen reúne únicamente la información registrada por la persona responsable. No constituye un diagnóstico ni reemplaza la evaluación de un profesional."),
                style: .caption
            )
        }
    }
}

/// Lleva la cuenta de dónde va el próximo bloque y abre una página nueva cuando
/// hace falta. Sin esto, el texto largo se corta en el borde de la hoja.
private final class PageWriter {
    enum Style {
        case title
        case subtitle
        case heading
        case body
        case detail
        case caption

        var font: UIFont {
            switch self {
            case .title: .systemFont(ofSize: 24, weight: .bold)
            case .subtitle: .systemFont(ofSize: 13, weight: .regular)
            case .heading: .systemFont(ofSize: 15, weight: .semibold)
            case .body: .systemFont(ofSize: 12, weight: .medium)
            case .detail: .systemFont(ofSize: 11, weight: .regular)
            case .caption: .systemFont(ofSize: 9, weight: .regular)
            }
        }

        var color: UIColor {
            switch self {
            case .title, .heading, .body: .black
            case .subtitle, .detail: .darkGray
            case .caption: .gray
            }
        }

        var spacingAfter: CGFloat {
            switch self {
            case .title: 4
            case .heading: 8
            default: 2
            }
        }
    }

    private let context: UIGraphicsPDFRendererContext
    private let bounds: CGRect
    private var cursor: CGFloat = 0

    private var contentWidth: CGFloat {
        bounds.width - PDFReportRenderer.margin * 2
    }

    private var maximumY: CGFloat {
        bounds.height - PDFReportRenderer.margin
    }

    init(context: UIGraphicsPDFRendererContext, bounds: CGRect) {
        self.context = context
        self.bounds = bounds
    }

    func beginPage() {
        context.beginPage()
        cursor = PDFReportRenderer.margin
    }

    func space(_ amount: CGFloat) {
        cursor += amount
    }

    /// Baja el cursor por debajo de algo ya dibujado, como el membrete. No sube
    /// nunca: si el contenido ya iba más abajo, se queda donde estaba.
    func moveBelow(_ y: CGFloat, padding: CGFloat) {
        cursor = max(cursor, y + padding)
    }

    func draw(_ text: String, style: Style) {
        guard !text.isEmpty else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: style.font,
            .foregroundColor: style.color
        ]

        let attributed = NSAttributedString(string: text, attributes: attributes)
        let constraint = CGSize(width: contentWidth, height: .greatestFiniteMagnitude)
        let size = attributed.boundingRect(
            with: constraint,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size

        if cursor + size.height > maximumY {
            beginPage()
        }

        attributed.draw(
            with: CGRect(
                x: PDFReportRenderer.margin,
                y: cursor,
                width: contentWidth,
                height: ceil(size.height)
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )

        cursor += ceil(size.height) + style.spacingAfter
    }
}
