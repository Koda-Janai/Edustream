import Foundation
import FirebaseCore
import SwiftUI

@main
@MainActor
struct EdustreamApp: App {
    private let firebase: FirebaseEdustream?

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["EDUSTREAM_EMULADOR"] == "1" {
            let (auth, db) = FirebaseEmulador.conectar(nombre: "edustream_local")
            firebase = FirebaseEdustream(auth: auth, db: db)
            return
        }
        #endif
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let opciones = FirebaseOptions(contentsOfFile: url.path),
              opciones.projectID == "edustream-ab036",
              opciones.bundleID == Bundle.main.bundleIdentifier else {
            firebase = nil
            return
        }

        FirebaseApp.configure(options: opciones)
        firebase = FirebaseEdustream()
    }

    var body: some Scene {
        WindowGroup {
            if let firebase {
                EdustreamInicioView(firebase: firebase)
            } else {
                ContentUnavailableView("Falta configurar Firebase", systemImage: "gear",
                    description: Text("Añade la configuración iOS de edustream-ab036 con el identificador correcto."))
            }
        }
    }
}

@MainActor
private struct EdustreamInicioView: View {
    let firebase: FirebaseEdustream

    @State private var error: String?
    @State private var iniciando = false

    var body: some View {
        Group {
            if let perfil = firebase.perfil {
                TabView {
                    NavigationStack { BibliotecaView(firebase: firebase) }
                        .tabItem { Label("Inicio", systemImage: "house") }
                    NavigationStack { PerfilView(firebase: firebase) }
                        .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
                }
                .id(perfil.id)
                .tint(EstiloEdustream.tinta)
            } else if let error {
                ContentUnavailableView {
                    Label("No se pudo iniciar Edustream", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Reintentar") { Task { await iniciar() } }
                }
            } else {
                ProgressView("Iniciando Edustream")
            }
        }
        .task(id: firebase.perfil?.id) {
            if firebase.perfil == nil { await iniciar() }
        }
    }

    private func iniciar() async {
        guard !iniciando else { return }
        iniciando = true
        defer { iniciando = false }
        error = nil
        do {
            try await firebase.iniciarSesionInvitada()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
