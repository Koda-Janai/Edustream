import SwiftUI

@MainActor
struct BibliotecaQuizView: View {
    let titulo: String
    let lecciones: [Leccion]
    let firebase: FirebaseEdustream

    var body: some View {
        List {
            ForEach(lecciones) { leccion in
                Section(leccion.titulo) {
                    PreguntaLeccion(leccion: leccion, firebase: firebase)
                }
            }
        }
        .navigationTitle(titulo)
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
struct PreguntaLeccion: View {
    let leccion: Leccion
    let firebase: FirebaseEdustream

    @State private var opcion: Int?
    @State private var pendiente = false
    @State private var enviado = false
    @State private var guardando = false
    @State private var error: String?

    var body: some View {
        Text(leccion.pregunta)
        Picker("Tu respuesta", selection: $opcion) {
            Text("Selecciona una opción").tag(nil as Int?)
            ForEach(leccion.opciones.indices, id: \.self) { indice in
                Text(leccion.opciones[indice]).tag(Optional(indice))
            }
        }
        .disabled(pendiente)
        .task { await restaurarIntento() }

        if enviado {
            Text(opcion == leccion.respuestaCorrecta ? "Correcto" : "Revisa tu respuesta")
                .font(.headline)
            Text(leccion.explicacion)
            Button("Nueva tentativa") {
                opcion = nil
                pendiente = false
                enviado = false
            }
        } else {
            Button(!pendiente ? "Comprobar respuesta" : "Reintentar envío") {
                Task { await enviar() }
            }
            .disabled(opcion == nil || guardando || leccion.id == nil)
        }
        if guardando { ProgressView("Guardando respuesta") }
        if let error { Text(error).foregroundStyle(.secondary) }
    }

    private func restaurarIntento() async {
        guard let id = leccion.id, !enviado, !guardando,
              let operacion = firebase.intentoPendiente(leccion: id) else { return }
        opcion = operacion.respuesta
        pendiente = true
    }

    private func enviar() async {
        guard let opcion, let id = leccion.id, !guardando, !enviado else { return }
        pendiente = true
        guardando = true
        error = nil
        defer { guardando = false }
        do {
            self.opcion = try await firebase.enviarRespuesta(leccion: id, respuesta: opcion)
            enviado = true
        } catch {
            self.error = "No se pudo enviar la respuesta. Puedes reintentar la misma tentativa."
        }
    }
}
