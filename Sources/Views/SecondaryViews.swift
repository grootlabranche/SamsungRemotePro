import PhotosUI
import SwiftUI
import UIKit

struct ApplicationsView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var identifier = ""
    @State private var deepLink = ""
    @State private var showingAdd = false
    @State private var showingTextInput = false
    @State private var selectedIconItem: PhotosPickerItem?
    @State private var selectedIconAppID: String?
    @State private var showingLimitAlert = false
    @State private var cropRequest: LogoCropRequest?

    private let maximumLauncherApps = 5

    var body: some View {
        List {
            Section {
                Button {
                    showingTextInput = true
                } label: {
                    Label("Saisir du texte sur la TV", systemImage: "keyboard")
                }
            } header: {
                Text("Outils")
            }

            if !service.detectedApplications.isEmpty {
                Section("Détectées par le téléviseur") {
                    ForEach(service.detectedApplications) { app in
                        HStack(spacing: 12) {
                            AppIconView(data: store.logoData(for: app.id, appName: app.name), size: 38)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(app.name)
                                Text(app.id).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer(minLength: 4)
                            if store.favoriteApps.contains(where: { $0.id == app.id }) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    .accessibilityLabel("Déjà dans les raccourcis")
                            } else {
                                Button {
                                    addDetectedApp(app)
                                } label: {
                                    Image(systemName: "plus.circle.fill").font(.title3)
                                }
                                .disabled(store.favoriteApps.count >= maximumLauncherApps)
                                .accessibilityLabel("Ajouter aux raccourcis de la Dynamic Island")
                            }
                            Button {
                                Task { await service.send(.launchApplication(app)) }
                                dismiss()
                            } label: { Image(systemName: "arrow.up.right.square") }
                                .accessibilityLabel("Lancer \(app.name)")
                        }
                    }
                }
            }

            Section {
                if store.favoriteApps.isEmpty {
                    ContentUnavailableView(
                        "Aucun raccourci",
                        systemImage: "app.badge",
                        description: Text("Ajoutez jusqu’à cinq applications à afficher dans la Dynamic Island. Vous pouvez aussi importer un logo personnalisé.")
                    )
                } else {
                    ForEach(store.favoriteApps) { app in
                        HStack(spacing: 12) {
                            Button {
                                Task { await service.send(.launchApplication(app)) }
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    AppIconView(data: store.logoData(for: app.id, appName: app.name), size: 42)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(app.name).foregroundStyle(.primary)
                                        Text(app.id).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer(minLength: 2)
                            PhotosPicker(selection: iconPickerBinding(for: app), matching: .images) {
                                Image(systemName: "photo.badge.plus").font(.title3)
                            }
                            .accessibilityLabel("Importer un logo pour \(app.name)")
                            Button(role: .destructive) {
                                store.favoriteApps.removeAll { $0.id == app.id }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .accessibilityLabel("Retirer \(app.name) des raccourcis")
                        }
                    }
                    .onMove { source, destination in store.favoriteApps.move(fromOffsets: source, toOffset: destination) }
                }
            } header: {
                HStack {
                    Text("Raccourcis Dynamic Island")
                    Spacer()
                    Text("\(store.favoriteApps.count)/\(maximumLauncherApps)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } footer: {
                Text("L’ordre de cette liste est celui affiché dans la Dynamic Island développée. Touchez l’icône photo pour choisir un logo dans Photos. Les raccourcis ouvrent l’application correspondante sur le téléviseur.")
            }
        }
        .navigationTitle("Applications")
        .task { await service.refreshInstalledApplications() }
        .onChange(of: selectedIconItem) { _, item in
            guard let item, let targetID = selectedIconAppID else { return }
            Task { await prepareCrop(from: item, for: targetID) }
        }
        .sheet(item: $cropRequest) { request in
            LogoCropView(image: request.image, appName: request.appName) { iconData in
                store.setCustomIcon(iconData, for: request.appID)
                cropRequest = nil
            } onCancel: {
                cropRequest = nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Fermer") { dismiss() } }
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()
                Button { showingAdd = true } label: { Image(systemName: "plus") }
                    .disabled(store.favoriteApps.count >= maximumLauncherApps)
                    .accessibilityLabel("Ajouter une application personnalisée")
            }
        }
        .alert("Ajouter un raccourci", isPresented: $showingAdd) {
            TextField("Nom de l’application", text: $name)
            TextField("Identifiant Samsung", text: $identifier)
            TextField("Lien profond facultatif", text: $deepLink)
            Button("Ajouter") { addFavorite() }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Le maximum est de cinq raccourcis. L’identifiant doit être exact : Samsung Remote Pro ne peut pas le deviner.")
        }
        .alert("Limite atteinte", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("La Dynamic Island accepte cinq raccourcis personnalisés dans cette version. Retirez-en un pour en ajouter un autre.")
        }
        .sheet(isPresented: $showingTextInput) { TextInputView() }
    }

    private func addDetectedApp(_ app: RemoteApplication) {
        guard store.favoriteApps.count < maximumLauncherApps else {
            showingLimitAlert = true
            return
        }
        var favorite = app
        favorite.isFavorite = true
        favorite.customIconData = store.customIconData(for: app.id)
        store.favoriteApps.append(favorite)
    }

    private func iconPickerBinding(for app: RemoteApplication) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { selectedIconAppID == app.id ? selectedIconItem : nil },
            set: { item in
                selectedIconAppID = app.id
                selectedIconItem = item
            }
        )
    }

    private func prepareCrop(from item: PhotosPickerItem, for appID: String) async {
        guard let sourceData = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: sourceData) else { return }
        let appName = store.favoriteApps.first(where: { $0.id == appID })?.name
            ?? service.detectedApplications.first(where: { $0.id == appID })?.name
            ?? appID
        cropRequest = LogoCropRequest(appID: appID, appName: appName, image: image)
        selectedIconItem = nil
    }

    private func addFavorite() {
        guard store.favoriteApps.count < maximumLauncherApps else {
            showingLimitAlert = true
            return
        }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !store.favoriteApps.contains(where: { $0.id == identifier }) else { return }
        store.favoriteApps.append(.init(
            id: identifier,
            name: name,
            deepLink: deepLink.isEmpty ? nil : deepLink,
            isFavorite: true
        ))
        name = ""; identifier = ""; deepLink = ""
    }
}

struct AppIconView: View {
    let data: Data?
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.43, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
    }
}

private struct LogoCropRequest: Identifiable {
    let id = UUID()
    let appID: String
    let appName: String
    let image: UIImage
}

struct AppLogoCustomizationView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedAppID: String?
    @State private var cropRequest: LogoCropRequest?
    @State private var showingNoAppsAlert = false

    private var apps: [RemoteApplication] {
        var result = service.detectedApplications
        var seen = Set(result.map(\.id))
        for app in store.favoriteApps where !seen.contains(app.id) {
            result.append(app)
            seen.insert(app.id)
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                Text("Sélectionnez une photo ou un logo, puis déplacez et zoomez l’image dans le cadre carré. Le résultat est enregistré pour cette application et réutilisé dans la télécommande et la Dynamic Island.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button {
                    Task { await service.refreshInstalledApplications() }
                    if apps.isEmpty { showingNoAppsAlert = true }
                } label: {
                    Label("Actualiser les apps détectées", systemImage: "arrow.clockwise")
                }
            }

            if apps.isEmpty {
                ContentUnavailableView(
                    "Aucune application trouvée",
                    systemImage: "app.badge",
                    description: Text("Connectez la TV, ouvrez Applications pour demander sa liste, ou ajoutez d’abord un raccourci personnalisé.")
                )
            } else {
                Section("Applications du téléviseur") {
                    ForEach(apps) { app in
                        HStack(spacing: 12) {
                            AppIconView(data: store.logoData(for: app.id, appName: app.name), size: 48)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(app.name)
                                Text(app.id).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                if store.customIconData(for: app.id) != nil {
                                    Text("Logo personnalisé enregistré").font(.caption2).foregroundStyle(.green)
                                }
                            }
                            Spacer(minLength: 6)
                            PhotosPicker(selection: photoBinding(for: app), matching: .images) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .contentShape(Rectangle())
                            }
                            .accessibilityLabel("Choisir et recadrer le logo de \(app.name)")
                            if store.customIconData(for: app.id) != nil {
                                Button(role: .destructive) {
                                    store.setCustomIcon(nil, for: app.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel("Supprimer le logo personnalisé de \(app.name)")
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
        }
        .navigationTitle("Logos des apps TV")
        .navigationBarTitleDisplayMode(.inline)
        .task { await service.refreshInstalledApplications() }
        .onChange(of: selectedPhoto) { _, item in
            guard let item, let appID = selectedAppID else { return }
            Task { await loadPhoto(item, appID: appID) }
        }
        .sheet(item: $cropRequest) { request in
            LogoCropView(image: request.image, appName: request.appName) { iconData in
                store.setCustomIcon(iconData, for: request.appID)
                cropRequest = nil
            } onCancel: {
                cropRequest = nil
            }
        }
        .alert("Aucune app détectée pour le moment", isPresented: $showingNoAppsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("La TV doit être connectée. Certaines versions de Tizen ne renvoient pas la liste des applications; les favoris déjà enregistrés restent modifiables.")
        }
    }

    private func photoBinding(for app: RemoteApplication) -> Binding<PhotosPickerItem?> {
        Binding(get: { selectedAppID == app.id ? selectedPhoto : nil }, set: { item in
            selectedAppID = app.id
            selectedPhoto = item
        })
    }

    private func loadPhoto(_ item: PhotosPickerItem, appID: String) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        let appName = apps.first(where: { $0.id == appID })?.name ?? appID
        cropRequest = LogoCropRequest(appID: appID, appName: appName, image: image)
        selectedPhoto = nil
    }
}

/// Square cropper with pan and zoom. Saved images are 256px PNGs with transparent rounded corners.
struct LogoCropView: View {
    let image: UIImage
    let appName: String
    let onSave: (Data) -> Void
    let onCancel: () -> Void

    @State private var zoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let side = min(geometry.size.width - 40, 320)
                let scale = max(side / max(image.size.width, 1), side / max(image.size.height, 1)) * zoom
                let displayWidth = image.size.width * scale
                let displayHeight = image.size.height * scale
                let currentOffset = clampOffset(
                    CGSize(width: offset.width + dragTranslation.width, height: offset.height + dragTranslation.height),
                    side: side,
                    displayWidth: displayWidth,
                    displayHeight: displayHeight
                )

                VStack(spacing: 22) {
                    Spacer(minLength: 12)
                    ZStack {
                        RoundedRectangle(cornerRadius: side * 0.20, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: displayWidth, height: displayHeight)
                            .offset(x: currentOffset.width, y: currentOffset.height)
                    }
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: side * 0.20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: side * 0.20, style: .continuous)
                            .stroke(.white.opacity(0.35), lineWidth: 1)
                    }
                    .gesture(
                        DragGesture()
                            .updating($dragTranslation) { value, state, _ in state = value.translation }
                            .onEnded { value in
                                offset = clampOffset(
                                    CGSize(width: offset.width + value.translation.width, height: offset.height + value.translation.height),
                                    side: side,
                                    displayWidth: displayWidth,
                                    displayHeight: displayHeight
                                )
                            }
                    )
                    Text("Faites glisser pour recadrer")
                        .font(.subheadline).foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        HStack {
                            Label("Zoom", systemImage: "plus.magnifyingglass")
                            Spacer()
                            Text("\(Int(zoom * 100)) %").monospacedDigit().foregroundStyle(.secondary)
                        }
                        Slider(value: $zoom, in: 1...3, step: 0.05)
                            .onChange(of: zoom) { _, _ in
                                let newScale = max(side / max(image.size.width, 1), side / max(image.size.height, 1)) * zoom
                                offset = clampOffset(offset, side: side, displayWidth: image.size.width * newScale, displayHeight: image.size.height * newScale)
                            }
                    }
                    .frame(width: side)
                    Spacer(minLength: 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 12)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Recadrer le logo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        if let data = makeRoundedIconData(side: 256) { onSave(data) }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func clampOffset(_ candidate: CGSize, side: CGFloat, displayWidth: CGFloat, displayHeight: CGFloat) -> CGSize {
        let limitX = max(0, (displayWidth - side) / 2)
        let limitY = max(0, (displayHeight - side) / 2)
        return CGSize(width: min(max(candidate.width, -limitX), limitX), height: min(max(candidate.height, -limitY), limitY))
    }

    private func makeRoundedIconData(side outputSide: CGFloat) -> Data? {
        let side: CGFloat = 320
        let scale = max(side / max(image.size.width, 1), side / max(image.size.height, 1)) * zoom
        let displayWidth = image.size.width * scale
        let displayHeight = image.size.height * scale
        let finalOffset = clampOffset(offset, side: side, displayWidth: displayWidth, displayHeight: displayHeight)
        let sourceSide = side / scale
        let originX = (image.size.width - sourceSide) / 2 - finalOffset.width / scale
        let originY = (image.size.height - sourceSide) / 2 - finalOffset.height / scale
        let targetRect = CGRect(x: max(0, min(image.size.width-sourceSide, originX)), y: max(0, min(image.size.height-sourceSide, originY)), width: min(sourceSide, image.size.width), height: min(sourceSide, image.size.height))
        let outputSize = CGSize(width: outputSide, height: outputSide)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        let rendered = renderer.image { context in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: outputSize), cornerRadius: outputSide * 0.22)
            path.addClip()
            let factor = outputSide / targetRect.width
            image.draw(in: CGRect(x: -targetRect.origin.x * factor, y: -targetRect.origin.y * factor, width: image.size.width * factor, height: image.size.height * factor))
        }
        return rendered.pngData()
    }
}

struct TextInputView: View {
    @EnvironmentObject private var service: SamsungTVService
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("La saisie de texte dépend de l’application actuellement ouverte sur le téléviseur. Si elle est refusée ou ignorée, utilisez le clavier affiché par la TV.")
                    .font(.footnote).foregroundStyle(.secondary)
                TextField("Texte à envoyer", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder).lineLimit(3...7)
                Spacer()
            }
            .padding()
            .navigationTitle("Saisie de texte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fermer") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Envoyer") { Task { await service.send(.typeText(text)); dismiss() } }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Télécommande") {
                Picker("Navigation", selection: $store.preferences.navigationMode) {
                    ForEach(NavigationMode.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Retour haptique", isOn: $store.preferences.hapticsEnabled)
                Toggle("Reconnexion automatique", isOn: $store.preferences.reconnectAutomatically)
            }
            Section("Personnalisation") {
                NavigationLink {
                    AppLogoCustomizationView()
                } label: {
                    Label("Logos personnalisés des apps TV", systemImage: "app.badge")
                }
                ColorPicker("Couleur des boutons", selection: Binding(
                    get: { Color(hexRGB: store.preferences.shortcutButtonColorHex) },
                    set: { store.preferences.shortcutButtonColorHex = $0.rgbHexString }
                ), supportsOpacity: false)
                Text("La couleur s’applique aux boutons ronds, au rocker de volume et aux raccourcis de la Live Activity. Elle est synchronisée dans l’état de la Dynamic Island.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Dynamic Island / Live Activity") {
                Toggle("Dynamic Island / Live Activity", isOn: $store.preferences.liveActivityEnabled)
                Text("Désactivée par défaut. Lorsqu’elle est activée, la Live Activity apparaît à l’ouverture de l’application, reste disponible en arrière-plan et peut afficher jusqu’à cinq applications épinglées. Si vous la supprimez manuellement, elle est recréée au prochain retour dans l’application. La désactivation termine l’activité sans désactiver la télécommande.")
                    .font(.footnote).foregroundStyle(.secondary)
                Picker("Action rapide", selection: $store.preferences.dynamicIslandAction) {
                    ForEach(LiveActivityQuickAction.allCases) { action in
                        Label(action.title, systemImage: action.systemImage).tag(action)
                    }
                }
                Text("Maintenez la Dynamic Island pour afficher l’action et jusqu’à cinq raccourcis d’applications. La présence d’une Live Activity dépend du réglage ci-dessus.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Boutons physiques de l’iPhone") {
                Toggle("Piloter le volume de la TV", isOn: $store.preferences.useHardwareVolumeButtons)
                Text("Actif uniquement quand Samsung Remote Pro est au premier plan. iOS ne fournit pas d’événement direct pour les boutons de volume : l’app observe les changements du volume système. Le volume de l’iPhone peut donc changer en même temps. Les réglages de volume via le Centre de contrôle ou certains écouteurs peuvent aussi être détectés.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Connexion") {
                if let television = store.selectedTelevision {
                    LabeledContent("Adresse", value: television.endpointDescription)
                    LabeledContent("Sécurité", value: television.usesSecureWebSocket ? "TLS (8002)" : "Non chiffrée (8001)")
                    Button("Oublier ce téléviseur", role: .destructive) { service.remove(television); dismiss() }
                }
            }
            Section("À propos") {
                LabeledContent("Version", value: "1.2.5")
                Text("Les boutons d’action des Live Activities exécutent une LiveActivityIntent dans le processus de l’app sans afficher son interface. Toucher le fond de l’activité ouvre toujours la télécommande.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Réglages")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fermer") { dismiss() } } }
    }
}

struct DiagnosticView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @EnvironmentObject private var network: NetworkMonitor
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Réseau") {
                LabeledContent("Connectivité", value: network.isConnected ? "Disponible" : "Indisponible")
                LabeledContent("Wi‑Fi", value: network.usesWiFi ? "Actif" : "Non détecté")
                LabeledContent("État", value: service.connectionState.title)
            }
            Section("Dernier résultat") { Text(service.lastDiagnostic).textSelection(.enabled) }
            if let television = store.selectedTelevision {
                Section {
                    Button("Tester l’accessibilité") { Task { await service.runDiagnostic(for: television) } }
                    Button("Reconnecter") { service.connect(to: television) }
                    Button("Déconnecter", role: .destructive) { service.disconnect() }
                }
            }
            Section("Limites") {
                Text("Les touches sont transmises sans accusé de réception par commande : un envoi ne prouve pas que l’application TV a exécuté l’action. Les commandes multimédia dépendent de l’application ouverte sur le téléviseur.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Diagnostic")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fermer") { dismiss() } } }
    }
}
