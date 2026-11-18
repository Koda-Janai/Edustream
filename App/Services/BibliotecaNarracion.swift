import AVFoundation
import Foundation
import Combine

@MainActor
final class BibliotecaNarracion: NSObject, ObservableObject {
    enum Estado: Equatable {
        case detenida
        case reproduciendo
        case pausando
        case pausada
        case continuando
    }

    @Published private(set) var estado: Estado = .detenida
    @Published private(set) var fragmento: NSRange?

    private let sintetizador = AVSpeechSynthesizer()
    private var lecturaActiva: ObjectIdentifier?

    override init() {
        super.init()
        sintetizador.delegate = self
    }

    func alternar(texto: String, idioma: String) {
        switch estado {
        case .detenida:
            guard !texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            let mensaje = AVSpeechUtterance(string: texto)
            mensaje.voice = AVSpeechSynthesisVoice(language: idioma)
            lecturaActiva = ObjectIdentifier(mensaje)
            estado = .reproduciendo
            sintetizador.speak(mensaje)
        case .reproduciendo:
            if sintetizador.pauseSpeaking(at: .word) {
                estado = .pausando
            }
        case .pausada:
            if sintetizador.continueSpeaking() {
                estado = .continuando
            }
        case .pausando, .continuando:
            break
        }
    }

    func detener() {
        lecturaActiva = nil
        fragmento = nil
        estado = .detenida
        sintetizador.stopSpeaking(at: .immediate)
    }

    nonisolated private func actualizar(_ estado: Estado, para lectura: ObjectIdentifier) {
        Task { @MainActor in
            guard lecturaActiva == lectura else { return }
            self.estado = estado
            if estado == .detenida {
                fragmento = nil
                lecturaActiva = nil
            }
        }
    }
}

extension BibliotecaNarracion: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString rango: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let lectura = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard lecturaActiva == lectura,
                  estado == .reproduciendo || estado == .continuando else { return }
            fragmento = rango
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance
    ) {
        actualizar(.pausada, para: ObjectIdentifier(utterance))
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance
    ) {
        actualizar(.reproduciendo, para: ObjectIdentifier(utterance))
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
    ) {
        actualizar(.detenida, para: ObjectIdentifier(utterance))
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance
    ) {
        actualizar(.detenida, para: ObjectIdentifier(utterance))
    }
}
