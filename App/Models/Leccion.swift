import FirebaseFirestore
import Foundation

struct Leccion: Decodable, Identifiable {
    @DocumentID var id: String?
    let titulo: String
    let tema: String
    let area: String
    let nivel: String
    let minutos: Int
    let destacada: Bool
    let texto: String
    let ejemploVisual: String
    let pregunta: String
    let opciones: [String]
    let respuestaCorrecta: Int
    let explicacion: String

    func coincide(con consulta: String) -> Bool {
        let campos = [titulo, tema, area]
        return consulta.split(whereSeparator: \.isWhitespace).allSatisfy { palabra in
            campos.contains { campo in
                campo.range(of: String(palabra), options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
    }
}
