import FirebaseFirestore
import Foundation
import XCTest
@testable import Edustream

final class FirebaseEdustreamTests: XCTestCase {
    @MainActor
    func testRegistroYAvanceConReintentos() async throws {
        let nombre = "prueba_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let (auth, db) = FirebaseEmulador.conectar(nombre: nombre)
        let servicio = FirebaseEdustream(auth: auth, db: db)
        try await servicio.iniciarSesionInvitada()
        let uid = try XCTUnwrap(servicio.perfil?.id)
        let lecciones = try await servicio.cargarLecciones()
        let id = try XCTUnwrap(lecciones.first(where: { $0.id == "proporciones" })?.id)

        try await servicio.completar(id)
        let usuario = db.collection("users").document(uid)
        let ref = usuario.collection("lessonProgress").document(id)
        let inicial = try await ref.getDocument(source: .server)
        let primeraMarca = try XCTUnwrap(inicial.data()?["completedAt"] as? Timestamp)

        try await servicio.completar(id)
        let repetida = try await ref.getDocument(source: .server)
        XCTAssertEqual(repetida.data()?["completedAt"] as? Timestamp, primeraMarca)
        let finalizaciones = try await servicio.cargarFinalizaciones()
        XCTAssertEqual(finalizaciones, [id])

        try await servicio.guardarPosicion(2, leccion: id)
        try await servicio.guardarPosicion(1, leccion: id)
        let posicion = try await servicio.cargarPosicion(id)
        XCTAssertEqual(posicion, 2)

        let intento = UUID()
        try await servicio.guardarIntento(id: intento, leccion: id, respuesta: 1)
        try await servicio.guardarIntento(id: intento, leccion: id, respuesta: 0)
        let intentos = try await usuario.collection("quizAttempts").getDocuments(source: .server)
        XCTAssertEqual(intentos.documents.count, 1)
        XCTAssertEqual(intentos.documents.first?.data()["answer"] as? Int, 1)

        let correo = "\(UUID().uuidString)@example.test"
        try await servicio.registrar(correo: correo, contrasena: "EdustreamEmulador2026!")
        XCTAssertEqual(servicio.perfil?.id, uid)
        XCTAssertEqual(servicio.perfil?.invitado, false)
        try servicio.cerrarSesion()
        try await servicio.iniciarSesion(correo: correo, contrasena: "EdustreamEmulador2026!")
        XCTAssertEqual(servicio.perfil?.id, uid)
        let avance = try await servicio.cargarFinalizaciones()
        XCTAssertEqual(avance, [id])
    }
}
