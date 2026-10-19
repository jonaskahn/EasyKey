import EasyEngineCore
import Foundation

struct MacroExpansion {
    let trigger: String
    var triggerLength: Int { trigger.count }
    let text: String
}

struct MacroExpander {
    private static let delimiterKeyCodes: Set<UInt16> = [
        KeyboardKeyCode.returnOrEnter,
        KeyboardKeyCode.tab,
        KeyboardKeyCode.space,
    ]

    private var macros: [Macro] = []
    private var trigger = ""
    private var overflowed = false

    mutating func update(macros: [Macro]) {
        self.macros = macros
        reset(reason: "macros-updated")
    }

    mutating func reset(reason: String = "session") {
        if !trigger.isEmpty {
            AppLog.keyboardDebug("macro reset reason=\(reason) buffered=\(trigger.count)")
        }
        trigger = ""
        overflowed = false
    }

    mutating func consume(
        character: Character,
        keyCode: UInt16,
        modifiers: Shortcut.ModifierFlags,
        options: MacroOptions,
        language: InputLanguage
    ) -> MacroExpansion? {
        guard options.enabled,
              modifiers.isDisjoint(with: [.control, .option, .command])
        else {
            reset(reason: "disabled-or-shortcut")
            return nil
        }

        if keyCode == KeyboardKeyCode.backspace {
            if !trigger.isEmpty { trigger.removeLast() }
            return nil
        }

        guard Self.delimiterKeyCodes.contains(keyCode) else {
            guard !character.isWhitespace else {
                reset(reason: "whitespace")
                return nil
            }
            guard !overflowed else { return nil }
            trigger.append(character)
            if trigger.count > MacroStore.maximumTriggerLength {
                trigger = ""
                overflowed = true
            }
            return nil
        }

        defer { reset(reason: "delimiter") }
        guard !overflowed else { return nil }
        guard let macro = macros.first(where: {
            $0.isEnabled
                && $0.category.matches(language)
                && $0.trigger.compare(trigger, options: .caseInsensitive) == .orderedSame
        })
        else {
            AppLog.keyboardDebug("macro delimiter matched=false buffered=\(trigger.count) language=\(language)")
            return nil
        }
        let text = options.autoCapitalize
            ? MacroStore.matchCapitalization(of: trigger, in: macro.expansion)
            : macro.expansion
        return MacroExpansion(trigger: trigger, text: text)
    }
}
