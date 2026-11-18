import SwiftUI

enum EstiloEdustream {
    static let tinta = Color(red: 0.12, green: 0.20, blue: 0.26)

    static func acento(_ tema: String) -> Color {
        switch tema {
        case "Series": .yellow
        case "Historia": .orange
        case "Deportes": .teal
        case "Química": .green
        case "Cine": .white
        case "Música": Color(red: 0.96, green: 0.61, blue: 0.38)
        case "Filosofía": Color(red: 0.36, green: 0.77, blue: 0.42)
        case "Arte": .pink
        case "Matemática": .red
        case "Videojuegos": .purple
        default: .cyan
        }
    }

    static func simbolo(_ tema: String) -> String {
        switch tema {
        case "Series": "tv"
        case "Historia": "building.columns"
        case "Deportes": "sportscourt"
        case "Química": "testtube.2"
        case "Cine": "film"
        case "Música": "music.note"
        case "Filosofía": "text.bubble"
        case "Arte": "paintpalette"
        case "Matemática": "function"
        case "Videojuegos": "gamecontroller"
        default: "atom"
        }
    }
}

struct TarjetaTema: View {
    let titulo: String
    let tema: String
    var subtitulo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(titulo, systemImage: EstiloEdustream.simbolo(tema))
                .font(.system(.headline, design: .serif))
            if let subtitulo {
                Text(subtitulo).font(.subheadline)
            }
            Capsule().fill(EstiloEdustream.acento(tema)).frame(height: 4)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(EstiloEdustream.tinta, in: RoundedRectangle(cornerRadius: 12))
    }
}
