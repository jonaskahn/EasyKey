---
id: "ai_integration"
title: "Ai Integration"
docforge_provenance:
  schema: "2.0"
  doc_id: "ai_integration"
  path: "docs/architecture/ai-integration.md"
  generated_at: "2026-08-03T10:00:00Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "deep-dive"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "ai-integration"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
      unresolved: []
    - id: "promptinput-surface"
      sources:
        - path: "EasyKeyApp/Features/Translation/SelectedTextCapture.swift"
          role: "code"
          git_blob: "9dcda2f02bf3f5110956dd12a292859a5789f6fd"
        - path: "EasyEngineCore/Translation/TranslationRequest.swift"
          role: "code"
          git_blob: "58f100adfd94b13ed6e9a0689983a9446f8491f0"
        - path: "EasyKeyApp/Features/Translation/HostSafety.swift"
          role: "code"
          git_blob: "275d4aa9b65469565580f4a241d4d4a6cbadb3aa"
      unresolved: []
    - id: "output-handling"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
        - path: "EasyKeyApp/Features/Translation/TranslationPanelPresenter.swift"
          role: "code"
          git_blob: "c4db933b5e640c60680df6bc917baa1db669947e"
      unresolved: []
    - id: "safety-and-evaluation"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppTranslationRuntime.swift"
          role: "code"
          git_blob: "c4df84fdde3f664cd167d91ce3a64b387e6ef30e"
        - path: "EasyKeyApp/Features/Settings/Translation/TranslationSettingsModel.swift"
          role: "code"
          git_blob: "6380a5fed49e57b42d37bb611ddcb6d26661ee43"
        - path: "EasyKeyApp/Features/Translation/HostSafety.swift"
          role: "code"
          git_blob: "275d4aa9b65469565580f4a241d4d4a6cbadb3aa"
      unresolved: []
    - id: "failure-and-fallback"
      sources:
        - path: "EasyKeyApp/Features/Translation/AppleTranslationProvider.swift"
          role: "code"
          git_blob: "b214166c0c4a16d48731844087c4810f4af89ca9"
        - path: "EasyKeyApp/Features/Translation/GoogleTranslationProvider.swift"
          role: "code"
          git_blob: "a58ea2ffd3149408365009e036353d1c130b3056"
      unresolved: []
    - id: "privacy-boundary"
      sources:
        - path: "README.md"
          role: "doc"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
        - path: "docs/_archive/PRIVACY.md"
          role: "doc"
          git_blob: "4fab52de09cef3d41e3f25c500a4ab0df475a2b1"
        - path: "EasyKeyApp/Features/Translation/TranslationCredentialStore.swift"
          role: "code"
          git_blob: "768aab956a8d02978101105e7a896b6d55c75376"
      unresolved: []
---
# AI integration

_Last reviewed: 2026-08-03_

EasyKey has no trained or fine-tuned model of its own — model-quality claims are therefore out of scope. This document covers the integration boundary only: what reaches a model, through which provider, and what happens to the result. Translation runs either on-device (Apple Translation, macOS 15+) or through a user-configured cloud provider; typing itself never touches a model.

```mermaid
flowchart LR
  Surface["Translation surfaces (editor, menu popover, hotkey panel)"] --> Runtime["AppTranslationRuntime"]
  Runtime -->|"source text + language pair"| Apple["Apple Translation (macOS 15+, on-device)"]
  Runtime -->|"source text + API key from Keychain"| Cloud["Cloud providers (Google, DeepL, OpenAI, Anthropic, Gemini, OpenRouter, Groq, compatible)"]
```

The boundary is deliberately narrow: exactly one request type (translate), a fixed set of provider adapters behind the `TranslationProviding` protocol, and no EasyKey-operated server in the path.

## Prompt/input surface

What reaches the model: plain source text plus a source/target language pair (`TranslationRequest`) — there are no prompt templates, system prompts, or conversational context. Input enters through three surfaces: the translation editor (user-typed), the menu-bar popover translation field, and captured selected text (`SelectedTextCaptureCoordinator`).

Scoping before a request reaches the network:

- **Selection capture is capped.** `AccessibilitySelectedTextReader` reads the focused element's selected text only for supported roles (text field, text area, combo box, static text, web area) and refuses secure fields; oversized selections (`> TranslationRequest.maximumSourceTextLength`) and blank results are rejected before any request.
- **Fallback capture restores the pasteboard.** When AX reading fails, `SystemSelectedTextSimulator` posts a simulated Cmd+C, saves and restores the user's pasteboard items, and only then submits.
- **Endpoints are fixed or validated.** Built-in providers use compile-time-validated URLs (`_validatedURL`); user-supplied "compatible" endpoints are rejected by `EasyKeyApp/Features/Translation/HostSafety.swift` unless they resolve to public, non-private, non-loopback hosts.
- **Auto-translate is time-boxed.** The configured auto-translation delay resets on every edit, so partial typing does not send a stream of half-formed requests.

## Output handling

**Used as:** shown directly to the user (advisory, user-confirmed) — never used to drive an action.

The provider response lands in the translation model and is rendered in the translation panel or menu-popover view; the user decides to replace the source text in the editor (via `TranslationTextEditor`), copy the result, or invoke optional speech. There is no path where model output triggers a system action, a write, or further network traffic.

## Safety and evaluation

**Safety controls:** no content filtering is applied to either direction — source text is sent verbatim and completions are shown verbatim. The controls that do exist are structural: first-use disclosure identifies each cloud provider before its first request (`TranslationDisclosureController`); credentials are validated against the provider's own endpoints before first use (`EasyKeyApp/Features/Settings/Translation/TranslationSettingsModel.swift` probes provider model endpoints); user-supplied endpoints are host-validated; and the Apple provider is availability-gated per OS.

**Evaluation evidence:** each provider adapter has a dedicated unit suite (`AppleTranslationProviderTests`, `GoogleTranslationProviderTests`, `DeepLTranslationProviderTests`, `OpenAICompatibleTranslationProviderTests`, credential-validation suites under `EasyKeyTests/`), and selected-text capture has its own suite (`SelectedTextCaptureTests`). Translation output quality is not evaluated by this repository — for cloud models that evaluation belongs to each provider; for Apple Translation it is Apple's model lifecycle, not EasyKey's.

## Failure and fallback

- **Provider unavailable:** adapters map network/HTTP failures to `TranslationError.providerUnavailable` (20 s request timeout); the panel presents the error and keeps the source text — no silent retry, no queue.
- **Unsupported language pair:** surfaces as `unsupportedLanguagePair`; the Apple provider additionally maps Apple's own unsupported-pair errors through the same domain error.
- **Language pack missing (Apple):** `appleLanguageDownloadRequired` tells the user a download is needed rather than failing opaque.
- **Cancellation:** user dismissal cancels the in-flight request and maps to `.cancelled`; in-flight state is dropped, not corrupted.
- **Credential failure:** stored-key absence or rejection shows `missing`/`invalid` status in the translation settings; translation requests from panels fail closed with the same status.

## Privacy boundary

- **Does user data leave the system in the prompt?** Yes, but only under explicit conditions: a cloud provider must be selected and configured, and a request is sent only from a translation surface (editor, popover, or hotkey panel) when the user translates or the configured auto-translate delay elapses after an edit. Typing and clipboard content never reach a provider.
- **Is it retained by the provider?** EasyKey does not know — providers handle submitted text under their own terms (documented per-provider in [PRIVACY.md](../security/data-handling.md)). EasyKey itself does not proxy, log, or persist source text, results, or history.
- **Credentials:** API keys live in the user's Keychain, device-only and non-synchronizing (`KeychainTranslationCredentialStore`); validation is a live endpoint check that does not submit source text.

See [data-handling](../security/data-handling.md) for the data-flow classification and [threat-model](../security/threat-model.md) for the model/provider call as an external trust boundary.
