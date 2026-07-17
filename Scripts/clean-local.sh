#!/bin/zsh
# Remove EasyKey local runtime / test data so the next launch starts fresh.
# Does not remove the installed app; use `make clean` for build artifacts.
set -euo pipefail

setopt NULL_GLOB

print "==> Quitting EasyKey if running..."
osascript -e 'quit app "EasyKey"' 2>/dev/null || true
killall EasyKey EasyKeyApp EasyKeyLoginHelper 2>/dev/null || true
sleep 0.3

print "==> Removing Application Support..."
rm -rf "${HOME}/Library/Application Support/EasyKey"

print "==> Removing CrashReporter leftovers..."
rm -f "${HOME}/Library/Application Support/CrashReporter"/EasyKey*
rm -f "${HOME}/Library/Application Support/CrashReporter"/EasyKeyApp*
rm -f "${HOME}/Library/Application Support/CrashReporter"/EasyKeyLoginHelper*

print "==> Removing Preferences..."
rm -f "${HOME}/Library/Preferences/one.ifelse.easykey.plist"
rm -f "${HOME}/Library/Preferences/com.easykey.EasyKey.plist"
rm -f "${HOME}/Library/Preferences"/one.ifelse.easykey.localization-tests.*.plist
rm -f "${HOME}/Library/Preferences"/one.ifelse.*.plist
rm -f "${HOME}/Library/Preferences"/com.easykey.*.plist

print "==> Removing defaults domains..."
defaults delete one.ifelse.easykey 2>/dev/null || true
defaults delete com.easykey.EasyKey 2>/dev/null || true
defaults delete one.ifelse.easykey.LoginHelper 2>/dev/null || true
defaults delete one.ifelse.easykeyKit 2>/dev/null || true
defaults delete com.easykey.EasyEngineCore 2>/dev/null || true

print "==> Clearing UITest containers (Data)..."
for container in \
    "${HOME}/Library/Containers/one.ifelse.EasyKeyUITests.xctrunner" \
    "${HOME}/Library/Containers/com.easykey.EasyKeyUITests.xctrunner"
do
    if [[ -d "$container" ]]; then
        rm -rf "${container}/Data" "${container}/tmp" 2>/dev/null || true
        # Full folder may retain Apple-protected metadata; ignore if so.
        rm -rf "$container" 2>/dev/null || true
    fi
done

print "==> Removing caches / saved state / HTTP / logs..."
rm -rf "${HOME}/Library/Caches/one.ifelse.easykey"
rm -rf "${HOME}/Library/Caches/com.easykey.EasyKey"
rm -rf "${HOME}/Library/Caches/EasyKey"
rm -rf "${HOME}/Library/Saved Application State/one.ifelse.easykey.savedState"
rm -rf "${HOME}/Library/Saved Application State/com.easykey.EasyKey.savedState"
rm -rf "${HOME}/Library/HTTPStorages/one.ifelse.easykey"
rm -rf "${HOME}/Library/HTTPStorages/com.easykey.EasyKey"
rm -rf "${HOME}/Library/Logs/EasyKey"
rm -rf "${HOME}/Library/Logs/one.ifelse.easykey"

print "==> Removing Xcode DerivedData (EasyKey*)..."
rm -rf "${HOME}/Library/Developer/Xcode/DerivedData"/EasyKey*

print "==> Flushing preference cache..."
killall cfprefsd 2>/dev/null || true

print "EasyKey local data cleaned."
