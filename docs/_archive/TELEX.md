---
id: "existing-telex"
title: "Telex Rule Set"
docforge_provenance:
  schema: "2.0"
  doc_id: "existing-telex"
  path: "docs/TELEX.md"
  generated_at: "2026-08-03T10:27:57+00:00"
  generator:
    name: "docforge"
    version: "2.8.0"
  tier: "diligence"
  target_depth: "reference"
  graph:
    provider: "codegraph"
    flow: "none"
  sections: []
---
# Telex Rule Set

This document defines EasyKey's implemented Telex behavior. When documentation, tests, and code disagree, this rule set and its conformance tests must be updated together.

## Input Profiles

EasyKey provides two Telex profiles:

| Behavior | Telex | Simple Telex |
|---|---:|---:|
| `aa`, `aw`, `ee`, `oo`, `ow`, `uw`, `dd` | Yes | Yes |
| Tone keys `s`, `f`, `r`, `x`, `j`, `z` | Yes | Yes |
| Position-free marks and tones | Yes | Yes |
| Repeat-to-undo | Yes | Yes |
| Standalone `w` to `ư` | Configurable, on by default | No |
| `[` to `ơ`, `]` to `ư`, `{` to `Ơ`, `}` to `Ư` | Configurable, on by default | No |

Simple Telex is not a tones-only mode. It is full Telex without standalone-`w` and bracket extensions. `aw`, `ow`, `uw`, and `uow` still work because `w` remains a modifier after a vowel.

## Letter Modifiers

Modifier keys are case-insensitive. Output case comes from the modified base letter.

| Input | Output | Example |
|---|---|---|
| `aa` | `â` | `caan` to `cân` |
| `aw` | `ă` | `trangw` to `trăng` |
| `ee` | `ê` | `ddeem` to `đêm` |
| `oo` | `ô` | `nhoo` to `nhô` |
| `ow` | `ơ` | `mow` to `mơ` |
| `uw` | `ư` | `tuw` to `tư` |
| `dd` | `đ` | `ddau` to `đâu` |
| `uow` | `ươ` | `uowj` to `ượ` |

Full Telex also supports:

| Input | Output |
|---|---|
| Standalone `w` | `ư` |
| `[` | `ơ` |
| `]` | `ư` |
| `{` | `Ơ` |
| `}` | `Ư` |

Standalone `w` applies at word start or after a valid Vietnamese onset. For example, `w` becomes `ư` and `tw` becomes `tư`. It never modifies the `u` glide in `qu`; `quow` becomes `quơ`.

## Tone Keys

| Key | Tone | Example |
|---|---|---|
| `s` | sắc | `tas` to `tá` |
| `f` | huyền | `taf` to `tà` |
| `r` | hỏi | `tar` to `tả` |
| `x` | ngã | `tax` to `tã` |
| `j` | nặng | `taj` to `tạ` |
| `z` | remove tone | `tasz` to `ta` |

Tone keys can appear anywhere in the active word. A later tone key replaces the current tone. `z` removes only the tone; it does not remove `â`, `ă`, `ê`, `ô`, `ơ`, `ư`, or `đ`.

A syllable ending in `c`, `ch`, `k`, `p`, or `t` requires sắc or nặng — a toneless checked final is not a complete Vietnamese syllable. An invalid tone key typed after such a final remains literal. Invalid checked-tone combinations formed by typing the final later (including a checked final with no tone) are rejected by spell validation at the word boundary.

## Position-Free Composition

EasyKey stores every raw keystroke and recomposes the active word after each edit.

- Tone keys apply to the complete vowel nucleus, regardless of key position.
- `a`, `e`, and `o` modifier repeats can find the nearest matching unmarked vowel in the active word. `baan` and `bana` both become `bân`.
- `w` scans backward through the active vowel nucleus. `Cuiw` becomes `Cưi`.
- `w` can convert `uo` across a valid final consonant. `dduocwj` becomes `được`.
- Backspace removes one raw keystroke and recomposes the remaining keys.

The engine infers required nucleus marks for standard Vietnamese forms:

- Plain `ie`, `ye`, or `uye` receives `ê` when a tone is applied, so `vietj` becomes `việt` and `Nguyexn` becomes `Nguyễn`.
- Applying `w` to `uoi` produces `ươi`, so `nguoiwf` becomes `người`.

## Repeat-To-Undo

Repeating the key that caused the latest reversible transformation removes that transformation and emits the key literally.

| Input | Output |
|---|---|
| `ass` | `as` |
| `herr` | `her` |
| `aaa` | `aa` |
| `aww` | `aw` |
| `ddd` | `dd` |
| `xooong` | `xoong` |

After an undo, later keys are interpreted normally. For example, `aaaa` becomes `aâ` and `dddd` becomes `dđ`.

## Tone Placement

EasyKey splits the active syllable into onset, vowel nucleus, and final. In `qu` and non-standalone `gi`, the `u` or `i` glide belongs to the onset and never receives the tone. Standalone `gì` keeps `i` as its vowel.

Tone target priority is strict:

1. One nucleus vowel: use it.
2. Nucleus contains `ơ`: use `ơ`.
3. Nucleus contains another marked vowel (`â`, `ă`, `ê`, `ô`, or `ư`): use it.
4. Syllable has a final consonant: use the last nucleus vowel.
5. Open bare `oo`: use the last vowel.
6. New style: open bare `oa`, `oe`, and `uy` use the last vowel.
7. Other open syllables: use the penultimate nucleus vowel.

This produces `việt`, `được`, `người`, `trường`, `Nguyễn`, `khuyến`, `khuỷu`, `ngoằn`, `của`, `mía`, `quả`, and `gì`.

## Old And New Styles

Old style is the default.

| Old style | New style |
|---|---|
| `hòa` | `hoà` |
| `khỏe` | `khoẻ` |
| `thủy` | `thuỷ` |

The styles differ only for open bare `oa`, `oe`, and `uy`. Closed syllables such as `hoàn`, `oo` clusters, and triphthongs such as `ngoáy` are identical in both styles.

## `uơ` And `ươ`

`uo` plus `w` normally becomes `ươ`. EasyKey keeps the plain `u` in these legal open exceptions:

- `thuowr` to `thuở`
- `quow` to `quơ` (`u` is already part of the `qu` onset)
- `huow` to `huơ`
- `khuow` to `khuơ`

Final-bearing forms continue to use normal `ươ`, so `thuowng` becomes `thương`.

## Spell Validation And Restoration

Spell checking runs when a word boundary is typed. Validation is structural and intentionally permissive. It checks:

- recognized Vietnamese onset;
- recognized vowel nucleus;
- recognized final consonant;
- checked-final tone legality.

When validation fails and automatic restoration is enabled, EasyKey replaces the transformed word with its exact raw keystrokes before inserting the boundary. This preserves English input such as `fix`.

The configurable restore-word shortcut performs the same raw restoration immediately. After manual restoration (`forceRaw`), typing a new non-boundary character commits the restored raw word and starts a new word.

## Live Confidence Scoring (Tier 2)

Optional advisory scoring runs after each keystroke when `typing.liveConfidenceScoring` is enabled (off by default). Composition always continues; the score only chooses whether `currentBuffer` shows the composed form or the raw keystrokes.

| Band | Score range (defaults) | Live display |
|---|---|---|
| High | `≥ 0.80` | Composed |
| Middle | `0.35 .. < 0.80` | Composed |
| Low | `< 0.35` | Raw keystrokes |

`forceRaw` (restore-word shortcut) always wins over the live band. Word-boundary commit remains Tier 1: `resolvedBoundaryText()` validates the composed buffer with `isValidWord` and never consults the live band.

Score starts at `0.55` and applies phonotactic signals only (no English wordlist): legal onset/prefix, illegal onset, nucleus parse progress, modifier density, long illegal consonant runs, and long runs with no modifiers.

## Optional Quick Telex Consonants

This option is off by default and is independent of Telex versus Simple Telex.

| Input | Output |
|---|---|
| `cc` | `ch` |
| `gg` | `gi` |
| `kk` | `kh` |
| `nn` | `ng` |
| `qq` | `qu` |
| `pp` | `ph` |
| `tt` | `th` |

## Defaults

- Input method: Simple Telex
- Tone style: old (`hòa`, `thủy`, `khỏe`)
- Position-free composition: always enabled
- Spell check: enabled
- Live confidence scoring: disabled
- Live confidence thresholds: low `0.35`, high `0.80`
- Automatic invalid-word restoration: enabled
- Standalone `w`: enabled for full Telex
- Bracket shortcuts: enabled for full Telex
- Quick Telex consonants: disabled
- Restore-word shortcut: unassigned

## Implementation Boundaries

- `TelexComposer` deterministically maps raw keys to composed atoms and tone.
- `VietnameseEngine` owns active raw keys, recomposition, boundaries, backspace, and restoration. When Tier 2 live confidence is enabled, it may instruct the display path to show raw keystrokes in the low band; boundary commit still uses the composed buffer.
- `VietnameseOrthography` owns onset, nucleus, final, and checked-tone validation, plus Tier 2 advisory `liveConfidenceScore` / band helpers.
- `TransformEngine` only renders composed atoms through the selected output encoding.
- `KeyboardInputPipeline` translates macOS events into engine events and applies engine edits. When the engine displays raw keystrokes, replacement units track insert characters rather than composed atoms.
