import SwiftUI

struct TelevisionSearchView: View {
    @EnvironmentObject private var service: SamsungTVService
    @EnvironmentObject private var store: TVStore
    @Environment(\.dismiss) private var dismiss
    @State private var results: [SamsungTV] = []
    @State private var isSearching = false

    var body: some View {
        List {
            if isSearching {
                Section { HStack { ProgressView(); Text("Recherche sur le réseau local…") } }
            } else if results.isEmpty {
                ContentUnavailableView("Aucun téléviseur détecté", systemImage: "tv.slash", description: Text("Saisissez l’adresse IP si votre téléviseur ne répond pas à la découverte réseau."))
            } else {
                Section("Téléviseurs détectés") {
                    ForEach(results) { television in
                        Button { connect(television) } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(television.name).font(.headline)
                                Text(television.model ?? television.endpointDescription).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Section { NavigationLink("Saisir une adresse IP") { ManualConnectionView() } }
        }
        .navigationTitle("Rechercher")
        .task { await search() }
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Réessayer") { Task { await search() } } } }
    }

    private func search() async {
        isSearching = true
        results = await service.discoverTelevisions()
        isSearching = false
    }
    private func connect(_ television: SamsungTV) {
        store.save(television)
        service.connect(to: television)
        dismiss()
    }
}

struct ManualConnectionView: View {
    @EnvironmentObject private var service: SamsungTVService
    @Environment(\.dismiss) private var dismiss
    @State private var host = ""
    @State private var useSecureConnection = false

    var body: some View {
        Form {
            Section("Téléviseur") {
                TextField("Adresse IP, par ex. 192.168.1.42", text: $host)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                Toggle("Connexion sécurisée (port 8002)", isOn: $useSecureConnection)
            }
            Section {
                Button("Vérifier et connecter") {
                    Task {
                        await service.validateAndConnect(host: host, secure: useSecureConnection)
                        if service.connectionState != .failed(.invalidAddress) { dismiss() }
                    }
                }
                .disabled(host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("Important") {
                Text("Certains téléviseurs anciens n’exposent que le port non chiffré 8001. N’utilisez ce mode que sur votre réseau domestique de confiance. Le mode sécurisé utilise le port 8002. Certaines TV Samsung utilisent un certificat local non reconnu par iOS ; dans ce cas, essayez le port 8001 sur votre réseau domestique.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Connexion manuelle")
    }
}
