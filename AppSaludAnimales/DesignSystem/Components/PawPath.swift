import CoreGraphics
import Foundation

/// La huella del ícono, dibujada dentro de un cuadrado.
///
/// Vive en un solo lugar porque la usan dos cosas que no se ven entre sí: la
/// ilustración de las pantallas vacías y el membrete del PDF. Con una copia en
/// cada una, el primer retoque las separaba y la app pasaba a tener dos huellas
/// parecidas, que es peor que tener una sola imperfecta.
///
/// Las proporciones salen del ícono: la almohadilla es un triángulo redondeado
/// —ancha abajo, angosta arriba— y no un círculo, que es lo que la hacía
/// parecer la huella de un oso. Los cuatro dedos son óvalos inclinados hacia
/// afuera: los dos del medio altos y casi derechos, los de las puntas más
/// chicos, más abajo y bien volcados.
enum PawPath {
    /// La almohadilla.
    static func pad(side: CGFloat) -> CGPath {
        let path = CGMutablePath()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * side, y: y * side)
        }

        path.move(to: point(0.500, 0.400))
        path.addCurve(
            to: point(0.225, 0.720),
            control1: point(0.385, 0.405),
            control2: point(0.288, 0.545)
        )
        path.addCurve(
            to: point(0.500, 0.875),
            control1: point(0.200, 0.820),
            control2: point(0.310, 0.875)
        )
        path.addCurve(
            to: point(0.775, 0.720),
            control1: point(0.690, 0.875),
            control2: point(0.800, 0.820)
        )
        path.addCurve(
            to: point(0.500, 0.400),
            control1: point(0.712, 0.545),
            control2: point(0.615, 0.405)
        )
        path.closeSubpath()

        return path
    }

    /// Los cuatro dedos, de izquierda a derecha.
    static func toes(side: CGFloat) -> [CGPath] {
        // Centro, tamaño e inclinación de cada uno, en proporción del lado.
        let toes: [(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, degrees: CGFloat)] = [
            (0.205, 0.437, 0.171, 0.225, -25),
            (0.390, 0.259, 0.171, 0.254, -8),
            (0.625, 0.259, 0.161, 0.244, 5),
            (0.797, 0.447, 0.166, 0.220, 28)
        ]

        return toes.map { toe in
            let oval = CGRect(
                x: -toe.width * side / 2,
                y: -toe.height * side / 2,
                width: toe.width * side,
                height: toe.height * side
            )

            var transform = CGAffineTransform(
                translationX: toe.x * side,
                y: toe.y * side
            )
            .rotated(by: toe.degrees * .pi / 180)

            return CGPath(ellipseIn: oval, transform: &transform)
        }
    }
}
