import SwiftUI

@MainActor
struct BibliotecaTemaView: View {
    let tema: String
    let lecciones: [Leccion]
    let firebase: FirebaseEdustream

    var body: some View {
        List {
            VStack(spacing: 12) {
                Image(systemName: EstiloEdustream.simbolo(tema))
                    .font(.system(size: 42))
                    .accessibilityHidden(true)
                Text(tema).font(.system(.largeTitle, design: .serif))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(EstiloEdustream.tinta, in: RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .bottom) {
                Capsule().fill(EstiloEdustream.acento(tema))
                    .frame(height: 5).padding(.horizontal, 14).padding(.bottom, 6)
            }

            ForEach(lecciones) { leccion in
                NavigationLink {
                    BibliotecaDetalleView(leccion: leccion, firebase: firebase)
                } label: {
                    TarjetaTema(titulo: leccion.titulo, tema: leccion.tema,
                                subtitulo: "\(leccion.nivel) · \(leccion.minutos) min")
                }
            }

            NavigationLink("Intentar quiz") {
                BibliotecaQuizView(titulo: "Quiz de \(tema)", lecciones: lecciones, firebase: firebase)
            }
        }
        .listStyle(.plain)
        .navigationTitle(tema)
        .navigationBarTitleDisplayMode(.inline)
    }
}
