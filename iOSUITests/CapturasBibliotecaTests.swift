import XCTest

final class CapturasBibliotecaTests: XCTestCase {
    @MainActor
    func testRecorridoDeBiblioteca() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["EDUSTREAM_EMULADOR"] = "1"
        app.launch()

        let series = app.descendants(matching: .any)["tema-Series"].firstMatch
        XCTAssertTrue(series.waitForExistence(timeout: 25), "La biblioteca debe cargar los temas.")
        capturar("01-inicio")
        series.tap()

        let piloto = app.descendants(matching: .any)["leccion-piloto"].firstMatch
        XCTAssertTrue(piloto.waitForExistence(timeout: 10))
        capturar("02-tema-series")
        piloto.tap()

        let lector = app.descendants(matching: .any)["abrir-lector"].firstMatch
        XCTAssertTrue(lector.waitForExistence(timeout: 10))
        capturar("03-leccion")
        lector.tap()

        let escuchar = app.buttons["Escuchar"].firstMatch
        XCTAssertTrue(escuchar.waitForExistence(timeout: 10))
        escuchar.tap()
        let resaltado = app.staticTexts["texto-lector-resaltado"].firstMatch
        XCTAssertTrue(resaltado.waitForExistence(timeout: 15), "La narración debe resaltar el texto.")
        XCTAssertTrue(app.buttons["Pausar"].exists, "El lector debe estar en reproducción.")
        capturar("04-lector")

        let perfil = app.tabBars.buttons["Perfil"].firstMatch
        XCTAssertTrue(perfil.waitForExistence(timeout: 10))
        perfil.tap()
        XCTAssertTrue(app.staticTexts["Invitado"].waitForExistence(timeout: 10))
        capturar("05-perfil")
    }

    @MainActor
    private func capturar(_ nombre: String) {
        let adjunto = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        adjunto.name = nombre
        adjunto.lifetime = .keepAlways
        add(adjunto)
    }
}
