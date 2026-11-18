import SwiftUI

@MainActor
struct PerfilView: View {
    let firebase: FirebaseEdustream
    @State private var finalizadas: Int?
    @State private var error: String?

    var body: some View {
        List {
            if let perfil = firebase.perfil {
                Section {
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 62))
                            .foregroundStyle(EstiloEdustream.tinta)
                            .accessibilityHidden(true)
                        Text(perfil.nombre ?? (perfil.invitado ? "Invitado" : "Estudiante"))
                            .font(.system(.title2, design: .serif))
                        if let correo = perfil.correo { Text(correo).foregroundStyle(.secondary) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }

                Section("Avance") {
                    if let finalizadas {
                        LabeledContent("Lecciones completadas", value: String(finalizadas))
                    } else if error == nil {
                        ProgressView("Consultando el avance")
                    }
                }

                Section("Cuenta") {
                    if perfil.invitado {
                        NavigationLink("Crear cuenta") { AccesoView(firebase: firebase, modo: .registro) }
                        NavigationLink("Iniciar sesión") { AccesoView(firebase: firebase, modo: .acceso) }
                    } else {
                        NavigationLink("Actualizar datos") { EditarPerfilView(firebase: firebase) }
                        Button("Cerrar sesión") {
                            do { try firebase.cerrarSesion() }
                            catch { self.error = error.localizedDescription }
                        }
                    }
                }
            }

            if let error { Text(error).foregroundStyle(.secondary) }
        }
        .navigationTitle("Perfil")
        .task { await cargar() }
        .refreshable { await cargar() }
    }

    private func cargar() async {
        error = nil
        do {
            finalizadas = try await firebase.cargarFinalizaciones().count
        } catch {
            if !Task.isCancelled { self.error = error.localizedDescription }
        }
    }
}
