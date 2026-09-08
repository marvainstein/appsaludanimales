import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Alta y edición de un compañero.
///
/// El mismo formulario sirve para el primer alta durante la bienvenida y para
/// editar después. En la bienvenida solo se piden cuatro cosas; el resto puede
/// completarse cuando la persona quiera.
struct CompanionFormView: View {
    enum Mode {
        case onboarding
        case create
        case edit(Companion)

        /// En la bienvenida se piden cuatro cosas y nada más. Todo lo demás
        /// aparece recién cuando la persona vuelve a editar.
        var showsOptionalDetails: Bool {
            switch self {
            case .onboarding: false
            case .create, .edit: true
            }
        }

        /// La bienvenida no se cierra sola: al guardar, la app ya muestra el
        /// dashboard del compañero recién creado.
        var dismissesAfterSaving: Bool {
            switch self {
            case .onboarding: false
            case .create, .edit: true
            }
        }

        var title: String {
            switch self {
            case .onboarding: String(localized: "Tu compañero")
            case .create: String(localized: "Nuevo compañero")
            case .edit: String(localized: "Editar")
            }
        }

        var saveTitle: String {
            switch self {
            case .onboarding: String(localized: "Empezar")
            case .create: String(localized: "Agregar compañero")
            case .edit: String(localized: "Guardar cambios")
            }
        }
    }

    let mode: Mode
    var onSaved: (Companion) -> Void = { _ in }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var nickname = ""
    @State private var species: Species = .dog
    @State private var breed = ""
    @State private var sex: Sex = .unknown
    @State private var birthDatePrecision: BirthDatePrecision = .unknown
    @State private var birthDate = Date()
    @State private var photoData: Data?
    @State private var photoDescription = ""
    @State private var relevantConditions = ""
    @State private var allergies = ""

    @State private var photoItem: PhotosPickerItem?
    @State private var saveErrorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            photoSection
            basicsSection
            birthdaySection

            if mode.showsOptionalDetails {
                detailsSection
            }

            saveSection
        }
        .navigationTitle(Text(mode.title))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExistingCompanion)
        .onChange(of: photoItem) { _, newItem in
            loadPhoto(from: newItem)
        }
        .alert(
            Text("No pudimos guardar"),
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("Entendido", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    // MARK: - Secciones

    private var photoSection: some View {
        Section {
            VStack(spacing: Spacing.md) {
                photoPreview

                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    Label {
                        Text(photoData == nil ? "Elegir una foto" : "Cambiar la foto")
                    } icon: {
                        Image(systemName: "photo")
                    }
                }
                .buttonStyle(.bordered)

                if photoData != nil {
                    Button(role: .destructive) {
                        photoData = nil
                        photoItem = nil
                        photoDescription = ""
                    } label: {
                        Text("Quitar la foto")
                    }
                    .font(AppFont.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)

            if photoData != nil {
                LabeledTextField(
                    label: String(localized: "Descripción de la foto"),
                    text: $photoDescription,
                    hint: String(localized: "Se lee en voz alta para quienes no ven la foto. Por ejemplo: “Luli, galga negra y blanca, echada en el pasto”.")
                )
            }
        } header: {
            Text("Foto")
        }
    }

    private var photoPreview: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .accessibilityLabel(Text(photoDescription.isEmpty
                        ? String(localized: "Foto elegida")
                        : photoDescription))
            } else {
                Image(systemName: species.symbolName)
                    .font(AppFont.heroSymbol)
                    .foregroundStyle(Palette.onAccentSoft)
                    .frame(width: 120, height: 120)
                    .background(Palette.accentSoft)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }
        }
    }

    private var basicsSection: some View {
        Section {
            LabeledTextField(
                label: String(localized: "Nombre"),
                text: $name,
                isRequired: true,
                autocapitalization: .words
            )

            Picker(selection: $species) {
                ForEach(Species.allCases, id: \.self) { species in
                    Text(species.label).tag(species)
                }
            } label: {
                Text("Especie")
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text("Especie"))

            if mode.showsOptionalDetails {
                LabeledTextField(
                    label: String(localized: "Apodo"),
                    text: $nickname,
                    hint: String(localized: "Cómo le decís todos los días."),
                    autocapitalization: .words
                )
            }
        } header: {
            Text("Datos básicos")
        }
    }

    private var birthdaySection: some View {
        Section {
            Picker(selection: $birthDatePrecision) {
                ForEach(BirthDatePrecision.allCases, id: \.self) { precision in
                    Text(precision.label).tag(precision)
                }
            } label: {
                Text("Qué sabés de la fecha")
            }

            if birthDatePrecision != .unknown {
                DatePicker(
                    selection: $birthDate,
                    in: ...Date(),
                    displayedComponents: .date
                ) {
                    Text("Fecha de cumpleaños")
                }
            }

            if let explanation = birthDatePrecision.explanation {
                Text(explanation)
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
            }
        } header: {
            Text("Cumpleaños")
        } footer: {
            Text("Muchos compañeros llegan sin fecha exacta. Una fecha estimada sirve igual, y la app la muestra siempre como aproximada.")
        }
    }

    private var detailsSection: some View {
        Section {
            LabeledTextField(
                label: String(localized: "Raza"),
                text: $breed,
                autocapitalization: .words
            )

            Picker(selection: $sex) {
                ForEach(Sex.allCases, id: \.self) { sex in
                    Text(sex.label).tag(sex)
                }
            } label: {
                Text("Sexo")
            }

            LabeledTextField(
                label: String(localized: "Condiciones relevantes"),
                text: $relevantConditions,
                hint: String(localized: "Lo que un veterinario debería saber enseguida.")
            )

            LabeledTextField(
                label: String(localized: "Alergias"),
                text: $allergies
            )
        } header: {
            Text("Más información")
        } footer: {
            Text("Todo esto es opcional y podés completarlo cuando quieras.")
        }
    }

    private var saveSection: some View {
        PrimaryButtonSection(
            title: mode.saveTitle,
            hint: canSave ? nil : String(localized: "Completá el nombre para poder continuar"),
            isEnabled: canSave,
            action: save
        )
    }

    // MARK: - Acciones

    private func loadExistingCompanion() {
        guard case let .edit(companion) = mode, name.isEmpty else { return }

        name = companion.name
        nickname = companion.nickname ?? ""
        species = companion.species
        breed = companion.breed ?? ""
        sex = companion.sex
        birthDatePrecision = companion.birthDatePrecision
        birthDate = companion.birthDate ?? Date()
        photoData = companion.photoData
        photoDescription = companion.photoAccessibilityDescription ?? ""
        relevantConditions = companion.relevantConditions ?? ""
        allergies = companion.allergies ?? ""
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photoData = data
            } else {
                saveErrorMessage = String(localized: "No pudimos usar esa imagen. Podés intentar con otra.")
            }
        }
    }

    private func save() {
        let companion: Companion

        switch mode {
        case let .edit(existing):
            companion = existing
        case .onboarding, .create:
            companion = Companion()
            modelContext.insert(companion)
        }

        companion.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        companion.nickname = optional(nickname)
        companion.species = species
        companion.breed = optional(breed)
        companion.sex = sex
        companion.birthDatePrecision = birthDatePrecision
        companion.birthDate = birthDatePrecision.normalized(birthDate)
        companion.photoData = photoData
        companion.photoAccessibilityDescription = optional(photoDescription)
        companion.relevantConditions = optional(relevantConditions)
        companion.allergies = optional(allergies)
        companion.updatedAt = Date()

        do {
            try modelContext.save()
            onSaved(companion)

            if mode.dismissesAfterSaving {
                dismiss()
            }
        } catch {
            saveErrorMessage = String(localized: "Los datos no se guardaron. Podés intentar de nuevo en un momento.")
        }
    }

    private func optional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview("Alta") {
    NavigationStack {
        CompanionFormView(mode: .create)
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
