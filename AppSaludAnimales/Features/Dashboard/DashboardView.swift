import SwiftData
import SwiftUI

/// Pantalla principal: qué necesito saber hoy sobre mi compañero.
///
/// Cuatro secciones en orden de urgencia. Las que todavía no tienen nada
/// explican qué va a aparecer ahí, en vez de mostrarse vacías.
struct DashboardView: View {
    let companion: Companion
    var companions: [Companion] = []
    var onSelectCompanion: (Companion) -> Void = { _ in }

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    /// El aviso de una toma que se parece a otra ya anotada, o de que no se pudo
    /// guardar. Es un aviso y no un candado: la persona decide.
    @State private var doseAlert: DoseAlert?

    /// El registro cuya ficha se está abriendo desde "En curso". Vale para todo
    /// lo que aparece ahí, no solo para las medicaciones: si una fila muestra
    /// información, tocarla tiene que llevar a la información completa.
    @State private var openedRecord: DashboardRecord?

    @State private var isAddingCompanion = false
    @State private var isRecording = false
    @State private var isShowingEmergency = false

    /// Momento desde el que se mira el dashboard. Se refresca al volver de un
    /// registro y al volver a la app: si se queda vieja, lo recién registrado
    /// queda "en el futuro" y desaparece de la actividad reciente.
    @State private var referenceDate = Date()

    /// El botón de registrar se achica apenas se empieza a bajar. Se guarda acá
    /// y no adentro del botón porque quien sabe cuánto se bajó es la lista.
    @State private var isRecordButtonCompact = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Se calcula una vez al aparecer, y no en cada dibujo: una tarjeta que
    /// aparece y desaparece sola mientras alguien lee es peor que no tenerla.
    @State private var isOfferingBackup = false

    /// Los dos avisos que puede dar anotar una toma.
    private enum DoseAlert: Identifiable {
        case duplicate(medicationID: UUID, message: String)
        case saveFailed

        var id: String {
            switch self {
            case let .duplicate(id, _): "duplicate-\(id)"
            case .saveFailed: "saveFailed"
            }
        }
    }

    private var snapshot: DashboardSnapshot {
        DashboardBuilder.snapshot(for: companion, on: referenceDate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                companionHeader

                if isOfferingBackup {
                    backupCard
                }

                // El primer día, las cuatro secciones están vacías a la vez.
                // Cuatro cajas grises apiladas explicando cada una qué va a
                // aparecer algún día no es una pantalla: es un formulario sin
                // llenar. Cuando no hay absolutamente nada se dice una sola vez
                // y con un dibujo.
                if snapshot.isEmpty {
                    firstDayState
                } else {
                    if companion.isPresent {
                        section(
                            title: String(localized: "Hoy"),
                            items: snapshot.today,
                            emptyMessage: String(localized: "No hay nada anotado para hoy.")
                        )

                        section(
                            title: String(localized: "Próximamente"),
                            subtitle: String(localized: "Los próximos 30 días"),
                            items: snapshot.upcoming,
                            emptyMessage: String(localized: "Cuando anotes un turno o una próxima vacuna, aparece acá.")
                        )

                        section(
                            title: String(localized: "En curso"),
                            items: snapshot.currentStatus,
                            emptyMessage: String(localized: "Acá vas a ver las medicaciones y los tratamientos en curso.")
                        )
                    }

                    section(
                        title: String(localized: "Actividad reciente"),
                        items: snapshot.recentActivity,
                        emptyMessage: String(localized: "Todavía no hay nada registrado. Lo que anotes va a quedar guardado acá.")
                    )

                    historyLink
                }
            }
            .padding(Spacing.lg)
        }
        // Umbral corto: apenas se empieza a bajar ya se leyó el botón entero, y
        // esperar más deja la animación a mitad de camino cuando se frena.
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > Spacing.xl
        } action: { _, isScrolled in
            guard isScrolled != isRecordButtonCompact else { return }

            // Quien pidió menos movimiento en los ajustes del sistema lo pidió
            // en serio: el botón cambia igual, pero sin animarse.
            withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                isRecordButtonCompact = isScrolled
            }
        }
        .background {
            if companion.isPresent {
                Palette.background
            } else {
                // La pantalla entera de quien cruzó el arcoíris toma sus
                // colores. Los textos de siempre se siguen leyendo encima
                // porque el celeste y el fondo cálido tienen la misma relación
                // clara-oscura, y hay una prueba que lo verifica.
                FarewellBackground(glowHeight: 320, glowOffset: -140)
                    .ignoresSafeArea()
            }
        }
        .navigationTitle(Text("Hoy"))
        .navigationDestination(item: $openedRecord) { record in
            if let entry = entry(for: record) {
                HealthRecordDetailView(companion: companion, entry: entry)
            }
        }
        .alert(item: $doseAlert) { alert in
            switch alert {
            case let .duplicate(medicationID, message):
                Alert(
                    title: Text("¿La anotamos igual?"),
                    message: Text(message),
                    primaryButton: .default(Text("Anotarla")) {
                        recordDose(medicationID: medicationID, force: true)
                    },
                    secondaryButton: .cancel(Text("No"))
                )
            case .saveFailed:
                Alert(
                    title: Text("No pudimos anotarla"),
                    message: Text("Podés intentar de nuevo en un momento."),
                    dismissButton: .cancel(Text("Entendido"))
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            if companion.isPresent {
                recordBar
            }
        }
        .toolbar { toolbarContent }
        .fullScreenCover(isPresented: $isShowingEmergency) {
            EmergencyView(companion: companion)
        }
        .sheet(isPresented: $isRecording, onDismiss: refreshReferenceDate) {
            QuickRecordSheet(companion: companion)
        }
        .sheet(isPresented: $isAddingCompanion, onDismiss: refreshReferenceDate) {
            NavigationStack {
                CompanionFormView(mode: .create) { newCompanion in
                    onSelectCompanion(newCompanion)
                }
            }
        }
        .onAppear {
            refreshReferenceDate()
            refreshBackupOffer()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshReferenceDate()
            }
        }
    }

    private func refreshReferenceDate() {
        referenceDate = Date()
    }

    private func refreshBackupOffer() {
        isOfferingBackup = BackupReminder.shouldOffer(
            lastBackup: BackupPreferences.lastBackup,
            snoozedAt: BackupPreferences.snoozedAt,
            oldestRecord: companion.createdAt
        )
    }

    /// Una pregunta, no un reto. Sin signos de admiración, sin contador de días
    /// sin respaldar, y con una salida que dura un mes.
    private var backupCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("¿Hacemos un respaldo?")
                .font(AppFont.cardTitle)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(BackupReminder.message(lastBackup: BackupPreferences.lastBackup))
                .font(AppFont.secondary)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.xl) {
                NavigationLink {
                    BackupView()
                } label: {
                    Text("Hacerlo ahora")
                        .frame(minHeight: Spacing.minimumTapTarget)
                }

                Button {
                    BackupPreferences.snoozedAt = Date()
                    isOfferingBackup = false
                } label: {
                    Text("Ahora no")
                        .frame(minHeight: Spacing.minimumTapTarget)
                }
                .accessibilityHint(Text("La app no vuelve a preguntarlo por un mes"))
            }
            .font(AppFont.cardTitle)
            .foregroundStyle(Palette.accent)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.accentSoft)
        )
    }

    // MARK: - Encabezado

    private var companionHeader: some View {
        NavigationLink {
            CompanionProfileView(companion: companion)
        } label: {
            HStack(spacing: Spacing.lg) {
                CompanionAvatar(companion: companion, size: 72)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(companion.displayName)
                        .font(AppFont.screenTitle)
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(AppFont.secondary)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.surface)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("dashboard.companion")
        .accessibilityLabel(Text("\(companion.displayName). \(subtitle)"))
        .accessibilityHint(Text("Abre el perfil"))
        .accessibilityAddTraits(.isButton)
    }

    /// Lo que ve alguien que abrió la app por primera vez y todavía no anotó
    /// nada. Es la primera impresión completa del producto.
    private var firstDayState: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            EmptyStateIllustration(kind: .firstDay)

            Text("Todavía no hay nada anotado de \(companion.displayName)")
                .font(AppFont.sectionTitle)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text(companion.isPresent
                ? "Cuando registres una medicación, un síntoma, un peso o un estudio, va a aparecer acá ordenado por lo que necesitás saber hoy."
                : "Acá aparecería su historia, y no llegó a cargarse nada.")
                .font(AppFont.body)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.surface)
        )
    }

    private var subtitle: String {
        var parts = [companion.species.label]

        if let age = companion.age {
            parts.append(age.formatted)
        }

        // Sin foto, el aro de colores no existe: acá es donde alguien que navega
        // con VoiceOver se entera.
        if let farewell = companion.farewellDate {
            parts.append(String(localized: "Cruzó el arcoíris · \(DateDescription.absolute(farewell))"))
        }

        return parts.joined(separator: " · ")
    }

    private var historyLink: some View {
        NavigationLink {
            HistoryView(companion: companion)
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)

                Text("Ver todo el historial")
                    .font(AppFont.cardTitle)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(AppFont.caption)
                    .foregroundStyle(Palette.inkMuted)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.lg)
            .frame(minHeight: Spacing.minimumTapTarget)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Ver todo el historial"))
        .accessibilityAddTraits(.isButton)
    }

    /// La acción central vive siempre a la vista, no escondida en un menú: es lo
    /// que la persona más va a hacer, muchas veces con una sola mano.
    private var recordBar: some View {
        RecordButton(isCompact: isRecordButtonCompact) {
            isRecording = true
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        // La franja de fondo solo tiene sentido con el botón ancho. Con el
        // círculo, una barra vacía ocuparía lugar sin decir nada.
        .background {
            if !isRecordButtonCompact {
                Rectangle()
                    .fill(.bar)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Secciones

    private func section(
        title: String,
        subtitle: String? = nil,
        items: [DashboardItem],
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: title, subtitle: subtitle)

            if items.isEmpty {
                SectionEmptyState(
                    message: emptyMessage,
                    background: companion.isPresent
                        ? Palette.surfaceMuted
                        : Palette.farewellSurfaceMuted
                )
            } else {
                ForEach(items) { item in
                    DashboardItemCard(
                        item: item,
                        referenceDate: referenceDate,
                        onRecordDose: item.recordableMedicationID.map { id in
                            { recordDose(medicationID: id, force: false) }
                        },
                        onOpen: item.record.map { record in
                            { openedRecord = record }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Anotar una toma desde acá

    /// El caso que trajo esto: la primera persona ajena al proyecto que probó la
    /// app tocó la fila que decía "Contal 150, media pastilla, activo" para dar
    /// la medicación. Es donde está la información, así que es donde uno espera
    /// actuar. "Registrar > Medicación" es el camino de quien ya sabe que
    /// existe.
    private func medication(with id: UUID) -> Medication? {
        companion.medications.first { $0.id == id }
    }

    /// La ficha del historial que corresponde a una fila de "En curso".
    private func entry(for record: DashboardRecord) -> HistoryEntry? {
        switch record {
        case let .medication(id):
            guard let medication = medication(with: id) else { return nil }
            return HistoryEntry(
                id: medication.id,
                title: medication.name,
                detail: medication.dose,
                date: medication.startDate,
                category: .medication,
                badge: medication.status().badge,
                reference: .medication(medication)
            )

        case let .treatment(id):
            guard let treatment = companion.treatments.first(where: { $0.id == id }) else { return nil }
            return HistoryEntry(
                id: treatment.id,
                title: treatment.name,
                detail: treatment.category,
                date: treatment.startDate,
                category: treatment.isPreventive ? .preventive : .treatment,
                badge: treatment.status().badge,
                reference: .treatment(treatment)
            )
        }
    }

    private func recordDose(medicationID: UUID, force: Bool) {
        guard let medication = medication(with: medicationID) else { return }

        let now = Date()

        if !force, let conflict = medication.conflictingDose(for: now) {
            doseAlert = .duplicate(
                medicationID: medicationID,
                message: DoseDuplicationCheck.warningMessage(for: conflict)
            )
            return
        }

        medication.doses.append(MedicationDose(administeredAt: now, dose: medication.dose))

        do {
            try modelContext.save()
            // Sin esto la toma recién anotada queda "en el futuro" respecto del
            // momento que el tablero tiene guardado, y no aparece.
            referenceDate = Date()
        } catch {
            doseAlert = .saveFailed
        }
    }

    // MARK: - Barra de herramientas

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // El acceso a emergencia ocupa el lugar más fijo y previsible de la
        // pantalla, con texto y no solo un ícono: en una emergencia nadie
        // debería tener que recordar dónde estaba esa función. El historial se
        // alcanza desde la tarjeta del final, que ya lleva su nombre completo.
        ToolbarItem(placement: .topBarLeading) {
            // El modo emergencia no tiene a quién atender.
            Button {
                isShowingEmergency = true
            } label: {
                Label {
                    Text("Emergencia")
                } icon: {
                    Image(systemName: "cross.case.fill")
                }
                .labelStyle(.titleAndIcon)
                .font(AppFont.chip)
            }
            .tint(StatusTone.critical.content)
            .accessibilityLabel(Text("Modo emergencia"))
            .accessibilityHint(Text("Muestra los datos urgentes de \(companion.displayName) y los teléfonos para llamar"))
            .accessibilityIdentifier("dashboard.emergency")
            .opacity(companion.isPresent ? 1 : 0)
            .disabled(!companion.isPresent)
            .accessibilityHidden(!companion.isPresent)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if companions.count > 1 {
                    Section {
                        ForEach(companions) { option in
                            Button {
                                onSelectCompanion(option)
                            } label: {
                                Label {
                                    Text(option.displayName)
                                } icon: {
                                    Image(systemName: option.id == companion.id
                                        ? "checkmark"
                                        : option.species.symbolName)
                                }
                            }
                        }
                    } header: {
                        Text("Cambiar")
                            .foregroundStyle(Palette.inkMuted)
                    }
                }

                Button {
                    isAddingCompanion = true
                } label: {
                    Label {
                        Text("Agregar un perro o un gato")
                    } icon: {
                        Image(systemName: "plus")
                    }
                }
            } label: {
                Label {
                    Text("Tus perros y gatos")
                } icon: {
                    Image(systemName: "pawprint.circle")
                }
            }
            .accessibilityLabel(Text("Tus perros y gatos"))
            .accessibilityHint(Text("Cambiar de perro o gato, o agregar uno nuevo"))
        }
    }
}
