PROJECT = EasyKey.xcodeproj
SCHEME = EasyKeyApp
CONFIGURATION_DEBUG = Debug
CONFIGURATION_RELEASE = Release
DESTINATION = platform=macOS
BUILD_DIR = $(CURDIR)/build
XCODEBUILD = xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination "$(DESTINATION)" -derivedDataPath "$(BUILD_DIR)"

.DEFAULT_GOAL := help

.PHONY: all build release run test coverage lint format clean clean-local clean-all qa archive export verify-arch verify-release dmg local-dmg help

# `make` with no args prints grouped help. `make all` still builds.
all: build

build:
	$(XCODEBUILD) -configuration "$(CONFIGURATION_DEBUG)" build

release:
	$(XCODEBUILD) -configuration "$(CONFIGURATION_RELEASE)" ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64" build

run: build
	open "$(BUILD_DIR)/Build/Products/$(CONFIGURATION_DEBUG)/EasyKey.app"

test:
	$(XCODEBUILD) -enableCodeCoverage YES test

coverage: test
	@xcrun xccov view --report $(shell ls -t $(BUILD_DIR)/Logs/Test/*.xcresult | head -1) 2>/dev/null | head -40

lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not installed. Install with: brew install swiftlint"; \
	fi

format:
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat .; \
	else \
		echo "SwiftFormat not installed. Install with: brew install swiftformat"; \
	fi

clean:
	$(XCODEBUILD) clean
	rm -rf "$(BUILD_DIR)"

# Quit EasyKey and wipe local runtime / test data (prefs, App Support, etc.).
clean-local:
	Scripts/clean-local.sh

# Build artifacts + local runtime / test data.
clean-all: clean clean-local

qa:
	Scripts/qa-gate.sh

archive:
	Scripts/archive.sh

export:
	Scripts/export.sh

verify-arch:
	Scripts/verify-arch.sh

verify-release:
	Scripts/verify-release.sh

# Signed distribution path (requires Developer ID + release env vars).
dmg: archive export
	Scripts/verify-release.sh
	Scripts/create-dmg.sh "$(BUILD_DIR)/export/EasyKey.app"

# Local universal DMG without Developer ID / notarization secrets.
local-dmg:
	RELEASE_LOCAL=1 Scripts/archive.sh
	RELEASE_LOCAL=1 Scripts/export.sh
	RELEASE_LOCAL=1 Scripts/verify-release.sh
	Scripts/create-dmg.sh "$(BUILD_DIR)/export/EasyKey.app"

# ---------------------------------------------------------------------------
# Help — grouped by usage. Run `make` (no args) or `make help`.
# ---------------------------------------------------------------------------
help:
	@echo ""
	@echo "  ╭───────────────────────────────────────────────────────────╮"
	@echo "  │  EasyKey — Make targets                                   │"
	@echo "  ╰───────────────────────────────────────────────────────────╯"
	@echo ""
	@echo "  Development"
	@echo "    make build          Debug build → build/Build/Products/Debug/EasyKey.app"
	@echo "    make run            Build debug + launch app"
	@echo "    make test           Unit + UI tests (with code coverage)"
	@echo "    make coverage       Print coverage summary from last test run"
	@echo "    make lint           Run SwiftLint (brew install swiftlint)"
	@echo "    make format         Run SwiftFormat (brew install swiftformat)"
	@echo ""
	@echo "  Clean"
	@echo "    make clean          Remove build/ artifacts (xcodebuild clean)"
	@echo "    make clean-local    Quit EasyKey + wipe local app/test data"
	@echo "    make clean-all      clean + clean-local"
	@echo ""
	@echo "  Quality"
	@echo "    make qa             Full QA gate (tests + verify-qa-artifacts)"
	@echo ""
	@echo "  Release (unsigned / local)"
	@echo "    make release        Universal Release build (arm64 + x86_64, no signing)"
	@echo "    make local-dmg      Universal ad-hoc DMG (no Developer ID, no notarization)"
	@echo ""
	@echo "  Release (signed / distributed)"
	@echo "    make archive        Create signed archive (needs Developer ID env)"
	@echo "    make export         Export .app from archive"
	@echo "    make verify-arch    Confirm arm64 + x86_64 in exported app"
	@echo "    make verify-release Full release verification"
	@echo "    make dmg            Signed universal DMG (needs Developer ID + notarization secrets)"
	@echo ""
	@echo "  Other"
	@echo "    make all            Build debug (default for 'make all')"
	@echo "    make help           Show this help"
	@echo ""
