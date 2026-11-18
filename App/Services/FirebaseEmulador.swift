#if DEBUG
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

@MainActor
enum FirebaseEmulador {
    static func conectar(nombre: String) -> (Auth, Firestore) {
        let opciones = FirebaseOptions(googleAppID: "1:1234567890:ios:abcdef0123456789",
                                       gcmSenderID: "1234567890")
        opciones.projectID = "demo-edustream"
        opciones.apiKey = "A" + String(repeating: "0", count: 38)
        FirebaseApp.configure(name: nombre, options: opciones)
        guard let app = FirebaseApp.app(name: nombre) else {
            preconditionFailure("No se pudo inicializar Firebase Emulator Suite.")
        }
        let auth = Auth.auth(app: app)
        auth.useEmulator(withHost: "127.0.0.1", port: 9099)

        let db = Firestore.firestore(app: app)
        let ajustes = db.settings
        ajustes.host = "127.0.0.1:8080"
        ajustes.cacheSettings = MemoryCacheSettings()
        ajustes.isSSLEnabled = false
        db.settings = ajustes
        return (auth, db)
    }
}
#endif
