import SwiftUI

@MainActor
struct EditarPerfilView: View {
    let firebase: FirebaseEdustream

    @Environment(\.dismiss) private var dismiss
    @State private var nombre = ""
    @State private var ocupado = false
    @State private var mensaje: String?

    private var nombreLimpio: String { nombre.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section {
                TextField("Nombre visible", text: $nombre)
                    .textContentType(.name)
                if let correo = firebase.perfil?.correo {
                    LabeledContent("Correo", value: correo)
                }
            }
            Button("Actualizar") { Task { await guardar() } }
                .disabled(nombreLimpio.isEmpty || nombreLimpio.count > 60 || ocupado)
            if ocupado { ProgressView() }
            if let correo = firebase.perfil?.correo {
                Button("Cambiar contraseña por correo") {
                    Task { await enviarEnlace(correo) }
                }
                .disabled(ocupado)
            }
            if let mensaje { Text(mensaje) }
        }
        .navigationTitle("Actualizar datos")
        .onAppear { nombre = firebase.perfil?.nombre ?? "" }
    }

    private func guardar() async {
        guard !ocupado else { return }
        ocupado = true
        mensaje = nil
        defer { ocupado = false }
        do {
            try await firebase.actualizarNombre(nombreLimpio)
            dismiss()
        } catch {
            mensaje = error.localizedDescription
        }
    }

    private func enviarEnlace(_ correo: String) async {
        guard !ocupado else { return }
        ocupado = true
        mensaje = nil
        defer { ocupado = false }
        do {
            try await firebase.recuperarContrasena(correo: correo)
            mensaje = "Revisa tu correo para elegir una nueva contraseña."
        } catch {
            mensaje = error.localizedDescription
        }
    }
}