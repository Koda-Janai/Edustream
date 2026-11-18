import SwiftUI

@MainActor
struct BibliotecaView: View {
    let firebase: FirebaseEdustream

    @State private var lecciones: [Leccion] = []
    @State private var consulta = ""
    @State private var nivel = ""
    @State private var cargando = false
    @State private var cargoCatalogo = false
    @State private var error: String?

    private var resultados: [Leccion] {
        lecciones.filter { (nivel.isEmpty || $0.nivel == nivel) && $0.coincide(con: consulta) }
    }

    private var exploraTemas: Bool {
        consulta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && nivel.isEmpty
    }

    private let orden = ["Series", "Historia", "Deportes", "Química", "Cine", "Música",
                         "Filosofía", "Arte", "Matemática", "Videojuegos", "Física"]

    var body: some View {
        Group {
            if !cargoCatalogo && (cargando || error == nil) {
                ProgressView("Cargando lecciones")
            } else if !cargoCatalogo, let error {
                ContentUnavailableView {
                    Label("No se pudo cargar Biblioteca", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Reintentar") { Task { await cargar() } }
                }
            } else {
                List {
                    if let error {
                        Text(error).foregroundStyle(.secondary)
                    }
                    if lecciones.isEmpty {
                        Text("Todavía no hay lecciones publicadas.")
                    } else if exploraTemas {
                        NavigationLink {
                            BibliotecaQuizView(titulo: "Prueba tus conocimientos",
                                               lecciones: lecciones, firebase: firebase)
                        } label: {
                            Label("Prueba tus conocimientos", systemImage: "checkmark.seal")
                                .font(.system(.headline, design: .serif))
                        }

                        let porTema = Dictionary(grouping: lecciones, by: \.tema)
                        let temas = orden.filter { porTema[$0] != nil }
                            + porTema.keys.filter { !orden.contains($0) }.sorted()
                        Section {
                            ForEach(temas, id: \.self) { tema in
                                NavigationLink {
                                    BibliotecaTemaView(tema: tema, lecciones: porTema[tema, default: []],
                                                        firebase: firebase)
                                } label: {
                                    TarjetaTema(titulo: tema, tema: tema)
                                }
                            }
                        }
                        let destacadas = lecciones.filter(\.destacada)
                        if !destacadas.isEmpty {
                            Section("Destacados") {
                                ForEach(destacadas, content: enlace)
                            }
                        }
                    } else if resultados.isEmpty {
                        ContentUnavailableView.search(text: consulta)
                    } else {
                        ForEach(resultados, content: enlace)
                    }
                }
                .listStyle(.plain)
                .refreshable { await cargar() }
                .searchable(text: $consulta, prompt: "Título, tema o área")
            }
        }
        .navigationTitle("Escoge un tema")
        .toolbar {
            if !lecciones.isEmpty {
                Menu {
                    Picker("Nivel", selection: $nivel) {
                        Text("Todos los niveles").tag("")
                        ForEach(Set(lecciones.map(\.nivel)).sorted(), id: \.self) { nivel in
                            Text(nivel).tag(nivel)
                        }
                    }
                } label: {
                    Label("Nivel", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task { if !cargoCatalogo { await cargar() } }
    }

    private func enlace(_ leccion: Leccion) -> some View {
        NavigationLink {
            BibliotecaDetalleView(leccion: leccion, firebase: firebase)
        } label: {
            TarjetaTema(titulo: leccion.titulo, tema: leccion.tema,
                        subtitulo: "\(leccion.nivel) · \(leccion.minutos) min")
        }
    }

    private func cargar() async {
        guard !cargando else { return }
        cargando = true
        defer { cargando = false }
        error = nil
        do {
            lecciones = try await firebase.cargarLecciones()
            cargoCatalogo = true
        } catch {
            if !Task.isCancelled { self.error = error.localizedDescription }
        }
    }
}
