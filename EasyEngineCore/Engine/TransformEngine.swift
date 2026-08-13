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

    /// Per-atom encoded units of the buffer. Platform layers use the UTF-16
    /// counts of these units for deletion counting without inspecting engine
    /// internals.
    public static func encodeUnits(
        _ state: SessionState,
        configuration: EngineConfiguration
    ) -> [String] {
        let toneTarget = TelexComposer.toneTargetIndex(atoms: state.atoms, style: configuration.toneStyle)
        return state.atoms.enumerated().map { index, atom in
            encode(
                atoms: [atom],
                tone: index == toneTarget ? state.tone : .none,
                encoding: configuration.outputEncoding,
                toneStyle: configuration.toneStyle
            )
        }
    }
}
