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
                            AppIconView(data: favoriteVersion(of: app)?.customIconData, size: 38)
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
                                    AppIconView(data: app.customIconData, size: 42)
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
            Task { await importIcon(from: item, for: targetID) }
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

    private func favoriteVersion(of app: RemoteApplication) -> RemoteApplication? {
        store.favoriteApps.first { $0.id == app.id }
    }

    private func addDetectedApp(_ app: RemoteApplication) {
        guard store.favoriteApps.count < maximumLauncherApps else {
            showingLimitAlert = true
            return
        }
        var favorite = app
        favorite.isFavorite = true
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

    private func importIcon(from item: PhotosPickerItem, for appID: String) async {
        guard let sourceData = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: sourceData),
              let compactData = compactLogoData(from: image),
              let index = store.favoriteApps.firstIndex(where: { $0.id == appID }) else { return }
        store.favoriteApps[index].customIconData = compactData
        selectedIconItem = nil
    }

    /// Downsample icons before saving and mirroring them into the Live Activity state.
    private func compactLogoData(from image: UIImage) -> Data? {
        let size = CGSize(width: 72, height: 72)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        defer { UIGraphicsEndImageContext() }
        UIColor.black.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else { return nil }
        let scale = max(size.width / sourceSize.width, size.height / sourceSize.height)
        let scaled = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let origin = CGPoint(x: (size.width - scaled.width) / 2, y: (size.height - scaled.height) / 2)
        image.draw(in: CGRect(origin: origin, size: scaled))
        return UIGraphicsGetImageFromCurrentImageContext()?.jpegData(compressionQuality: 0.48)
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
            Section("Dynamic Island") {
                Picker("Action rapide", selection: $store.preferences.dynamicIslandAction) {
                    ForEach(LiveActivityQuickAction.allCases) { action in
                        Label(action.title, systemImage: action.systemImage).tag(action)
                    }
                }
                Text("La Live Activity démarre automatiquement lorsque la TV est connectée. Maintenez la Dynamic Island pour afficher l’action et jusqu’à cinq raccourcis d’applications.")
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
                LabeledContent("Version", value: "1.1.0")
                Text("Les commandes réseau et le contrôle TV restent locaux. Les raccourcis de la Dynamic Island ouvrent l’application pour envoyer la commande avec la session WebSocket enregistrée.")
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
