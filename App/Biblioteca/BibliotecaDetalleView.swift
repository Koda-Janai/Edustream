import SwiftUI

@MainActor
struct BibliotecaDetalleView: View {
    let leccion: Leccion
    let firebase: FirebaseEdustream

    @State private var completada = false
    @State private var guardando = false
    @State private var error: String?

    var body: some View {
        List {
            Section("Lección") {
                NavigationLink("Leer o escuchar") {
                    BibliotecaLecturaView(leccion: leccion, firebase: firebase)
                }
                Text(leccion.ejemploVisual)
                    .font(.system(.body, design: .monospaced))
                    .padding(.vertical, 8)
            }

            Section("Práctica") {
                PreguntaLeccion(leccion: leccion, firebase: firebase)
            }

            Section("Progreso") {
                Button(completada ? "Lección completada" : "Marcar como completada") {
                    Task { await completar() }
                }
                .disabled(completada || guardando || leccion.id == nil)
                if guardando { ProgressView("Guardando") }
                if let error { Text(error).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle(leccion.titulo)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let id = leccion.id else { return }
            do {
                let estado = try await firebase.estaCompletada(id)
                if estado { completada = true }
            } catch {
                if !Task.isCancelled && !completada { self.error = error.localizedDescription }
            }
        }
    }

    private func completar() async {
        guard let id = leccion.id, !guardando, !completada else { return }
        guardando = true
        defer { guardando = false }
        error = nil
        do {
            try await firebase.completar(id)
            completada = true
        } catch {
            self.error = "No se pudo guardar el progreso. Puedes reintentar."
        }
    }
}
