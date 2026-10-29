import SwiftUI

struct ApplicationsView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var identifier = ""
    @State private var deepLink = ""
    @State private var showingAdd = false

    var body: some View {
        List {
            if !service.detectedApplications.isEmpty {
                Section("Détectées par le téléviseur") {
                    ForEach(service.detectedApplications) { app in
                        Button {
                            Task { await service.send(.launchApplication(app)) }
                            dismiss()
                        } label: { Label(app.name, systemImage: "app") }
                    }
                }
            }
            if store.favoriteApps.isEmpty {
                ContentUnavailableView("Aucun favori", systemImage: "app.badge", description: Text("Ajoutez une application avec un identifiant que vous connaissez. La TV ne permet pas toujours de lister les applications installées."))
            } else {
                Section("Favoris") {
                    ForEach(store.favoriteApps) { app in
                        Button {
                            Task { await service.send(.launchApplication(app)) }
                            dismiss()
                        } label: { Label(app.name, systemImage: "play.square") }
                    }
                    .onDelete { store.favoriteApps.remove(atOffsets: $0) }
                }
            }
        }
        .navigationTitle("Applications")
        .task { await service.refreshInstalledApplications() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Fermer") { dismiss() } }
            ToolbarItem(placement: .topBarTrailing) { Button { showingAdd = true } label: { Image(systemName: "plus") } }
        }
        .alert("Ajouter un favori", isPresented: $showingAdd) {
            TextField("Nom", text: $name)
            TextField("Identifiant Samsung", text: $identifier)
            TextField("Lien profond facultatif", text: $deepLink)
            Button("Ajouter") { addFavorite() }
            Button("Annuler", role: .cancel) { }
        } message: { Text("L’identifiant doit provenir de votre configuration ou de la documentation de l’application. Il n’est pas deviné par Samsung Remote Pro.") }
    }

    private func addFavorite() {
        guard !name.isEmpty, !identifier.isEmpty else { return }
        store.favoriteApps.append(.init(id: identifier, name: name, deepLink: deepLink.isEmpty ? nil : deepLink, isFavorite: true))
        name = ""; identifier = ""; deepLink = ""
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
                Toggle("Commandes multimédia", isOn: $store.preferences.showExtraCommands)
            }
            Section("Connexion") {
                Toggle("Reconnexion automatique", isOn: $store.preferences.reconnectAutomatically)
                if let television = store.selectedTelevision {
                    LabeledContent("Adresse", value: television.endpointDescription)
                    LabeledContent("Sécurité", value: television.usesSecureWebSocket ? "TLS (8002)" : "Non chiffrée (8001)")
                    Button("Oublier ce téléviseur", role: .destructive) { service.remove(television); dismiss() }
                }
            }
            Section("À propos") {
                LabeledContent("Version", value: "1.0.0")
                Text("Aucune donnée personnelle ni commande n’est envoyée à un service cloud par l’application.")
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
                Text("Les touches sont transmises sans accusé de réception par commande : un envoi ne prouve pas que l’application TV a exécuté l’action. Les recherches ±10 secondes utilisent le retour/l’avance rapides, sans garantie de durée exacte.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Diagnostic")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fermer") { dismiss() } } }
    }
}
