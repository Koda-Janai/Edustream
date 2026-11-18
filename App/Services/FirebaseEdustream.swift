import FirebaseAuth
import FirebaseFirestore
import Foundation
import Observation

@MainActor
@Observable
final class FirebaseEdustream {
    private let auth: Auth
    private let db: Firestore
    private let pendientes: UserDefaults
    private(set) var perfil: Perfil?

    init(auth: Auth = Auth.auth(), db: Firestore = Firestore.firestore(),
         pendientes: UserDefaults = .standard) {
        self.auth = auth
        self.db = db
        self.pendientes = pendientes
        actualizarSesion()
    }

    func iniciarSesionInvitada() async throws {
        if auth.currentUser == nil { _ = try await auth.signInAnonymously() }
        actualizarSesion()
    }

    func iniciarSesion(correo: String, contrasena: String) async throws {
        _ = try await auth.signIn(withEmail: correo, password: contrasena)
        actualizarSesion()
    }

    func registrar(correo: String, contrasena: String) async throws {
        if let actual = auth.currentUser, actual.isAnonymous {
            let credencial = EmailAuthProvider.credential(withEmail: correo, password: contrasena)
            _ = try await actual.link(with: credencial)
        } else {
            _ = try await auth.createUser(withEmail: correo, password: contrasena)
        }
        actualizarSesion()
    }

    func recuperarContrasena(correo: String) async throws {
        try await auth.sendPasswordReset(withEmail: correo)
    }

    func actualizarNombre(_ nombre: String) async throws {
        guard let usuario = auth.currentUser else { throw ErrorOperacion.sinSesion }
        let cambio = usuario.createProfileChangeRequest()
        cambio.displayName = nombre
        try await cambio.commitChanges()
        actualizarSesion()
    }

    func cerrarSesion() throws {
        try auth.signOut()
        actualizarSesion()
    }

    private func actualizarSesion() {
        perfil = auth.currentUser.map {
            Perfil(id: $0.uid, nombre: $0.displayName, correo: $0.email, invitado: $0.isAnonymous)
        }
    }

    func cargarLecciones() async throws -> [Leccion] {
        let resultado = try await db.collection("lessons").getDocuments()
        return try resultado.documents.map { try $0.data(as: Leccion.self) }
            .sorted { $0.titulo.localizedStandardCompare($1.titulo) == .orderedAscending }
    }

    func cargarFinalizaciones() async throws -> Set<String> {
        let usuario = try referenciaUsuario()
        let resultado = try await usuario.collection("lessonProgress").getDocuments()
        return Set(resultado.documents.map(\.documentID))
    }

    func estaCompletada(_ id: String) async throws -> Bool {
        let referencia = try referenciaUsuario().collection("lessonProgress").document(id)
        return try await referencia.getDocument().exists
    }

    func completar(_ id: String) async throws {
        let referencia = try referenciaUsuario().collection("lessonProgress").document(id)
        try await crearSiFalta(referencia, datos: ["completedAt": FieldValue.serverTimestamp()])
    }

    func intentoPendiente(leccion: String) -> IntentoPendiente? {
        guard let uid = auth.currentUser?.uid,
              let datos = pendientes.data(forKey: claveIntento(uid: uid, leccion: leccion)) else { return nil }
        return try? JSONDecoder().decode(IntentoPendiente.self, from: datos)
    }

    func enviarRespuesta(leccion: String, respuesta: Int) async throws -> Int {
        guard let uid = auth.currentUser?.uid else { throw ErrorOperacion.sinSesion }
        let clave = claveIntento(uid: uid, leccion: leccion)
        let intento = intentoPendiente(leccion: leccion) ?? IntentoPendiente(id: UUID(), respuesta: respuesta)
        pendientes.set(try JSONEncoder().encode(intento), forKey: clave)
        try await guardarIntento(id: intento.id, leccion: leccion, respuesta: intento.respuesta)
        if let datos = pendientes.data(forKey: clave),
           let actual = try? JSONDecoder().decode(IntentoPendiente.self, from: datos),
           actual.id == intento.id {
            pendientes.removeObject(forKey: clave)
        }
        return intento.respuesta
    }

    private func claveIntento(uid: String, leccion: String) -> String {
        "edustream.intento.\(uid).\(leccion)"
    }

    func guardarIntento(id: UUID, leccion: String, respuesta: Int) async throws {
        let referencia = try referenciaUsuario().collection("quizAttempts").document(id.uuidString)
        try await crearSiFalta(referencia, datos: [
            "lessonId": leccion,
            "answer": respuesta,
            "submittedAt": FieldValue.serverTimestamp()
        ])
    }

    func cargarPosicion(_ id: String) async throws -> Int {
        let referencia = try referenciaUsuario().collection("readingProgress").document(id)
        return try await referencia.getDocument().data()?["position"] as? Int ?? 0
    }

    func guardarPosicion(_ posicion: Int, leccion: String) async throws {
        let referencia = try referenciaUsuario().collection("readingProgress").document(leccion)
        _ = try await db.runTransaction { transaccion, puntero in
            do {
                let anterior = try transaccion.getDocument(referencia).data()?["position"] as? Int ?? 0
                if posicion > anterior {
                    transaccion.setData(["position": posicion], forDocument: referencia)
                }
            } catch {
                puntero?.pointee = error as NSError
            }
            return nil
        }
    }

    private func crearSiFalta(_ referencia: DocumentReference, datos: [String: Any]) async throws {
        _ = try await db.runTransaction { transaccion, puntero in
            do {
                if try !transaccion.getDocument(referencia).exists {
                    transaccion.setData(datos, forDocument: referencia)
                }
            } catch {
                puntero?.pointee = error as NSError
            }
            return nil
        }
    }

    private func referenciaUsuario() throws -> DocumentReference {
        guard let uid = auth.currentUser?.uid else { throw ErrorOperacion.sinSesion }
        return db.collection("users").document(uid)
    }

    private enum ErrorOperacion: LocalizedError {
        case sinSesion

        var errorDescription: String? { "Inicia sesión para guardar el avance." }
    }
}
