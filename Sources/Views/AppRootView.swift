import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @State private var showingPicker = false

    var body: some View {
        Group {
            if store.selectedTelevision == nil {
                NavigationStack { WelcomeView() }
            } else {
                RemoteControlView(showingPicker: $showingPicker)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingPicker) { TelevisionPickerView() }
    }
}

private struct WelcomeView: View {
    @EnvironmentObject private var service: SamsungTVService
    @State private var showSearch = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "tv.and.hifispeaker.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.white)
            Text("Samsung Remote Pro")
                .font(.largeTitle.bold())
            Text("Contrôlez votre téléviseur Samsung depuis le réseau local.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 36)
            Button("Rechercher un téléviseur") { showSearch = true }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .accessibilityHint("Demande l’autorisation d’accéder au réseau local si nécessaire")
            NavigationLink("Saisir une adresse IP") { ManualConnectionView() }
                .foregroundStyle(.blue)
            Text("Le téléviseur et l’iPhone doivent être sur le même réseau Wi‑Fi. Lors de la première connexion, acceptez la demande affichée sur le téléviseur.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
        .navigationDestination(isPresented: $showSearch) { TelevisionSearchView() }
    }
}

struct TelevisionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: TVStore
    @EnvironmentObject private var service: SamsungTVService
    @State private var addManual = false

    var body: some View {
        NavigationStack {
            List {
                Section("Téléviseurs enregistrés") {
                    ForEach(store.televisions) { television in
                        Button {
                            store.select(television)
                            service.connect(to: television)
                            dismiss()
                        } label: {
                            HStack {
                                Label(television.name, systemImage: "tv")
                                Spacer()
                                if store.selectedTelevision?.id == television.id { Image(systemName: "checkmark").foregroundStyle(.blue) }
                            }
                        }
                    }
                    .onDelete { indexSet in indexSet.forEach { service.remove(store.televisions[$0]) } }
                }
                Section { Button("Ajouter un téléviseur") { addManual = true } }
            }
            .navigationTitle("Téléviseurs")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fermer") { dismiss() } } }
            .sheet(isPresented: $addManual) { NavigationStack { ManualConnectionView() } }
        }
    }
}
