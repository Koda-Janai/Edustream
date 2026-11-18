import SwiftUI

@MainActor
struct AccesoView: View {
    enum Modo: Equatable { case acceso, registro }
    let firebase: FirebaseEdustream
    let modo: Modo

    @Environment(\.dismiss) private var dismiss
    @State private var correo = ""
    @State private var contrasena = ""
    @State private var confirmacion = ""
    @State private var ocupado = false
    @State private var mensaje: String?

    private var titulo: String { modo == .registro ? "Registra tu cuenta" : "Iniciar sesión" }
    private var correoLimpio: String { correo.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section {
                TextField("Correo electrónico", text: $correo)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Contraseña", text: $contrasena)
                    .textContentType(modo == .registro ? .newPassword : .password)
                if modo == .registro {
                    SecureField("Confirmar contraseña", text: $confirmacion)
                        .textContentType(.newPassword)
                }
            }

            Section {
                Button(modo == .registro ? "Registrarse" : "Iniciar sesión") {
                    Task { await enviar() }
                }
                .disabled(correoLimpio.isEmpty || contrasena.isEmpty)
                if modo == .acceso {
                    Button("Recuperar contraseña") { Task { await recuperar() } }
                        .disabled(correoLimpio.isEmpty)
                }
            } footer: {
                if modo == .registro {
                    Text("Al crear la cuenta conservarás el avance de esta sesión de invitado.")
                }
            }

            if ocupado { ProgressView() }
            if let mensaje { Text(mensaje) }
        }
        .disabled(ocupado)
        .navigationTitle(titulo)
    }

    private func enviar() async {
        guard !ocupado else { return }
        if modo == .registro && contrasena != confirmacion {
            mensaje = "Las contraseñas deben coincidir."
            return
        }

        ocupado = true
        mensaje = nil
        defer { ocupado = false }
        do {
            switch modo {
            case .acceso:
                try await firebase.iniciarSesion(correo: correoLimpio, contrasena: contrasena)
            case .registro:
                try await firebase.registrar(correo: correoLimpio, contrasena: contrasena)
            }
            dismiss()
        } catch {
            mensaje = error.localizedDescription
        }
    }

    private func recuperar() async {
        guard !ocupado else { return }
        ocupado = true
        mensaje = nil
        defer { ocupado = false }
        do {
            try await firebase.recuperarContrasena(correo: correoLimpio)
            mensaje = "Si el correo tiene una cuenta asociada, recibirá un enlace de recuperación."
        } catch {
            mensaje = error.localizedDescription
        }
    }
}
