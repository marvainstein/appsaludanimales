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

    static func render(_ report: HealthReport) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "\(report.companionName) · \(report.periodDescription)",
            kCGPDFContextCreator as String: String(localized: "Salud Animal")
        ]

        let bounds = CGRect(origin: .zero, size: pageSize)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds, format: format)

        return renderer.pdfData { context in
            let writer = PageWriter(context: context, bounds: bounds)
            writer.beginPage()

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
