PROJECT = EasyKey.xcodeproj
SCHEME = EasyKeyApp
CONFIGURATION_DEBUG = Debug
CONFIGURATION_RELEASE = Release
DESTINATION = platform=macOS
BUILD_DIR = $(CURDIR)/build
XCODEBUILD = xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination "$(DESTINATION)" -derivedDataPath "$(BUILD_DIR)"

.DEFAULT_GOAL := help

.PHONY: all build release run test test-parallel coverage coverage-parallel coverage-gate build-for-testing lint format clean clean-local clean-all qa archive export verify-arch verify-release dmg local-dmg help

# `make` with no args prints grouped help. `make all` still builds.
all: build

build:
	$(XCODEBUILD) -configuration "$(CONFIGURATION_DEBUG)" build

release:
	$(XCODEBUILD) -configuration "$(CONFIGURATION_RELEASE)" ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64" build

run: build
	open "$(BUILD_DIR)/Build/Products/$(CONFIGURATION_DEBUG)/EasyKey.app"

COVERAGE_THRESHOLD ?= 90
SHARDS_DIR = $(BUILD_DIR)/Shards
MERGED_XCRESULT = $(BUILD_DIR)/Merged.xcresult

# Per-shard test filters (mirror .github/workflows/ci.yml).
FILTER_unit = -only-testing:EasyKeyTests
FILTER_ui-1 = -only-testing:EasyKeyUITests/SettingsCoverageTests
FILTER_ui-2 = -only-testing:EasyKeyUITests/SettingsInteractionTests
FILTER_ui-3 = -only-testing:EasyKeyUITests/SettingsNavigationTests \
              -only-testing:EasyKeyUITests/SettingsWorkflowTests \
              -only-testing:EasyKeyUITests/OnboardingCoverageTests \
              -only-testing:EasyKeyUITests/SettingsAccessibilityTests \
              -only-testing:EasyKeyUITests/EasyKeyUITests
SHARDS = unit ui-1 ui-2 ui-3

# Serial full run — reliable local default.
test:
	$(XCODEBUILD) -enableCodeCoverage YES test

# Full run + enforce the same coverage gate as CI.
coverage: test
	@$(MAKE) --no-print-directory coverage-gate \
		XCRESULT="$(shell ls -td $(BUILD_DIR)/Logs/Test/*.xcresult | head -1)"

# Parallel sharded run: build once, then run each shard concurrently, merge, gate.
# NOTE: all shards share one UserDefaults domain on a single Mac, so UI shards can
# flake here. If you see spurious failures, fall back to serial `make test`.
test-parallel: build-for-testing
	@rm -rf "$(SHARDS_DIR)" && mkdir -p "$(SHARDS_DIR)"
	@echo "Running shards in parallel: $(SHARDS)"
	@$(MAKE) --no-print-directory -j$(words $(SHARDS)) $(addprefix shard-,$(SHARDS))
	@$(MAKE) --no-print-directory coverage-gate \
		XCRESULT="$(shell echo $(addsuffix .xcresult,$(addprefix $(SHARDS_DIR)/,$(SHARDS))))" \
		MERGE=1

# Alias so `make coverage-parallel` reads naturally.
coverage-parallel: test-parallel

build-for-testing:
	$(XCODEBUILD) -enableCodeCoverage YES build-for-testing

# shard-<name>: run one shard's filter against the already-built product.
shard-%:
	$(XCODEBUILD) -enableCodeCoverage YES \
		-resultBundlePath "$(SHARDS_DIR)/$*.xcresult" \
		$(FILTER_$*) \
		test-without-building

# coverage-gate: merge (if MERGE=1) then enforce COVERAGE_THRESHOLD on XCRESULT.
coverage-gate:
	@set -e; \
	if [ "$(MERGE)" = "1" ]; then \
		rm -rf "$(MERGED_XCRESULT)"; \
		xcrun xcresulttool merge $(XCRESULT) --output-path "$(MERGED_XCRESULT)"; \
		report="$(MERGED_XCRESULT)"; \
	else \
		report="$(XCRESULT)"; \
	fi; \
	Scripts/check-coverage.sh "$$report" "$(COVERAGE_THRESHOLD)"

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

release-config-check:
	@if [ -z "$$SPARKLE_PUBLIC_ED_KEY" ]; then \
		echo "Error: SPARKLE_PUBLIC_ED_KEY environment variable is not set." >&2; \
		exit 1; \
	fi

verify-arch:
	Scripts/verify-arch.sh

verify-release:
	Scripts/verify-release.sh

# Signed and notarized distribution path.
dmg: release-config-check archive export
	@set -e; \
	app="$(BUILD_DIR)/export/EasyKey.app"; \
	version=$$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$$app/Contents/Info.plist"); \
	dmg="$(BUILD_DIR)/EasyKey-$$version-universal.dmg"; \
	Scripts/verify-arch.sh "$$app"; \
	codesign --verify --deep --strict --verbose=2 "$$app"; \
	Scripts/notarize.sh "$$app"; \
	Scripts/staple.sh "$$app"; \
	DMG_PATH="$$dmg" Scripts/create-dmg.sh "$$app"; \
	Scripts/notarize.sh "$$dmg"; \
	Scripts/staple.sh "$$dmg"; \
	Scripts/verify-release.sh "$$app" "$$dmg"

# Local universal DMG without Developer ID / notarization secrets.
local-dmg: release-config-check
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
	@echo "    make test           Unit + UI tests, serial (with code coverage)"
	@echo "    make test-parallel  Sharded parallel run (faster; UI shards may flake)"
	@echo "    make coverage       Serial run + enforce $(COVERAGE_THRESHOLD)% coverage gate"
	@echo "    make coverage-parallel  Sharded parallel run + coverage gate"
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
	@echo "    make dmg            Signed + notarized universal DMG (needs release secrets)"
	@echo ""
	@echo "  Other"
	@echo "    make all            Build debug (default for 'make all')"
	@echo "    make help           Show this help"
	@echo ""
