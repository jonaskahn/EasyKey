import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct MacroEditorSheet: View {
    let macro: Macro?
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var trigger = ""
    @State private var expansion = ""
    @State private var enabled = true
    @State private var category: MacroCategory = .vietnamese
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(macro == nil ? localization.string(.macrosNew) : localization.string(.macrosEdit))
                .font(.title2.weight(.semibold))

            Form {
                TextField(localization.string(.macrosTrigger), text: $trigger)

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.string(.macrosExpansionField))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $expansion)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: DesignScale.radiusSM))
                        .accessibilityLabel(localization.string(.macrosExpansionField))
                }

                Toggle(localization.string(.commonEnabled), isOn: $enabled)

                Picker(localization.string(.macrosCategory), selection: $category) {
                    Text(localization.string(.languageVietnamese)).tag(MacroCategory.vietnamese)
                    Text(localization.string(.languageEnglish)).tag(MacroCategory.english)
                    Text(localization.string(.languageBoth)).tag(MacroCategory.both)
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)

            if let error {
                Text(error).foregroundStyle(.red).font(.caption)
            }

            HStack {
                Spacer()
                Button(localization.string(.commonCancel)) { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.cancelAction)
                Button(localization.string(.commonSave)) { save() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || expansion.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            trigger = macro?.trigger ?? ""
            expansion = macro?.expansion ?? ""
            enabled = macro?.isEnabled ?? true
            category = macro?.category ?? .vietnamese
        }
    }

    func save() {
        do {
            if let macro {
                _ = try coordinator.macroStore.edit(
                    id: macro.id,
                    trigger: trigger,
                    expansion: expansion,
                    isEnabled: enabled,
                    category: category
                )
            } else {
                _ = try coordinator.macroStore.add(trigger: trigger, expansion: expansion, isEnabled: enabled, category: category)
            }
            coordinator.refreshMacros()
            dismiss()
        } catch {
            self.error = localization.errorMessage(error)
        }
    }
}
