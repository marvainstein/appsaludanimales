import SwiftUI

/// El fondo de quien cruzó el arcoíris: celeste con un arco de colores detrás.
///
/// El arco va difuminado y por debajo de todo: tiene que sentirse como una luz
/// en el fondo y no como un adorno pegado encima. Los colores están apagados a
/// propósito, porque es un recuerdo y no una celebración.
///
/// En modo oscuro el celeste se vuelve un azul profundo, con la misma relación
/// clara-oscura que el fondo normal de la app. Por eso los colores de texto de
/// siempre se siguen leyendo encima, y hay pruebas que lo verifican.
struct FarewellBackground: View {
    var glowHeight: CGFloat = 160
    var glowOffset: CGFloat = -60

    var body: some View {
        ZStack(alignment: .top) {
            Palette.farewellCard

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: Palette.rainbow,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: glowHeight)
                .blur(radius: glowHeight / 4)
                .opacity(0.55)
                .offset(y: glowOffset)
        }
    }
}
