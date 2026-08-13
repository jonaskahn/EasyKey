import EasyEngineCore
import Foundation

struct MacroExpansion {
    let triggerLength: Int
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

    mutating func update(macros: [Macro]) {
        self.macros = macros
        trigger = ""
    }

    mutating func reset() {
        trigger = ""
    }

    mutating func consume(
        character: Character,
        keyCode: UInt16,
        modifiers: Shortcut.ModifierFlags,
        options: MacroOptions,
        language: InputLanguage
    ) -> MacroExpansion? {
        guard options.enabled,
              modifiers.isEmpty
        else {
            trigger = ""
            return nil
        }

        guard Self.delimiterKeyCodes.contains(keyCode) else {
            guard !character.isWhitespace else {
                trigger = ""
                return nil
            }
            trigger.append(character)
            if trigger.count > MacroStore.maximumTriggerLength {
                trigger.removeFirst(trigger.count - MacroStore.maximumTriggerLength)
            }
            return nil
        }

        defer { trigger = "" }
        guard let macro = macros.first(where: {
            $0.isEnabled
                && $0.category.matches(language)
                && $0.trigger.compare(trigger, options: .caseInsensitive) == .orderedSame
        })
        else {
            return nil
        }
        let text = options.autoCapitalize
            ? MacroStore.matchCapitalization(of: trigger, in: macro.expansion)
            : macro.expansion
        return MacroExpansion(triggerLength: trigger.count, text: text)
    }
}
