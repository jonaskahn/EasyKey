import Foundation

/// Encoding facade. Composition lives in `TelexComposer`; this type renders
/// composed atoms plus tone through the selected output encoding.
public enum TransformEngine {
    public static func encode(
        atoms: [BufferAtom],
        tone: Tone,
        encoding: EncodingTable,
        toneStyle: ToneStyle
    ) -> String {
        let encoder = EncodingFactory.encoding(for: encoding)
        let toneTarget = TelexComposer.toneTargetIndex(atoms: atoms, style: toneStyle)
        return encoder.encode(atoms: atoms, tone: tone, toneTargetIndex: toneTarget)
    }

    public static func encode(
        _ state: SessionState,
        configuration: EngineConfiguration
    ) -> String {
        encode(
            atoms: state.atoms,
            tone: state.tone,
            encoding: configuration.outputEncoding,
            toneStyle: configuration.toneStyle
        )
    }
}
