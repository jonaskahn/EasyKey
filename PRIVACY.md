# EasyKey Privacy

EasyKey separates local typing, local translation, and optional cloud translation.

## Local Processing

- Vietnamese typing transformations, macros, encoding conversion, settings, and pronunciation run on your Mac.
- Typing outside translation editors does not invoke translation and is not uploaded.
- Apple Translation runs on-device on macOS 15 or later. macOS may download language resources from Apple.
- EasyKey collects no analytics or telemetry.

## Optional Cloud Translation

Cloud translation is opt-in. In the translation source editor or Option+A popup, when you type or paste, EasyKey sends submitted source text directly to the selected provider after the configured idle delay. Each edit restarts the timer. Pressing Return translates immediately. General keyboard input outside translation editors is not translated. Requests do not pass through an EasyKey server.

First use of each cloud provider shows a disclosure naming the provider and explaining transfer before the request proceeds. Declining cancels the request. Consent can be reset in Translation settings.

Provider handling and retention depend on provider terms, account tier, and account controls. Links reviewed on July 19, 2026:

- [DeepL Privacy Policy](https://www.deepl.com/privacy)
- [Google Cloud Translation data usage](https://cloud.google.com/translate/data-usage)
- [OpenAI API data controls](https://platform.openai.com/docs/guides/your-data)
- [Anthropic Privacy Center](https://privacy.anthropic.com/)
- [Gemini API Additional Terms](https://ai.google.dev/gemini-api/terms)

Provider names and links identify interoperability and provider-controlled data handling. They do not imply sponsorship, affiliation, or endorsement.

## Credentials And Persistence

- Cloud-provider credentials are stored in macOS Keychain with `WhenUnlockedThisDeviceOnly` accessibility and synchronization disabled.
- Credential validation contacts provider account, usage, model, or minimal translation endpoints as required by that provider. It does not submit source text.
- EasyKey does not persist source text, translated results, provider prompts, or translation history.
- Translation content and credentials are excluded from EasyKey logs and diagnostic exports.

## Other Network Activity

When configured, Sparkle checks the release appcast over HTTPS and verifies update signatures. EasyKey otherwise contacts only a selected translation provider for explicit translation or credential validation.

Clipboard history is a separate opt-in local feature. See README for its memory-only default and optional encrypted persistence behavior.
