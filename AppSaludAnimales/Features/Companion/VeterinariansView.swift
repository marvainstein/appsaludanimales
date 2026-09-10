import SwiftData
import SwiftUI

/// Las veterinarias de un compañero.
///
/// Son varias a propósito. La de siempre puede no atender a las tres de la
/// mañana, y la que atiende de urgencia puede no conocer la historia. En una
/// emergencia lo que hace falta no es una lista de opciones cercanas: es el
/// teléfono de la que ya sabés que atiende bien.
///
/// La app llegó a tener un buscador de veterinarias en el mapa y se sacó a
/// propósito. Una lista ordenada por distancia es una recomendación aunque el
/// texto diga que no lo es, y en una emergencia nadie lee el descargo: llama al
/// primero. Los datos del mapa no saben nada sobre el trato ni sobre quién
/// atiende de madrugada. Recomendar a quién llevar un animal enfermo es el
/// consejo más pesado que existe, y esta app no da consejos.
struct VeterinariansView: View {
    let companion: Companion

    @Environment(\.modelContext) private var modelContext

    @State private var editing: Professional?
    @State private var isAdding = false

    private var veterinarians: [Professional] {
        companion.professionals.sorted { lhs, rhs in
            lhs.isPrimaryVeterinarian == rhs.isPrimaryVeterinarian
                ? lhs.createdAt < rhs.createdAt
                : lhs.isPrimaryVeterinarian
        }
    }

    var body: some View {
        List {
            Section {
                if veterinarians.isEmpty {
                    SectionEmptyState(
                        message: String(localized: "Todavía no cargaste ninguna. La primera que agregues aparece en el modo emergencia, lista para llamar.")
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(veterinarians) { professional in
                        Button {
                            editing = professional
                        } label: {
                            row(for: professional)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
            } header: {
                Text("Veterinarias")
                    .foregroundStyle(Palette.inkMuted)
            } footer: {
                Text(veterinarians.isEmpty
                    ? "Guardá las que ya conocés: la de siempre, la que atiende de urgencia, la que queda cerca del trabajo."
                    : "Aparecen en el modo emergencia en este orden, con un botón para llamar. Para borrar una, deslizala hacia la izquierda.")
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                // Un HStack con relleno propio en vez de un `Label` con alto
                // mínimo: adentro del Label el texto queda en una línea que no
                // puede crecer y la auditoría lo marca como recortado con el
                // cuerpo de letra grande. Es la misma forma que usan las
                // opciones del registro rápido, que sí pasan la auditoría.
                Button {
                    isAdding = true
                } label: {
                    HStack(spacing: Spacing.lg) {
                        Image(systemName: "plus")
                            .foregroundStyle(Palette.accent)
                            .frame(width: Spacing.xl)
                            .accessibilityHidden(true)

                        Text("Agregar una veterinaria")
                            .font(AppFont.body)
                            .foregroundStyle(Palette.accent)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, Spacing.sm)
                    .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Agregar una veterinaria"))
                // Al reemplazar el elemento por uno propio se pierde el rasgo
                // de botón, y sin él VoiceOver lee el texto sin decir que se
                // puede tocar.
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("veterinarians.add")
            }
        }
        .navigationTitle(Text("Veterinarias"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isAdding) {
            VeterinarianFormView(companion: companion)
        }
        .sheet(item: $editing) { professional in
            VeterinarianFormView(companion: companion, editing: professional)
        }
    }

    private func row(for professional: Professional) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Text(professional.name)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if professional.isPrimaryVeterinarian {
                    StatusChip(
                        status: StatusBadge(
                            label: String(localized: "De cabecera"),
                            symbolName: "star.fill",
                            tone: .neutral
                        )
                    )
                }
            }

            if let detail = detail(for: professional) {
                Text(detail)
                    .font(AppFont.secondary)
                    .foregroundStyle(Palette.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        // `.combine` no llega a unir el nombre con su detalle adentro de una
        // lista: quedan como dos paradas sueltas de VoiceOver. Con la etiqueta
        // escrita a mano, cada veterinaria es una sola cosa.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel(for: professional)))
        .accessibilityHint(Text("Abre los datos para cambiarlos"))
        .accessibilityAddTraits(.isButton)
    }

    private func accessibilityLabel(for professional: Professional) -> String {
        var parts = [professional.name]

        if professional.isPrimaryVeterinarian {
            parts.append(String(localized: "de cabecera"))
        }

        if let detail = detail(for: professional) {
            parts.append(detail)
        }

        return parts.joined(separator: ", ")
    }

    private func detail(for professional: Professional) -> String? {
        [professional.clinic, professional.phone]
            .compactMap { $0 }
            .first { !$0.isEmpty }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(veterinarians[index])
        }

        try? modelContext.save()
    }
}
