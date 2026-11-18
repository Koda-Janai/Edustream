import Foundation
import SwiftUI

@MainActor
struct BibliotecaLecturaView: View {
    let leccion: Leccion
    let firebase: FirebaseEdustream

    @StateObject private var narracion = BibliotecaNarracion()
    @State private var pagina = 0
    @State private var avance = 0
    @State private var guardado = 0
    @State private var restaurando = true
    @State private var guardando = false
    @State private var error: String?

    private var parrafos: [String] {
        let bloques = leccion.texto.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return bloques.isEmpty ? [leccion.texto] : bloques
    }

    private var texto: String { parrafos[pagina] }

    var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Fragmento \(pagina + 1) de \(parrafos.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .id("inicio")
                    Text(textoResaltado)
                        .font(.system(.body, design: .serif))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if restaurando { ProgressView("Consultando posición") }
                    if let error {
                        Text(error).foregroundStyle(.secondary)
                        if avance > guardado {
                            Button("Reintentar guardado") { Task { await guardarAvance() } }
                        }
                    }
                }
                .padding()
            }
            .onChange(of: pagina) { _, _ in scroll.scrollTo("inicio", anchor: .top) }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button {
                    narracion.alternar(texto: texto, idioma: "es-MX")
                } label: {
                    Label(etiqueta, systemImage: muestraPausa ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(EstiloEdustream.tinta)
                .disabled(texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || narracion.estado == .pausando || narracion.estado == .continuando)

                if parrafos.count > 1 {
                    HStack {
                        Button("Anterior") { avanzar(-1) }.disabled(restaurando || pagina == 0)
                        Spacer()
                        Button("Siguiente") { avanzar(1) }.disabled(restaurando || pagina + 1 >= parrafos.count)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
        }
        .navigationTitle(leccion.titulo)
        .navigationBarTitleDisplayMode(.inline)
        .task { await restaurar() }
        .onDisappear { narracion.detener() }
    }

    private func avanzar(_ paso: Int) {
        let siguiente = pagina + paso
        guard parrafos.indices.contains(siguiente) else { return }
        narracion.detener()
        pagina = siguiente
        avance = max(avance, pagina)
        Task { await guardarAvance() }
    }

    private func restaurar() async {
        defer { restaurando = false }
        guard let id = leccion.id else { return }
        do {
            let posicion = try await firebase.cargarPosicion(id)
            guard !Task.isCancelled else { return }
            let visible = min(max(0, posicion), parrafos.count - 1)
            if pagina != visible { narracion.detener() }
            pagina = visible
            avance = visible
            guardado = visible
        } catch {
            if !Task.isCancelled { self.error = "No se pudo recuperar la posición de lectura." }
        }
    }

    private func guardarAvance() async {
        guard !guardando, let id = leccion.id else { return }
        guardando = true
        defer { guardando = false }

        while avance > guardado {
            let posicion = avance
            do {
                try await firebase.guardarPosicion(posicion, leccion: id)
                guardado = posicion
                error = nil
            } catch {
                self.error = "No se pudo guardar el avance de lectura."
                return
            }
        }
    }

    private var muestraPausa: Bool {
        narracion.estado == .reproduciendo || narracion.estado == .pausando
    }

    private var etiqueta: String {
        switch narracion.estado {
        case .detenida: return "Escuchar"
        case .reproduciendo, .pausando: return "Pausar"
        case .pausada, .continuando: return "Continuar"
        }
    }

    private var textoResaltado: AttributedString {
        var resultado = AttributedString(texto)
        guard let fragmento = narracion.fragmento,
              let rango = Range(fragmento, in: texto),
              let inicio = AttributedString.Index(rango.lowerBound, within: resultado),
              let fin = AttributedString.Index(rango.upperBound, within: resultado) else {
            return resultado
        }
        resultado[inicio..<fin].backgroundColor = Color.yellow.opacity(0.4)
        resultado[inicio..<fin].underlineStyle = .single
        return resultado
    }
}
