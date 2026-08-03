---
id: "adr-encrypted-clipboard"
title: "Adr Encrypted Clipboard"
docforge_provenance:
  schema: "2.0"
  doc_id: "adr-encrypted-clipboard"
  path: "docs/architecture/decisions/encrypted-clipboard.md"
  generated_at: "2026-08-03T08:44:33Z"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections:
    - id: "context-and-problem-statement"
      sources:
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "history"
      unresolved: []
    - id: "decision"
      sources:
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardKeyStore.swift"
          git_blob: "8308409cb0bb907254e169b15dd74b9304399ed3"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardHistoryModel.swift"
          git_blob: "6fe0b0f894f3d17c9546f48eb32f497701ac0ede"
          role: "code"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "consequences"
      sources:
        - path: "EasyKeyApp/Features/Clipboard/ClipboardKeyStore.swift"
          git_blob: "8308409cb0bb907254e169b15dd74b9304399ed3"
          role: "code"
        - path: "EasyKeyApp/Features/Clipboard/ClipboardPersistence.swift"
          git_blob: "2f2f6e1c7c03071c95010c565309b55a06b15c34"
          role: "code"
        - path: "README.md"
          git_blob: "8a49fce7363abdb421327cd946dd2c356d9d1c1a"
          role: "doc"
      unresolved: []
    - id: "confirmation"
      sources:
        - path: "EasyKeyTests/ClipboardPersistenceTests.swift"
          git_blob: "57c5f410fff920cbe73f2ea4f3dc376e42e4f5b1"
          role: "test"
        - path: "EasyKeyTests/ClipboardHistoryModelTests.swift"
          git_blob: "1bcf884200d20c95d0d60cabf476d1310c778965"
          role: "test"
      unresolved: []
---
# 2. Encrypt persisted clipboard history with AES-GCM and a device-only Keychain key

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** project maintainer

## Context and problem statement

The clipboard manager captures copied text, URLs, images, and file references. It is off by default and history stays in memory unless "Keep history after restart" is enabled — but once persistence exists, clipboard content sits at rest in the app's Application Support directory, readable by any process running as the user. The "Private by Design" posture in [product overview](../../product/overview.md) rules out plaintext history: "History remains in memory unless Keep history after restart is enabled; then it is AES-GCM encrypted on-device with an unlocked-this-device-only, non-synchronizing Keychain key. Disabling persistence deletes stored data." The opt-in clipboard manager shipped in commit b6ab8c5 with this design in place.

## Considered options

- **AES-GCM sealing with a Keychain-held key** — CryptoKit `AES.GCM`, 256-bit symmetric key stored in the Keychain, never synchronized.
- **Plaintext JSON on disk** — simplest, but contradicts the privacy contract.
- **Reliance on FileVault** — whole-disk encryption is not guaranteed to be enabled on the user's Mac.
- **No persistence** — the "keep history after restart" feature could not exist.

## Decision

We chose **AES-GCM with a device-only Keychain key**. `ClipboardPersistence` is an actor that seals the history manifest and every image/RTF payload with `AES.GCM.seal`, writes sealed `.ekc`/`.ekp` files, and bounds every read by size; `KeychainClipboardKeyStore` stores a 256-bit key with `kSecAttrSynchronizable = false` and `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, using the data-protection Keychain outside test runs. History is off by default; `deleteAll()` removes the on-disk directory and deletes the Keychain key, and `ClipboardHistoryModel.clearAll()`/`disablePersistence` advance a generation counter so no queued save can commit after the state is cleared. [product overview](../../product/overview.md) documents the user-visible contract: disabling persistence deletes stored data.

## Decision drivers

- The threat model is "at rest on this Mac": content must be unreadable without the device unlocked and the Keychain available — nothing more, nothing less.
- Keychain `WhenUnlockedThisDeviceOnly` with synchronization disabled is the platform-native way to express "this device only", which the privacy text promises.
- CryptoKit's `AES.GCM` is a first-party primitive, avoiding a third-party cryptography dependency.

## Option comparison

| Option | Good | Neutral | Bad |
|---|---|---|---|
| AES-GCM + Keychain key | content sealed at rest; no third-party crypto; key never leaves the device | key material handled by the OS Keychain | losing the key loses history — deliberately, recovery is impossible |
| Plaintext JSON | trivially debuggable | — | any user-readable file leaks clipboard content; violates the privacy contract |
| FileVault reliance | zero code | — | cannot be assumed; users may have it disabled |
| No persistence | nothing to protect | — | drops the feature; "keep history after restart" impossible |

## Consequences

**Positive:** persisted history is unreadable at rest without the device-unlocked Keychain; disabling persistence or clearing history removes both the ciphertext and the key, so the data is unrecoverable; payload and manifest sizes are bounded on both write and read.

**Negative:** the key is non-recoverable — restoring a Time Machine backup without the Keychain item, or reinstalling macOS, makes old history permanently unreadable; every save and load pays the sealing overhead; the design deliberately blocks any future cross-device history sync.

**Neutral:** persistence is now an explicit, privacy-labeled opt-in with its own data-lifecycle semantics (clear = key deletion), distinct from in-memory capture.

## Revisit if

- Users ask for cross-device clipboard history (requires a different key-distribution model and contradicts the current privacy promise).
- The Keychain accessibility policy changes on future macOS releases.
- CryptoKit's `AES.GCM` sealed-box format needs migration (the versioned `schemaVersion` field in the persistence document is the intended seam).

## Confirmation

`ClipboardPersistenceTests` exercises save/load/deleteAll round-trips and bounded-read limits, and `ClipboardHistoryModelTests` covers `clearAll()` deleting disk state and key as one serialized sequence. Both run under `make test`; the 90% line-coverage gate is enforced by `make coverage` and CI.
